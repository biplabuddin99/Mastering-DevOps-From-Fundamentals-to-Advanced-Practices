# terraform_front_end_public

**BMI Health Tracker — Public Frontend EIP + New VPC + Local Certbot**

> Creates **all networking from scratch** (VPC, subnets, NAT Gateway).  
> The frontend EC2 has a **static Elastic IP** and sits in a public subnet. No ALB. TLS is handled directly by Certbot HTTP-01 on Nginx.

[![Terraform](https://img.shields.io/badge/Terraform-≥1.14-623CE4?logo=terraform)](https://developer.hashicorp.com/terraform)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-26.04_LTS-E95420?logo=ubuntu)](https://releases.ubuntu.com/resolute/)
[![AWS](https://img.shields.io/badge/AWS-ap--south--1-FF9900?logo=amazonaws)](https://aws.amazon.com)

---

## Architecture

```
                   ┌────────────────────────────┐
                   │   Internet / Users         │
                   └─────────────┬──────────────┘
                                 │ HTTPS :443 / HTTP :80
                   ┌─────────────▼──────────────┐
                   │   Route53 DNS (A Record)   │
                   │   bmi-terraform            │
                   │   .ostaddevops.click       │
                   └─────────────┬──────────────┘
                                 │
┌────────────────────────────────────────────────────────┐
│                   VPC (10.0.0.0/16)                    │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Public Subnet (10.0.1.0/24)                      │ │
│  │  ┌─────────────────────────────────────────────┐  │ │
│  │  │  TIER 1: Frontend EC2 (t3.small)            │  │ │
│  │  │  Ubuntu 26.04 LTS                           │  │ │
│  │  │  • React 18 + Vite SPA (built to /var/www/) │  │ │
│  │  │  • Nginx Reverse Proxy + HTTPS redirect     │  │ │
│  │  │  • Let's Encrypt TLS (Certbot HTTP-01)      │  │ │
│  │  │  • Elastic IP (Static Public Address)       │  │ │
│  │  └─────────────────────┬───────────────────────┘  │ │
│  └───────────────────────┬─────────────────────── ───┘ │
│                        │ proxy /api/* → :3000          │
│  ┌───────────────────────▼──────────────────────────┐  │
│  │  Private Subnet (10.0.10.0/24)                   │  │
│  │  ┌────────────────────┐  ┌─────────────────────┐ │  │
│  │  │  TIER 2: Backend     │  │  TIER 3: Database │ │  │
│  │  │  t3.small            │  │  t3.medium        │ │  │
│  │  │  Ubuntu 26.04 LTS   │  │  Ubuntu 26.04 LTS  │ │  │
│  │  │  Node.js 22 LTS     │◄─┤  PostgreSQL 18     │ │  │
│  │  │  Express :3000      │  │  Port :5432        │ │  │
│  │  │  PM2 process mgr    │  │  Encrypted gp3     │ │  │
│  │  └────────────────────┘  └─────────────────────┘ │  │
│  │                │                                 │  │
│  └────────────────▼────────────────────────────── ──┘  │
│              NAT Gateway → Internet Gateway            │
└────────────────────────────────────────────────────────┘

   IAM Roles (all three tiers)
   ├── Database  : SSM only (AmazonSSMManagedInstanceCore)
   ├── Backend   : SSM only (AmazonSSMManagedInstanceCore)
   └── Frontend  : SSM + Route53 ListHostedZones/GetChange (read-only)
```

**Smart renewal:** On re-deployment, the script checks the local cert via `openssl`. If it has **≥ 10 days** remaining it skips certbot — preventing Let's Encrypt rate-limit errors.

---

## Prerequisites

- Route53 hosted zone for your domain (`ostaddevops.click`)
- EC2 key pair in `ap-south-1`
- S3 bucket for Terraform state (`batch-12-tf-states`)
- AWS CLI configured: `aws configure --profile sarowar-ostad`
- Your public IP (for SSH access restriction)

> No pre-existing VPC or security groups needed — everything is created.

---

## Quick Start

```powershell
# 1. Edit terraform.tfvars — fill in your domain, key_name, ssh_allowed_cidrs, db_password

# 2. backend-config.tfbackend already exists with:
#   bucket  = "batch-12-tf-states"
#   key     = "fpub-trfm/terraform.tfstate"
#   region  = "ap-south-1"
#   profile = "sarowar-ostad"

# 3. Initialise
terraform init -backend-config="backend-config.tfbackend"

# 4. Plan
terraform plan -var-file="terraform.tfvars"

# 5. Deploy (~20–30 minutes, 40 resources)
terraform apply -var-file="terraform.tfvars"
```

---

## terraform.tfvars Reference

| Variable | Example Value | Description |
|---|---|---|
| `aws_region` | `"ap-south-1"` | AWS region |
| `aws_profile` | `"sarowar-ostad"` | AWS CLI named profile |
| `project_name` | `"bmi-terraform"` | Resource naming prefix |
| `environment` | `"production"` | Environment tag |
| `vpc_cidr` | `"10.0.0.0/16"` | CIDR for the new VPC |
| `public_subnet_cidrs` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | Public subnet CIDRs |
| `private_subnet_cidrs` | `["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]` | Private subnet CIDRs |
| `availability_zones` | `["ap-south-1a", "ap-south-1b", "ap-south-1c"]` | AZs for subnets |
| `key_name` | `"sarowar-ostad-mumbai"` | EC2 key pair name |
| `ssh_allowed_cidrs` | `["<your-ip>/32"]` | Your IP only — SSH to frontend |
| `domain_name` | `"bmi-terraform.ostaddevops.click"` | FQDN for the application |
| `hosted_zone_name` | `"ostaddevops.click"` | Route53 hosted zone name |
| `db_password` | `"<strong-password>"` | PostgreSQL password (sensitive) |
| `git_repo_url` | GitHub HTTPS URL | Repository to clone on EC2 boot |
| `git_branch` | `"main"` | Branch to deploy |
| `ami_id` | `""` | Leave empty — auto-resolves Ubuntu 26.04 via SSM |
| `instance_type_frontend` | `"t3.small"` | Frontend instance size |
| `instance_type_backend` | `"t3.small"` | Backend instance size |
| `instance_type_database` | `"t3.medium"` | Database instance size |
| `backend_port` | `3000` | Node.js API port |
| `db_port` | `5432` | PostgreSQL port |

---

## Resources Created (40 total)

| Module | Resources |
|---|---|
| `module.vpc` | VPC, IGW, 3 public subnets, 3 private subnets, EIP (NAT), NAT GW, 2 route tables, 6 route table associations |
| `module.iam` | 3 × IAM roles (db, backend, frontend), 1 × Route53 policy, 3 × SSM attachments, 3 × instance profiles |
| `module.security_groups` | Frontend SG, backend SG, database SG |
| `module.ec2` | 3 × EC2 instances, EIP (frontend), EIP association, Route53 A record, 3 × `null_resource` SSM waits |

---

## Module Structure

```
terraform_front_end_public/
├── main.tf                     # Data sources (SSM AMI, Route53), module calls
├── variables.tf                # All input variable declarations
├── outputs.tf                  # URLs, IPs, IDs, VPC info, SSH + SSM commands
├── backend.tf                  # S3 remote state
├── provider.tf                 # Terraform + AWS provider, required versions
├── terraform.tfvars            # ← Your config (git-ignored)
├── backend-config.tfbackend    # ← S3 credentials (git-ignored)
├── modules/
│   ├── vpc/
│   │   ├── main.tf             # VPC, IGW, subnets, NAT GW, route tables
│   │   ├── variables.tf
│   │   └── outputs.tf          # VPC ID, subnet IDs, NAT GW IP
│   ├── security_groups/
│   │   ├── main.tf             # 3 tiered SGs with SG-to-SG references
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/
│   │   ├── main.tf             # DB: SSM only; Backend: SSM only; Frontend: SSM + Route53
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2/
│   │   ├── main.tf             # EIP → DB (SSM wait) → Backend (SSM wait) → Route53 → Frontend (SSM wait)
│   │   ├── variables.tf
│   │   └── outputs.tf          # Instance IDs, private IPs, frontend public IP
│   └── route53/
│       ├── main.tf             # A record → Frontend EIP, TTL=60
│       ├── variables.tf
│       └── outputs.tf
└── scripts/
    ├── database_setup.sh       # PostgreSQL 18 auto-detect, pg_isready poll, migrations
    ├── backend_setup.sh        # Node.js 22, DB wait loop (30×10s), PM2
    ├── frontend_setup.sh       # Nginx, React build, DNS poll, Certbot HTTP-01 (≥10d check)
    └── generate_certificate.sh # Manual cert re-issuance script
```

---

## Deployment Order (enforced by Terraform)

```
1. VPC + Subnets + NAT GW + IGW          (~2–3 min)
2. IAM roles (parallel with VPC)         (~30s)
3. Security Groups                       (~30s)
4. Elastic IP (frontend — created early for Route53)
5. Database EC2 → PostgreSQL 18 setup
   └─ [SSM PingStatus poll: 30×20s max]
6. Backend EC2 → Node.js 22 + PM2
   └─ [SSM PingStatus poll: 30×20s max]
7. Route53 A record created              (DNS live BEFORE frontend boots)
8. Frontend EC2 → Nginx + React build
   └─ EIP association (immediate)
   └─ DNS poll until domain resolves to EIP
   └─ certbot --nginx HTTP-01 challenge
   └─ [SSM PingStatus poll: 30×20s max]
```

**Total: ~20–30 minutes** (DNS propagation is the main variable)

---

## Accessing Instances

```bash
# Frontend — direct SSH (public IP, key required)
ssh -i ~/.ssh/sarowar-ostad-mumbai.pem ubuntu@<frontend-eip>

# Backend / Database — via SSH ProxyJump through frontend
ssh -i ~/.ssh/sarowar-ostad-mumbai.pem \
  -J ubuntu@<frontend-eip> \
  ubuntu@<backend-private-ip>

# All tiers — via SSM (no key needed)
aws ssm start-session \
  --target <instance-id> \
  --region ap-south-1 \
  --profile sarowar-ostad

# View boot log
sudo tail -f /var/log/user-data.log

# Re-run init scripts (all are idempotent)
sudo bash /usr/local/bin/init-database.sh
sudo bash /usr/local/bin/init-backend.sh
sudo bash /usr/local/bin/init-frontend.sh

# Manual cert re-issuance
sudo bash /usr/local/bin/generate-certificate.sh
```

---

## Security Controls

| Control | Detail |
|---|---|
| Backend + DB private | No public IPs — outbound via NAT Gateway only |
| SG chaining | Frontend SG → Backend SG → Database SG |
| SSH restricted | Port 22 open only to `ssh_allowed_cidrs` (your IP /32) |
| Cert rate-limit guard | Skips certbot if local cert has ≥10 days remaining |
| SSM all tiers | DB and backend accessible without SSH via SSM |
| Encrypted EBS | All volumes: `encrypted = true`, gp3 |
| Least-privilege IAM | DB+Backend: SSM only; Frontend: SSM + Route53 (read-only) |
| IMDSv2 | Token-based IMDS calls in frontend script |

---

## Outputs

```
application_url          = "https://bmi-terraform.ostaddevops.click"
frontend_public_ip       = "<elastic-ip>"
frontend_instance_id     = "i-xxx"
backend_instance_id      = "i-yyy"
database_instance_id     = "i-zzz"
backend_private_ip       = "10.0.x.x"
database_private_ip      = "10.0.x.x"
vpc_id                   = "vpc-xxx"
nat_gateway_ip           = "<nat-eip>"
```

---

## Tear Down

```powershell
terraform destroy -var-file="terraform.tfvars"
```

> Destroys all 40 resources including the **entire VPC**, all subnets, NAT Gateway, EC2 instances, EIP, and Route53 record.  
> The Let's Encrypt certificate stored in `/etc/letsencrypt/` is lost when the instance is destroyed.  
> The S3 state bucket is **not** affected.

---

## Comparison with `terraform_private_alb_acm`

| | `terraform_private_alb_acm` | `terraform_front_end_public` |
|---|---|---|
| VPC | Pre-existing (bring your own) | **Created from scratch** |
| Frontend | Private subnet, behind ALB | **Public subnet, Elastic IP** |
| Load balancer | Application Load Balancer | **None — Nginx handles directly** |
| TLS | ACM cert (ALB terminates) | **Local cert (Nginx terminates)** |
| Certbot method | DNS-01 (no port 80 needed) | **HTTP-01 (port 80 required)** |
| Monthly cost | ~$16–20 higher (ALB) | Lower |
| Scalability | ALB supports multiple instances | Single frontend instance |
| Resources | 15 | **40** |

---

## Project Lead

**MD Sarowar Alam**  
Lead DevOps Engineer, WPP Production  
📧 Email: [sarowar@hotmail.com](mailto:sarowar@hotmail.com)  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

