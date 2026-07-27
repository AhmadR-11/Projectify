# ==============================================================================
# PROJECTIFY — PRODUCTION DOCKERFILE
# ==============================================================================
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  ❓ DOES THIS DOCKERFILE CREATE MULTIPLE CONTAINERS?                        │
# │                                                                             │
# │  NO. This Dockerfile creates ONE single image → ONE single container.       │
# │                                                                             │
# │  It uses a "Multi-Stage Build" pattern with 3 stages, but stages are        │
# │  TEMPORARY build-time steps only — like scaffolding during construction.    │
# │  Once the build finishes, all temporary stages are DISCARDED automatically. │
# │  Only the FINAL stage (runner) becomes the Docker image and container.      │
# │                                                                             │
# │  STAGE 1: deps      → ❌ TEMPORARY (installs all deps including devDeps)    │
# │  STAGE 2: prod-deps → ❌ TEMPORARY (prunes devDeps → lean node_modules)     │
# │  STAGE 3: builder   → ❌ TEMPORARY (compiles Next.js app)                   │
# │  STAGE 4: runner    → ✅ FINAL IMAGE → runs as: Container: projectify-app   │
# │                                                                             │
# │  The postgres and redis containers are created by docker-compose.yml,       │
# │  NOT by this Dockerfile.                                                    │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ARCHITECTURE: Multi-Stage Build (4 stages — optimized for image size)
#
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │  STAGE 1: deps      (TEMPORARY — installs ALL deps for building)        │
#   │  Purpose : npm ci — installs both prod + devDependencies               │
#   ├─────────────────────────────────────────────────────────────────────────┤
#   │  STAGE 2: prod-deps (TEMPORARY — produces LEAN node_modules for runner) │
#   │  Purpose : Start from full install, then prune ALL devDependencies      │
#   │  Saves   : ~300-400MB (TypeScript, ESLint, Tailwind, Prisma CLI gone)   │
#   ├─────────────────────────────────────────────────────────────────────────┤
#   │  STAGE 3: builder   (TEMPORARY — compiles the Next.js app)              │
#   │  Purpose : Uses Stage 1's full deps to run next build + prisma generate │
#   ├─────────────────────────────────────────────────────────────────────────┤
#   │  STAGE 4: runner    (FINAL IMAGE → becomes the actual running container)│
#   │  Container Name   : projectify-app                                      │
#   │  Container Purpose: Runs Node.js server (Next.js + Socket.IO)           │
#   │  node_modules from: Stage 2 (prod-deps — lean, no build tools)         │
#   │  .next output from: Stage 3 (builder — fully compiled)                 │
#   │  Port             : 3000                                                │
#   └─────────────────────────────────────────────────────────────────────────┘
#
# KEY FACTS ABOUT THIS PROJECT:
#   - Entrypoint   : node server.js  (custom HTTP + Socket.IO server)
#   - NOT using    : next start      (custom server.js overrides this)
#   - Port         : 3000 (or $PORT env var)
#   - Build cmd    : prisma generate && next build
#   - Sharp        : Requires native platform-specific binaries (handled below)
#   - Prisma       : Needs schema + generated client in the runner image
#   - Socket.IO    : Runs inside the same Node.js HTTP server process
#
# HOW TO BUILD:
#   docker build -t projectify-app:latest .
#
# HOW TO RUN (with all required env vars):
#   docker run -p 3000:3000 --env-file .env projectify-app:latest
# ==============================================================================


# ==============================================================================
# STAGE 1 — deps
# ❌ NOT A CONTAINER — This is a TEMPORARY build stage (discarded after build)
# ─────────────────────────────────────────────────────────────────────────────
# Purpose : Install all npm dependencies needed to build the application.
#           Both devDependencies (TypeScript, Prisma CLI, Tailwind) and
#           production dependencies are installed here.
# Why separate stage? So the final image does NOT include build tools,
#           keeping the production container lean and secure.
# Install all dependencies (both devDependencies and dependencies)
# We need devDependencies at this stage because TypeScript, Prisma CLI,
# Tailwind, ESLint, and PostCSS are all devDependencies but required at build.
# ==============================================================================
FROM node:18-alpine AS deps

# Install system-level dependencies required by native Node.js modules:
#
#   libc6-compat  → Required by Next.js and some native modules on Alpine Linux
#                   (Alpine uses musl libc instead of glibc; this adds compat layer)
#   openssl       → Required by Prisma to connect to PostgreSQL over SSL
#   python3       → Required by node-gyp (bcrypt native bindings need it)
#   make          → Required by node-gyp for compiling C++ native addons
#   g++           → C++ compiler required by bcrypt + other native packages
RUN apk add --no-cache \
    libc6-compat \
    openssl \
    python3 \
    make \
    g++

# Set the working directory inside the container
# All subsequent commands will run from /app
WORKDIR /app

# Copy ONLY the package manifests first (before copying source code)
# This leverages Docker's layer caching:
#   - If package.json hasn't changed → Docker reuses the cached node_modules layer
#   - If package.json DID change     → Docker re-runs npm ci from scratch
#   This makes rebuilds significantly faster when only source code changes.
COPY package.json package-lock.json ./

# Copy Prisma schema now because postinstall runs "prisma generate"
# Prisma generate requires the schema.prisma file to exist during npm install
COPY prisma ./prisma

# Install ALL dependencies (including devDependencies) using package-lock.json
# --frozen-lockfile ensures exact versions from lock file (no surprise updates)
# This is important for reproducible builds in CI/CD pipelines
#
# ─── Network Retry Settings ──────────────────────────────────────────────────
# These settings prevent ECONNRESET errors (network timeout during npm ci)
# when Docker's internet connection is slow or briefly interrupted:
#   fetch-retry-mintimeout : minimum wait between retries (20 seconds)
#   fetch-retry-maxtimeout : maximum wait between retries (120 seconds)
#   fetch-retries          : retry failed downloads up to 5 times
#   fetch-timeout          : give each individual request 300 seconds
#
# The --prefer-offline flag uses locally cached packages first (if available)
# so re-builds are much faster (no re-downloading packages that haven't changed)
RUN npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-retries 5 && \
    npm config set fetch-timeout 300000 && \
    npm ci --prefer-offline || npm ci


# ==============================================================================
# STAGE 2 — prod-deps
# ❌ NOT A CONTAINER — TEMPORARY build stage (discarded after build)
# ─────────────────────────────────────────────────────────────────────────────
# PURPOSE: Produce a LEAN node_modules that has ONLY production dependencies.
#          This is what goes into the final runner image — NOT the full install.
#
# WHY THIS SAVES ~300-400MB:
#   Full install (Stage 1) includes devDependencies:
#     - typescript       (~60MB)  ← compiler, useless at runtime
#     - tailwindcss      (~50MB)  ← CSS build tool, useless at runtime
#     - eslint           (~50MB)  ← linter, useless at runtime
#     - prisma CLI       (~50MB)  ← migration tool, useless at runtime
#     - postcss          (~10MB)  ← CSS processor, useless at runtime
#     - @types/*         (~80MB)  ← TypeScript type defs, useless at runtime
#   This stage removes ALL of the above, keeping only what the app needs to RUN.
#
# HOW IT WORKS:
#   1. Start from the full deps install (Stage 1)
#   2. Run `npm prune --omit=dev` — removes all devDependencies from node_modules
#   3. The lean node_modules is then copied to the final runner image
#
# WHY NOT just run `npm ci --omit=dev` directly?
#   Because `postinstall` runs `prisma generate` which needs the Prisma CLI.
#   The Prisma CLI is a devDependency — so we need to install everything first,
#   then prune. Pruning after install is the correct pattern here.
# ==============================================================================
FROM node:18-alpine AS prod-deps

RUN apk add --no-cache \
    libc6-compat \
    openssl

WORKDIR /app

# Start from the full node_modules produced in Stage 1
# (which includes devDeps needed for postinstall/prisma generate)
COPY --from=deps /app/node_modules ./node_modules

# Copy package.json so npm knows which packages are devDependencies
COPY package.json package-lock.json ./

# Remove ALL devDependencies from node_modules in-place
# After this command, node_modules contains ONLY production dependencies
# Packages removed: typescript, tailwindcss, eslint, prisma CLI, postcss, @types/*
RUN npm prune --omit=dev


# ==============================================================================
# STAGE 3 — builder
# ❌ NOT A CONTAINER — This is a TEMPORARY build stage (discarded after build)
# ─────────────────────────────────────────────────────────────────────────────
# Purpose : Compile the full TypeScript/Next.js application into optimized
#           production JavaScript. Also generates the Prisma database client.
#           After this stage completes, only the compiled OUTPUT (.next/ folder
#           and generated Prisma client) is passed to Stage 3. All source files,
#           TypeScript files, and build tools are discarded.
# Compile the Next.js application and generate Prisma client
# This stage produces the .next build output and generated Prisma client
# ==============================================================================
FROM node:18-alpine AS builder

# Install OpenSSL for Prisma SSL connection + libc compatibility for Alpine
RUN apk add --no-cache \
    libc6-compat \
    openssl

WORKDIR /app

# Copy all node_modules from the deps stage
# This avoids re-running npm install in the builder stage
COPY --from=deps /app/node_modules ./node_modules

# Copy the entire project source code into the builder container
# .dockerignore prevents unnecessary files (node_modules, .git, .env etc.)
# from being included in the Docker build context
COPY . .

# ─── Build-time Environment Variables ────────────────────────────────────────
# Next.js bakes NEXT_PUBLIC_* variables into the JavaScript bundle at BUILD time.
# These are NOT secrets — they are embedded into client-side JavaScript.
# Runtime secrets (DATABASE_URL, API keys, etc.) must be passed at container
# startup via --env-file or Kubernetes Secrets (never baked into the image).
#
# These ARG values are declared here so they can be passed via:
#   docker build --build-arg NEXT_PUBLIC_APP_URL=https://myapp.com .
# Or via Jenkins pipeline environment variables.
ARG NEXT_PUBLIC_APP_URL
ARG NEXT_PUBLIC_SOCKET_URL

# Expose the ARGs as ENV so Next.js build process can access them
ENV NEXT_PUBLIC_APP_URL=$NEXT_PUBLIC_APP_URL
ENV NEXT_PUBLIC_SOCKET_URL=$NEXT_PUBLIC_SOCKET_URL

# Tell Next.js this is a production build.
# This enables production optimizations (minification, tree-shaking, etc.)
ENV NODE_ENV=production

# Disable Next.js telemetry data collection during builds
# This is a best practice in CI/CD to avoid unexpected outbound network calls
ENV NEXT_TELEMETRY_DISABLED=1

# ─── Run the production build ─────────────────────────────────────────────────
# This runs the "build" script from package.json:
#   "build": "prisma generate && next build"
#
# Step 1 — prisma generate:
#   Reads prisma/schema.prisma and generates the TypeScript Prisma client
#   in node_modules/@prisma/client. This MUST run before next build because
#   the app imports from @prisma/client throughout the codebase.
#
# Step 2 — next build:
#   - Compiles all TypeScript files
#   - Runs the SWC minifier (swcMinify: true in next.config.mjs)
#   - Tree-shakes large packages (lucide, framer-motion, three, recharts)
#   - Builds the .next/ output directory with all static assets and page chunks
RUN npm run build


# ==============================================================================
# STAGE 3 — runner
# ✅ THE ACTUAL CONTAINER — This is the ONLY stage that becomes a running container
# ─────────────────────────────────────────────────────────────────────────────
# Container Name    : projectify-app  (tagged as projectify-app:latest)
# Container Purpose : Runs the complete Projectify web application
#                     - Next.js App Router (SSR + API Routes)
#                     - Socket.IO WebSocket server (real-time chat)
#                     - Background meeting reminder CRON scheduler
#                     - Prisma ORM connecting to PostgreSQL
# Container Port    : 3000
# Container Runtime : node server.js (custom HTTP + Socket.IO entrypoint)
# ─────────────────────────────────────────────────────────────────────────────
# This is the smallest possible image that can run the application.
# It contains ONLY the compiled output and production runtime files.
# Build tools, TypeScript source, and devDependencies are NOT included.
# (They were used in Stage 1 and Stage 2 which are now discarded)
# Build tools, devDependencies, and source TypeScript files are NOT included.
# ==============================================================================
FROM node:18-alpine AS runner

# Install ONLY the runtime system dependencies needed:
#   openssl     → Required by Prisma for SSL connections to PostgreSQL
#   dumb-init   → Lightweight process manager for Docker containers:
#                 - Handles UNIX signal forwarding (SIGTERM, SIGINT) correctly
#                 - Prevents zombie processes in containerized Node.js apps
#                 - Ensures graceful shutdown when Kubernetes sends SIGTERM
RUN apk add --no-cache \
    openssl \
    dumb-init

WORKDIR /app

# Set Node.js environment to production
# This disables React dev-mode warnings and enables production optimizations
ENV NODE_ENV=production

# Disable Next.js telemetry in production runtime as well
ENV NEXT_TELEMETRY_DISABLED=1

# Set default port (can be overridden at container runtime via $PORT env var)
# This matches what server.js reads: process.env.PORT || '3000'
ENV PORT=3000

# ─── Create a non-root user for security ─────────────────────────────────────
# Running as root inside a container is a security risk.
# If an attacker gains code execution, root inside the container maps to root
# outside (in many configurations). A non-root user limits blast radius.
# -S = system user (no shell/password), -G = assign to group
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# ─── Copy build artifacts from the builder stage ─────────────────────────────
# We selectively copy ONLY what is needed to run the application.
# Anything not copied here does NOT end up in the final image.

# Copy the compiled Next.js output directory
# This contains all pages, chunks, static files, and the server manifest
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next

# Copy LEAN production-only node_modules from the prod-deps stage (Stage 2)
# This node_modules has had ALL devDependencies removed via `npm prune --omit=dev`
# It is ~300-400MB smaller than the full node_modules from the builder stage
# Packages REMOVED (not in this copy): typescript, tailwindcss, eslint,
# prisma CLI, postcss, @types/*, eslint-config-next
# Packages KEPT: next, react, prisma client, socket.io, cohere, three, etc.
COPY --from=prod-deps --chown=nextjs:nodejs /app/node_modules ./node_modules

# Copy the custom Node.js HTTP + Socket.IO server
# This is the ENTRYPOINT of the application — not `next start`
COPY --from=builder --chown=nextjs:nodejs /app/server.js ./server.js

# Copy the meeting scheduler runner (required by server.js on startup)
# This background CRON module is loaded by server.js at boot time
COPY --from=builder --chown=nextjs:nodejs /app/lib/meeting-scheduler-runner.js ./lib/meeting-scheduler-runner.js

# Copy Prisma schema and generated client
# - schema.prisma is needed at runtime for Prisma to resolve connection
# - The generated @prisma/client is already in node_modules (copied above)
COPY --from=builder --chown=nextjs:nodejs /app/prisma ./prisma

# Copy the Next.js configuration file
# Required at runtime by the Next.js server for image optimization,
# redirect rules, and custom headers
COPY --from=builder --chown=nextjs:nodejs /app/next.config.mjs ./next.config.mjs

# Copy package.json (required by Node.js module resolution at runtime)
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./package.json

# Copy public directory (static assets: favicon, images, fonts, etc.)
# These are served directly by Next.js without going through the app logic
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# ─── Switch to non-root user ──────────────────────────────────────────────────
# All subsequent commands and the running container will execute as 'nextjs' user
USER nextjs

# ─── Expose the application port ─────────────────────────────────────────────
# EXPOSE is metadata only — it documents which port the container listens on.
# Actual port binding happens with -p 3000:3000 in docker run or in docker-compose.yml
# This must match server.js: process.env.PORT || '3000'
EXPOSE 3000

# ─── Health Check ─────────────────────────────────────────────────────────────
# Docker and Kubernetes will use this to determine if the container is healthy.
# - Calls the /api/health endpoint (already built into this project)
# - interval: check every 30 seconds
# - timeout: wait up to 10 seconds for a response
# - start-period: give the app 40 seconds to start before health checks begin
#   (Next.js + Prisma + Socket.IO startup takes a few seconds)
# - retries: mark as unhealthy after 3 consecutive failures
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:' + (process.env.PORT || 3000) + '/api/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# ─── Container Startup Command ────────────────────────────────────────────────
# dumb-init is the process manager (PID 1 inside the container)
# It correctly forwards signals (SIGTERM from `docker stop` / Kubernetes) to node
# which allows the app to gracefully close connections before shutting down.
#
# DO NOT use: CMD ["node", "server.js"]
# Using dumb-init as PID 1 prevents zombie process accumulation and
# ensures Kubernetes pod termination works correctly.
CMD ["dumb-init", "node", "server.js"]
