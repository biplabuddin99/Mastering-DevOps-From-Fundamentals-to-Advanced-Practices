# BMI Health Tracker — 3-Tier AWS Infrastructure

[![Terraform](https://img.shields.io/badge/Terraform-≥1.14-623CE4?logo=terraform)](https://developer.hashicorp.com/terraform)
[![Node.js](https://img.shields.io/badge/Node.js-22.x_LTS-339933?logo=node.js)](https://nodejs.org)
[![React](https://img.shields.io/badge/React-18.x-61DAFB?logo=react)](https://react.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-336791?logo=postgresql)](https://www.postgresql.org)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-26.04_LTS-E95420?logo=ubuntu)](https://releases.ubuntu.com/resolute/)
[![AWS](https://img.shields.io/badge/AWS-ap--south--1-FF9900?logo=amazonaws)](https://aws.amazon.com)

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Overview](#2-architecture-overview)
3. [Tech Stack](#3-tech-stack)
4. [Folder Structure](#4-folder-structure)
5. [Application Workflow](#5-application-workflow)
6. [CI/CD Pipeline Overview](#6-cicd-pipeline-overview)
7. [GitHub Actions Workflow](#7-github-actions-workflow)
8. [Self-Hosted Runner Setup](#8-self-hosted-runner-setup)
9. [Deployment Modules](#9-deployment-modules)
10. [Environment Variables](#10-environment-variables)
11. [Prerequisites](#11-prerequisites)
12. [Local Development Setup](#12-local-development-setup)
13. [Build and Run Instructions](#13-build-and-run-instructions)
14. [Testing Instructions](#14-testing-instructions)
15. [Production Deployment](#15-production-deployment)
16. [Monitoring and Logging](#16-monitoring-and-logging)
17. [Security Best Practices](#17-security-best-practices)
18. [Troubleshooting](#18-troubleshooting)
19. [Future Improvements](#19-future-improvements)
20. [Contributor Guidelines](#20-contributor-guidelines)
21. [License](#21-license)

---

## 1. Project Overview

**BMI Health Tracker** is a production-grade 3-tier web application deployed on AWS that allows users to log and track their Body Mass Index (BMI), Basal Metabolic Rate (BMR), and daily calorie requirements over time. The application calculates health metrics using the Mifflin-St Jeor equation and visualises 30-day BMI trends via an interactive chart.

The entire infrastructure is provisioned and managed using **Terraform**, deployed on **Ubuntu 26.04 LTS (Resolute Raccoon)** EC2 instances across two independently selectable architecture patterns:

| Module | Architecture | Use Case |
|---|---|---|
| `terraform_private_alb_acm/` | ALB-fronted, all EC2s private, DNS-01 cert → ACM | Production with HA/scaling headroom |
| `terraform_front_end_public/` | Frontend EIP public, no ALB, HTTP-01 cert local | Cost-optimised single-instance |

---

## 2. Architecture Overview

### Module 1 — `terraform_private_alb_acm` (ALB + Private EC2s)

```
Internet
   │
   ▼
Route53  (A-Alias → ALB)
   │
   ▼
Application Load Balancer  ← public subnets, TLS 1.3, ACM cert
   │  HTTP :80 → 301 HTTPS
   │  HTTPS :443 → Target Group
   ▼
Frontend EC2  (private subnet)     Nginx + React SPA
   │  /api/* proxy → :3000
   ▼
Backend EC2   (private subnet)     Node.js 22 + Express + PM2
   │  :5432
   ▼
Database EC2  (private subnet)     PostgreSQL 18
```

- All EC2 instances in **private subnets** — no public IPs
- **Certbot DNS-01** issues cert via Route53, imported to ACM
- ALB terminates TLS; instances never see HTTPS traffic
- Pre-existing VPC/subnets/security-groups required

### Module 2 — `terraform_front_end_public` (EIP + No ALB)

```
Internet
   │
   ▼
Route53  (A → Frontend EIP)
   │
   ▼
Frontend EC2  (public subnet, Elastic IP)   Nginx + React SPA + Certbot HTTP-01
   │  /api/* proxy → :3000
   ▼
Backend EC2   (private subnet)              Node.js 22 + Express + PM2
   │  :5432
   ▼
Database EC2  (private subnet)              PostgreSQL 18
```

- Creates **VPC from scratch** (10.0.0.0/16, NAT Gateway, route tables)
- Frontend on public subnet with static EIP
- Certbot HTTP-01 — cert stored locally in `/etc/letsencrypt/`
- Lower cost (no ALB ~$16–20/month saving)

---

## 3. Tech Stack

### Application

| Layer | Technology | Version | Details |
|---|---|---|---|
| Frontend | React | 18.x | Vite build, SPA with React Router |
| Frontend | Vite | 5.x | Dev server :5173, production build |
| Frontend | Axios | 1.x | API client with interceptors |
| Frontend | Chart.js + react-chartjs-2 | 4.x / 5.x | 30-day BMI trend chart |
| Backend | Node.js | 22 LTS | Express API server |
| Backend | Express | 4.x | REST API framework |
| Backend | PM2 | latest | Process manager, auto-restart, systemd |
| Backend | dotenv | 16.x | Environment variable management |
| Database | PostgreSQL | 18 | Relational DB, connection pooling via `pg` |
| Web Server | Nginx | latest | Reverse proxy, static file serving, TLS |

### Infrastructure

| Component | Technology | Details |
|---|---|---|
| IaC | Terraform ≥1.14 | AWS provider ~5.0, null provider ~3.0 |
| Cloud | AWS ap-south-1 | Mumbai region |
| Compute | EC2 t3.small / t3.medium | Ubuntu 26.04 LTS (Resolute Raccoon) |
| AMI | SSM Parameter Store | Auto-resolves latest Ubuntu 26.04 |
| Networking | VPC, Subnets, NAT GW, IGW | Module 2 creates from scratch |
| Load Balancer | Application Load Balancer | Module 1 only, TLS 1.3 |
| DNS | Route53 | A/Alias records |
| TLS (Module 1) | Let's Encrypt + ACM | Certbot DNS-01 → imported to ACM |
| TLS (Module 2) | Let's Encrypt (local) | Certbot HTTP-01 → Nginx |
| State | S3 + encryption | `batch-12-tf-states` bucket |
| Access | AWS SSM Session Manager | No bastion required |
| Storage | EBS gp3 | 30GB (DB), 20GB (backend/frontend), encrypted |

---

## 4. Folder Structure

```
terraform-3-tier-different-servers/
│
├── backend/                          # Node.js Express API
│   ├── src/
│   │   ├── server.js                 # Express app entry point (port 3000)
│   │   ├── routes.js                 # API route handlers
│   │   ├── db.js                     # PostgreSQL connection pool
│   │   └── calculations.js           # BMI, BMR, calorie calculations
│   ├── migrations/
│   │   ├── 001_create_measurements.sql
│   │   └── 002_add_measurement_date.sql
│   ├── ecosystem.config.js           # PM2 configuration
│   └── package.json
│
├── frontend/                         # React + Vite SPA
│   ├── src/
│   │   ├── App.jsx                   # Root component, stats display
│   │   ├── api.js                    # Axios API client
│   │   ├── main.jsx                  # React entry point
│   │   ├── index.css                 # Global styles
│   │   └── components/
│   │       ├── MeasurementForm.jsx   # Add new measurement form
│   │       └── TrendChart.jsx        # 30-day BMI trend chart
│   ├── vite.config.js                # Vite + dev proxy config
│   ├── index.html
│   └── package.json
│
├── database/
│   └── setup-database.sh             # Manual DB setup script (standalone)
│
├── terraform_private_alb_acm/        # Module 1: ALB + all private EC2s
│   ├── main.tf                       # Root orchestration
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf                    # S3 remote state
│   ├── terraform.tfvars              # Active config (git-ignored)
│   ├── terraform.tfvars.example      # Template
│   ├── backend-config.tfbackend      # S3 backend credentials (git-ignored)
│   └── modules/
│       ├── alb/                      # Application Load Balancer
│       ├── dns/                      # Route53 A-Alias record
│       ├── ec2/                      # 3 EC2 instances + cert wait
│       │   └── templates/
│       │       ├── database-init.sh
│       │       ├── backend-init.sh
│       │       └── frontend-init.sh
│       └── iam/                      # Frontend IAM role (Route53 + ACM + SSM)
│
└── terraform_front_end_public/       # Module 2: EIP frontend + creates VPC
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── backend.tf
    ├── provider.tf
    ├── terraform.tfvars              # Active config (git-ignored)
    ├── backend-config.tfbackend      # S3 backend credentials (git-ignored)
    ├── modules/
    │   ├── vpc/                      # VPC, subnets, NAT GW, IGW
    │   ├── security_groups/          # Tiered SGs (frontend/backend/database)
    │   ├── iam/                      # SSM roles for all 3 tiers
    │   ├── ec2/                      # 3 EC2 instances + EIP + SSM waits
    │   └── route53/                  # A record → Frontend EIP
    └── scripts/
        ├── database_setup.sh
        ├── backend_setup.sh
        ├── frontend_setup.sh
        └── generate_certificate.sh
```

---

## 5. Application Workflow

### API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Health check — returns `{ status: "ok", environment: "production" }` |
| `POST` | `/api/measurements` | Submit a new measurement |
| `GET` | `/api/measurements` | Retrieve all measurements (newest first) |
| `GET` | `/api/measurements/trends` | 30-day daily average BMI trend |

### POST `/api/measurements` — Request Body

```json
{
  "weightKg": 75.0,
  "heightCm": 175,
  "age": 30,
  "sex": "male",
  "activity": "moderate",
  "measurementDate": "2026-07-07"
}
```

**`activity` values:** `sedentary` | `light` | `moderate` | `active` | `very_active`

### Health Metric Calculations

| Metric | Formula |
|---|---|
| BMI | `weight(kg) / height(m)²` |
| BMR (male) | `10×weight + 6.25×height − 5×age + 5` (Mifflin-St Jeor) |
| BMR (female) | `10×weight + 6.25×height − 5×age − 161` |
| Daily Calories | `BMR × activity_multiplier` |

| BMI Range | Category |
|---|---|
| < 18.5 | Underweight |
| 18.5 – 24.9 | Normal |
| 25 – 29.9 | Overweight |
| ≥ 30 | Obese |

### Database Schema

```sql
CREATE TABLE measurements (
  id               SERIAL PRIMARY KEY,
  weight_kg        NUMERIC(5,2) NOT NULL,
  height_cm        NUMERIC(5,2) NOT NULL,
  age              INTEGER NOT NULL,
  sex              VARCHAR(10) NOT NULL,          -- 'male' | 'female'
  activity_level   VARCHAR(30),
  bmi              NUMERIC(4,1) NOT NULL,
  bmi_category     VARCHAR(30),
  bmr              INTEGER,
  daily_calories   INTEGER,
  measurement_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at       TIMESTAMPTZ DEFAULT now()
);
```

---

## 6. CI/CD Pipeline Overview

Deployment is automated via **GitHub Actions** with a **self-hosted runner** running on the frontend EC2 instance.

### Pipeline Flow

```
Developer pushes to main
        │
        ▼
GitHub Actions Workflow triggered
        │
        ├── [Test Job]
        │     ├── Install dependencies
        │     ├── Run backend tests
        │     └── Build frontend (smoke check)
        │
        ├── [Terraform Job] (on infra changes)
        │     ├── terraform init
        │     ├── terraform validate
        │     ├── terraform plan
        │     └── terraform apply (on main branch)
        │
        └── [Deploy Job] (on app changes)
              ├── Pull latest code on EC2 (via self-hosted runner)
              ├── npm install --production (backend)
              ├── npm run build (frontend)
              ├── Deploy dist/ to Nginx web root
              └── pm2 restart bmi-backend
```

### Workflow Triggers

| Trigger | Action |
|---|---|
| Push to `main` | Full deploy pipeline |
| Pull Request | Test + Plan only (no apply) |
| Manual dispatch | Full pipeline with environment selection |

---

## 7. GitHub Actions Workflow

Place workflow files in `.github/workflows/` at the repository root.

### Required GitHub Secrets

Configure in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key (or use OIDC) |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `AWS_REGION` | `ap-south-1` |
| `TF_BACKEND_BUCKET` | `batch-12-tf-states` |
| `DB_PASSWORD` | PostgreSQL password |

### Sample Deploy Workflow

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: self-hosted          # self-hosted runner on frontend EC2
    steps:
      - uses: actions/checkout@v4

      - name: Install backend deps
        run: cd backend && npm install --production

      - name: Build frontend
        run: cd frontend && npm install && npm run build

      - name: Deploy frontend to Nginx
        run: |
          sudo cp -r frontend/dist/* /var/www/bmi-health-tracker/
          sudo chown -R www-data:www-data /var/www/bmi-health-tracker/

      - name: Restart backend
        run: pm2 restart bmi-backend
```

### Sample Terraform Workflow

```yaml
name: Terraform

on:
  push:
    paths: ['terraform_private_alb_acm/**', 'terraform_front_end_public/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: terraform_private_alb_acm
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.14.3"

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - run: terraform init -backend-config="bucket=${{ secrets.TF_BACKEND_BUCKET }}"
      - run: terraform validate
      - run: terraform plan -var-file="terraform.tfvars"
      - if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve -var-file="terraform.tfvars"
```

---

## 8. Self-Hosted Runner Setup

The GitHub Actions self-hosted runner runs on the **frontend EC2** instance (which already has Node.js 22, npm, PM2, and Nginx installed by Terraform).

### Installation (via SSM Session)

```bash
# 1. Connect to frontend EC2
aws ssm start-session \
  --target <frontend-instance-id> \
  --region ap-south-1 \
  --profile sarowar-ostad

# 2. Create runner directory
mkdir -p /home/ubuntu/actions-runner && cd /home/ubuntu/actions-runner

# 3. Download runner (get exact URL from GitHub → Settings → Actions → Runners → New)
curl -o actions-runner-linux-x64.tar.gz -L \
  https://github.com/actions/runner/releases/latest/download/actions-runner-linux-x64.tar.gz
tar xzf actions-runner-linux-x64.tar.gz

# 4. Configure (token from GitHub → Settings → Actions → Runners → New self-hosted)
./config.sh \
  --url https://github.com/<your-org>/<your-repo> \
  --token <RUNNER_TOKEN> \
  --name bmi-frontend-runner \
  --labels self-hosted,linux,x64

# 5. Install and start as a systemd service
sudo ./svc.sh install ubuntu
sudo ./svc.sh start
sudo ./svc.sh status
```

### Runner Requirements

| Requirement | Status |
|---|---|
| Ubuntu 26.04 LTS | Provisioned by Terraform |
| Node.js 22 LTS | Installed by user-data script |
| npm | Installed with Node.js |
| PM2 | Installed by user-data script |
| Nginx | Installed by user-data script |
| AWS CLI v2 | Available via apt (Module 1 only) |
| IAM role | Attached via EC2 instance profile |

---

## 9. Deployment Modules

### Module 1 — `terraform_private_alb_acm`

**When to use:** Production workloads needing ALB, horizontal scaling, or WAF.

| Resource | Details |
|---|---|
| VPC | Pre-existing (provided via `vpc_id`) |
| EC2 Frontend | Private subnet, t3.medium, Nginx, IAM role |
| EC2 Backend | Private subnet, t3.medium, Node.js 22, PM2 |
| EC2 Database | Private subnet, t3.medium, PostgreSQL 18, 30GB gp3 |
| ALB | Public subnets, HTTP→HTTPS redirect, TLS 1.3 |
| ACM Certificate | Certbot DNS-01 → imported to ACM (skipped if ≥10 days remain) |
| Route53 | A-Alias → ALB |
| State Key | `bmi-health-tracker/terraform.tfstate` |
| Total Resources | 15 |

**Live URL:** `https://bmi.ostaddevops.click`

### Module 2 — `terraform_front_end_public`

**When to use:** Development, demos, or cost-sensitive workloads.

| Resource | Details |
|---|---|
| VPC | Created from scratch (10.0.0.0/16) |
| Public Subnets | 3 × /24 across 3 AZs (10.0.1–3.0/24) |
| Private Subnets | 3 × /24 across 3 AZs (10.0.10–30.0/24) |
| NAT Gateway | In first public subnet |
| EC2 Frontend | Public subnet, t3.small, Elastic IP, Nginx, Certbot |
| EC2 Backend | Private subnet, t3.small, Node.js 22, PM2 |
| EC2 Database | Private subnet, t3.medium, PostgreSQL 18, 30GB gp3 |
| Route53 | A → Frontend EIP, TTL=60 |
| State Key | `fpub-trfm/terraform.tfstate` |
| Total Resources | 40 |

**Live URL:** `https://bmi-terraform.ostaddevops.click`

---

## 10. Environment Variables

### Backend `.env`

```env
# Database
DATABASE_URL=postgresql://bmi_user:<password>@<db-private-ip>:5432/bmi_health_tracker
DB_HOST=<db-private-ip>
DB_PORT=5432
DB_NAME=bmi_health_tracker
DB_USER=bmi_user
DB_PASSWORD=<strong-password>

# Server
PORT=3000
NODE_ENV=production

# CORS
FRONTEND_URL=https://<your-domain>
CORS_ORIGIN=*
```

> `.env` is written automatically by `backend-init.sh` / `backend_setup.sh` at EC2 boot time. Never commit it.

### Terraform `terraform.tfvars`

| Variable | Module 1 Example | Module 2 Example | Required |
|---|---|---|---|
| `aws_region` | `"ap-south-1"` | `"ap-south-1"` | Yes |
| `aws_profile` | `"sarowar-ostad"` | `"sarowar-ostad"` | Yes |
| `domain_name` | `"bmi.ostaddevops.click"` | `"bmi-terraform.ostaddevops.click"` | Yes |
| `hosted_zone_id` | `"Z1019653XLWIJ02C53P5"` | — | Module 1 |
| `hosted_zone_name` | — | `"ostaddevops.click"` | Module 2 |
| `key_name` | `"sarowar-ostad-mumbai"` | `"sarowar-ostad-mumbai"` | Yes |
| `db_password` | `"<strong-password>"` | `"<strong-password>"` | Yes |
| `git_repo_url` | GitHub HTTPS URL | GitHub HTTPS URL | Yes |
| `ami_id` | `""` (auto Ubuntu 26.04) | `""` (auto Ubuntu 26.04) | No |
| `vpc_id` | `"vpc-0ace4e15b703a5d19"` | — | Module 1 |
| `vpc_cidr` | — | `"10.0.0.0/16"` | Module 2 |
| `ssh_allowed_cidrs` | — | `["<your-ip>/32"]` | Module 2 |

---

## 11. Prerequisites

### Local Machine

| Tool | Minimum Version | Install |
|---|---|---|
| Terraform | 1.14+ | [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | v2 | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| Node.js | 22 LTS | [nodejs.org](https://nodejs.org) |
| Git | any | [git-scm.com](https://git-scm.com) |
| PowerShell | 7+ (Windows) | Included in Windows 11 / [github.com/PowerShell](https://github.com/PowerShell/PowerShell) |

### AWS Account Requirements

- IAM permissions: EC2, VPC, ELB, Route53, ACM, SSM, S3, IAM
- Route53 hosted zone for your domain
- EC2 key pair in `ap-south-1` region
- S3 bucket `batch-12-tf-states` (or your own) for Terraform state
- **Module 1 only:** Pre-existing VPC with public/private subnets and security groups

### AWS CLI Setup

```bash
aws configure --profile sarowar-ostad
# AWS Access Key ID:     <key>
# AWS Secret Access Key: <secret>
# Default region:        ap-south-1
# Default output format: json

# Verify
aws sts get-caller-identity --profile sarowar-ostad
```

---

## 12. Local Development Setup

```bash
# Clone
git clone https://github.com/sarowar-alam/terraform-3-tier-different-servers.git
cd terraform-3-tier-different-servers

# ── Backend ──────────────────────────────────────────────
cd backend
cp .env.example .env      # Edit DB credentials for local PostgreSQL
npm install
npm run dev               # http://localhost:3000

# ── Frontend (new terminal) ───────────────────────────────
cd frontend
npm install
npm run dev               # http://localhost:5173
                          # /api requests proxied to :3000 via vite.config.js
```

### Local PostgreSQL via Docker

```bash
docker run -d \
  --name bmi-postgres \
  -e POSTGRES_DB=bmi_health_tracker \
  -e POSTGRES_USER=bmi_user \
  -e POSTGRES_PASSWORD=localdev \
  -p 5432:5432 \
  postgres:18

# Apply migrations
psql -h localhost -U bmi_user -d bmi_health_tracker \
  -f backend/migrations/001_create_measurements.sql
psql -h localhost -U bmi_user -d bmi_health_tracker \
  -f backend/migrations/002_add_measurement_date.sql
```

---

## 13. Build and Run Instructions

### Backend

```bash
cd backend

# Development
npm run dev                           # nodemon auto-reload on :3000

# Production
npm install --production
node src/server.js

# Production with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup                           # Register auto-start with systemd
```

### Frontend

```bash
cd frontend
npm install
npm run build                         # Output: frontend/dist/

# Preview production build
npm run preview                       # http://localhost:5173
```

### Deploy to Nginx (production EC2)

```bash
sudo cp -r frontend/dist/* /var/www/bmi-health-tracker/
sudo chown -R www-data:www-data /var/www/bmi-health-tracker/
sudo nginx -t && sudo systemctl reload nginx
```

---

## 14. Testing Instructions

### Backend API — Manual Tests

```bash
BASE=http://localhost:3000

# Health check
curl $BASE/health

# Create measurement
curl -X POST $BASE/api/measurements \
  -H "Content-Type: application/json" \
  -d '{"weightKg":75,"heightCm":175,"age":30,"sex":"male","activity":"moderate"}'

# List all
curl $BASE/api/measurements

# 30-day trends
curl $BASE/api/measurements/trends
```

### Production Smoke Test

```bash
# Module 1
curl -Is https://bmi.ostaddevops.click/health | head -5

# Module 2
curl -Is https://bmi-terraform.ostaddevops.click/health | head -5
```

### Database Verification (via SSM)

```bash
aws ssm start-session \
  --target <database-instance-id> \
  --region ap-south-1 \
  --profile sarowar-ostad

# Inside instance:
sudo -u postgres psql -d bmi_health_tracker -c "\dt"
sudo -u postgres psql -d bmi_health_tracker \
  -c "SELECT COUNT(*) FROM measurements;"
sudo -u postgres psql -d bmi_health_tracker \
  -c "SHOW listen_addresses;"         -- Should be '*'
```

---

## 15. Production Deployment

### Module 1 — `terraform_private_alb_acm`

```powershell
Set-Location terraform_private_alb_acm

# One-time: create backend-config.tfbackend
# (already exists — do not overwrite)

# Initialise
terraform init -backend-config="backend-config.tfbackend"

# Review
terraform plan -var-file="terraform.tfvars"

# Deploy (~15–20 min, 15 resources)
terraform apply -var-file="terraform.tfvars"

# Tear down
terraform destroy -var-file="terraform.tfvars"
```

### Module 2 — `terraform_front_end_public`

```powershell
Set-Location terraform_front_end_public

terraform init    -backend-config="backend-config.tfbackend"
terraform plan    -var-file="terraform.tfvars"
terraform apply   -var-file="terraform.tfvars"   # ~20–30 min, 40 resources
terraform destroy -var-file="terraform.tfvars"
```

### Deployment Timeline

| Stage | Module 1 | Module 2 |
|---|---|---|
| VPC / Networking | Pre-existing | ~3 min |
| IAM + Security Groups | ~1 min | ~1 min |
| Database EC2 + PostgreSQL 18 | ~4 min | ~4 min |
| Backend EC2 + Node.js 22 + PM2 | ~4 min | ~4 min |
| Frontend EC2 + Nginx + Certbot | ~5 min | ~5 min |
| DNS propagation + cert issuance | ~5–15 min | ~5–30 min |
| **Total** | **~15–20 min** | **~20–30 min** |

### Accessing Instances (No Bastion, No SSH Required)

```bash
aws ssm start-session \
  --target <instance-id> \
  --region ap-south-1 \
  --profile sarowar-ostad

# Monitor boot progress
sudo tail -f /var/log/user-data.log
```

---

## 16. Monitoring and Logging

### Log Locations

| Instance | File | Content |
|---|---|---|
| All | `/var/log/user-data.log` | EC2 boot initialisation output |
| Frontend | `/var/log/nginx/bmi-access.log` | HTTP request log |
| Frontend | `/var/log/nginx/bmi-error.log` | Nginx errors |
| Backend | `backend/logs/out.log` | PM2 stdout |
| Backend | `backend/logs/err.log` | PM2 stderr |
| Backend | `backend/logs/combined.log` | PM2 combined with timestamps |

### PM2 Monitoring

```bash
pm2 status                   # All process status
pm2 logs bmi-backend         # Live log tail
pm2 monit                    # CPU + RAM real-time dashboard
pm2 describe bmi-backend     # Full process metadata
```

### Certificate Expiry

```bash
# Module 1 — ACM
aws acm describe-certificate \
  --certificate-arn <arn> \
  --region ap-south-1 \
  --query "Certificate.NotAfter" \
  --output text

# Module 2 — Local
openssl x509 \
  -in /etc/letsencrypt/live/<domain>/fullchain.pem \
  -noout -enddate
```

Auto-renewal cron (both modules):

```
# /etc/cron.d/certbot-renew
0 0,12 * * *  root  certbot renew --quiet
```

Both modules skip certbot at boot if an existing certificate has **≥ 10 days** remaining, preventing Let's Encrypt rate-limit errors on frequent redeployments.

---

## 17. Security Best Practices Applied

| Practice | Implementation |
|---|---|
| Private subnets for app/DB | No public IPs on backend or database (both modules) |
| Tiered security groups | ALB → Frontend SG → Backend SG → Database SG; no internet bypass |
| Encrypted EBS | All volumes encrypted at rest (`encrypted = true`, gp3) |
| Encrypted S3 state | `encrypt = true` in backend config |
| Least-privilege IAM | Frontend: Route53+ACM+SSM; DB+Backend: SSM only |
| `sensitive = true` | `db_password` variable never shown in plan output |
| TLS 1.3 | `ELBSecurityPolicy-TLS13-1-2-2021-06` (Module 1 ALB) |
| Let's Encrypt rate-limit guard | Skip certbot if cert ≥10 days valid (ACM check / local openssl) |
| No SSH bastion | All access via IAM-authenticated SSM Session Manager |
| Nginx security headers | `X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options: nosniff`, `X-XSS-Protection` |
| IMDSv2 | Frontend uses token-based IMDS calls (`X-aws-ec2-metadata-token`) |
| IP-restricted SSH | `ssh_allowed_cidrs` limited to operator IP `/32` (Module 2) |
| Git-ignored secrets | `.tfvars`, `.env`, `backend-config.tfbackend` excluded from version control |

---

## 18. Troubleshooting

### S3 Backend Bucket Not Found

```
Error: Failed to get existing workspaces: S3 bucket does not exist
```

**Fix:** Verify `backend-config.tfbackend` has `bucket = "batch-12-tf-states"` (not `batch-10-tf-states`).

---

### Duplicate Provider / Module Error on `terraform init`

```
Error: Duplicate provider configuration
```

**Fix:** A stray `.tf` file is present. Find and rename it:

```powershell
Get-ChildItem -Filter "*.tf" | Select-Object Name, LastWriteTime
Rename-Item <stray-file>.tf <stray-file>.tf.bak
```

---

### EC2 Boot Failure — Check Logs

```bash
aws ssm start-session --target <instance-id> --region ap-south-1
sudo tail -100 /var/log/user-data.log
```

---

### Backend Cannot Reach Database

```bash
# On backend EC2:
nc -z <db-private-ip> 5432 && echo "reachable" || echo "blocked"
sudo cat /var/log/user-data.log | grep -E "database|reachable|attempt"
```

The backend polls for 5 minutes (30 × 10s). Verify database security group allows port 5432 from the backend security group.

---

### Certificate Not Issued — DNS Not Propagated

Module 2 polls DNS up to 30 minutes before running certbot. Check:

```bash
# On frontend EC2:
dig +short bmi-terraform.ostaddevops.click A
curl http://bmi-terraform.ostaddevops.click/health
sudo cat /var/log/user-data.log | grep -E "DNS|certbot|RESOLVED|EIP"
```

---

### Let's Encrypt Rate Limit

```
too many certificates already issued for this exact set of domains
```

**Cause:** More than 5 cert requests for the same domain in 7 days.
**Prevention:** The ≥10 day cert check already guards against this.
**Fix:** Wait 7 days, or test with [Let's Encrypt staging environment](https://letsencrypt.org/docs/staging-environment/).

---

### PM2 Not Running After Reboot

```bash
pm2 list
sudo systemctl status pm2-ubuntu
# If not running:
pm2 start ecosystem.config.js
pm2 save
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu
```

---

### PostgreSQL Version Mismatch

```bash
ls /etc/postgresql/              # Should show 18 on Ubuntu 26.04
sudo -u postgres psql -c "SELECT version();"
sudo -u postgres psql -c "SHOW listen_addresses;"   # Must be '*'
```

If `listen_addresses` is `localhost`, the auto-detect in `database-init.sh` failed:

```bash
sudo bash /usr/local/bin/init-database.sh   # Re-run safely (idempotent)
```

---

## 19. Future Improvements

| Priority | Improvement | Details |
|---|---|---|
| High | Add `.github/workflows/` | Implement deploy, terraform, and test pipelines |
| High | ACM-native certificate | Replace Certbot+import with ACM DNS validation (simpler, auto-renews) |
| High | Amazon RDS | Managed PostgreSQL with automated backups, Multi-AZ, point-in-time recovery |
| Medium | Auto Scaling Group | Replace single frontend EC2 with ASG behind ALB (Module 1) |
| Medium | CloudWatch dashboards | CPU, memory, error rate, request latency metrics and alarms |
| Medium | AWS Secrets Manager | Remove plaintext passwords from `.env` and `tfvars` |
| Medium | WAF on ALB | Rate limiting, SQL injection protection, geo-blocking |
| Medium | User authentication | JWT or AWS Cognito for per-user measurement history |
| Medium | HTTPS for API proxy | Internal ALB for backend (currently HTTP between Nginx and backend) |
| Low | Terraform Cloud | Team state management with policy enforcement |
| Low | Docker + ECS | Containerised workloads for portability |
| Low | Multi-region DR | Cross-region replication and Route53 health checks |

---

## 20. Contributor Guidelines

### Branch Strategy

```
main              ← Protected, production-ready
  ├─ feature/<name>    New features
  ├─ fix/<name>        Bug fixes
  └─ infra/<name>      Infrastructure changes
```

### Commit Convention

```
feat:   add BMI trend CSV export
fix:    correct pg_isready polling in database-init.sh
infra:  upgrade Node.js 20 → 22 LTS across all scripts
docs:   update README troubleshooting section
```

### Pull Request Checklist

- [ ] `terraform validate` passes for any modified Terraform module
- [ ] `terraform plan` reviewed — no unintended destroys
- [ ] No secrets, passwords, or credentials in any committed file
- [ ] `.tfvars`, `.env`, and `backend-config.tfbackend` are git-ignored
- [ ] Backend starts cleanly: `node src/server.js`
- [ ] Frontend builds cleanly: `npm run build`

### Files That Must Never Be Committed

```gitignore
backend/.env
terraform_private_alb_acm/terraform.tfvars
terraform_private_alb_acm/backend-config.tfbackend
terraform_front_end_public/terraform.tfvars
terraform_front_end_public/backend-config.tfbackend
**/.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl   # optional: can be committed for reproducibility
```

---

## 21. License

This project is open for educational and demonstration use.

---

*Built with Terraform · Node.js · React · PostgreSQL · Nginx · PM2 · AWS EC2 · ALB · Route53 · ACM · Let's Encrypt · Ubuntu 26.04 LTS*

---

## Project Lead

**MD Sarowar Alam**  
Lead DevOps Engineer, WPP Production  
📧 Email: [sarowar@hotmail.com](mailto:sarowar@hotmail.com)  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

