# 🧠 mem.md — Projectify Project Memory File

> This file captures everything about the Projectify project — tech stack, architecture, folder structure, conventions, progress, DevOps plans, and key decisions.
> Paste this file into any AI tool (ChatGPT, Claude, Gemini, etc.) as full context before starting a session.

---

## 1. 📌 Project Name & Purpose

**Project Name**: Projectify

**What it does**:
Projectify is a comprehensive, centralized **Final Year Project (FYP) Management Platform** for multi-campus university environments. It manages the complete FYP lifecycle — from student group formation, project proposal submission, AI-powered plagiarism/feasibility checking, supervisor assignment, real-time encrypted chat, hardware resource requests, automated meeting scheduling, to multi-stage panel evaluation defense systems. It is a production-grade, multi-tenant, role-based web application.

**Live / Repo**: `https://github.com/AhmadR-11/Projectify`

---

## 2. 🛠️ Full Tech Stack

### Frontend
| Layer | Technology | Version |
|---|---|---|
| Framework | Next.js (App Router) | 14.2 |
| UI Library | React | 18.3 |
| Language | TypeScript | 5.4 |
| Styling | Tailwind CSS | 3.4 |
| UI Components | Radix UI + shadcn/ui pattern | Latest |
| Icons | Lucide React | 0.390 |
| Animations | Framer Motion | 11 |
| 3D Visuals | Three.js + @react-three/fiber + @react-three/drei | 0.160 / 8.15 |
| Particle Effects | tsParticles + @tsparticles/react | 3.9 |
| Charts & Dashboards | Recharts | 3.5 |
| Emoji Picker | emoji-picker-react | 4.16 |

### Backend
| Layer | Technology | Version |
|---|---|---|
| Runtime | Node.js | ≥18 |
| Server | Custom `server.js` (HTTP + Socket.IO co-located) | - |
| API Routes | Next.js App Router API Routes | 14.2 |
| Auth | NextAuth.js v5 (Credentials Provider + JWT) | 5.0-beta.30 |
| Password Hashing | bcryptjs | 3.0 |
| Real-Time | Socket.IO (WebSocket server) | 4.8 |
| ORM | Prisma | 5.14 |
| Redis Client | ioredis | 5.9 |
| WS Scaling Adapter | @socket.io/redis-adapter | 8.3 |

### Databases & Storage
| Type | Service | Purpose |
|---|---|---|
| Primary DB | PostgreSQL | All application data |
| Vector DB | Pinecone | AI semantic similarity search |
| In-Memory / PubSub | Redis | Socket.IO horizontal scaling |
| Object Storage | Cloudflare R2 (S3-compatible) | File uploads (proposals, avatars) |

### AI & Document Processing
| Service / Library | Purpose |
|---|---|
| Cohere AI (`command-r7b-12-2024`) | LLM metadata extraction, feasibility analysis, duplicate explanation |
| Cohere Embed API | 1024-dimensional semantic vector embeddings |
| Pinecone (`project-embeddings` index) | Cosine similarity search (>50% threshold = duplicate flag) |
| Pinecone (`supervisors` index) | Supervisor profile embeddings for AI-matching |
| pdf-parse | Extract text from PDF proposals |
| mammoth | Extract text from DOCX proposals |
| sharp | Server-side image processing |

### Email / Communications
| Service | Purpose |
|---|---|
| Brevo API (HTTP) | Primary transactional email (Railway-compatible, no SMTP blocking) |
| Resend | Alternative email API provider |
| Nodemailer | Fallback SMTP transport |

### Security
| Mechanism | Detail |
|---|---|
| Session Strategy | JWT (30-day expiry) |
| Password Hashing | bcryptjs (async, salted) |
| Chat Encryption | AES-256-CBC (`lib/encryption.ts`) before DB write |
| Route Protection | NextAuth middleware + RBAC in `middleware.ts` |

### Architecture Pattern
- **Layered Monolith with Real-Time Extension**
- Stateless Next.js server + Redis adapter = horizontally scalable
- Heavy AI/ML workloads offloaded to Cohere + Pinecone managed APIs
- Custom `server.js` co-locates Socket.IO with Next.js HTTP handler (no separate WS service)

---

## 3. 📁 Folder / Monorepo Structure

```
Projectify/                         ← Root repository (GitHub: AhmadR-11/Projectify)
│
├── app/                            ← Next.js App Router
│   ├── admin/                      ← Admin dashboard (campuses, coordinators)
│   ├── coordinator/                ← Coordinator dashboard (panels, users, resources)
│   ├── supervisor/                 ← Supervisor dashboard (groups, meetings, grading)
│   ├── student/                    ← Student dashboard (proposals, chat, evaluations)
│   ├── api/                        ← All REST API Routes
│   │   ├── auth/                   ← NextAuth handlers
│   │   ├── chat/, groups/, meetings/, projects/, notifications/
│   │   ├── coordinator/, supervisor/, student/, admin/
│   │   ├── cron/                   ← Background job trigger endpoints
│   │   └── health/                 ← Railway health check endpoint
│   ├── landing/                    ← Public landing page (Three.js 3D scene)
│   ├── login/                      ← Authentication page
│   ├── forgot-password/            ← Password reset flow
│   ├── layout.tsx                  ← Root layout + global providers
│   └── globals.css                 ← Global styles
│
├── components/                     ← Shared React components
│   ├── ui/                         ← shadcn/ui base components (button, card, input, label, skeleton)
│   ├── *Sidebar.tsx                ← Role-specific sidebars (Admin, Coordinator, Student, Supervisor)
│   ├── *Profile.tsx                ← Profile page components
│   ├── NotificationBell.tsx        ← Live notification bell
│   ├── SearchCommand.tsx           ← Global search (⌘K shortcut)
│   ├── SocketProvider.tsx          ← Socket.IO React context provider
│   ├── ThemeProvider.tsx           ← Dark/light mode (next-themes)
│   └── ThemeToggle.tsx
│
├── lib/                            ← Core services and utilities
│   ├── auth.ts                     ← NextAuth config (Credentials + JWT)
│   ├── prisma.ts                   ← Prisma client singleton
│   ├── cohere.ts                   ← Cohere AI: extraction, feasibility, embedding
│   ├── pinecone.ts                 ← Pinecone vector DB: upsert + similarity query
│   ├── socket.ts                   ← Server-side socket event handlers
│   ├── socket-client.ts            ← Client-side socket hooks and helpers
│   ├── socket-emitters.ts          ← Typed event emitter functions
│   ├── encryption.ts               ← AES-256-CBC encrypt/decrypt for chat
│   ├── email.ts                    ← Email dispatch (Brevo / Resend / Nodemailer)
│   ├── r2.ts                       ← Cloudflare R2 file upload/download
│   ├── document-parser.ts          ← PDF + DOCX text extraction
│   ├── meeting-scheduler-runner.js ← Background CRON scheduler (Node.js)
│   ├── meeting-scheduler.ts        ← Meeting reminder email logic
│   ├── cohort-utils.ts             ← Cohort-related helper functions
│   └── utils.ts                    ← General utilities (cn() for Tailwind)
│
├── prisma/                         ← Database layer
│   ├── schema.prisma               ← Full DB schema (~795 lines, PostgreSQL)
│   ├── migrations/                 ← Auto-generated migration history
│   ├── seed.js                     ← Seed script for initial data
│   └── update-defaults.js          ← Utility for updating default values
│
├── types/                          ← TypeScript type definitions
├── public/                         ← Static assets (favicon, images)
├── pages/                          ← Legacy Pages Router (minimal usage)
├── profileimage/                   ← Local profile image fallback
│
├── server.js                       ← Custom Node.js HTTP + Socket.IO server
├── middleware.ts                   ← Edge-compatible auth + RBAC middleware
├── next.config.mjs                 ← Next.js config (R2, SWC, package optimizations)
├── tailwind.config.ts              ← Tailwind CSS config
├── tsconfig.json                   ← TypeScript config
├── postcss.config.mjs              ← PostCSS config
├── package.json                    ← Dependencies + scripts
├── .env                            ← Local environment variables (gitignored)
├── .env.example                    ← Template for environment variables
├── .gitignore                      ← node_modules/, .next/, .env excluded
├── railway.json                    ← Railway.app deployment config
├── nixpacks.toml                   ← Railway build (nixpacks) config
├── vercel.json                     ← Vercel deployment config
│
├── infra/                          ← [PLANNED] DevOps infrastructure (not yet created)
│   ├── docker/
│   │   ├── Dockerfile
│   │   └── .dockerignore
│   ├── docker-compose.yml
│   ├── kubernetes/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   ├── configmap.yaml
│   │   └── secrets.yaml
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/
│       ├── prometheus.yml
│       └── grafana/dashboard.json
│
├── Jenkinsfile                     ← [PLANNED] Jenkins CI/CD pipeline
└── README.md                       ← Full project documentation (written)
```

---

## 4. 🧹 Coding Conventions

### Naming
- **Files**: `PascalCase` for React components (`StudentSidebar.tsx`), `camelCase` for utilities and lib files (`socket-client.ts`, `cohort-utils.ts`).
- **Variables / Functions**: `camelCase` throughout TypeScript.
- **Database (Prisma)**: `camelCase` for field names in schema; `@map("snake_case")` decorator used to map to PostgreSQL snake_case column names.
- **API Routes**: kebab-case folder names matching REST semantics (`resource-requests`, `industrial-projects`).
- **Environment variables**: `UPPER_SNAKE_CASE` for server-side secrets; `NEXT_PUBLIC_` prefix for client-exposed variables.

### Code Style
- **TypeScript strict mode** enabled in `tsconfig.json`.
- `cn()` utility from `clsx` + `tailwind-merge` is used for all dynamic className composition.
- Tailwind CSS utility classes used inline; no custom CSS files except `globals.css`.
- React Server Components (RSC) used where possible; Client Components marked with `"use client"` at the top.
- Prisma client accessed via the singleton in `lib/prisma.ts` (prevents connection pool exhaustion in dev hot-reload).
- Socket.IO global instance stored on `global.io` in `server.js` and accessed from API routes.

### Patterns
- **RBAC enforced at two levels**: Middleware (route-level blocking) + API route level (per-handler checks).
- **Role-specific dashboards**: Each role (`admin`, `coordinator`, `supervisor`, `student`) has its own top-level Next.js route group.
- **Background scheduling**: Long-running CRON tasks run inside the custom Node.js server process via `meeting-scheduler-runner.js`.
- **AI pipeline**: Triggered on project proposal upload; runs fully server-side via API route handler.
- **Chat encryption**: All messages encrypted before INSERT and decrypted after SELECT — encryption is transparent to the rest of the app.

---

## 5. 📊 Current Status

### ✅ Done (Application Layer)
- Full multi-role authentication (Admin, Coordinator, Supervisor, Student) with NextAuth JWT
- Role-based access control (RBAC) via middleware + API-level checks
- Full PostgreSQL database schema (795 lines, 25+ models, migrations in place)
- Real-time encrypted messaging with Socket.IO + AES-256 encryption
- AI pipeline: PDF/DOCX parsing → Cohere LLM extraction → Feasibility scoring → Pinecone vector similarity search
- Industrial Projects portal (post + browse + request + approve)
- Multi-stage Evaluation Panel system (create panels, assign examiners, dual scoring)
- Hardware/software resource request workflow (3-level approval)
- Background meeting scheduler with email reminders (24hr + 1hr before)
- Notification system (broadcast + per-user, via Socket.IO)
- Profile management with Cloudflare R2 image uploads
- Admin dashboard: campus management, coordinator assignment
- Full README.md written with architecture diagram

### ✅ Done (DevOps Planning, Infrastructure & Deployment - Phases 1 to 6)
- DevOps tool selection finalized (Jenkins, Docker, Docker Compose, Kubernetes, Terraform, AWS, Prometheus, Grafana)
- Complete DevOps flow documented (push → Jenkins → Terraform → Docker → ECR → EKS → Monitoring)
- Monorepo structure for `infra/` folder designed (`infra/terraform/` and `infra/kubernetes/`)
- `.gitignore` updated (node_modules, `.terraform/`, `*.tfstate`, `terraform.tfvars`, `secrets.yaml` securely excluded)
- **Phase 1 (Docker Containerization)**: Multi-stage `Dockerfile` (350MB lean build, non-root `nextjs` user, `dumb-init`) + `docker-compose.yml` (App + Postgres + Redis).
- **Phase 2 & 3 (Jenkins CI/CD Pipeline)**: Automated `Jenkinsfile` pipeline with 7 stages (Checkout → Verify → Lint → Validate → Docker Build → Health Test → Cleanup) verified & running on `http://localhost:8080`.
- **Phase 4 (Terraform AWS IaC)**: Provisioned live AWS VPC (Multi-AZ), ECR repo (`867490540447.dkr.ecr.us-east-1.amazonaws.com/projectify-app`), RDS PostgreSQL 16 (`projectify-db`), ElastiCache Redis (`projectify-redis`), and EKS Kubernetes Cluster (`projectify-eks-cluster`).
- **Phase 5 (Kubernetes Manifests & Deployment)**: Production manifests created (`configmap.yaml`, `secrets.yaml`, `deployment.yaml`, `service.yaml`, `ingress.yaml`). Pod `projectify-app-5d4c7d8c57-g4vkf` status **`1/1 Running`** live on AWS EKS.
- **Phase 6 (Public AWS Load Balancer)**: Configured LoadBalancer Service (`projectify-service`) exposing live public URL (`http://a0b5f7996d0d943338d87f37052a4ed2-242634869.us-east-1.elb.amazonaws.com`).

### 🔲 DevOps Implementation Roadmap
- [x] **Phase 1**: Write `Dockerfile` + `docker-compose.yml` (app + postgres + redis) — test locally
- [x] **Phase 2**: Set up Jenkins server (local / Docker container)
- [x] **Phase 3**: Write `Jenkinsfile` with stages (Checkout → Lint → Prisma Validate → Docker Build → Health Test)
- [x] **Phase 4**: Write Terraform configs (`infra/terraform/`) to provision AWS: VPC, ECR, RDS, ElastiCache, EKS
- [x] **Phase 5**: Write Kubernetes manifests (`infra/kubernetes/`: `deployment.yaml`, `service.yaml`, `ingress.yaml`, `configmap.yaml`, `secrets.yaml`)
- [x] **Phase 6**: Configure AWS Load Balancer (`projectify-service`: `http://a0b5f7996d0d943338d87f37052a4ed2-242634869.us-east-1.elb.amazonaws.com`)
- [ ] **Phase 7**: Point Route 53 domain to ALB for public URL
- [ ] **Phase 8**: Deploy Prometheus + Grafana inside EKS + add `/metrics` endpoint to Next.js app

---

## 6. 🔑 Key Decisions Already Made

| Decision | Choice | Reason |
|---|---|---|
| **Framework** | Next.js 14 App Router | SSR + API Routes + RSC in one framework, no separate backend needed |
| **Custom Server** | `server.js` (not `next start`) | Socket.IO must co-locate with HTTP server; `next start` doesn't support this |
| **Auth Strategy** | NextAuth v5 + JWT (not DB sessions) | Stateless sessions for horizontal scaling compatibility |
| **Login identifier** | Email OR Student Roll Number | Students don't always know their email; roll number login is university-standard |
| **Chat Encryption** | AES-256-CBC at application layer | Data encrypted before hitting DB; Prisma/PostgreSQL layer is unaware |
| **AI Provider** | Cohere (not OpenAI) | Superior embedding quality + combined LLM + Embed API in one provider |
| **Vector DB** | Pinecone (not Qdrant/Weaviate) | Managed, serverless, no infrastructure; `qdrant.ts` exists but unused |
| **File Storage** | Cloudflare R2 (not AWS S3) | Zero egress fees; S3-compatible API; cheaper at scale |
| **Email Provider** | Brevo API (not SMTP) | Railway blocks SMTP port 587; HTTP API works universally |
| **WS Scaling** | Redis PubSub adapter | Allows multiple Node.js instances to share Socket.IO events |
| **CSS** | Tailwind CSS | Fast development, no CSS file sprawl |
| **DevOps CI/CD** | Jenkins (not GitLab CI / GitHub Actions) | Learning classic enterprise-grade DevOps skills |
| **Cloud** | AWS | Industry standard; EKS (Kubernetes), RDS (PostgreSQL), ElastiCache (Redis), ECR (Docker) |
| **IaC** | Terraform (not Pulumi/CDK) | Industry standard, provider-agnostic, large community |
| **Monitoring** | Prometheus + Grafana | Open source standard; deep K8s integration |
| **Deployment Target** | AWS EKS (Kubernetes) | Socket.IO + Redis adapter was built for horizontal pod scaling |
| **Repo Structure** | Monorepo (app + infra in same repo) | App code + K8s manifests + Terraform must be versioned together |
| **Packer** | ❌ Skipped | Not needed — using Docker containers, not custom EC2 AMIs |
| **HashiCorp Vault** | ❌ Phase 2 (not now) | Secrets management via K8s Secrets first; Vault added later |
| **GitLab Migration** | ❌ Stay on GitHub | Code already on GitHub; Jenkins connects to GitHub natively |

---

## 7. 👥 User Roles (System-Wide)

| Role | Key Capabilities |
|---|---|
| **Student** | Create/join groups, submit proposals (AI pipeline), browse supervisors, chat, submit assignments, view scores, request resources |
| **FYP Supervisor** | Publish industrial projects, review proposals with AI reports, accept groups, schedule meetings, grade assignments, chat with groups |
| **FYP Coordinator** | Configure campus settings, create evaluation panels, approve resources, manage users, send campus notifications |
| **Administrator** | Create campuses globally, assign coordinators, manage all users across all campuses |

---

## 8. 🧠 AI Pipeline (How It Works)

```
Student uploads PDF/DOCX
        ↓
document-parser.ts → extracts raw text
        ↓
lib/cohere.ts → LLM extracts: { title, abstract, techStack, skills, timeline } (strict JSON)
        ↓
lib/cohere.ts → Feasibility Analysis: timeline realism, skill coverage, risk report
        ↓
Cohere Embed API → generates 1024-dimensional vector embedding
        ↓
lib/pinecone.ts → upserts vector to Pinecone "project-embeddings" index
        ↓
Pinecone cosine similarity query
        ↓
if similarity > 50% → LLM generates human-readable "duplicate explanation"
        ↓
Full AI report shown to Coordinator for final accept/reject decision
```

---

## 9. 🗄️ Database Schema (Key Models)

**Provider**: PostgreSQL via Prisma ORM

**Core Models**: `User`, `Admin`, `FYPCoordinator`, `FYPSupervisor`, `Student`, `Campus`, `Group`, `Project`, `GroupChat`, `Message`, `Conversation`, `Meeting`, `EvaluationPanel`, `PanelCheckpoint`, `EvaluationScore`, `ResourceRequest`, `IndustrialProject`, `IndustrialProjectRequest`, `Invitation`, `GroupInvitation`, `Notification`, `NotificationRecipient`, `PasswordResetToken`, `PinnedConversation`

**Key Design Rules**:
- Role tables (`Admin`, `Student`, etc.) are 1-to-1 with `User` table (cascade delete)
- `campusId` on Students, Supervisors, Coordinators, Groups for campus-level data isolation
- User `status` field: `ACTIVE | SUSPENDED | REMOVED` (no hard deletes)
- Chat messages stored AES-256 encrypted; decrypted in application layer only

---

## 10. 🌐 Deployment Strategy

### Current State
- **Development**: Local with manual Node.js install
- **Planned Production**: AWS (EKS + RDS + ElastiCache + ECR)

### Public URL Flow
```
User Browser
   → DNS (AWS Route 53) → resolves domain to ALB IP
   → AWS Application Load Balancer (ALB) → terminates HTTPS/SSL (ACM certificate)
   → Kubernetes Ingress (EKS) → routes to Node.js Pods on port 3000
   → server.js → Next.js App Router + Socket.IO
```

### Planned AWS Services
| Service | Purpose |
|---|---|
| EKS | Managed Kubernetes cluster |
| RDS (PostgreSQL) | Managed database |
| ElastiCache (Redis) | Managed Redis for Socket.IO |
| ECR | Docker image registry |
| ALB | Application Load Balancer + WebSocket support |
| ACM | Free SSL/TLS certificates |
| Route 53 | DNS management |
| VPC | Network isolation |
| IAM | Role-based AWS access for Terraform |
| S3 + DynamoDB | Terraform remote state + locking |

---

## 11. ⚙️ Environment Variables (Key List)

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string (pooled) |
| `DIRECT_URL` | PostgreSQL direct URL (for migrations) |
| `NEXTAUTH_SECRET` | JWT session encryption key (32+ chars) |
| `NEXTAUTH_URL` | App base URL |
| `NEXT_PUBLIC_APP_URL` | Public app URL (client-side) |
| `MESSAGE_ENCRYPTION_KEY` | 32-char AES-256 key for chat encryption |
| `R2_ACCOUNT_ID`, `R2_BUCKET_NAME`, `R2_API_TOKEN`, `R2_PUBLIC_URL` | Cloudflare R2 file storage |
| `cohere_api_key`, `COHERE_MODEL` | Cohere AI |
| `PINECONE_API_KEY`, `PINECONE_INDEX_NAME`, `PINECONE_SUPERVISORS_INDEX_NAME` | Pinecone vector DB |
| `NEXT_PUBLIC_SOCKET_URL` | Socket.IO server URL |
| `REDIS_URL` | Redis connection (optional for WS scaling) |
| `BREVO_API_KEY`, `BREVO_SENDER_EMAIL` | Brevo transactional email |
| `APP_URL` | Used in email links |

---

## 12. 🚦 NPM Scripts Reference

| Script | Command | Description |
|---|---|---|
| Start dev | `npm run dev` | Custom Node.js server (server.js) with Socket.IO |
| Start Next only | `npm run dev:next` | Next.js only (no Socket.IO) |
| Build | `npm run build` | `prisma generate && next build` |
| Production | `npm start` | `node server.js` |
| Lint | `npm run lint` | ESLint |
| DB Push | `npm run db:push` | Sync schema to DB (no migration file) |
| DB Generate | `npm run db:generate` | Regenerate Prisma client |
| DB Studio | `npm run db:studio` | Open Prisma GUI |
| DB Seed | `npm run db:seed` | Run `prisma/seed.js` |

---

*Last updated: 2026-07-25 | Maintained by: Ahmad*
