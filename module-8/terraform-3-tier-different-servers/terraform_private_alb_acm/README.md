# terraform_private_alb_acm

**BMI Health Tracker — ALB + Private EC2s + ACM Certificate**

> All three EC2 instances (frontend, backend, database) are in **private subnets**.  
> The Application Load Balancer is the sole internet entry point, terminating TLS via an ACM certificate issued by Certbot DNS-01.

[![Terraform](https://img.shields.io/badge/Terraform-≥1.14-623CE4?logo=terraform)](https://developer.hashicorp.com/terraform)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-26.04_LTS-E95420?logo=ubuntu)](https://releases.ubuntu.com/resolute/)
[![AWS](https://img.shields.io/badge/AWS-ap--south--1-FF9900?logo=amazonaws)](https://aws.amazon.com)

---

## Architecture

```
                        ┌──────────────────────────┐
                        │   Internet / Users       │
                        └────────────┤────────── ──┘
                                     │  HTTPS :443 / HTTP :80
                        ┌────────────▼────────────┐
                        │   Route53 DNS (A Alias) │
                        │   bmi.ostaddevops.click │
                        └────────────┤────────────┘
                                     │
                   ┌─────────────────▼────────────────┐
                   │    Application Load Balancer     │
                   │  HTTP :80  ──► redirect HTTPS    │
                   │  HTTPS :443  TLS 1.3 (ACM cert)  │
                   │  Public Subnets — 2 AZs          │
                   └─────────────────┬────────────────┘
                                     │ HTTP :80 (Target Group)
              ┌──────────────────────▼──────────────────────┐
              │           AWS VPC — Private Subnets         │
              │                                             │
              │  ┌──────────────────┐                       │
              │  │  TIER 1: Frontend │                      │
              │  │  EC2 t3.medium    │                      │
              │  │  Ubuntu 26.04 LTS │                      │
              │  │  Nginx :80        │                      │
              │  │  React 18 SPA     │                      │
              │  └────────┬─────────┘                       │
              │           │ proxy /api/* → :3000            │
              │  ┌────────▼─────────┐                       │
              │  │  TIER 2: Backend  │                      │
              │  │  EC2 t3.medium    │                      │
              │  │  Ubuntu 26.04 LTS │                      │
              │  │  Node.js 22 LTS   │                      │
              │  │  Express :3000    │                      │
              │  │  PM2 process mgr  │                      │
              │  └────────┬─────────┘                       │
              │           │ pg pool → :5432                 │
              │  ┌────────▼─────────┐                       │
              │  │  TIER 3: Database │                      │
              │  │  EC2 t3.medium    │                      │
              │  │  Ubuntu 26.04 LTS │                      │
              │  │  PostgreSQL 18    │                      │
              │  │  Port 5432        │                      │
              │  │  Encrypted gp3    │                      │
              │  └──────────────────┘                       │
              │                                             │
              └─────────────────────────────────────────────┘

   IAM Role (Frontend EC2 only)
   ├── Route53: ChangeResourceRecordSets (DNS-01 challenge)
   ├── ACM: ImportCertificate (import Let's Encrypt cert)
   └── SSM: AmazonSSMManagedInstanceCore (Session Manager)
```

**Smart renewal:** On re-deployment, the script checks ACM first. If the existing certificate has **≥ 10 days** remaining it skips certbot entirely — preventing Let's Encrypt rate-limit errors.

---

## Prerequisites

- Pre-existing VPC with:
  - 2+ public subnets (for ALB)
  - 2+ private subnets (for EC2s)
  - Security groups for ALB, frontend, backend, database
  - NAT Gateway (for private EC2 outbound internet)
- Route53 hosted zone for your domain
- EC2 key pair in `ap-south-1`
- S3 bucket for Terraform state (`batch-12-tf-states`)
- AWS CLI configured: `aws configure --profile sarowar-ostad`

---

## Quick Start

```powershell
# 1. Copy and fill in variables
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your VPC IDs, SG IDs, domain, etc.

# 2. backend-config.tfbackend already exists with:
#   bucket  = "batch-12-tf-states"
#   key     = "bmi-health-tracker/terraform.tfstate"
#   region  = "ap-south-1"
#   profile = "sarowar-ostad"

# 3. Initialise
terraform init -backend-config="backend-config.tfbackend"

# 4. Plan
terraform plan -var-file="terraform.tfvars"

# 5. Deploy (~15–20 minutes, 15 resources)
terraform apply -var-file="terraform.tfvars"
```

---

## terraform.tfvars Reference

| Variable | Example Value | Description |
|---|---|---|
| `aws_region` | `"ap-south-1"` | AWS region |
| `aws_profile` | `"sarowar-ostad"` | AWS CLI named profile |
| `vpc_id` | `"vpc-0ace4e15b703a5d19"` | Pre-existing VPC ID |
| `public_subnet_ids` | `["subnet-xxx", "subnet-yyy"]` | ALB public subnets (min 2 AZs) |
| `private_subnet_ids` | `["subnet-aaa", "subnet-bbb"]` | EC2 private subnets |
| `alb_security_group_id` | `"sg-xxx"` | ALB SG — allows :80/:443 from internet |
| `frontend_security_group_id` | `"sg-yyy"` | Frontend SG — allows :80 from ALB SG only |
| `backend_security_group_id` | `"sg-zzz"` | Backend SG — allows :3000 from frontend SG only |
| `database_security_group_id` | `"sg-www"` | Database SG — allows :5432 from backend SG only |
| `hosted_zone_id` | `"Z1019653XLWIJ02C53P5"` | Route53 hosted zone ID |
| `domain_name` | `"bmi.ostaddevops.click"` | FQDN for the application |
| `key_name` | `"sarowar-ostad-mumbai"` | EC2 key pair name |
| `db_password` | `"<strong-password>"` | PostgreSQL password (sensitive) |
| `git_repo_url` | GitHub HTTPS URL | Repository to clone on EC2 boot |
| `git_branch` | `"main"` | Branch to deploy |
| `ami_id` | `""` | Leave empty — auto-resolves Ubuntu 26.04 via SSM |
| `instance_type_frontend` | `"t3.medium"` | Frontend instance size |
| `instance_type_backend` | `"t3.medium"` | Backend instance size |
| `instance_type_database` | `"t3.medium"` | Database instance size |
| `backend_port` | `3000` | Node.js API port |
| `db_port` | `5432` | PostgreSQL port |

---

## Resources Created (15 total)

| Module | Resources |
|---|---|
| `module.iam` | IAM role, 2 inline policies (Route53 + ACM), SSM attachment, instance profile |
| `module.ec2` | 3 × EC2 instances, `null_resource` (ACM cert wait) |
| `module.alb` | ALB, target group, HTTP listener (redirect), HTTPS listener |
| `module.dns` | Route53 A-Alias record → ALB |
| Root | Target group attachment (frontend → ALB TG) |

---

## Module Structure

```
terraform_private_alb_acm/
├── main.tf                     # Provider, data sources (SSM AMI, VPC, Route53), module calls
├── variables.tf                # All input variable declarations
├── outputs.tf                  # URLs, IPs, IDs, cert info, SSH commands
├── backend.tf                  # S3 remote state (empty backend block)
├── terraform.tfvars            # ← Your config (git-ignored)
├── terraform.tfvars.example    # Template
├── backend-config.tfbackend    # ← S3 credentials (git-ignored)
└── modules/
    ├── alb/
    │   ├── main.tf             # ALB, target group, HTTP+HTTPS listeners
    │   ├── variables.tf
    │   └── outputs.tf
    ├── dns/
    │   ├── main.tf             # Route53 A-Alias → ALB (dualstack)
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ec2/
    │   ├── main.tf             # 3 EC2 instances (dependency: db→be→fe)
    │   ├── certificate-wait.tf # PowerShell polls ACM every 30s, max 20 attempts
    │   ├── variables.tf
    │   ├── outputs.tf          # Instance IDs, private IPs, certificate ARN
    │   └── templates/
    │       ├── database-init.sh   # PostgreSQL 18 auto-detect, pg_isready poll, migrations
    │       ├── backend-init.sh    # Node.js 22, PM2, DB wait loop (30×10s)
    │       └── frontend-init.sh   # Nginx, React build, Certbot DNS-01, ACM import (≥10d check)
    └── iam/
        ├── main.tf             # Frontend role: Route53 write + ACM import + SSM
        ├── variables.tf
        └── outputs.tf
```

---

## Deployment Timeline

| Step | Duration |
|---|---|
| IAM role creation | ~30s |
| Database EC2 + PostgreSQL 18 | ~4 min |
| Backend EC2 + Node.js 22 + PM2 | ~4 min |
| Frontend EC2 + Nginx + React build | ~5 min |
| Certbot DNS-01 + ACM import | ~3–10 min |
| Terraform ACM poll (20×30s max) | ~3–10 min |
| ALB + DNS + TG attachment | ~1 min |
| **Total** | **~15–20 min** |

---

## Accessing Instances

All instances are in private subnets — no SSH bastion needed.

```bash
# Connect via SSM
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
```

---

## Security Controls

| Control | Detail |
|---|---|
| No public IPs on EC2s | All instances in private subnets — internet via NAT only |
| SG chaining | ALB SG → Frontend SG → Backend SG → Database SG |
| TLS 1.3 | `ELBSecurityPolicy-TLS13-1-2-2021-06` on ALB HTTPS listener |
| Certbot DNS-01 | Port 80 never required for cert issuance |
| Cert rate-limit guard | Skips certbot if ACM cert has ≥10 days remaining |
| SSM only | Port 22 not required on any EC2 |
| Encrypted EBS | All volumes: `encrypted = true`, gp3 |
| Least-privilege IAM | Frontend gets Route53+ACM+SSM; DB+Backend get SSM only |

---

## Outputs

```
application_url        = "https://bmi.ostaddevops.click"
alb_dns_name           = "<alb>.ap-south-1.elb.amazonaws.com"
certificate_arn        = "arn:aws:acm:ap-south-1:..."
frontend_instance_id   = "i-xxx"
backend_instance_id    = "i-yyy"
database_instance_id   = "i-zzz"
frontend_private_ip    = "10.x.x.x"
backend_private_ip     = "10.x.x.x"
database_private_ip    = "10.x.x.x"
```

---

## Tear Down

```powershell
terraform destroy -var-file="terraform.tfvars"
```

> Destroys all 15 resources including EC2 instances, ALB, IAM role, Route53 record, and ACM certificate.  
> The S3 state bucket and VPC are **not** touched (pre-existing resources).

---

## Project Lead

**MD Sarowar Alam**  
Lead DevOps Engineer, WPP Production  
📧 Email: [sarowar@hotmail.com](mailto:sarowar@hotmail.com)  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

