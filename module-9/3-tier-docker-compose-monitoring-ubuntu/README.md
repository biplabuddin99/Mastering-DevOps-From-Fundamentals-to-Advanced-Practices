# BMI Health Tracker — Production Three-Tier Application

> A fully containerised, production-ready health tracking application with automated deployments, real-time monitoring, and complete observability. Deployed on AWS EC2 with Docker Compose, monitored with Prometheus / Grafana / Loki, and automated with a self-hosted GitHub Actions runner.

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/ec2/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-316192?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Grafana](https://img.shields.io/badge/Grafana-Loki%20%7C%20Prometheus-E6522C?logo=grafana&logoColor=white)](https://grafana.com/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)

---

## Table of Contents

- [Learning Path Overview](#learning-path-overview)
- [Phase 1 — Container Orchestration with Docker Compose](#phase-1--container-orchestration-with-docker-compose)
- [Application Architecture](#application-architecture)
- [Technology Stack](#technology-stack)
- [Infrastructure Requirements](#infrastructure-requirements)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Phase 2 — Deploy the Three-Tier Application](#phase-2--deploy-the-three-tier-application)
- [Phase 3 — Add the Monitoring Stack](#phase-3--add-the-monitoring-stack)
- [Phase 4 — GitHub Actions Deployment](#phase-4--github-actions-deployment)
- [Environment Variables](#environment-variables)
- [API Reference](#api-reference)
- [Operations Runbook](#operations-runbook)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Performance](#performance)
- [Path to Kubernetes](#path-to-kubernetes)
- [Roadmap](#roadmap)

---

## Learning Path Overview

This repository teaches production DevOps through a deliberate four-phase progression using a real three-tier application. Each phase builds on the previous one. By the end you will have a production-ready, fully-observed, automatically-deployed system — and the engineering reasoning to reproduce it.

| Phase | Tool | What It Delivers |
|-------|------|------------------|
| **Phase 1** | Docker Compose (concepts) | Why multi-container orchestration exists; what Compose gives you and where it stops |
| **Phase 2** | `docker-compose.yml` | Three-tier application running with correct networking, persistence, health checks, and restart policy |
| **Phase 3** | `docker-compose.monitoring.yml` | Full observability — metrics, logs, and 5 pre-provisioned dashboards added to the running stack |
| **Phase 4** | `.github/workflows/deploy.yml` | Self-hosted CI/CD that automates the exact same deployment logic as manual — no drift |

The phases are sequential during initial setup. After that, pushing to `main` triggers Phase 4, which runs Phases 2 and 3 together in a single pipeline.

---

## Phase 1 — Container Orchestration with Docker Compose

This phase is conceptual. No containers are started here. This section provides the engineering reasoning that justifies every decision made in Phases 2, 3, and 4. Read it before running any commands.

### What Docker Compose Is

Docker Compose is a **declarative orchestration layer** for multi-container applications running on a single Docker host. You describe your entire stack — every service, its configuration, its network connections, its storage — in a YAML file. You manage the entire stack with one command.

The key word is **declarative**. You describe the desired state of the system; Compose works out how to achieve it.

### Single Container vs Multi-Service Systems

A single `docker run` command works for one container. Production applications are never one container:

| Component | Container | Responsibility |
|-----------|-----------|----------------|
| Frontend | React + Nginx | Serve static assets; proxy API calls |
| Backend | Node.js + Express | Business logic, calculations, database access |
| Database | PostgreSQL | Persist data, enforce schema constraints |
| Metrics | Prometheus + cAdvisor + node-exporter | Observe container and host performance |
| Logging | Loki + Promtail | Aggregate and query logs across all services |
| Dashboards | Grafana | Visualise metrics and logs in one pane |

Without an orchestration tool you would manually:

- `docker network create` for every network
- `docker run` each container with correct flags
- Manage startup order (database before API, API before frontend)
- Restart failed containers by hand
- Pass environment variables individually
- Mount volumes manually
- Tear everything down container by container

This is brittle, error-prone, and impossible to version-control as infrastructure.

### How Docker Compose Differs from Plain Docker

| Concern | `docker run` (imperative) | `docker-compose.yml` (declarative) |
|---------|--------------------------|-------------------------------------|
| Define services | Separate command per container | All services in one file |
| Network setup | Manual `docker network create` | Automatic — named networks in YAML |
| Volume setup | Manual `docker volume create` | Automatic — named volumes in YAML |
| Startup ordering | Script required | `depends_on` + `condition: service_healthy` |
| Environment vars | `-e KEY=VALUE` per container | `environment:` block or `env_file:` |
| Version control | Commands in a shell script | Committed YAML — infrastructure as code |
| Start full stack | Multiple sequential commands | `docker compose up -d` |
| Stop full stack | `docker stop` each container | `docker compose down` |
| Rebuild one image | `docker build` + `docker run` | `docker compose up -d --build service` |
| View all logs | Per-container | `docker compose logs -f` |

### What Docker Compose Gives You

**Automatic Networks**
Services on the same named network reach each other by service name. DNS resolution is handled automatically. In this project:

- `backend` reaches `postgres` at `postgres:5432` via `bmi-backend-network`
- `frontend` reaches `backend` at `backend:3000` via `bmi-frontend-network`
- `frontend` cannot reach `postgres` — it is on a different network with no DNS entry

This is genuine network isolation without any firewall rules or iptables configuration.

**Named Volumes**
Persistent data (PostgreSQL rows, Prometheus TSDB blocks, Grafana dashboards) survives container restarts. The volume lifecycle is independent of the container lifecycle. Removing a container does not destroy its data unless you explicitly pass `--volumes`.

**Health-Check-Gated Startup Order**
```yaml
backend:
  depends_on:
    postgres:
      condition: service_healthy
```
Compose will not start `backend` until `postgres` passes its `HEALTHCHECK`. This eliminates the most common containerised app failure: the API crashing at startup because the database is not yet accepting connections.

**Environment Management**
A single `.env` file at the project root. Compose interpolates `${VAR}` in the YAML at runtime. No credentials in source code. No credentials in Dockerfiles. No credentials baked into images.

**Idempotent Operations**
`docker compose up -d` is safe to run repeatedly. Compose compares desired state against running state and only changes what is different. This is the foundation of declarative infrastructure management.

### The Operational Limits of Docker Compose

Understanding these limits is not optional — they are precisely why Kubernetes was built.

**Single Host**
Every container runs on one machine. If that machine fails, everything fails. There is no mechanism in Docker Compose to spread containers across multiple hosts.

**No True High Availability**
`docker compose up --scale backend=3` starts three replicas, but all three run on the same host. A hardware failure loses all replicas simultaneously. True HA requires distributing replicas across failure domains (different physical servers, racks, or availability zones).

**No Rolling Deployments**
`docker compose up -d --force-recreate` tears down the old container and starts the new one. There is a window where the service is unavailable. Achieving zero-downtime requires external tooling (load balancer + blue-green scripting).

**No Self-Healing at the Infrastructure Level**
`restart: unless-stopped` restarts a crashed container process. It does not migrate the container to a different host when the current host is out of memory, does not replace a node that has failed at the hardware level, and does not handle split-brain scenarios.

**No Horizontal Auto-Scaling**
Compose does not monitor CPU or memory and add replicas based on load. You scale manually. This is a core Kubernetes feature (Horizontal Pod Autoscaler).

**No Built-In Secret Management**
Secrets live in `.env` files or environment variables, visible to any process on the host. Kubernetes Secrets and HashiCorp Vault integration provide proper encrypted secret lifecycle management.

**No Resource Quotas Per Team or Namespace**
All containers share the host’s resources. A runaway container can starve others. `docker-compose.prod.yml` in this project adds per-service CPU and memory hard limits as a mitigation, but this is not the same as platform-level resource governance.

### When Kubernetes Becomes Necessary

| You need this | Why Compose cannot provide it |
|---------------|--------------------------------|
| Survive a host failure with no downtime | K8s schedules pods across nodes — one node failing does not take down the service |
| >1 replica of each service for true HA | K8s distributes replicas across failure domains automatically |
| Auto-scale on traffic spikes | HPA scales replicas based on CPU, memory, or custom metrics |
| Multiple teams deploying independent services | K8s namespaces provide resource isolation and RBAC per team |
| Rolling deployments with instant rollback | K8s Deployments manage rolling updates — `kubectl rollout undo` reverts in seconds |
| Encrypted secrets at rest | K8s Secrets + Vault integration — proper secret lifecycle, rotation, audit |
| Platform-level SLOs, multi-region, self-healing | K8s is the industry standard for production workloads at this maturity level |

The migration from Compose to Kubernetes is not a full rewrite. The containers and their configuration remain identical. Only the orchestration layer changes. See the [Path to Kubernetes](#path-to-kubernetes) section at the end of this document.

### Why This Project Uses Docker Compose

1. **Single-host workloads are real production deployments.** A BMI tracker serving thousands of users does not require Kubernetes. Over-engineering wastes money and adds operational complexity without a corresponding benefit.

2. **Compose teaches the fundamentals first.** Networks, volumes, health checks, startup ordering, environment management — these concepts map directly to Kubernetes. Understanding them in Compose makes Kubernetes comprehensible, not magical.

3. **The operational patterns transfer directly.** The database initialisation scripts, the health check logic, the monitoring stack configuration, the rolling deploy strategy — all of this has a Kubernetes equivalent. Learning it in Compose is the prerequisite.

4. **Compose fits the target environment.** Running Kubernetes on a t2.medium EC2 instance would consume all available memory before the application starts. Compose runs the entire 9-container stack including full monitoring on ~770 MB.

5. **The progression from Compose to Kubernetes is intentional.** This repository is Phase 1 of a learning path. Phase 2 is Kubernetes. The [Path to Kubernetes](#path-to-kubernetes) section describes what that migration looks like.

---

## Overview

### What This Application Does

The BMI Health Tracker is a three-tier web application that calculates and persists body mass index measurements over time.

| Feature | Detail |
|---------|--------|
| BMI calculation | Weight / Height² with WHO category (Underweight / Normal / Overweight / Obese) |
| BMR calculation | Mifflin-St Jeor equation, sex-specific |
| Daily calorie estimate | BMR × activity multiplier (5 levels) |
| History tracking | All measurements persisted to PostgreSQL |
| Trend visualisation | 30-day average BMI chart (Chart.js) |

### What This Repo Demonstrates

This repository implements a complete four-phase DevOps learning progression using a real production application:

| Phase | Tool | What You Learn |
|-------|------|----------------|
| Phase 1 | Docker Compose (concepts) | Container orchestration, networks, volumes, health checks, dependencies, Compose vs Kubernetes |
| Phase 2 | `docker-compose.yml` | Three-tier app deployment, startup ordering, env management, persistence |
| Phase 3 | `docker-compose.monitoring.yml` | Full observability with Prometheus, Grafana, Loki, Promtail; 5 pre-provisioned dashboards |
| Phase 4 | `.github/workflows/deploy.yml` | Self-hosted CI/CD, deployment parity, postgres startup guard, rolling updates |

---

## Application Architecture

### Container Map

```
┌───────────────────────────────────────────────────────────────────────────┐
│  AWS EC2  ubuntu@ip-*  (t2.medium — 4 GB RAM, 2 vCPU)                     │
│                                                                           │
│  ┌─────────── App Stack  (Phase 2 — docker-compose.yml) ──────────────┐   │
│  │                                                                    │   │
│  │  ┌──────────────────┐   /api/*   ┌──────────────────┐              │   │
│  │  │  bmi-frontend    │ ─────────► │  bmi-backend     │              │   │
│  │  │  React + Nginx   │            │  Node.js Express │              │   │
│  │  │  :80 (public)    │            │  :3000 (internal)│              │   │
│  │  └──────────────────┘            └────────┬─────────┘              │   │
│  │                                           │ postgres://            │   │
│  │                                  ┌────────▼─────────┐              │   │
│  │                                  │  bmi-postgres    │              │   │
│  │                                  │  PostgreSQL 14   │              │   │
│  │                                  │  :5432 (internal)│              │   │
│  │                                  └──────────────────┘              │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌── Monitoring Stack  (Phase 3 — docker-compose.monitoring.yml) ─────┐   │
│  │                                                                    │   │
│  │  ┌──────────────┐  scrape  ┌──────────────┐                        │   │
│  │  │  prometheus  │ ◄─────── │   cadvisor   │  (container metrics)   │   │
│  │  │  :9090       │          └──────────────┘                        │   │
│  │  │  (public)    │  scrape  ┌──────────────┐                        │   │
│  │  │              │ ◄─────── │node-exporter │  (host metrics)        │   │
│  │  └──────┬───────┘          └──────────────┘                        │   │
│  │         │ datasource                                               │   │
│  │  ┌──────▼───────┐          ┌──────────────┐  push logs             │   │
│  │  │   grafana    │ ◄─────── │    loki      │ ◄──── promtail         │   │
│  │  │  :3001       │ datasrc  │  :3100       │       (docker sock)    │   │
│  │  │  (public)    │          │  (internal)  │                        │   │
│  │  └──────────────┘          └──────────────┘                        │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌──── CI/CD  (Phase 4 — .github/workflows/deploy.yml) ───────────────┐   │
│  │                                                                    │   │
│  │  GitHub ──webhook──► actions-runner (systemd)                      │   │
│  │                           │                                        │   │
│  │                     git pull + docker compose build + deploy       │   │
│  └────────────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────────────┘
```

### Network Isolation

| Network | Members | Purpose |
|---------|---------|---------|
| `bmi-backend-network` | postgres, backend | DB ↔ API only |
| `bmi-frontend-network` | backend, frontend | API ↔ Nginx proxy only |
| `monitoring-network` | prometheus, grafana, loki, promtail, cadvisor, node-exporter | All monitoring tools |

Port 5432 (postgres) and port 3000 (backend) are **never published to the host**. All external traffic enters through Nginx on port 80.

### CI/CD Flow

```
git push origin main
        ↓
GitHub webhook → self-hosted runner on EC2
        ↓
git pull → docker compose build --no-cache
        ↓
docker compose up -d --force-recreate --no-deps backend frontend
        ↓
Health checks (backend /health · frontend · Grafana · Prometheus)
        ↓
docker image prune → deployment summary logged to GitHub Actions
```

### Design Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Orchestrator | Docker Compose | Single host — simpler than Kubernetes at this scale |
| CI runner | Self-hosted on EC2 | Builds run locally — no Docker Hub, no SSH secrets, 2–3 min deploys |
| Log collection | Promtail → Loki | Label-based LogQL; native Grafana integration |
| Metrics | Prometheus + cAdvisor + node-exporter | Standard OSS stack; 400+ container and host metrics |
| DB migrations | SQL files in `database/init-scripts/` | Declarative, idempotent, auto-run once on first container start |

---

## Technology Stack

### Application

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend | React | 18 |
| | Vite | 5 |
| | Chart.js | 4 |
| | Nginx | 1.25-alpine |
| Backend | Node.js | 18-alpine |
| | Express | 4.18 |
| | node-postgres (pg) | 8.11 |
| | PM2 | latest |
| Database | PostgreSQL | 14-alpine |

### Monitoring

| Tool | Role |
|------|------|
| Prometheus | Metrics TSDB — scrapes cAdvisor + node-exporter |
| cAdvisor | Per-container CPU / memory / network |
| node-exporter | Host CPU / memory / disk / network |
| Grafana | Dashboards (5 pre-provisioned) |
| Loki | Log storage and query engine |
| Promtail | Log shipper (docker_sd_configs via Docker socket) |

### Infrastructure

| Component | Detail |
|-----------|--------|
| Cloud | AWS EC2 — Ubuntu 24.04 LTS |
| Instance | t2.medium (4 GB RAM, 2 vCPU) |
| Storage | 30 GB EBS gp3 |
| CI/CD | GitHub Actions — self-hosted runner (systemd service on EC2) |

---

## Infrastructure Requirements

### EC2 Security Group — Inbound Rules

| Port | Source | Service |
|------|--------|---------|
| 22 | Your IP only | SSH |
| 80 | 0.0.0.0/0 | Application (Nginx) |
| 3001 | Your IP only | Grafana |
| 9090 | Your IP only | Prometheus |

> Ports 3000, 5432, 3100, 8080, 9100 are internal Docker network only — never opened to the host.

### Instance Sizing

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 3 GB | **4 GB (t2.medium)** |
| vCPU | 1 | 2 |
| Disk | 20 GB | 30 GB |
| OS | Ubuntu 22.04 | **Ubuntu 24.04 LTS** |

> Running all 9 containers + the GitHub Actions runner on a t2.small causes OOM kills. t2.medium is the minimum practical size.

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml                  # CI/CD — self-hosted runner, local build + deploy
│
├── backend/
│   ├── Dockerfile
│   ├── ecosystem.config.js             # PM2 — logs redirected to /proc/1/fd/1+2 (Docker stdout/stderr)
│   ├── package.json
│   └── src/
│       ├── server.js                   # Express entry point + /health endpoint
│       ├── db.js                       # pg connection pool (max 20)
│       ├── routes.js                   # /api/measurements CRUD + /api/measurements/trends
│       └── calculations.js             # BMI / BMR / calorie maths
│
├── frontend/
│   ├── Dockerfile                      # Multi-stage: Vite build → Nginx serve
│   ├── package.json
│   ├── vite.config.js
│   └── src/
│       ├── App.jsx
│       ├── api.js                      # Axios client — relative URLs via Nginx proxy
│       └── components/
│           ├── MeasurementForm.jsx
│           └── TrendChart.jsx
│
├── database/
│   └── init-scripts/
│       ├── 01-init.sql
│       ├── 02-create-measurements.sql
│       └── 03-add-measurement-date.sql # Auto-run once via docker-entrypoint-initdb.d
│
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml              # Scrape jobs: prometheus, node-exporter, cadvisor
│   ├── loki/
│   │   └── loki-config.yml
│   ├── promtail/
│   │   └── promtail-config.yml         # docker_sd_configs; labels: container_name, service, stream
│   └── grafana/
│       ├── dashboards/
│       │   ├── docker-monitoring.json  # 23 panels: container + host metrics
│       │   ├── docker-logs.json        # 8 panels: all-container log streams
│       │   ├── application-logs.json   # 17 panels: bmi-* containers — errors, HTTP, DB, stderr
│       │   ├── host-system.json        # 30 panels: TCP, FDs, swap, disk latency, network errors
│       │   └── observability-health.json # 28 panels: scrape targets, TSDB, Loki pipeline
│       └── provisioning/
│           ├── datasources/
│           │   └── datasources.yml     # Prometheus (uid: prometheus) + Loki (uid: loki)
│           └── dashboards/
│               └── dashboards.yml      # updateIntervalSeconds: 10
│
├── scripts/
│   ├── setup-github-runner.sh          # Interactive runner registration on EC2
│   ├── health-check.sh                 # Verify all service endpoints
│   ├── backup-database.sh              # pg_dump helper
│   └── install-docker-ubuntu.sh        # Docker install on fresh Ubuntu
│
├── docker-compose.yml                  # Phase 2: postgres + backend + frontend
├── docker-compose.monitoring.yml       # Phase 3: prometheus + grafana + loki + promtail + cadvisor + node-exporter
├── docker-compose.prod.yml             # Optional overlay: CPU/memory hard limits per service (no Docker Hub required)
├── .env.example                        # Template — copy to .env before first deploy
│
├── PHASE1-DEPLOYMENT.md                # Step-by-step Phase 1 Docker Compose concepts
├── PHASE2-MONITORING.md                # Step-by-step Phase 3 monitoring stack setup
├── PHASE3-CICD.md                      # Step-by-step Phase 4 CI/CD setup
├── SETUP-GITHUB-RUNNER.md              # Runner detailed reference
└── QUICKSTART-RUNNER.md                # Runner quick reference (8 steps)
```

### Key File Reference

| File | Edit When |
|------|-----------|
| `docker-compose.yml` | Adding services, changing ports or environment |
| `docker-compose.prod.yml` | Adjusting per-service CPU and memory hard limits |
| `docker-compose.monitoring.yml` | Changing monitoring topology or retention |
| `.env` | Rotating passwords, changing EC2 IP |
| `.github/workflows/deploy.yml` | Changing CI/CD steps or triggers |
| `backend/src/routes.js` | Adding / changing API endpoints |
| `backend/src/calculations.js` | Changing BMI/BMR formulae |
| `monitoring/prometheus/prometheus.yml` | Adding scrape targets |
| `monitoring/grafana/dashboards/*.json` | Updating Grafana panels |
| `monitoring/promtail/promtail-config.yml` | Changing log labels or pipeline stages |

---

## Quick Start

**Estimated time: 15 minutes** (assuming Docker is already installed)

```bash
# 1. SSH into EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# 2. Clone
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu

# 3. Configure environment
cp .env.example .env
nano .env
# Set POSTGRES_PASSWORD (required) and FRONTEND_URL=http://YOUR_EC2_IP

# 4. Build and run (Phase 2 + 3 together: app + monitoring)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build

# 4a. Optional: also apply production resource limits
# docker compose -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.monitoring.yml up -d --build

# 5. Wait ~30–60 seconds for all health checks to pass
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml ps
```

**Access points:**

| Service | URL | Credentials |
|---------|-----|-------------|
| Application | `http://YOUR_EC2_IP` | — |
| Grafana | `http://YOUR_EC2_IP:3001` | admin / admin |
| Prometheus | `http://YOUR_EC2_IP:9090` | — |

---

## Phase 2 — Deploy the Three-Tier Application

### Step 1 — Install Docker on EC2

```bash
# Remove old versions
sudo apt remove docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key and repository
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine + Compose plugin
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu
# Log out and back in, then verify:
docker ps
docker compose version
```

### Step 2 — Clone and Configure

```bash
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu

cp .env.example .env
nano .env
```

Required `.env` content:

```env
# PostgreSQL
POSTGRES_USER=bmi_user
POSTGRES_PASSWORD=YourSecurePassword123!   # Required — no default
POSTGRES_DB=bmidb

# Application
NODE_ENV=production
FRONTEND_URL=http://YOUR_EC2_PUBLIC_IP     # Used for CORS — must match actual IP
```

> `.env` is in `.gitignore`. Never commit it. The `POSTGRES_PASSWORD` has no default — startup fails without it.

### Step 3 — Build and Deploy

```bash
docker compose up -d --build
```

**Expected startup order:** postgres → (healthy) → backend → (healthy) → frontend → (healthy)

```bash
# Confirm all three show (healthy)
docker compose ps

# Backend responds
curl http://localhost/health
# → {"status":"ok","environment":"production"}

# API responds
curl http://localhost/api/measurements
# → {"rows":[...]}
```

> `/health` is served through Nginx on port 80, not port 3000 directly.

### Database Initialisation

On first start, PostgreSQL automatically runs all `*.sql` files in `database/init-scripts/` via `docker-entrypoint-initdb.d`. This creates the `measurements` table with all columns. This runs **only once** — skipped if the volume already exists.

To force re-initialise (destroys all data):

```bash
docker compose down -v
docker compose up -d
```

### Adding a Database Column

Create a new file in `database/init-scripts/` (e.g. `04-add-notes.sql`):

```sql
ALTER TABLE measurements ADD COLUMN IF NOT EXISTS notes TEXT;
```

For **existing deployments**, apply it manually:

```bash
docker compose exec postgres psql -U bmi_user -d bmidb \
  -c "ALTER TABLE measurements ADD COLUMN IF NOT EXISTS notes TEXT;"
```

### Optional: Production Resource Limits

`docker-compose.prod.yml` is a Compose override that adds CPU and memory hard limits per service using the locally-built images. It does not require Docker Hub or any external registry.

```bash
# App + resource limits
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

# App + resource limits + monitoring (full production stack)
docker compose \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  -f docker-compose.monitoring.yml \
  up -d --build
```

| Service | CPU limit | Memory limit |
|---------|-----------|--------------|
| backend | 1.0 vCPU | 1 GB |
| frontend | 0.5 vCPU | 512 MB |
| postgres | 1.0 vCPU | 1 GB |

Resource limits prevent a runaway container from starving others on the same host. This is the closest Docker Compose gets to Kubernetes resource governance.

---

## Phase 3 — Add the Monitoring Stack

### Deploy Monitoring Stack

```bash
# Start or restart with monitoring
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d

# All 9 containers should be running
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml ps
```

### Verify Prometheus Targets

```bash
# All three targets must show state: "up"
curl -s http://localhost:9090/api/v1/targets | \
  python3 -c "import sys,json; \
  [print(t['labels']['job'], t['health']) \
   for t in json.load(sys.stdin)['data']['activeTargets']]"
```

Expected:
```
prometheus   up
node-exporter  up
cadvisor     up
```

### Prometheus Scrape Configuration

Defined in `monitoring/prometheus/prometheus.yml`:

| Job | Target | Metrics provided |
|-----|--------|-----------------|
| `prometheus` | `localhost:9090` | Prometheus self-metrics, TSDB stats |
| `node-exporter` | `node-exporter:9100` | Host CPU / memory / disk / network |
| `cadvisor` | `cadvisor:8080` | Per-container CPU / memory / network / I/O |

> The backend does **not** expose a `/metrics` endpoint. Application-layer resource data comes from cAdvisor.

To add a scrape target, edit `monitoring/prometheus/prometheus.yml` then:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml restart prometheus
```

### Grafana Dashboards

Grafana is automatically provisioned on startup from `monitoring/grafana/provisioning/`. No manual import is required. Dashboard JSON files in `monitoring/grafana/dashboards/` are picked up within 10 seconds of any change — **no restart needed**.

**Default login:** admin / admin (you will be prompted to change this on first login)

#### Five Pre-Provisioned Dashboards

| Dashboard | UID | Panels | Datasource |
|-----------|-----|--------|------------|
| Docker Container Monitoring | `docker-monitoring` | 23 | Prometheus |
| Docker Logs | `docker-logs` | 8 | Loki |
| Application Logs | `app-logs` | 17 | Loki |
| Host System Metrics | `host-system` | 30 | Prometheus |
| Observability Health | `observability-health` | 28 | Prometheus + Loki |

**docker-monitoring.json** — 6 rows:

| Row | Panels |
|-----|--------|
| Overview | Running containers, Host CPU %, Host Memory %, Max Disk % |
| Container CPU & Memory | CPU % per container (timeseries), Memory working set |
| Container Network I/O | Network RX bytes/s, TX bytes/s |
| Host CPU | Stacked CPU by mode (user/system/iowait/steal), CPU gauge |
| Host Memory & Load | Memory breakdown, Load average 1m/5m/15m |
| Disk & Network | Disk read/write bytes/s, Host network RX/TX |

**application-logs.json** — 5 rows (17 panels):

| Row | Panels |
|-----|--------|
| All App Logs | Log stream, Log rate by container, Error logs |
| Service Error Summary | Backend/Frontend/Postgres error counts (stat), Error rate timeseries |
| Nginx Access | HTTP requests log viewer, HTTP method rate (GET/POST/DELETE) |
| PostgreSQL Activity | DB connections log, Slow queries log (>500ms) |
| Backend Node.js | Stderr log viewer, Stdout vs Stderr rate |

**host-system.json** — 6 rows (30 panels): System uptime, process states, memory/swap, file descriptors, TCP connections, disk I/O latency, network errors and drops.

**observability-health.json** — 5 rows (28 panels): Scrape target UP/DOWN status, Prometheus TSDB health, monitoring container resource usage, Loki log pipeline throughput.

### How Logs Flow

```
Container stdout/stderr
        ↓
/var/lib/docker/containers/<id>/*-json.log
        ↓
Promtail (docker_sd_configs via /var/run/docker.sock)
  adds labels: container_name, service, stream
        ↓
Loki (http://loki:3100/loki/api/v1/push)
        ↓
Grafana (Loki datasource, uid: loki)
```

> Processes inside containers must write to **stdout/stderr**, not to files. Backend uses PM2 with `out_file: '/proc/1/fd/1'` and `error_file: '/proc/1/fd/2'` in `ecosystem.config.js` to ensure this.

### Loki Label Reference

Promtail applies these labels to every log line:

| Label | Example value | Notes |
|-------|--------------|-------|
| `container_name` | `/bmi-backend` | Leading `/` is part of the value |
| `service` | `backend` | Docker Compose service name |
| `stream` | `stdout` | `stdout` or `stderr` |

Use `container_name` in LogQL — the `/` prefix is required:

```logql
{container_name="/bmi-backend"}
{container_name=~"/bmi-backend|/bmi-frontend|/bmi-postgres"}
{container_name=~"/bmi-backend|/bmi-frontend|/bmi-postgres"} |~ "(?i)error|exception|fail"
{container_name="/bmi-backend", stream="stderr"}
```

### PostgreSQL Log Visibility

`docker-compose.yml` passes these flags to PostgreSQL so DB activity appears in Grafana:

```
log_connections=on           — logs every new connection
log_disconnections=on        — logs every disconnect
log_statement=mod            — logs INSERT / UPDATE / DELETE / DDL
log_min_duration_statement=500  — logs any query > 500 ms
log_min_messages=warning     — logs warnings and above
```

### Grafana Provisioning Paths

| Path in container | Local path | Controls |
|-------------------|-----------|---------|
| `/etc/grafana/provisioning` | `monitoring/grafana/provisioning/` | Datasource + dashboard config |
| `/var/lib/grafana/dashboards` | `monitoring/grafana/dashboards/` | Dashboard JSON files |

### Useful PromQL Queries

```promql
# Container memory working set
container_memory_working_set_bytes{name=~"bmi-.*"}

# Container CPU %
sum(rate(container_cpu_usage_seconds_total{name=~"bmi-.*"}[5m])) by (name) * 100

# Host CPU used %
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Host memory used %
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Disk usage % per mountpoint
(1 - node_filesystem_avail_bytes{fstype!~"tmpfs|overlay|squashfs"} /
     node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs"}) * 100

# Network receive rate
rate(container_network_receive_bytes_total{name=~"bmi-.*"}[5m])
```

---

## Phase 4 — GitHub Actions Deployment

### Why Self-Hosted Runner

| | GitHub Cloud Runner | Self-Hosted (EC2) |
|---|---|---|
| Repo access | Needs SSH secrets | Direct — same machine as deployment |
| Docker builds | Requires Docker Hub push/pull | Local build only |
| Deploy time | ~7–10 min | **~2–3 min** |
| External dependencies | Docker Hub account | None |
| Cost | Uses free minutes quota | Free (your EC2) |

### Deployment Parity — Manual vs CI/CD

Both deployment methods produce **identical final state** (9 containers, same networks, same volumes). The only intentional differences are:

| Aspect | Method A — Manual | Method B — GitHub Actions |
|--------|------------------|---------------------------|
| Command | `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build` | Staged: build → postgres → app → monitoring |
| Image cache | Uses layer cache (faster) | `--no-cache` (always fresh build) |
| Startup order | Docker Compose `depends_on` health chain | Manual postgres-first + `pg_isready` poll |
| Monitoring restart | Only if config changed | Not force-recreated (preserves metric history) |
| `.env` required | Yes — created manually before run | Yes — checked by bootstrap step, fails fast if missing |
| Fresh server | Clone + `.env` documented in Phase 1 | Bootstrap step clones repo if not present |

> The CI/CD workflow uses `--force-recreate --no-deps` for app containers (backend, frontend) to guarantee the newly-built image is used, while leaving postgres and monitoring untouched on incremental deploys.

### First-Time Server Setup (Pre-flight for CI/CD)

These steps must be completed **once manually** on a fresh server before the first CI/CD run. After this, all subsequent deploys are fully automated.

```bash
# 1. SSH into the fresh EC2 instance
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# 2. Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo apt-get install -y docker-compose-plugin
sudo usermod -aG docker ubuntu
newgrp docker
docker compose version   # Verify

# 3. Clone the repository
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git \
  ~/3-tier-docker-compose-monitoring-ubuntu
cd ~/3-tier-docker-compose-monitoring-ubuntu

# 4. Create and configure .env (REQUIRED — never committed to git)
cp .env.example .env
nano .env
# Set: POSTGRES_PASSWORD=<strong-password>
# Set: FRONTEND_URL=http://YOUR_EC2_PUBLIC_IP

# 5. Register the GitHub Actions runner (see steps below)
```

After these 5 steps, all future deployments run automatically on `git push origin main`.

### Step 1 — Register the Runner on GitHub

1. Go to: **Repository → Settings → Actions → Runners → New self-hosted runner**
2. Select **Linux** / **x64**
3. Keep the page open — you will copy the download URL and token from it

### Step 2 — Install the Runner on EC2

```bash
# On EC2
mkdir -p ~/actions-runner && cd ~/actions-runner

# Copy the exact download URL from GitHub's page (version changes over time)
curl -o actions-runner-linux-x64.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.x.x/actions-runner-linux-x64-2.x.x.tar.gz

tar xzf ./actions-runner-linux-x64.tar.gz

# Configure — paste the full ./config.sh command from GitHub's page (includes your one-time token)
./config.sh --url https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu \
  --token YOUR_ONE_TIME_TOKEN
# Accept defaults: press Enter through runner group, runner name, and _work folder
```

### Step 3 — Install as a systemd Service

```bash
cd ~/actions-runner
sudo ./svc.sh install ubuntu
sudo ./svc.sh start
sudo ./svc.sh status    # Must show: active (running)
```

The service auto-starts on EC2 reboot.

### Step 4 — Add Docker Access

```bash
sudo usermod -aG docker ubuntu
newgrp docker
docker ps    # Must work without sudo
```

### Step 5 — Verify Runner is Online

GitHub → **Settings → Actions → Runners** → runner shows **Idle** ✅

If it shows **Offline**:

```bash
cd ~/actions-runner
sudo systemctl restart actions.runner.*
sudo systemctl status  actions.runner.*
```

### The Workflow File

**Location:** `.github/workflows/deploy.yml`

**Trigger:** Push to `main` branch, or manual dispatch

**Runs on:** `self-hosted` (your EC2)

**Steps:**

| Step | What it does |
|------|-------------|
| Ensure docker group membership | Checks ubuntu is in docker group; adds if missing |
| Checkout code | `actions/checkout@v4` into runner work directory |
| **Bootstrap project directory** | Clones repo to `/home/ubuntu/` if not present; fails fast with instructions if `.env` is missing |
| Pull latest code | `git fetch && git reset --hard origin/main` in project directory |
| Build application images | `docker compose build --no-cache` |
| Deploy application | Starts postgres, polls `pg_isready`, then `--force-recreate --no-deps backend frontend` |
| Ensure monitoring | `up -d` prometheus, grafana, loki, promtail, cadvisor, node-exporter |
| Health check | `curl http://localhost/health` (via Nginx proxy), frontend port 80, Grafana port 3001, Prometheus `/-/healthy` |
| Show container status | `docker compose ps` |
| Cleanup old images | `docker image prune -af --filter "until=24h"` |
| Deployment summary | Logs public IP and service URLs |

**Postgres startup guard** — the deploy step polls `pg_isready` up to 12 times (every 5 s, 60 s max) before starting backend and frontend. This prevents backend container crashes on fresh deploys where postgres needs time to initialise.

### Triggering a Deploy

```bash
# Normal path — any push to main triggers the workflow
git add .
git commit -m "feat: your change"
git push origin main

# Monitor at:
# https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/actions
```

### Rollback

**Option 1 — Git revert (recommended, triggers CI/CD):**

```bash
git revert HEAD
git push origin main
# CI/CD automatically redeploys the reverted version
```

**Option 2 — Manual on EC2:**

```bash
cd ~/3-tier-docker-compose-monitoring-ubuntu
git log --oneline -10
git checkout <previous-commit-hash>
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build
```

**Option 3 — Tag before deploying:**

```bash
# Before a deploy
git tag v1.2.0 && git push origin v1.2.0

# To rollback
git checkout v1.2.0
docker compose up -d --build
```

### Skip CI/CD for a Commit

```bash
git commit -m "docs: update README [skip ci]"
```

---

## Environment Variables

### Root `.env` — the only file that matters

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `POSTGRES_USER` | Yes | `bmi_user` | PostgreSQL username |
| `POSTGRES_PASSWORD` | **Yes** | — | PostgreSQL password — startup fails without this |
| `POSTGRES_DB` | Yes | `bmidb` | Database name |
| `NODE_ENV` | Yes | `production` | Node environment |
| `FRONTEND_URL` | Yes | `http://localhost` | EC2 public IP — used for CORS |

Copy `.env.example` to `.env` before first deploy. Never commit `.env` (it is gitignored).

> `backend/.env.example` exists but is not used — Docker Compose injects all variables directly into containers from the root `.env`.

---

## API Reference

**Base URL:** `http://YOUR_EC2_IP/api` (proxied through Nginx on port 80)

### POST /api/measurements

Create a new measurement.

**Request body:**

```json
{
  "weightKg": 70,
  "heightCm": 175,
  "age": 30,
  "sex": "male",
  "activity": "moderate",
  "measurementDate": "2026-04-02"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `weightKg` | number | ✅ | Positive |
| `heightCm` | number | ✅ | Positive |
| `age` | number | ✅ | Positive |
| `sex` | string | ✅ | `"male"` or `"female"` |
| `activity` | string | No | `"sedentary"` `"light"` `"moderate"` `"active"` `"very_active"` |
| `measurementDate` | string | No | ISO date, defaults to today |

**Response 201:**

```json
{
  "measurement": {
    "id": 4,
    "weight_kg": "70.00",
    "height_cm": "175.00",
    "age": 30,
    "sex": "male",
    "activity_level": "moderate",
    "bmi": "22.9",
    "bmi_category": "Normal",
    "bmr": 1649,
    "daily_calories": 2556,
    "measurement_date": "2026-04-02T00:00:00.000Z",
    "created_at": "2026-04-02T04:12:07.114Z"
  }
}
```

```bash
curl -X POST http://YOUR_EC2_IP/api/measurements \
  -H "Content-Type: application/json" \
  -d '{"weightKg":70,"heightCm":175,"age":30,"sex":"male","activity":"moderate"}'
```

### GET /api/measurements

Return all measurements, ordered by date descending.

```bash
curl http://YOUR_EC2_IP/api/measurements
# → {"rows":[{...},...]}
```

### GET /api/measurements/trends

Return 30-day daily average BMI.

```bash
curl http://YOUR_EC2_IP/api/measurements/trends
# → {"rows":[{"day":"2026-04-02T00:00:00.000Z","avg_bmi":"22.9"},...]}
```

### GET /health

Application health check (served through Nginx on port 80).

```bash
curl http://YOUR_EC2_IP/health
# → {"status":"ok","environment":"production"}
```

---

## Operations Runbook

### Start / Stop / Restart

```bash
# Start everything (app + monitoring)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d

# Stop (keeps volumes and data)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml down

# Restart single service
docker compose restart backend

# Restart with rebuild
docker compose up -d --build backend

# Force-recreate app containers without touching database or monitoring
docker compose up -d --force-recreate --no-deps backend frontend
```

### Update from Git (Manual Deploy)

```bash
cd ~/3-tier-docker-compose-monitoring-ubuntu
git pull origin main
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml ps
```

### Full Teardown and Rebuild

```bash
# Stop + remove containers (data safe in volumes)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml down

# Rebuild and start
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build
```

### Teardown Including All Data (⚠️ deletes database)

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml down --volumes
```

### Database Backup and Restore

```bash
# Backup (plain SQL)
docker compose exec postgres pg_dump -U bmi_user bmidb \
  > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup (compressed)
docker compose exec postgres pg_dump -U bmi_user bmidb \
  | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Restore from plain SQL
cat backup.sql | docker compose exec -T postgres psql -U bmi_user -d bmidb

# Restore from compressed
gunzip -c backup.sql.gz | docker compose exec -T postgres psql -U bmi_user -d bmidb
```

Automate backups with cron (on EC2):

```bash
crontab -e
# Add:
0 2 * * * cd ~/3-tier-docker-compose-monitoring-ubuntu && \
  docker compose exec -T postgres pg_dump -U bmi_user bmidb \
  | gzip > ~/backups/bmidb_$(date +\%Y\%m\%d).sql.gz
```

### View Logs

```bash
# All containers, follow
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml logs -f

# Single container
docker compose logs -f backend

# Last 200 lines
docker compose logs --tail=200 backend

# Filter errors
docker compose logs backend 2>&1 | grep -i error
```

### Disk Space Management

```bash
# Check host disk
df -h

# Check Docker objects
docker system df

# Safe cleanup — removes images older than 24h, keeps running containers
docker image prune -af --filter "until=24h"
docker builder prune -af

# Nuclear clean (removes ALL unused Docker objects)
docker system prune -af
```

### GitHub Actions Runner Management

```bash
# Status
cd ~/actions-runner
sudo ./svc.sh status

# Start / stop / restart
sudo ./svc.sh start
sudo ./svc.sh stop
sudo ./svc.sh restart

# View runner logs (last 30 minutes, follow)
sudo journalctl -u actions.runner.* --since "30 minutes ago" -f

# Re-register runner (if registration token expired)
cd ~/actions-runner
./config.sh remove --token YOUR_OLD_TOKEN
# Get new token: GitHub → Settings → Actions → Runners → New self-hosted runner
./config.sh \
  --url https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu \
  --token NEW_TOKEN
sudo ./svc.sh install ubuntu && sudo ./svc.sh start
```

### Add a Custom Grafana Dashboard

1. Build and configure the dashboard in the Grafana UI
2. Export it: Dashboard **Settings** → **JSON Model** → copy all
3. Save as `monitoring/grafana/dashboards/my-dashboard.json`
4. Grafana auto-loads it within 10 seconds — no restart needed
5. Commit the JSON file to git so it deploys with the next push

### Add a Prometheus Scrape Target

Edit `monitoring/prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['my-service:9999']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

Then restart Prometheus:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml restart prometheus
```

### psql Shell Access

```bash
docker compose exec postgres psql -U bmi_user -d bmidb

# Useful psql commands:
\dt                        -- list tables
\d measurements            -- describe measurements table
SELECT * FROM measurements ORDER BY created_at DESC LIMIT 5;
```

---

## Troubleshooting

### Container shows (unhealthy)

```bash
# See what the health check returned
docker inspect bmi-backend | grep -A 20 '"Health"'

# Check logs
docker compose logs --tail=50 backend

# Manual health check
curl http://localhost/health
```

**Most common cause:** backend fails to connect to postgres on first start. Wait 30–60 s, then:

```bash
docker compose restart backend
```

### Cannot access the application from browser

1. Verify EC2 Security Group allows port 80 from `0.0.0.0/0`
2. Confirm you are using the **public** IP (not `10.x.x.x` private IP)
3. Check frontend: `docker compose ps bmi-frontend`
4. Check port is bound: `sudo ss -tlpn | grep :80`

### Database connection errors (ECONNREFUSED / authentication failed)

```bash
# Is postgres running and healthy?
docker compose ps bmi-postgres

# Can the backend reach it?
docker compose exec backend ping postgres

# Is the password correct?
docker compose exec postgres pg_isready -U bmi_user -d bmidb

# What env vars does the backend see?
docker compose exec backend env | grep DATABASE
```

### No logs appearing in Grafana

**Backend logs missing:**

Verify `ecosystem.config.js` has:

```javascript
out_file:   '/proc/1/fd/1',
error_file: '/proc/1/fd/2',
```

And verify the `Dockerfile` starts the app with `pm2-runtime` (not `node` directly):

```dockerfile
CMD ["pm2-runtime", "ecosystem.config.js"]
```

Then rebuild:

```bash
docker compose up -d --build backend
docker logs bmi-backend    # Must show startup messages
```

**Postgres logs missing:**

Verify `docker-compose.yml` has the `command:` block with `-c log_statement=mod`, then:

```bash
docker compose up -d --force-recreate postgres
docker logs bmi-postgres   # Must show connection log lines
```

**All logs missing:**

Check Promtail:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml logs promtail
# Look for "level=info msg=Attached to container" entries
```

### Grafana shows "datasource not found"

```bash
# Verify UIDs in provisioning file
docker compose exec grafana \
  cat /etc/grafana/provisioning/datasources/datasources.yml

# Restart Grafana to re-apply provisioning
docker compose restart grafana
```

Datasource UIDs must match what dashboard JSON files reference: `prometheus` and `loki`.

### Loki shows (unhealthy) in docker ps

This is a **false positive** — the Docker healthcheck timing is misconfigured in the image. Loki is functional. Verify:

```bash
curl http://localhost:3100/ready    # → "ready"
```

If it returns `ready`, ignore the unhealthy status.

### Grafana shows "No data" on panels

1. Check Prometheus scrape targets are all UP: `http://YOUR_EC2_IP:9090/targets`
2. Test the datasource: Grafana → **Settings → Data Sources → Prometheus → Test**
3. Check the time range in the dashboard is not too narrow
4. For Loki panels — confirm containers are actually producing logs

### Runner shows Offline in GitHub

```bash
cd ~/actions-runner
sudo systemctl status actions.runner.*
sudo ./svc.sh restart
```

If still offline after restart — token expired. Re-register following the runner management steps above.

### Disk full during CI/CD build

```bash
df -h
docker system df
docker image prune -af --filter "until=24h"
docker builder prune -af
```

### Port 80 already in use

```bash
sudo lsof -i :80
sudo systemctl stop apache2    # or nginx, if installed
sudo systemctl disable apache2
```

---

## Security

### What Is Already Protected

| Area | Control |
|------|---------|
| Database port (5432) | Not published to host; internal to `bmi-backend-network` only |
| Backend port (3000) | Not published to host; accessible only via Nginx proxy |
| Credentials | In `.env` (gitignored); never hardcoded in source |
| SQL injection | Parameterised queries (`$1`, `$2`, ...) in all database calls |
| CORS | Restricted to `FRONTEND_URL` value |
| Container networking | Three isolated networks; frontend cannot reach database directly |
| Image attack surface | Alpine base images throughout |

### Recommended Hardening for Production

**1. Change Grafana admin password** — you are prompted on first login.

**2. HTTPS with Certbot:**

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

**3. Rate limiting in `frontend/nginx.conf`:**

```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
location /api/ {
    limit_req zone=api burst=20 nodelay;
    proxy_pass http://backend:3000/api/;
}
```

**4. Security headers in `frontend/nginx.conf`:**

```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

**5. Image vulnerability scanning:**

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image bmi-backend:latest
```

### Security Checklist

- [ ] `POSTGRES_PASSWORD` is strong (16+ chars, mixed case/numbers/symbols)
- [ ] `.env` is never committed — verify with `git status`
- [ ] Grafana password changed from `admin`
- [ ] EC2 Security Group restricts Grafana (3001) and Prometheus (9090) to your IP
- [ ] SSH uses key authentication only (no password auth on EC2)
- [ ] Regular `docker image prune` to remove layers with old dependencies
- [ ] HTTPS enabled if the application is publicly accessible

---

## Performance

### Measured Resource Usage (t2.medium at idle)

| Container | CPU | RAM |
|-----------|-----|-----|
| bmi-frontend | <1% | ~20 MB |
| bmi-backend | <1% | ~80 MB |
| bmi-postgres | <1% | ~50 MB |
| prometheus | 1–2% | ~200 MB |
| grafana | <1% | ~150 MB |
| loki | <1% | ~100 MB |
| promtail | <1% | ~50 MB |
| cadvisor | 1–2% | ~100 MB |
| node-exporter | <1% | ~20 MB |
| **Total** | **~7%** | **~770 MB** |

During a CI/CD build, the runner can use 50–100% CPU for 30–60 s while building images.

### Tuning

**PostgreSQL connection pool** is `max: 20` in `backend/src/db.js`. Adequate for a single-instance app on t2.medium.

**Prometheus retention** defaults to 15 days / 10 GB. Reduce if disk is constrained (edit `docker-compose.monitoring.yml`):

```yaml
command:
  - --storage.tsdb.retention.time=7d
  - --storage.tsdb.retention.size=5GB
```

**Loki retention** — edit `monitoring/loki/loki-config.yml`:

```yaml
limits_config:
  retention_period: 168h    # 7 days
```

**Prometheus scrape interval** — edit `monitoring/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 30s      # Default 15s — reduce to lower CPU/disk usage
```

**Grafana dashboard refresh** — change from 10 s to 30 s or 1 m in panel settings to reduce Prometheus query load at the expense of near-real-time visibility.

---

## Path to Kubernetes

Docker Compose is the right tool for this workload. When the system grows beyond a single host, the migration to Kubernetes is a natural extension — not a rewrite.

### Concept Mapping

Every Docker Compose concept has a direct Kubernetes equivalent. Learning Compose correctly means you already understand Kubernetes conceptually.

| Docker Compose | Kubernetes equivalent | Notes |
|----------------|----------------------|-------|
| Service | `Deployment` + `Service` | K8s separates the workload definition from the network endpoint |
| Named network | `Namespace` + `NetworkPolicy` | K8s provides cluster-wide DNS; NetworkPolicy controls allowed traffic |
| Named volume | `PersistentVolumeClaim` | PVC lifecycle is independent of pod lifecycle |
| `depends_on: condition: service_healthy` | Init containers + readiness probes | K8s has more granular startup control |
| `env_file: .env` | `ConfigMap` + `Secret` | Secrets are stored encrypted at rest in etcd |
| `restart: unless-stopped` | `restartPolicy: Always` + liveness probe | K8s also heals across node failures |
| `deploy.resources.limits` | `resources.limits` in pod spec | Identical concept; enforced at the kernel level via cgroups |
| `docker compose up --scale backend=3` | `replicas: 3` in Deployment | K8s spreads replicas across nodes automatically |
| Prometheus + Grafana | Same — but with kube-state-metrics + K8s dashboards | Add cluster-level metrics on top of existing stack |
| Loki + Promtail | Same — but Promtail uses K8s pod discovery | Label set expands: namespace, pod name, container name |

### When to Migrate

Migrate when you hit any of these:

1. **Uptime requirement exceeds what single-host allows.** A host maintenance window, hardware failure, or EC2 stop/start causes downtime. If your SLA requires 99.9%+ availability, you need multi-node.

2. **Deployment frequency increases.** Multiple pushes per day to multiple services with no tolerance for even seconds of downtime requires K8s rolling deployments.

3. **Team size grows.** Multiple developers, multiple services, multiple environments (dev/staging/prod). K8s namespaces, RBAC, and separate clusters per environment prevent teams from interfering with each other.

4. **Traffic is unpredictable.** If you need to scale from 1 replica to 10 and back in response to load, HPA is the right tool.

5. **Compliance requires encrypted secrets.** `.env` files and environment variables do not meet SOC 2 or PCI-DSS secret management requirements.

### Migration Path

#### Step 1: Convert Compose to Kubernetes Manifests

```bash
# Install kompose
curl -L https://github.com/kubernetes/kompose/releases/latest/download/kompose-linux-amd64 \
  -o /usr/local/bin/kompose && chmod +x /usr/local/bin/kompose

# Convert (generates raw K8s YAML as a starting point)
kompose convert -f docker-compose.yml -f docker-compose.monitoring.yml
```

`kompose` produces Deployment, Service, and PersistentVolumeClaim YAMLs. These need manual review — the output is a scaffold, not production-ready.

#### Step 2: Move Secrets to Kubernetes Secrets

```bash
# Create secrets from .env values
kubectl create secret generic bmi-secrets \
  --from-literal=POSTGRES_PASSWORD=YourSecurePassword \
  --from-literal=POSTGRES_USER=bmi_user \
  --from-literal=POSTGRES_DB=bmidb
```

Reference in pod spec:
```yaml
env:
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: bmi-secrets
        key: POSTGRES_PASSWORD
```

#### Step 3: Replace Nginx Proxy with an Ingress Controller

The Nginx container in this project acts as a reverse proxy for `/api` and `/health`. In Kubernetes, this role is served by an Ingress controller (nginx-ingress, Traefik, or AWS ALB Ingress Controller).

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bmi-ingress
spec:
  rules:
    - http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: bmi-backend
                port:
                  number: 3000
          - path: /
            pathType: Prefix
            backend:
              service:
                name: bmi-frontend
                port:
                  number: 80
```

#### Step 4: Replace Docker Compose Healthchecks with Probes

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 40
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 10
```

#### Step 5: Package with Helm

Once the manifests are stable, package them as a Helm chart for repeatable deployments across environments:

```
helm-chart/
├── Chart.yaml
├── values.yaml          # Default values — override per environment
├── templates/
│   ├── deployment-backend.yaml
│   ├── deployment-frontend.yaml
│   ├── statefulset-postgres.yaml
│   ├── service-*.yaml
│   ├── ingress.yaml
│   └── secret.yaml
```

```bash
helm install bmi-app ./helm-chart --set postgres.password=YOURPASSWORD
helm upgrade bmi-app ./helm-chart --set image.tag=v2.0.0
helm rollback bmi-app 1
```

### Tools You Will Use

| Tool | Purpose |
|------|---------|
| `kubectl` | Primary cluster CLI — same role as `docker compose` |
| `helm` | Package manager for K8s applications |
| `kompose` | One-time Compose → K8s manifest converter |
| `kube-state-metrics` | Cluster-level metrics for Prometheus |
| `metrics-server` | Required for HPA (reads pod CPU/memory) |
| `cert-manager` | Automated TLS certificate management |
| `external-secrets` | Sync secrets from AWS Secrets Manager / Vault |

The monitoring stack (Prometheus, Grafana, Loki) is unchanged. You add kube-state-metrics and update Promtail's scrape config to use Kubernetes pod discovery instead of Docker socket discovery.

---

## Roadmap

| Status | Item |
|--------|------|
| ✅ | Phase 1: Docker Compose concepts documented |
| ✅ | Phase 2: Three-tier application (React / Node.js / PostgreSQL) |
| ✅ | Phase 3: Prometheus + Grafana + Loki observability stack |
| ✅ | Phase 4: Self-hosted GitHub Actions CI/CD |
| ✅ | 5 pre-provisioned Grafana dashboards (106 panels total) |
| ✅ | Zero-downtime rolling deploys |
| ✅ | Postgres startup guard in deploy workflow |
| 📋 | HTTPS with Let's Encrypt |
| 📋 | Automated unit + integration tests in CI |
| 📋 | Prometheus alerting rules + Alertmanager |
| 📋 | Grafana alert notifications (Slack / email) |
| 📋 | Automated database backups to S3 |
| 📋 | Kubernetes migration (Helm charts) |
| 📋 | Multi-AZ with RDS PostgreSQL |
| 📋 | Distributed tracing (Grafana Tempo) |
| 📋 | Terraform for EC2 provisioning |

---

## 🧑‍💻 Project Lead

*Md. Sarowar Alam*  
Lead DevOps Engineer, WPP Production
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---

