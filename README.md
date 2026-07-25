<div align="center">

# 🚀 Projectify

### Centralized Final Year Project Management Platform

*A full-stack, AI-powered platform for managing the complete FYP lifecycle across multi-campus university environments.*

[![Next.js](https://img.shields.io/badge/Next.js-14.2-black?logo=nextdotjs)](https://nextjs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.4-blue?logo=typescript)](https://typescriptlang.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-latest-336791?logo=postgresql)](https://postgresql.org)
[![Prisma](https://img.shields.io/badge/Prisma-5.14-2D3748?logo=prisma)](https://prisma.io)
[![Socket.IO](https://img.shields.io/badge/Socket.IO-4.8-black?logo=socketdotio)](https://socket.io)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-3.4-38bdf8?logo=tailwindcss)](https://tailwindcss.com)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Key Features](#-key-features)
- [User Roles](#-user-roles)
- [AI Pipeline](#-ai-pipeline)
- [Database Schema](#-database-schema)
- [Project Structure](#-project-structure)
- [Environment Variables](#-environment-variables)
- [Getting Started](#-getting-started)
- [Deployment](#-deployment)
- [API Overview](#-api-overview)

---

## 🌐 Overview

**Projectify** is a comprehensive, multi-tenant Final Year Project (FYP) Management Platform engineered for multi-campus university environments. It orchestrates the complete FYP lifecycle — from initial team formation and project proposals, to supervisor mentorship, hardware resource management, automated meeting scheduling, encrypted real-time messaging, and multi-stage panel evaluation defense systems.

The platform is underpinned by an **integrated AI engine** that:
- Parses uploaded proposal documents (PDF/DOCX)
- Extracts structured metadata using an LLM
- Validates project feasibility within a 4-month academic timeline
- Performs semantic vector similarity searches to block duplicate projects from prior years

---

## 🏛️ Architecture

Projectify follows a **Layered Monolith with Real-Time Extension** architecture pattern, combining the reliability of a well-structured monolith with the scalability characteristics of microservice-adjacent cloud services.

```
┌─────────────────────────────────────────────────────────────────────┐
│                          CLIENT BROWSER                             │
│                                                                     │
│   React 18 + Next.js App Router  │  Socket.IO Client (WebSocket)   │
└──────────────────┬──────────────────────────────┬──────────────────┘
                   │ HTTPS                        │ WSS
                   ▼                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    NODE.JS SERVER  (server.js)                      │
│                                                                     │
│  ┌──────────────────────┐    ┌──────────────────────────────────┐  │
│  │   Next.js Handler     │    │        Socket.IO Server          │  │
│  │   (App Router SSR)    │    │  (path: /api/socketio)           │  │
│  │                       │    │  - Rate limiting (30msg/10s)     │  │
│  │  ┌─────────────────┐  │    │  - User socket mapping           │  │
│  │  │   Middleware     │  │    │  - Room management               │  │
│  │  │  (auth + RBAC)  │  │    │  - AES-256 message encryption   │  │
│  │  └─────────────────┘  │    └──────────┬───────────────────────┘  │
│  └──────────┬────────────┘               │                          │
│             │                            │  Redis PubSub            │
└─────────────┼────────────────────────────┼──────────────────────────┘
              │                            ▼
              │              ┌─────────────────────────┐
              │              │         REDIS            │
              │              │  (@socket.io/redis-      │
              │              │   adapter)               │
              │              │  - Cross-server WS       │
              │              │    broadcasting          │
              │              └─────────────────────────┘
              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     API ROUTES  (app/api/**)                        │
│                                                                     │
│  /auth     /admin    /coordinator    /supervisor    /student        │
│  /chat     /groups   /meetings       /projects      /notifications  │
│  /profile  /invitations              /resource-requests             │
│  /evaluations        /industrial-projects           /cron           │
└──────────┬──────────────────────┬──────────────────────────────────┘
           │                      │
           ▼                      ▼
┌─────────────────────┐  ┌───────────────────────────────────────────┐
│  PRISMA ORM (v5.14) │  │           CLOUD SERVICES                  │
│                     │  │                                           │
│  - Type-safe query  │  │  ┌──────────────┐  ┌───────────────────┐  │
│  - Relations        │  │  │  Cohere AI   │  │     Pinecone      │  │
│  - Migrations       │  │  │  (LLM + Embed│  │  (Vector Search)  │  │
│  - Connection pool  │  │  │   API)       │  │  project-         │  │
└──────────┬──────────┘  │  └──────────────┘  │  embeddings index │  │
           │             │                     └───────────────────┘  │
           ▼             │  ┌──────────────┐  ┌───────────────────┐  │
┌──────────────────────┐ │  │ Cloudflare   │  │  Brevo / Resend   │  │
│     POSTGRESQL        │ │  │ R2 Storage   │  │  (Email API)      │  │
│                       │ │  │ (S3-compat.) │  │                   │  │
│  - Users / Auth       │ │  └──────────────┘  └───────────────────┘  │
│  - Campuses           │ └───────────────────────────────────────────┘
│  - Groups / Students  │
│  - Projects           │
│  - Chat Messages      │
│  - Evaluations        │
│  - Notifications      │
│  - Meetings           │
│  - Resource Requests  │
└──────────────────────┘
```

### Architecture Decision: Why Layered Monolith?

| Concern | Decision | Reason |
|---|---|---|
| **Scalability** | Stateless Next.js + Redis WS adapter | Allows horizontal pod scaling without socket state loss |
| **Latency** | Server-side Prisma queries | Eliminates N+1 and cross-service network hops |
| **Real-time** | Socket.IO co-located with app server | Avoids a separate WS microservice while retaining Redis-based horizontal scaling |
| **AI** | External Cohere + Pinecone APIs | Heavy ML workloads offloaded to purpose-built managed services |
| **Storage** | Cloudflare R2 (S3-compat.) | Cost-effective zero-egress-fee object storage |

---

## 🛠️ Tech Stack

### Frontend

| Technology | Version | Purpose |
|---|---|---|
| **Next.js** | 14.2 | App Router framework (SSR + RSC + API Routes) |
| **React** | 18.3 | Component rendering engine |
| **TypeScript** | 5.4 | Static typing across the entire codebase |
| **Tailwind CSS** | 3.4 | Utility-first CSS framework |
| **Radix UI** | Latest | Accessible, unstyled UI primitives (Label, Slot) |
| **shadcn/ui** | - | Design system built on Radix UI + Tailwind |
| **Framer Motion** | 11 | Declarative animations and page transitions |
| **Recharts** | 3.5 | SVG-based data visualization and dashboards |
| **Three.js + R3F** | 0.160 / 8.15 | 3D interactive hero scenes on landing page |
| **tsParticles** | 3.9 | Animated particle canvas backgrounds |
| **Lucide React** | 0.390 | Icon library |
| **emoji-picker-react** | 4.16 | Emoji picker in chat interface |

### Backend

| Technology | Version | Purpose |
|---|---|---|
| **Node.js** | ≥18 | JavaScript runtime (custom `server.js`) |
| **Next.js API Routes** | 14.2 | Serverless-style REST API handlers |
| **NextAuth.js** | 5.0-beta | Authentication (Credentials + JWT strategy) |
| **Bcrypt / Bcryptjs** | 5.1 / 3.0 | Password hashing |
| **Socket.IO** | 4.8 | WebSocket server for real-time messaging |
| **Prisma ORM** | 5.14 | Database ORM with migrations |
| **ioredis** | 5.9 | Redis client for Socket.IO horizontal scaling |
| **@socket.io/redis-adapter** | 8.3 | Redis pub/sub adapter for multi-instance WebSockets |

### Databases & Storage

| Service | Type | Purpose |
|---|---|---|
| **PostgreSQL** | Relational DB | Primary data store (all app models) |
| **Pinecone** | Vector DB | Semantic similarity search for project embeddings |
| **Redis** | In-memory store | WebSocket message broadcasting across server instances |
| **Cloudflare R2** | Object Storage | File uploads (proposals, profile images, resources) |

### AI & Document Processing

| Library / Service | Purpose |
|---|---|
| **Cohere AI** (`command-r7b-12-2024`) | LLM for metadata extraction, feasibility analysis, duplication explanation |
| **Cohere Embed API** | 1024-dimensional semantic vector embeddings |
| **Pinecone** (`project-embeddings` index) | Cosine similarity search against past project vectors |
| **pdf-parse** | Extracts raw text from PDF proposal documents |
| **mammoth** | Extracts text content from DOCX proposal documents |
| **sharp** | Server-side image processing and optimization |

### Communications & Email

| Service | Purpose |
|---|---|
| **Brevo API** | Primary transactional email provider (HTTP API, Railway compatible) |
| **Resend** | Alternative email provider (API-based) |
| **Nodemailer** | Fallback SMTP email transport |

### Document & Data Utilities

| Library | Purpose |
|---|---|
| **xlsx** | Generate Excel spreadsheets for grade exports |
| **jszip / adm-zip** | Compress and package project files for bulk download |
| **uuid** | Generate universally unique identifiers |

### Dev & Build Tools

| Tool | Purpose |
|---|---|
| **Prisma CLI** | Schema migration and database seeding |
| **ESLint** | Code linting (`eslint-config-next`) |
| **PostCSS + Autoprefixer** | CSS post-processing for Tailwind |
| **SWC** | Rust-based fast minification (`swcMinify: true`) |
| **nixpacks.toml** | Railway build configuration |

---

## 🌟 Key Features

### 🤖 AI-Backed Proposal Processing
Automatically processes student project proposals through a multi-step AI pipeline:
- **Document Parsing**: Extracts raw text from PDF and DOCX files
- **LLM Metadata Extraction**: Pulls title, abstract, tech stack, and required skills in strict JSON format
- **Feasibility Scoring**: Cohere grades timeline realism, team capability, and resource requirements — generating a Risk Report with scope alteration suggestions
- **Semantic Deduplication**: 1024-dimensional Cohere embeddings are upserted into Pinecone; cosine similarity > 50% triggers a "duplicate" flag with an LLM-generated human-readable explanation

### 💬 Real-Time Encrypted Messaging
- 1-on-1 and group chat between students, supervisors, and coordinators
- **AES-256-CBC encryption** applied to all messages before database persistence
- Typing indicators, read receipts, and online/offline presence
- File sharing support (uploaded to Cloudflare R2)
- Rate limiting (max 30 messages per 10-second window per user)

### 📋 Multi-Stage Evaluation Panels
- Coordinators configure formal "Panel Checkpoints" (e.g., Proposal Defense, Mid-term, Final Defense)
- Each panel has assigned timeframes, venues, chair supervisors, and external examiners
- Dual-scoring system: Supervisor score vs. independent Panel score
- Score analytics dashboard with Recharts visualizations

### 📁 Structured Assignment Submissions
- Supervisors and coordinators create assignments with due dates and rubric criteria
- Student groups submit their work through secure file uploads
- Automatic grade tracking and comparison across evaluation rounds

### 🔧 Hardware/Software Resource Requests
Hierarchical multi-level approval workflow:
```
Student Group → Requests Resource → Supervisor Reviews/Approves → Coordinator Final Approval
```

### 📅 Automated Meeting Scheduler
- Background CRON polling system ([`lib/meeting-scheduler-runner.js`](lib/meeting-scheduler-runner.js))
- Supervisors schedule meetings with groups
- Email reminders automatically dispatched **24 hours** and **1 hour** before scheduled time
- Nodemailer / Brevo API integration for reliable delivery

### 🏭 Industrial Projects Portal
- Faculty supervisors can publish pre-defined "Industrial Projects" with tech stack, features, and thumbnails
- Student groups without initial ideas can browse and request adoption of industrial projects
- Full request/approval lifecycle managed within the platform

### 🔔 Real-Time Notifications
- System-wide broadcast notifications (campus-wide or cohort-targeted)
- Role-specific event notifications via Socket.IO
- Notification bell with unread count in all dashboards

---

## 👥 User Roles

### 🧑‍🎓 Student
- Create a group (up to max members) or accept invitations to join existing groups
- Upload project proposals (PDF/DOCX) which trigger the AI pipeline
- Browse and request supervisor-published Industrial Projects
- Real-time chat with group members and assigned supervisor
- Submit assignments, view evaluation scores, and track milestone feedback
- Browse supervisor profiles filtered by specialization and availability
- Request hardware/software resources through the escalation workflow

### 👨‍🏫 FYP Supervisor
- Publish domain specialization, achievements, and available group slot count
- Upload Industrial Projects for student adoption
- Review incoming student proposal requests with embedded AI reports
- Accept or reject group supervision requests
- Schedule meetings with automatic email reminder system
- Grade group assignments and submit panel evaluation scores
- Real-time chat with all supervised groups

### 👔 FYP Coordinator *(Per-Campus)*
- Configure campus-level settings: active semester, max coordinators/supervisors
- Create and manage Evaluation Panel Checkpoints with venue/timeframe/examiner assignments
- Manage industrial project pool for their campus
- Grant final approval on resource requests escalated by supervisors
- Manage user roster: add/remove students and supervisors
- View campus-wide analytics and evaluation score breakdowns
- Send campus-wide or cohort-targeted broadcast notifications

### 🛡️ Administrator *(Global)*
- Create and configure campuses across the university system
- Assign Coordinator roles to faculty members
- Monitor all-campus system metrics from the admin dashboard
- Manage user status (activate/suspend/remove) globally
- Full access to all platform data across all campuses

---

## 🧠 AI Pipeline

The AI subsystem runs automatically when a student uploads a project proposal document:

```
1. DOCUMENT UPLOAD
   └─► Student uploads PDF or DOCX proposal
       └─► File stored on Cloudflare R2
       └─► Raw text extracted via pdf-parse / mammoth

2. METADATA EXTRACTION  (lib/cohere.ts)
   └─► Raw text sent to Cohere `command-r7b-12-2024`
   └─► Returns strict JSON:
       { title, abstract, techStack[], skills[], timeline }

3. FEASIBILITY ANALYSIS  (lib/cohere.ts)
   └─► Cohere evaluates:
       - Timeline realism vs. 4-month semester
       - Team skill coverage vs. required tech stack
       - Scope and resource requirements
   └─► Returns: Risk Report + actionable scope suggestions

4. VECTOR EMBEDDING  (lib/pinecone.ts)
   └─► Cohere Embed API generates 1024-dimensional embedding
   └─► Vector upserted into Pinecone `project-embeddings` index
       with metadata: { title, groupId, year, campus }

5. SIMILARITY SEARCH  (lib/pinecone.ts)
   └─► Query Pinecone with new embedding
   └─► Cosine similarity > 50% → flag as potential duplicate
   └─► If flagged: LLM generates human-readable explanation:
       "Your project is similar to [prior project] because..."

6. RESULT DISPLAYED TO COORDINATOR
   └─► Full AI report shown on proposal review page
   └─► Coordinator makes final accept/reject decision
```

Additionally, supervisor profiles are embedded into a separate **`supervisors` Pinecone index** to enable AI-powered supervisor-to-student matching based on project domain alignment.

---

## 🗄️ Database Schema

All data is stored in **PostgreSQL** and managed through **Prisma ORM**. The schema defines the following core models:

```
User (base entity)
 ├── Admin
 ├── FYPCoordinator ──────── Campus
 ├── FYPSupervisor  ──────── Campus
 └── Student ─────────────── Campus
                             Group
                              ├── GroupInvitation
                              ├── GroupChat ──── Conversation ── Message
                              ├── Meeting
                              └── Project ──── ProjectProposal
                                              ├── AIReport
                                              └── Submission

IndustrialProject ──── IndustrialProjectRequest
EvaluationPanel ──── PanelCheckpoint ──── EvaluationScore
ResourceRequest
Notification ──── NotificationRecipient
PasswordResetToken
Invitation
PinnedConversation
```

Key design decisions:
- **Role-based tables**: Each user role (Student, Supervisor, Coordinator, Admin) has its own table with a `userId` foreign key to the base `User` table (1-to-1 relations with cascade delete)
- **Multi-campus isolation**: `campusId` is present on Students, Supervisors, Coordinators, and Groups to enforce campus-level data scoping
- **Soft status flags**: Users have `status: ACTIVE | SUSPENDED | REMOVED` — no hard deletes for user accounts
- **Chat encryption**: Messages are stored AES-256 encrypted; the `encryption.ts` module handles symmetric key management

---

## 📁 Project Structure

```
Projectify/
├── app/                          # Next.js App Router
│   ├── admin/                    # Admin dashboard routes
│   │   ├── campuses/             # Campus management
│   │   ├── coordinators/         # Coordinator assignment
│   │   └── dashboard/            # Admin overview
│   ├── coordinator/              # Coordinator routes
│   │   ├── add-student/          # Enroll new students
│   │   ├── add-supervisor/       # Onboard supervisors
│   │   ├── chat/                 # Coordinator messaging
│   │   ├── evaluation-panels/    # Configure defense panels
│   │   ├── industrial-projects/  # Manage project pool
│   │   ├── manage-users/         # User roster management
│   │   └── resource-requests/    # Approve resource escalations
│   ├── supervisor/               # Supervisor routes
│   │   ├── chat/                 # Group conversations
│   │   ├── evaluations/          # Grade assignments
│   │   ├── groups/               # Supervised groups
│   │   ├── industrial-projects/  # Publish industrial projects
│   │   └── resource-requests/    # Review student requests
│   ├── student/                  # Student routes
│   │   ├── browse-supervisors/   # Discover supervisors
│   │   ├── chat/                 # Group & supervisor chat
│   │   ├── evaluations/          # View scores
│   │   ├── group/                # Group management
│   │   ├── industrial-projects/  # Browse available projects
│   │   ├── invitations/          # Manage group invites
│   │   ├── projects/             # Project proposal upload
│   │   └── resource-requests/    # Submit resource requests
│   ├── api/                      # REST API Routes
│   │   ├── admin/                # Admin operations
│   │   ├── auth/                 # NextAuth handlers
│   │   ├── chat/                 # Messaging endpoints
│   │   ├── coordinator/          # Coordinator operations
│   │   ├── cron/                 # Background job triggers
│   │   ├── groups/               # Group management
│   │   ├── meetings/             # Meeting scheduling
│   │   ├── notifications/        # Notification dispatch
│   │   ├── projects/             # Project + AI pipeline
│   │   ├── student/              # Student operations
│   │   └── supervisor/           # Supervisor operations
│   ├── landing/                  # Public landing page (Three.js)
│   ├── login/                    # Authentication page
│   ├── forgot-password/          # Password reset flow
│   ├── layout.tsx                # Root layout + providers
│   └── globals.css               # Global styles
│
├── components/                   # Shared React components
│   ├── ui/                       # shadcn/ui base components
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── input.tsx
│   │   ├── label.tsx
│   │   └── skeleton.tsx
│   ├── AdminSidebar.tsx          # Role-specific sidebars
│   ├── CoordinatorSidebar.tsx
│   ├── StudentSidebar.tsx
│   ├── SupervisorSidebar.tsx
│   ├── CoordinatorProfile.tsx    # Profile components
│   ├── StudentProfile.tsx
│   ├── SupervisorProfile.tsx
│   ├── NotificationBell.tsx      # Live notification bell
│   ├── SearchCommand.tsx         # Global search (⌘K)
│   ├── SocketProvider.tsx        # Socket.IO context provider
│   ├── ThemeProvider.tsx         # Dark/light mode provider
│   └── ThemeToggle.tsx
│
├── lib/                          # Core utilities and services
│   ├── auth.ts                   # NextAuth configuration
│   ├── prisma.ts                 # Prisma client singleton
│   ├── cohere.ts                 # Cohere AI (LLM + embeddings)
│   ├── pinecone.ts               # Pinecone vector DB client
│   ├── socket.ts                 # Server-side socket helpers
│   ├── socket-client.ts          # Client-side socket hooks
│   ├── socket-emitters.ts        # Typed event emitters
│   ├── encryption.ts             # AES-256 message encryption
│   ├── email.ts                  # Transactional email dispatch
│   ├── r2.ts                     # Cloudflare R2 file storage
│   ├── document-parser.ts        # PDF/DOCX text extraction
│   ├── meeting-scheduler-runner.js # Background CRON scheduler
│   ├── meeting-scheduler.ts      # Meeting reminder logic
│   ├── cohort-utils.ts           # Cohort helper utilities
│   └── utils.ts                  # General utilities (cn, etc.)
│
├── prisma/                       # Database layer
│   ├── schema.prisma             # Full database schema (795 lines)
│   ├── migrations/               # Auto-generated migration history
│   ├── seed.js                   # Database seed script
│   └── update-defaults.js        # Default value update script
│
├── types/                        # TypeScript type definitions
├── public/                       # Static assets
├── pages/                        # Legacy Pages Router (if any)
├── profileimage/                 # Local profile image storage
│
├── server.js                     # Custom Node.js server (HTTP + Socket.IO)
├── middleware.ts                  # Auth + RBAC middleware (edge-compatible)
├── next.config.mjs               # Next.js configuration
├── tailwind.config.ts            # Tailwind CSS configuration
├── tsconfig.json                 # TypeScript configuration
├── postcss.config.mjs            # PostCSS configuration
├── package.json                  # Dependencies and scripts
├── .env.example                  # Environment variable template
├── railway.json                  # Railway deployment config
├── nixpacks.toml                 # Nixpacks build config (Railway)
└── vercel.json                   # Vercel deployment config
```

---

## 🔐 Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | ✅ | PostgreSQL connection string (pooled) |
| `DIRECT_URL` | ✅ | PostgreSQL direct connection (for Prisma migrations) |
| `NEXTAUTH_SECRET` | ✅ | Secret for JWT session encryption (min 32 chars) |
| `NEXTAUTH_URL` | ✅ | Base URL of the app (e.g. `http://localhost:3000`) |
| `NEXT_PUBLIC_APP_URL` | ✅ | Public-facing app URL |
| `MESSAGE_ENCRYPTION_KEY` | ✅ | 32-character AES-256 key for chat message encryption |
| `R2_ACCOUNT_ID` | ✅ | Cloudflare R2 Account ID |
| `R2_BUCKET_NAME` | ✅ | Cloudflare R2 Bucket name |
| `R2_API_TOKEN` | ✅ | Cloudflare R2 API Token |
| `R2_PUBLIC_URL` | ✅ | Public CDN URL for R2 bucket |
| `cohere_api_key` | ✅ | Cohere AI API Key |
| `COHERE_MODEL` | ✅ | Cohere LLM model (e.g. `command-r-08-2024`) |
| `PINECONE_API_KEY` | ✅ | Pinecone Vector DB API Key |
| `PINECONE_INDEX_NAME` | ✅ | Pinecone index for project embeddings |
| `PINECONE_SUPERVISORS_INDEX_NAME` | ✅ | Pinecone index for supervisor profiles |
| `NEXT_PUBLIC_SOCKET_URL` | ⚠️ | Socket.IO server URL (leave empty for same-origin) |
| `REDIS_URL` | ⚠️ | Redis URL (optional; enables horizontal WS scaling) |
| `BREVO_API_KEY` | ✅ | Brevo (Sendinblue) API Key for transactional email |
| `BREVO_SENDER_EMAIL` | ✅ | Verified sender email address in Brevo |
| `APP_URL` | ✅ | Production app URL (used in email links) |

---

## 🚀 Getting Started

### Prerequisites

- **Node.js** v18 or higher
- **PostgreSQL** database instance
- **Redis** instance (optional, for multi-server WebSocket scaling)
- Accounts and API keys for: Pinecone, Cohere AI, Cloudflare R2, Brevo

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your credentials
```

### 3. Set Up the Database

```bash
# Push schema to your PostgreSQL database
npm run db:push

# (Optional) Seed with sample data
npm run db:seed

# Open Prisma Studio to inspect data
npm run db:studio
```

### 4. Run in Development

```bash
npm run dev
```

The server starts at [http://localhost:3000](http://localhost:3000)

### Available Scripts

| Command | Description |
|---|---|
| `npm run dev` | Start development server (Node.js + Socket.IO + Next.js) |
| `npm run dev:next` | Start Next.js only (without custom server) |
| `npm run build` | Generate Prisma client + build production bundle |
| `npm start` | Start production server |
| `npm run lint` | Run ESLint |
| `npm run db:push` | Sync Prisma schema to database |
| `npm run db:generate` | Regenerate Prisma client after schema changes |
| `npm run db:studio` | Launch Prisma Studio GUI |
| `npm run db:seed` | Seed database with initial data |

---

## ☁️ Deployment

### Railway *(Recommended)*

The project includes pre-configured Railway deployment files:

```bash
# railway.json and nixpacks.toml are pre-configured
# Just connect your Railway project to this repository
```

Railway environment variables to set: all variables from the `.env.example` file.

Build command: `npm run build` (runs `prisma generate && next build`)  
Start command: `node server.js`

### Vercel

> ⚠️ **Note**: Socket.IO WebSockets require a persistent server and do **not** work on Vercel's serverless Edge functions. Real-time features will be limited on Vercel deployments.

`vercel.json` is provided for static routes and API rewrite configuration. For full Socket.IO support, pair with a dedicated WebSocket host (Railway, Render, Fly.io).

---

## 📡 API Overview

All API routes live under `app/api/` and follow Next.js App Router conventions.

| Prefix | Operations |
|---|---|
| `/api/auth` | NextAuth sign-in, sign-out, session |
| `/api/admin` | Campus management, coordinator assignment |
| `/api/coordinator` | User management, panel creation, resource approvals |
| `/api/supervisor` | Group supervision, meeting scheduling, grading |
| `/api/student` | Group management, proposal submission |
| `/api/projects` | Project CRUD + AI pipeline trigger |
| `/api/chat` | Message send/receive, conversation history |
| `/api/groups` | Group creation, invitations, member management |
| `/api/meetings` | Schedule meetings, retrieve meeting history |
| `/api/notifications` | Broadcast and per-user notification management |
| `/api/invitations` | Group invitation send/accept/reject |
| `/api/profile` | Profile view and update |
| `/api/health` | Health check endpoint (Railway monitoring) |
| `/api/cron` | Background job triggers |

---

## 📄 License

This project is private and proprietary. All rights reserved.

---

<div align="center">

Built with ❤️ for university FYP management.

</div>
