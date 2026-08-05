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
├── Dockerfile                      ← Multi-stage Docker build (350MB lean image, non-root user, dumb-init)
├── docker-compose.yml              ← Local development stack (App + PostgreSQL + Redis)
├── Jenkinsfile                     ← Jenkins CI/CD pipeline (7 stages: Checkout → Verify → Lint → Validate → Build → Health → Cleanup)
│
├── infra/                          ← DevOps infrastructure (fully implemented)
│   ├── kubernetes/                 ← Kubernetes manifests for EKS
│   │   ├── deployment.yaml         ← App Deployment (3 replicas, rolling update, health probes)
│   │   ├── service.yaml            ← LoadBalancer Service (port 80 → 3000)
│   │   ├── ingress.yaml            ← Ingress rules for domain routing
│   │   ├── configmap.yaml          ← Non-secret environment variables
│   │   ├── secrets.yaml            ← Base64-encoded secrets (gitignored)
│   │   ├── secrets.yaml.example    ← Template for secrets
│   │   └── aws-load-balancer-controller.yaml  ← AWS LB Controller Helm values
│   │
│   └── terraform/                  ← Terraform IaC for AWS provisioning
│       ├── providers.tf            ← AWS provider + required providers
│       ├── vpc.tf                  ← VPC, subnets (2 public + 2 private), NAT, IGW
│       ├── eks.tf                  ← EKS cluster + managed node group (t3.micro)
│       ├── rds.tf                  ← RDS PostgreSQL 16 (db.t3.micro)
│       ├── elasticache.tf          ← ElastiCache Redis (cache.t3.micro)
│       ├── ecr.tf                  ← ECR repository for Docker images
│       ├── route53.tf              ← Route 53 DNS zone + ACM SSL certificate
│       ├── alb_controller_iam.tf   ← IAM roles for AWS Load Balancer Controller
│       ├── variables.tf            ← Input variables (region, CIDR, DB creds, domain)
│       ├── outputs.tf              ← Output values (endpoints, cluster name)
│       ├── terraform.tfvars        ← Variable values (gitignored)
│       └── terraform.tfvars.example ← Template for variable values
│
└── README.md                       ← Full project documentation (complete)
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

### ✅ Done (DevOps Infrastructure & Deployment - All 8 Phases Complete)
- DevOps tool selection finalized (Jenkins, Docker, Docker Compose, Kubernetes, Terraform, AWS, Prometheus, Grafana)
- Complete DevOps flow documented (push → Jenkins → Terraform → Docker → ECR → EKS → Monitoring)
- Monorepo structure for `infra/` folder implemented (`infra/terraform/` and `infra/kubernetes/`)
- `.gitignore` updated (node_modules, `.terraform/`, `*.tfstate`, `terraform.tfvars`, `secrets.yaml` securely excluded)
- **Phase 1 (Docker Containerization)**: Multi-stage `Dockerfile` (350MB lean build, non-root `nextjs` user, `dumb-init`) + `docker-compose.yml` (App + Postgres + Redis).
- **Phase 2 & 3 (Jenkins CI/CD Pipeline)**: Automated `Jenkinsfile` pipeline with 7 stages (Checkout → Verify → Lint → Validate → Docker Build → Health Test → Cleanup) verified & running on `http://localhost:8080`.
- **Phase 4 (Terraform AWS IaC)**: Provisioned live AWS VPC (Multi-AZ), ECR repo (`867490540447.dkr.ecr.us-east-1.amazonaws.com/projectify-app`), RDS PostgreSQL 16 (`projectify-db`), ElastiCache Redis (`projectify-redis`), and EKS Kubernetes Cluster (`projectify-eks-cluster`).
- **Phase 5 (Kubernetes Manifests & Deployment)**: Production manifests created (`configmap.yaml`, `secrets.yaml`, `deployment.yaml`, `service.yaml`, `ingress.yaml`). Pod deployed and running live on AWS EKS.
- **Phase 6 (Public AWS Load Balancer)**: Configured LoadBalancer Service (`projectify-service`) exposing live public URL via AWS Classic Load Balancer.
- **Phase 7 (Custom Domain Routing & SSL Setup)**: Configured custom domain mapping (`infra/terraform/route53.tf`) & DuckDNS CNAME routing to AWS Load Balancer endpoint. ACM SSL certificate provisioning configured.
- **Phase 8 (Prometheus & Grafana Monitoring)**: Cluster-level metrics collection via Prometheus (kube-state-metrics, node-exporter) and application performance dashboards via Grafana. Deployed inside EKS using Helm charts.

### ✅ DevOps Implementation Roadmap (All Phases Complete)
- [x] **Phase 1**: Write `Dockerfile` + `docker-compose.yml` (app + postgres + redis) — tested locally
- [x] **Phase 2**: Set up Jenkins server (local Docker container on `http://localhost:8080`)
- [x] **Phase 3**: Write `Jenkinsfile` with stages (Checkout → Lint → Prisma Validate → Docker Build → Health Test)
- [x] **Phase 4**: Write Terraform configs (`infra/terraform/`) to provision AWS: VPC, ECR, RDS, ElastiCache, EKS
- [x] **Phase 5**: Write Kubernetes manifests (`infra/kubernetes/`: `deployment.yaml`, `service.yaml`, `ingress.yaml`, `configmap.yaml`, `secrets.yaml`)
- [x] **Phase 6**: Configure AWS Load Balancer (Classic LB via `projectify-service` LoadBalancer type)
- [x] **Phase 7**: Point custom domain (Route 53 / DuckDNS) to AWS Load Balancer for public URL + ACM SSL
- [x] **Phase 8**: Deploy Prometheus + Grafana inside EKS for cluster & application monitoring dashboards

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

### Environments
| Environment | Stack | Status |
|---|---|---|
| **Local Development** | `docker-compose.yml` (App + PostgreSQL + Redis) | ✅ Ready |
| **CI/CD** | Jenkins pipeline (local Docker) → Docker Build → ECR Push | ✅ Configured |
| **Production** | AWS EKS + RDS + ElastiCache + ECR + Load Balancer | ✅ Implemented (currently torn down to save costs) |
| **PaaS Fallback** | Railway.app (simple deployment for demos) | ✅ Configured |

### Production Traffic Flow
```
User Browser
   → DNS (DuckDNS CNAME / Route 53) → resolves to AWS Load Balancer
   → AWS Classic Load Balancer → forwards to EKS NodePort
   → Kubernetes Service (LoadBalancer type) → routes to App Pods on port 3000
   → server.js → Next.js App Router + Socket.IO
```

### AWS Services Used
| Service | Purpose | Terraform File |
|---|---|---|
| **VPC** | Multi-AZ network (2 public + 2 private subnets, NAT, IGW) | `vpc.tf` |
| **EKS** | Managed Kubernetes cluster (v1.30, t3.micro nodes) | `eks.tf` |
| **RDS** | PostgreSQL 16 managed database (db.t3.micro) | `rds.tf` |
| **ElastiCache** | Redis for Socket.IO horizontal scaling (cache.t3.micro) | `elasticache.tf` |
| **ECR** | Docker image registry | `ecr.tf` |
| **Load Balancer** | Classic LB for public traffic routing | `service.yaml` |
| **Route 53** | DNS zone management | `route53.tf` |
| **ACM** | Free SSL/TLS certificate provisioning | `route53.tf` |
| **IAM** | Service roles for EKS, LB Controller, nodes | `alb_controller_iam.tf` |

### Monitoring Stack
| Tool | Purpose | Deployment |
|---|---|---|
| **Prometheus** | Cluster metrics collection (CPU, memory, pod health, node stats) | Helm chart in EKS |
| **Grafana** | Visual dashboards for cluster & app performance | Helm chart in EKS |
| **kube-state-metrics** | Kubernetes object metrics (deployments, pods, services) | Bundled with Prometheus |
| **node-exporter** | Node-level hardware/OS metrics | Bundled with Prometheus |

### Re-deploy Commands (After `terraform destroy`)
```bash
# 1. Re-provision AWS infrastructure
cd infra/terraform
terraform init
terraform apply -auto-approve

# 2. Configure kubectl for EKS
aws eks update-kubeconfig --name projectify-eks-cluster --region us-east-1

# 3. Build & push Docker image to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 867490540447.dkr.ecr.us-east-1.amazonaws.com
docker build -t projectify-app .
docker tag projectify-app:latest 867490540447.dkr.ecr.us-east-1.amazonaws.com/projectify-app:latest
docker push 867490540447.dkr.ecr.us-east-1.amazonaws.com/projectify-app:latest

# 4. Deploy Kubernetes manifests
cd ../kubernetes
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# 5. Push database schema & seed
kubectl exec -it $(kubectl get pods -l app=projectify -o jsonpath='{.items[0].metadata.name}') -- npx prisma db push
kubectl exec -it $(kubectl get pods -l app=projectify -o jsonpath='{.items[0].metadata.name}') -- node prisma/seed.js

# 6. Install Prometheus & Grafana (monitoring)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
kubectl port-forward svc/prometheus-grafana -n monitoring 3001:80
# Access Grafana at http://localhost:3001 (admin/prom-operator)
```

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

*Last updated: 2026-08-05 | Maintained by: Ahmad*
*Status: All 8 DevOps phases complete. Infrastructure currently torn down to save costs. Re-deploy anytime using commands above.*
