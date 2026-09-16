# BMI Health Tracker - Production Deployment Guide

> **Full-stack health monitoring application with automated AWS infrastructure provisioning**

A production-ready BMI (Body Mass Index) Health Tracker application deployed as a single-tier architecture on AWS EC2, with comprehensive Terraform automation for infrastructure-as-code deployment.

---

## Table of Contents

- [Quick Start](#quick-start)
- [System Overview](#system-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Local Development](#local-development)
- [Infrastructure Deployment](#infrastructure-deployment)
- [Testing](#testing)
- [Operations & Monitoring](#operations--monitoring)
- [Troubleshooting](#troubleshooting)
- [Contributing Changes](#contributing-changes)
- [Rollback Procedures](#rollback-procedures)
- [Security Considerations](#security-considerations)
- [Performance & Scaling](#performance--scaling)
- [Dependencies](#dependencies)
- [Release Workflow](#release-workflow)
- [Author](#-author)

---

## Quick Start

**For engineers who just need to deploy:**

```bash
# 1. Clone repository
git clone https://github.com/md-sarowar-alam/terraform-3-tier-basic.git
cd terraform-3-tier-basic

# 2. Configure AWS credentials
aws configure --profile sarowar-ostad

# 3. Configure Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS resource IDs

# 4. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 5. Access application
# Get URL from terraform output:
terraform output application_url
```

**Deployment time:** ~12-15 minutes (automated)

---

## System Overview

### What is this?

The BMI Health Tracker is a full-stack web application that allows users to:
- Track body measurements (weight, height, BMI)
- Visualize health trends over time
- Store historical health data
- Access insights through a modern React-based UI

### Technology Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Frontend** | React + Vite | 5.0+ | Modern, responsive UI with fast refresh |
| **Backend** | Node.js + Express | 20 LTS | RESTful API, business logic |
| **Database** | PostgreSQL | 14+ | Persistent storage, relational data |
| **Web Server** | Nginx | 1.18+ | Reverse proxy, static file serving |
| **Process Manager** | Systemd | - | Backend service management |
| **Infrastructure** | Terraform + AWS EC2 | 1.0+ | Infrastructure as code |
| **OS** | Ubuntu | 22.04 LTS | Base operating system |

### Deployment Architecture

**Single EC2 Instance (All-in-One)**
- **Design Decision:** Cost-effective development/testing deployment
- **Components:** Frontend (Nginx), Backend (Node.js), Database (PostgreSQL) on one instance
- **Scaling Path:** Migrate to RDS, ECS/EKS, CloudFront for production scale

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS Cloud                             │
│  ┌───────────────────────────────────────────────────┐  │
│  │              VPC (Existing)                        │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │        Public Subnet (Existing)              │  │  │
│  │  │                                               │  │  │
│  │  │  ┌────────────────────────────────────────┐  │  │  │
│  │  │  │   EC2 Instance (t3.medium)             │  │  │  │
│  │  │  │   Ubuntu 22.04 LTS                      │  │  │  │
│  │  │  │                                          │  │  │  │
│  │  │  │   ┌────────────┐                        │  │  │  │
│  │  │  │   │   Nginx    │  Port 80               │  │  │  │
│  │  │  │   │ (Frontend) │◄────────── Internet    │  │  │  │
│  │  │  │   └──────┬─────┘                        │  │  │  │
│  │  │  │          │ Proxy /api/*                 │  │  │  │
│  │  │  │   ┌──────▼─────┐                        │  │  │  │
│  │  │  │   │  Node.js   │  Port 3000             │  │  │  │
│  │  │  │   │  (Backend) │                        │  │  │  │
│  │  │  │   └──────┬─────┘                        │  │  │  │
│  │  │  │          │                               │  │  │  │
│  │  │  │   ┌──────▼─────┐                        │  │  │  │
│  │  │  │   │ PostgreSQL │  Port 5432             │  │  │  │
│  │  │  │   │ (Database) │                        │  │  │  │
│  │  │  │   └────────────┘                        │  │  │  │
│  │  │  │                                          │  │  │  │
│  │  │  │   Storage: 20GB EBS (encrypted)         │  │  │  │
│  │  │  └────────────────────────────────────────┘  │  │  │
│  │  │                                               │  │  │
│  │  │   Security Group (Existing):                 │  │  │
│  │  │   - Port 22 (SSH) from admin IPs            │  │  │
│  │  │   - Port 80 (HTTP) from 0.0.0.0/0           │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘

Terraform State Storage: S3 Bucket (encrypted)
```

### Request Flow

```
User Browser
    │
    │ HTTP :80
    ▼
┌─────────────────┐
│     Nginx       │  Serves static files (React app)
│  (Port 80)      │  Proxies /api/* to backend
└────────┬────────┘
         │ /api/*
         ▼
┌─────────────────┐
│   Node.js API   │  Express REST API
│  (Port 3000)    │  Business logic, validation
└────────┬────────┘
         │ SQL queries
         ▼
┌─────────────────┐
│   PostgreSQL    │  Persistent storage
│  (Port 5432)    │  Measurements table
└─────────────────┘
```

### Design Decisions

| Decision | Rationale | Trade-offs |
|----------|-----------|------------|
| **Single EC2 Instance** | Cost-effective for dev/test, simpler operations | Limits scalability, single point of failure |
| **Existing VPC/Subnet** | Leverages pre-configured network infrastructure | Requires existing AWS resources |
| **Terraform Modules** | Reusable, maintainable, follows best practices | More complex than flat structure |
| **S3 Backend (no DynamoDB)** | State persistence, team collaboration | No state locking (acceptable for single operator) |
| **Systemd over PM2** | Native OS integration, better reliability, auto-start | Less flexible than PM2 ecosystem |
| **Git-based deployment** | Single source of truth, version controlled | Requires git clone during bootstrap |
| **Cloud-init userdata** | Zero-touch provisioning, reproducible | Debugging harder than manual setup |
| **Embedded credentials** | Simplified deployment for dev/test | Not suitable for production (use Secrets Manager) |

---

## Prerequisites

### Required Accounts & Access

1. **AWS Account** with permissions for:
   - EC2 (create instances, manage security groups)
   - VPC (describe existing resources)
   - S3 (create bucket, read/write state)
   - (Optional) IAM role for EC2 instance profile

2. **GitHub Account** (for cloning repository)

3. **Existing AWS Infrastructure:**
   - VPC with Internet Gateway
   - Public subnet with internet access
   - Security Group with proper rules (see below)
   - EC2 Key Pair for SSH access

### Required Tools

Install these on your **local machine** (deployment workstation):

| Tool | Version | Installation | Purpose |
|------|---------|--------------|---------|
| **Terraform** | ≥ 1.0 | [Download](https://www.terraform.io/downloads) | Infrastructure provisioning |
| **AWS CLI** | ≥ 2.0 | [Install Guide](https://aws.amazon.com/cli/) | AWS credential management |
| **Git** | ≥ 2.30 | [Download](https://git-scm.com/) | Version control |
| **SSH Client** | - | Built-in (Linux/Mac) or PuTTY (Windows) | Instance access |

**Installation verification:**
```bash
terraform version   # Should show v1.0 or higher
aws --version       # Should show aws-cli/2.x
git --version       # Should show git version 2.x
ssh -V              # Should show OpenSSH or PuTTY
```

### AWS Configuration

#### 1. Configure AWS CLI Profile

```bash
# Configure named profile
aws configure --profile sarowar-ostad
# Enter:
#   AWS Access Key ID
#   AWS Secret Access Key  
#   Default region: ap-south-1 (or your region)
#   Default output format: json

# Verify configuration
aws sts get-caller-identity --profile sarowar-ostad
```

#### 2. Create S3 Bucket for Terraform State

```bash
# Create bucket (replace with your bucket name)
aws s3 mb s3://batch09-ostad --region ap-south-1 --profile sarowar-ostad

# Enable versioning (recommended)
aws s3api put-bucket-versioning \
  --bucket batch09-ostad \
  --versioning-configuration Status=Enabled \
  --profile sarowar-ostad

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket batch09-ostad \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' \
  --profile sarowar-ostad
```

#### 3. Prepare Networking Resources

```bash
# Get your VPC ID
aws ec2 describe-vpcs \
  --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],CidrBlock]' \
  --output table \
  --profile sarowar-ostad

# Get public subnet ID (must have internet gateway route)
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-YOUR_VPC_ID" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch,Tags[?Key==`Name`].Value|[0]]' \
  --output table \
  --profile sarowar-ostad

# Get security group ID
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=vpc-YOUR_VPC_ID" \
  --query 'SecurityGroups[*].[GroupId,GroupName,Description]' \
  --output table \
  --profile sarowar-ostad
```

#### 4. Security Group Requirements

Your security group **must** allow:

| Type | Protocol | Port | Source | Purpose |
|------|----------|------|--------|---------|
| SSH | TCP | 22 | Your IP/CIDR | Remote administration |
| HTTP | TCP | 80 | 0.0.0.0/0 | Web application access |
| HTTPS | TCP | 443 | 0.0.0.0/0 | (Optional) SSL access |
| All | All | All | Security Group ID | Intra-instance communication |

**Create security group if needed:**
```bash
aws ec2 create-security-group \
  --group-name bmi-health-tracker-sg \
  --description "Security group for BMI Health Tracker" \
  --vpc-id vpc-YOUR_VPC_ID \
  --profile sarowar-ostad

# Add rules (replace sg-xxx with your SG ID)
aws ec2 authorize-security-group-ingress \
  --group-id sg-YOUR_SG_ID \
  --ip-permissions \
    IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges='[{CidrIp=YOUR_IP/32,Description="SSH from admin"}]' \
    IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges='[{CidrIp=0.0.0.0/0,Description="HTTP public access"}]' \
  --profile sarowar-ostad
```

#### 5. Create EC2 Key Pair

```bash
# Create new key pair
aws ec2 create-key-pair \
  --key-name sarowar-ostad-mumbai \
  --query 'KeyMaterial' \
  --output text \
  --profile sarowar-ostad \
  > ~/.ssh/sarowar-ostad-mumbai.pem

# Set permissions
chmod 400 ~/.ssh/sarowar-ostad-mumbai.pem
```

---

## Project Structure

```
terraform-3-tier-basic/
│
├── IMPLEMENTATION_AUTO.sh          # Automated deployment script (946 lines)
│                                   # Handles complete app setup on EC2
│
├── backend/                        # Node.js Express API
│   ├── src/
│   │   ├── server.js              # Entry point, Express setup
│   │   ├── routes.js              # API route definitions
│   │   ├── db.js                  # PostgreSQL connection pool
│   │   ├── calculations.js        # BMI calculation logic
│   │   └── metrics.js             # Statistics calculations
│   ├── migrations/                # Database schema migrations
│   │   ├── 001_create_measurements.sql
│   │   └── 002_add_measurement_date.sql
│   ├── ecosystem.config.js        # PM2 configuration (legacy)
│   ├── package.json               # Node dependencies
│   └── .env.example               # Environment template
│
├── frontend/                      # React + Vite SPA
│   ├── src/
│   │   ├── main.jsx              # React entry point
│   │   ├── App.jsx               # Root component
│   │   ├── api.js                # Backend API client
│   │   ├── index.css             # Global styles
│   │   └── components/
│   │       ├── MeasurementForm.jsx   # Data entry form
│   │       └── TrendChart.jsx        # Chart.js visualizations
│   ├── index.html                # HTML template
│   ├── vite.config.js            # Vite build configuration
│   └── package.json              # Frontend dependencies
│
├── database/
│   └── setup-database.sh         # Manual DB setup script (legacy)
│
└── terraform/                     # Infrastructure as Code
    ├── backend.tf                # S3 backend configuration
    ├── main.tf                   # Root module, calls EC2 module
    ├── variables.tf              # Input variable definitions
    ├── outputs.tf                # Output values (IPs, URLs, SSH)
    ├── terraform.tfvars          # Your configuration (git-ignored)
    ├── terraform.tfvars.example  # Configuration template
    ├── .gitignore                # Terraform artifact exclusions
    └── modules/
        └── ec2/
            ├── main.tf           # EC2 instance resource
            ├── variables.tf      # Module input variables
            ├── outputs.tf        # Module outputs
            └── user-data.sh      # Cloud-init bootstrap script
```

### Key Files Explained

| File | Purpose | When to Modify |
|------|---------|----------------|
| `IMPLEMENTATION_AUTO.sh` | Automated deployment orchestrator | When changing deployment steps |
| `terraform/main.tf` | Infrastructure definition | When adding/changing AWS resources |
| `terraform/modules/ec2/user-data.sh` | Bootstrap script | When changing initialization logic |
| `backend/src/server.js` | API server entry point | When adding API features |
| `frontend/src/App.jsx` | UI root component | When changing UI layout |
| `backend/migrations/*.sql` | Database schema | When modifying database structure |

---

## Local Development

### Backend Local Setup

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Edit .env with your local PostgreSQL credentials
nano .env

# Required values:
# DATABASE_URL=postgresql://bmi_user:password@localhost:5432/bmidb
# PORT=3000
# NODE_ENV=development

# Ensure PostgreSQL is installed and running
sudo systemctl status postgresql

# Create database and user
sudo -u postgres psql
CREATE DATABASE bmidb;
CREATE USER bmi_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE bmidb TO bmi_user;
\q

# Run migrations
psql -U bmi_user -d bmidb -h localhost -f migrations/001_create_measurements.sql
psql -U bmi_user -d bmidb -h localhost -f migrations/002_add_measurement_date.sql

# Start backend server
node src/server.js
# Server runs on http://localhost:3000
```

### Frontend Local Setup

```bash
# Navigate to frontend
cd frontend

# Install dependencies
npm install

# Configure API endpoint (if needed)
# Edit src/api.js to point to:
# - http://localhost:3000/api (local backend)
# - http://YOUR_EC2_IP/api (deployed backend)

# Start development server
npm run dev
# Frontend runs on http://localhost:5173
```

### Testing Locally

```bash
# Terminal 1: Start backend
cd backend && node src/server.js

# Terminal 2: Start frontend dev server
cd frontend && npm run dev

# Terminal 3: Test API
curl http://localhost:3000/api/measurements

# Expected: [] (empty array initially)

# Test browser: http://localhost:5173
```

---

## Infrastructure Deployment

### Pre-Deployment Checklist

- [ ] AWS CLI configured with correct profile
- [ ] S3 bucket created for Terraform state
- [ ] VPC, subnet, and security group IDs identified
- [ ] EC2 key pair created and downloaded
- [ ] `terraform.tfvars` configured with your values
- [ ] Git repository accessible (public or SSH key added)

### Step-by-Step Deployment

#### 1. Clone Repository

```bash
git clone https://github.com/md-sarowar-alam/terraform-3-tier-basic.git
cd terraform-3-tier-basic
```

#### 2. Configure Terraform Variables

```bash
cd terraform

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Critical variables to update:**
```hcl
aws_profile       = "sarowar-ostad"              # Your AWS CLI profile
aws_region        = "ap-south-1"                 # Your deployment region
vpc_id            = "vpc-06f7dead5c49ece64"     # Your VPC ID
subnet_id         = "subnet-0880772cfbeb8bb6f"  # Your public subnet ID
security_group_id = "sg-097d6afb08616ba09"      # Your security group ID
key_name          = "sarowar-ostad-mumbai"      # Your EC2 key pair
db_password       = "ChangeThisPassword123!"     # Strong database password
```

#### 3. Initialize Terraform

```bash
# Initialize backend and download providers
terraform init

# Expected output:
# Terraform has been successfully initialized!
```

**Common initialization issues:**
- **S3 bucket not found:** Create bucket first (see Prerequisites)
- **Profile not configured:** Run `aws configure --profile <name>`
- **Region mismatch:** Ensure bucket region matches `backend.tf`

#### 4. Plan Infrastructure Changes

```bash
# Generate execution plan
terraform plan

# Review output carefully:
# - Should show creation of 1 EC2 instance
# - Check AMI ID, instance type, networking
# - Verify userdata script will be applied
```

#### 5. Deploy Infrastructure

```bash
# Apply infrastructure changes
terraform apply

# Review plan, type 'yes' to proceed
# Deployment takes ~2 minutes for EC2 creation
# Then ~10-12 minutes for application deployment (userdata)
```

#### 6. Monitor Deployment Progress

```bash
# Get instance public IP
terraform output instance_public_ip

# Get SSH command
terraform output ssh_command

# SSH into instance
ssh -i ~/.ssh/sarowar-ostad-mumbai.pem ubuntu@<PUBLIC_IP>

# Monitor deployment logs (on EC2 instance)
sudo tail -f /var/log/user-data.log           # Bootstrap progress
sudo tail -f /var/log/bmi-deployment.log      # Application deployment
sudo tail -f /var/log/cloud-init-output.log   # Cloud-init output
```

#### 7. Verify Deployment

```bash
# Check all services are running
sudo systemctl status bmi-backend
sudo systemctl status nginx
sudo systemctl status postgresql

# Test backend API
curl http://localhost:3000/api/measurements

# Test frontend
curl http://localhost

# Access from browser
# Get URL: terraform output application_url
```

### Deployment Timeline

| Phase | Duration | Key Activities |
|-------|----------|----------------|
| Terraform Apply | ~2 min | EC2 instance creation, EBS attachment |
| Cloud-init Bootstrap | ~3 min | Package updates, git clone, prerequisites |
| NVM/Node.js Install | ~2-3 min | NVM installation, Node.js LTS download |
| PostgreSQL Setup | ~1 min | Database creation, user setup, migrations |
| Backend Build | ~2-3 min | npm install, dependency download |
| Frontend Build | ~2-3 min | Vite build, static file generation |
| Service Configuration | ~1 min | Systemd service, Nginx config, startup |
| **Total** | **~12-15 min** | Fully automated, zero-touch |

---

## Testing

### Manual Testing Checklist

After deployment, verify:

1. **Backend Health:**
   ```bash
   # On EC2 instance:
   curl http://localhost:3000/api/measurements
   # Expected: [] or [{"id": 1, ...}]
   
   # Check service
   sudo systemctl status bmi-backend
   sudo journalctl -u bmi-backend -n 50
   ```

2. **Frontend Serving:**
   ```bash
   curl -I http://localhost
   # Expected: HTTP/1.1 200 OK
   
   # Check Nginx
   sudo nginx -t
   sudo systemctl status nginx
   ```

3. **Database Connectivity:**
   ```bash
   PGPASSWORD=<your_password> psql -U bmi_user -d bmidb -h localhost -c "SELECT COUNT(*) FROM measurements;"
   # Expected: count value (0 if no data)
   ```

4. **End-to-End Test (Browser):**
   - Navigate to `http://<PUBLIC_IP>`
   - Should load React app without errors
   - Enter test measurement (e.g., 70kg, 175cm)
   - Verify form submission succeeds
   - Check data appears in database

### Automated Testing

**Backend API Tests:**
```bash
cd backend

# Install dev dependencies
npm install --save-dev

# Run tests (if available)
npm test
```

**Frontend Tests:**
```bash
cd frontend

# Run tests
npm test

# Run build (validates configuration)
npm run build
```

---

## Operations & Monitoring

### Service Management

All commands run on the **EC2 instance** (after SSH):

```bash
# Backend Service (systemd)
sudo systemctl status bmi-backend      # Check status
sudo systemctl start bmi-backend       # Start service
sudo systemctl stop bmi-backend        # Stop service
sudo systemctl restart bmi-backend     # Restart service
sudo systemctl enable bmi-backend      # Enable auto-start on boot
sudo journalctl -u bmi-backend -f      # Tail logs

# Nginx (Web Server)
sudo systemctl status nginx            # Check status
sudo systemctl restart nginx           # Restart after config changes
sudo nginx -t                          # Test configuration syntax
sudo nginx -s reload                   # Reload without downtime

# PostgreSQL (Database)
sudo systemctl status postgresql       # Check status
sudo systemctl restart postgresql      # Restart database
sudo -u postgres psql                  # Connect as admin
```

### Log Files

| Log File | Purpose | Access Command |
|----------|---------|----------------|
| `/var/log/user-data.log` | Cloud-init bootstrap script | `sudo tail -f /var/log/user-data.log` |
| `/var/log/bmi-deployment.log` | Application deployment | `sudo tail -f /var/log/bmi-deployment.log` |
| `/var/log/bmi-backend.log` | Backend API logs | `sudo tail -f /var/log/bmi-backend.log` |
| `/var/log/nginx/bmi-access.log` | HTTP access logs | `sudo tail -f /var/log/nginx/bmi-access.log` |
| `/var/log/nginx/bmi-error.log` | Nginx errors | `sudo tail -f /var/log/nginx/bmi-error.log` |
| `/var/log/postgresql/*.log` | Database logs | `sudo tail -f /var/log/postgresql/*.log` |

### Database Operations

```bash
# Connect to database
PGPASSWORD=<password> psql -U bmi_user -d bmidb -h localhost

# Common queries
SELECT * FROM measurements ORDER BY created_at DESC LIMIT 10;
SELECT COUNT(*) FROM measurements;
SELECT * FROM measurements WHERE weight > 80;

# Backup database
pg_dump -U bmi_user -d bmidb -h localhost > backup_$(date +%Y%m%d).sql

# Restore database
psql -U bmi_user -d bmidb -h localhost < backup_20260224.sql
```

### Performance Monitoring

```bash
# System resources
htop                    # CPU, memory, processes
df -h                   # Disk usage
free -h                 # Memory usage
iostat -x 1            # Disk I/O

# Network
netstat -tuln          # Active ports
ss -tuln               # Socket statistics

# Application-specific
curl http://localhost:3000/api/stats    # API metrics (if endpoint exists)
sudo systemctl status bmi-backend       # Service health
```

### Health Check Endpoints

```bash
# Backend API
curl http://localhost:3000/api/measurements
# Should return JSON array

# Frontend
curl -I http://localhost
# Should return 200 OK

# Database
PGPASSWORD=<pass> psql -U bmi_user -d bmidb -h localhost -c "SELECT 1;"
# Should return (1 row)
```

---

## Troubleshooting

### Common Issues & Solutions

#### 1. Deployment Stuck / Cloud-init Hanging

**Symptom:** `cloud-init status --wait` hangs indefinitely

**Diagnosis:**
```bash
# Check cloud-init status
cloud-init status

# Check running processes
ps aux | grep cloud-init

# Check logs
sudo tail -f /var/log/cloud-init-output.log
```

**Solution:** Fixed in latest version (removed cloud-init wait from userdata)

#### 2. Backend Service Fails to Start

**Symptom:** `systemctl status bmi-backend` shows failed/inactive

**Diagnosis:**
```bash
# Check service logs
sudo journalctl -u bmi-backend -n 100 --no-pager

# Check manual start
cd /home/ubuntu/bmi-health-tracker/backend
node src/server.js
```

**Common causes:**
- Missing Node.js PATH in systemd service
- Database connection failure (wrong credentials)
- Missing .env file
- Port 3000 already in use

**Solutions:**
```bash
# Fix Node.js path in systemd service
NODE_PATH=$(which node)
sudo nano /etc/systemd/system/bmi-backend.service
# Update ExecStart to full node path

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart bmi-backend
```

#### 3. Database Connection Errors

**Symptom:** Backend logs show "ECONNREFUSED" or authentication errors

**Diagnosis:**
```bash
# Test connection manually
PGPASSWORD=<password> psql -U bmi_user -d bmidb -h localhost

# Check PostgreSQL is running
sudo systemctl status postgresql

# Check pg_hba.conf
sudo cat /etc/postgresql/*/main/pg_hba.conf | grep bmi
```

**Solutions:**
```bash
# Ensure authentication rule exists
sudo su - postgres
psql -c "SHOW hba_file;"
# Edit file and add:
# host    bmidb    bmi_user    127.0.0.1/32    md5

# Reload PostgreSQL
sudo systemctl reload postgresql
```

#### 4. Nginx 502 Bad Gateway

**Symptom:** Browser shows "502 Bad Gateway" error

**Diagnosis:**
```bash
# Check backend is running
sudo systemctl status bmi-backend
curl http://localhost:3000/api/measurements

# Check Nginx config
sudo nginx -t
sudo cat /etc/nginx/sites-enabled/bmi-health-tracker
```

**Solutions:**
```bash
# Ensure backend is running
sudo systemctl start bmi-backend

# Verify Nginx proxy_pass
sudo nano /etc/nginx/sites-available/bmi-health-tracker
# Should have: proxy_pass http://127.0.0.1:3000/api/;

# Restart Nginx
sudo systemctl restart nginx
```

#### 5. NVM Installation Fails

**Symptom:** `mkdir: cannot create directory '/.nvm': Permission denied`

**Solution:** Fixed in latest version (added `-H` flag to sudo in user-data.sh)

#### 6. Terraform State Lock Issues

**Symptom:** "Error acquiring state lock"

**Note:** This configuration doesn't use DynamoDB locking (as per requirements)

**Solutions:**
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>

# Or refresh state
terraform refresh
```

### Debug Mode

**Enable verbose logging:**

```bash
# Terraform debug
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply

# Backend debug
# Edit backend/src/server.js to add console.log statements

# Check deployment script output
sudo cat /var/log/bmi-deployment.log | less
```

---

## Contributing Changes

### Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/your-feature-name

# 2. Make changes locally
# Edit files, test locally

# 3. Test changes
cd backend && npm test
cd frontend && npm test

# 4. Commit changes
git add .
git commit -m "feat: Add new feature description"

# 5. Push branch
git push origin feature/your-feature-name

# 6. Create Pull Request (on GitHub)

# 7. After approval, merge to main
# 8. Deploy to production
```

### Code Style Guidelines

**Backend (Node.js):**
- Use ES6+ syntax
- Async/await for promises
- Error handling with try/catch
- Input validation for all API endpoints

**Frontend (React):**
- Functional components with hooks
- PropTypes for type validation
- Extract reusable logic to custom hooks
- Keep components under 200 lines

**Infrastructure (Terraform):**
- Use modules for reusability
- Variable validation where applicable
- Descriptive resource names
- Comments for complex logic

### Testing Before Merge

```bash
# Backend tests
cd backend
npm install
npm test

# Frontend build test
cd frontend
npm install
npm run build

# Terraform validation
cd terraform
terraform init
terraform validate
terraform plan
```

### Infrastructure Changes

**When modifying Terraform:**

1. **Test in dev environment first:**
   ```bash
   # Use separate tfvars
   terraform plan -var-file=dev.tfvars
   terraform apply -var-file=dev.tfvars
   ```

2. **Review plan carefully:**
   - Resources to be destroyed (red)
   - Resources to be created (green)
   - Resources to be modified (yellow)

3. **Backup state before major changes:**
   ```bash
   # Download current state
   terraform state pull > backup-state-$(date +%Y%m%d).json
   ```

4. **Apply with caution:**
   ```bash
   terraform apply -auto-approve=false
   # Review, then type 'yes'
   ```

---

## Rollback Procedures

### Application Rollback (Git-based)

```bash
# SSH into EC2 instance
ssh -i ~/.ssh/key.pem ubuntu@<PUBLIC_IP>

# Navigate to app directory
cd /home/ubuntu/bmi-health-tracker

# Check current version
git log -1 --oneline

# Rollback to previous commit
git log --oneline  # Find commit hash
git checkout <previous-commit-hash>

# Redeploy
echo "y" | bash ./IMPLEMENTATION_AUTO.sh --skip-backup

# Restart services
sudo systemctl restart bmi-backend
sudo systemctl restart nginx
```

### Infrastructure Rollback (Terraform)

```bash
# Option 1: Destroy and recreate with previous config
terraform destroy -auto-approve
git checkout <previous-commit>
terraform apply -auto-approve

# Option 2: State rollback (advanced)
# Download previous state from S3 versioning
aws s3api list-object-versions \
  --bucket batch09-ostad \
  --prefix bmi-app/terraform.tfstate

# Restore specific version
aws s3api get-object \
  --bucket batch09-ostad \
  --key bmi-app/terraform.tfstate \
  --version-id <VERSION_ID> \
  terraform.tfstate.backup
```

### Database Rollback

```bash
# If you have a backup
PGPASSWORD=<password> psql -U bmi_user -d bmidb -h localhost < backup.sql

# Point-in-time restore (requires backup strategy)
# Restore from most recent backup before issue
```

---

## Security Considerations

### Secrets Management

**Current Implementation (Dev/Test):**
- Database credentials in `terraform.tfvars` (git-ignored)
- Credentials passed via EC2 userdata (base64 encoded by AWS)
- Stored in Terraform state (S3 encrypted)

**Production Recommendations:**
1. **Use AWS Secrets Manager:**
   ```hcl
   data "aws_secretsmanager_secret_version" "db_password" {
     secret_id = "bmi-app/db-password"
   }
   ```

2. **Instance Profile with IAM Role:**
   - Grant EC2 minimal required permissions
   - No hardcoded credentials

3. **Environment-specific separation:**
   - Different AWS accounts for dev/staging/prod
   - Separate Terraform workspaces or directories

### Network Security

**Implemented:**
- ✅ Security group restricts traffic
- ✅ SSH access from specific IPs only
- ✅ Database listens only on localhost
- ✅ IMDSv2 enforced (prevents SSRF attacks)

**Production Enhancements:**
```bash
# Configure AWS WAF for application firewall
# Set up VPN or bastion host for SSH
# Implement SSL/TLS (Let's Encrypt):
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

### Compliance & Audit

```bash
# Check open ports
sudo netstat -tuln

# Review firewall rules
sudo ufw status

# Check who logged in
last -20

# Review sudo commands
sudo cat /var/log/auth.log | grep sudo
```

---

## Performance & Scaling

### Current Capacity

| Metric | Estimate | Bottleneck |
|--------|----------|------------|
| **Concurrent Users** | ~100 | t3.medium CPU/memory |
| **API Requests/sec** | ~50-100 | Node.js single process |
| **Database Connections** | 10-20 | PostgreSQL default pool |
| **Storage** | 20GB | EBS volume size |

### Scaling Path

**Vertical Scaling (Immediate):**
```hcl
# Edit terraform/terraform.tfvars
instance_type = "t3.large"  # or t3.xlarge

# Apply change
terraform apply
# Note: Requires instance stop/start (brief downtime)
```

**Horizontal Scaling (Production):**

1. **Database Layer:**
   - Migrate to RDS PostgreSQL (managed, multi-AZ)
   - Enable read replicas for read-heavy workloads
   - Connection pooling (PgBouncer)

2. **Application Layer:**
   - Deploy to ECS/EKS with auto-scaling
   - Use ALB for load distribution
   - Multiple instances across AZs

3. **Frontend Layer:**
   - Deploy to S3 + CloudFront CDN
   - Edge caching for static assets
   - CloudFront Functions for routing

4. **Caching Layer:**
   - Redis/ElastiCache for sessions
   - API response caching
   - Database query caching

### Monitoring Setup

**CloudWatch Integration:**
```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Configure metrics
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Start agent
sudo systemctl start amazon-cloudwatch-agent
```

**Application Metrics:**
- API response times
- Error rates (4xx, 5xx)
- Database query performance
- Active user sessions

---

## Dependencies

### Production Dependencies (Automated)

Installed automatically by `IMPLEMENTATION_AUTO.sh` during deployment:

**System Packages:**
- `curl`, `wget`, `git` - Utilities
- `postgresql`, `postgresql-contrib` - Database
- `nginx` - Web server

**Runtime Environments:**
- **NVM** (Node Version Manager) - v0.39.7
- **Node.js** - Latest LTS (via NVM)
- **npm** - Bundled with Node.js

**Backend Dependencies (package.json):**
```json
{
  "express": "^4.18.2",
  "pg": "^8.11.3",
  "cors": "^2.8.5",
  "dotenv": "^16.3.1"
}
```

**Frontend Dependencies (package.json):**
```json
{
  "react": "^18.2.0",
  "react-dom": "^18.2.0",
  "chart.js": "^4.4.0",
  "react-chartjs-2": "^5.2.0",
  "@vitejs/plugin-react": "^4.2.1"
}
```

### Development Dependencies

For local development, additionally install:
```bash
# Backend dev tools
npm install --save-dev nodemon jest supertest

# Frontend dev tools  
npm install --save-dev eslint prettier @testing-library/react
```

### Security Updates

```bash
# Check for vulnerable packages
cd backend && npm audit
cd frontend && npm audit

# Update dependencies
npm update

# Fix vulnerabilities automatically
npm audit fix
```

---

## Release Workflow

### Version Management

**Semantic Versioning:** Use `MAJOR.MINOR.PATCH` format

- **MAJOR:** Breaking API changes
- **MINOR:** New features, backward compatible
- **PATCH:** Bug fixes, security patches

### Release Process

#### 1. Prepare Release

```bash
# Create release branch
git checkout -b release/v1.2.0

# Update version in package.json files
cd backend && npm version minor
cd frontend && npm version minor

# Run full test suite
npm test

# Build and verify
npm run build
```

#### 2. Tag Release

```bash
# Commit version updates
git add backend/package.json frontend/package.json
git commit -m "chore: Bump version to v1.2.0"

# Create annotated tag
git tag -a v1.2.0 -m "Release v1.2.0

Features:
- Added trend analysis dashboard
- Improved chart performance

Fixes:
- Fixed BMI calculation rounding
- Resolved database connection pool exhaustion

Breaking Changes:
- API endpoint /api/stats now requires authentication
"

# Push tag
git push origin v1.2.0
```

#### 3. Deploy Release

```bash
# Option A: Automated (via userdata pull from main)
terraform destroy -auto-approve
terraform apply -auto-approve
# Pulls latest main branch from GitHub

# Option B: Manual update on existing instance
ssh ubuntu@<IP>
cd /home/ubuntu/bmi-health-tracker
git fetch --tags
git checkout v1.2.0
echo "y" | bash ./IMPLEMENTATION_AUTO.sh --skip-backup
```

#### 4. Verify Release

```bash
# Check application version
curl http://<IP>/api/version

# Run smoke tests
./scripts/smoke-test.sh

# Monitor for errors
sudo journalctl -u bmi-backend -f
```

### Hotfix Process

**For critical production issues:**

```bash
# 1. Create hotfix branch from production tag
git checkout -b hotfix/v1.2.1 v1.2.0

# 2. Apply fix
# Edit files, test locally

# 3. Commit and tag
git commit -m "fix: Critical security patch"
git tag -a v1.2.1 -m "Hotfix: Security patch"

# 4. Deploy immediately
# SSH to instance and checkout hotfix tag

# 5. Merge back to main
git checkout main
git merge hotfix/v1.2.1
git push origin main --tags
```

---

## Reliability Considerations

### High Availability (Future)

**Current Setup:** Single instance (no HA)

**Production HA Setup:**

1. **Multi-AZ Deployment:**
   - EC2 instances in multiple availability zones
   - Application Load Balancer for traffic distribution
   - RDS Multi-AZ for database failover

2. **Auto-Recovery:**
   ```hcl
   # Add to EC2 instance
   resource "aws_instance" "app" {
     monitoring = true
     
     # Auto-recovery on system status checks
     metadata_options {
       instance_metadata_tags = "enabled"
     }
   }
   
   resource "aws_cloudwatch_metric_alarm" "auto_recovery" {
     alarm_name          = "ec2-auto-recovery"
     comparison_operator = "GreaterThanThreshold"
     evaluation_periods  = "2"
     metric_name         = "StatusCheckFailed_System"
     namespace           = "AWS/EC2"
     period              = "60"
     statistic           = "Average"
     threshold           = "0"
     alarm_actions       = ["arn:aws:automate:ap-south-1:ec2:recover"]
   }
   ```

3. **Backup Strategy:**
   ```bash
   # Automated daily backups
   # Add to cron:
   0 2 * * * /usr/local/bin/backup-bmi-app.sh
   ```

### Disaster Recovery

**Recovery Time Objective (RTO):** ~15 minutes (recreate from Terraform)
**Recovery Point Objective (RPO):** Depends on backup frequency

**Recovery Procedure:**
```bash
# 1. Ensure you have:
#    - Latest Terraform configuration (git)
#    - Database backup (S3 or local)
#    - Terraform state (S3 backend)

# 2. Recreate infrastructure
cd terraform
terraform apply -auto-approve

# 3. Restore database (if needed)
ssh ubuntu@<NEW_IP>
# Upload backup
scp -i key.pem backup.sql ubuntu@<NEW_IP>:/tmp/
# Restore
PGPASSWORD=<pass> psql -U bmi_user -d bmidb -h localhost < /tmp/backup.sql

# 4. Verify application
curl http://<NEW_IP>
```

### Data Backup Automation

**Create backup script:**
```bash
# /usr/local/bin/backup-bmi-app.sh
#!/bin/bash
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/home/ubuntu/backups"
S3_BUCKET="s3://batch09-ostad/backups"

mkdir -p $BACKUP_DIR

# Backup database
PGPASSWORD=$DB_PASSWORD pg_dump -U bmi_user -d bmidb -h localhost \
  | gzip > $BACKUP_DIR/bmidb-$BACKUP_DATE.sql.gz

# Upload to S3
aws s3 cp $BACKUP_DIR/bmidb-$BACKUP_DATE.sql.gz $S3_BUCKET/

# Keep only last 7 days locally
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

# S3 lifecycle policy keeps 30 days
```

**Install cron:**
```bash
sudo crontab -e
# Add: 0 2 * * * /usr/local/bin/backup-bmi-app.sh
```

---

## Automation Details

### IMPLEMENTATION_AUTO.sh Overview

**Purpose:** Complete zero-touch deployment automation script

**What it does:**
1. Validates prerequisites (Node.js, PostgreSQL, Nginx)
2. Installs missing dependencies (NVM, Node.js, system packages)
3. Configures PostgreSQL database, user, permissions
4. Runs database migrations
5. Creates backend .env configuration
6. Installs backend dependencies (npm install)
7. Builds frontend for production (Vite build)
8. Creates systemd service for backend
9. Configures Nginx reverse proxy
10. Runs health checks
11. Displays deployment summary

**Invocation:**
```bash
# Interactive mode (prompts for credentials)
./IMPLEMENTATION_AUTO.sh

# Non-interactive mode (uses env vars)
export DB_NAME="bmidb"
export DB_USER="bmi_user"
export DB_PASSWORD="password"
echo "y" | bash ./IMPLEMENTATION_AUTO.sh --fresh

# Options:
#   --fresh        : Clean install (removes node_modules)
#   --skip-nginx   : Skip Nginx configuration
#   --skip-backup  : Skip creating backup
```

**Idempotency:** Script can be run multiple times safely

### Terraform Automation

**Module Structure:**
- **Root module** (`terraform/`): Orchestrates deployment
- **EC2 module** (`terraform/modules/ec2/`): Instance provisioning

**Automated tasks:**
1. EC2 instance creation with proper networking
2. EBS volume creation and encryption
3. Security group association
4. Public IP allocation
5. Userdata script injection (via templatefile)
6. Database credentials templating
7. Output generation (IPs, URLs, SSH commands)

**Terraform workflow:**
```bash
init    # Initialize backend, download providers
validate # Check configuration syntax
plan     # Preview changes (dry-run)
apply    # Execute changes
output   # Display output values
destroy  # Remove all resources
```

### CI/CD Integration (Future)

**GitHub Actions example:**
```yaml
# .github/workflows/deploy.yml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-south-1
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Apply
        run: |
          cd terraform
          terraform init
          terraform apply -auto-approve
```

---

## Quick Reference Commands

### Daily Operations

```bash
# Access application
firefox http://$(terraform output -raw instance_public_ip)

# SSH to instance
eval $(terraform output -raw ssh_command)

# Check service status
sudo systemctl status bmi-backend nginx postgresql

# View logs
sudo tail -f /var/log/bmi-backend.log
sudo tail -f /var/log/nginx/bmi-access.log

# Restart services
sudo systemctl restart bmi-backend
sudo systemctl restart nginx
```

### Terraform Operations

```bash
# Check current state
terraform show

# List resources
terraform state list

# Get specific output
terraform output instance_public_ip

# Refresh state from AWS
terraform refresh

# Import existing resource
terraform import module.ec2_instance.aws_instance.this i-xxxxx

# Remove resource from state (without destroying)
terraform state rm module.ec2_instance.aws_instance.this
```

### Database Operations

```bash
# Connect to database
PGPASSWORD=<pass> psql -U bmi_user -d bmidb -h localhost

# Useful queries
\dt                                    # List tables
\d measurements                        # Describe table
SELECT COUNT(*) FROM measurements;     # Count records
```

### Emergency Procedures

```bash
# Backend crashed - restart
sudo systemctl restart bmi-backend
sudo journalctl -u bmi-backend -n 100

# Database crashed - restart
sudo systemctl restart postgresql

# Out of disk space - clean up
sudo du -sh /var/log/* | sort -h
sudo journalctl --vacuum-time=7d    # Keep only 7 days of logs
docker system prune -a              # If docker is installed

# High CPU - identify process
top
ps aux --sort=-%cpu | head -20

# Kill runaway process
sudo kill -9 <PID>
```

---

## Additional Resources

### Official Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [React Documentation](https://react.dev/)
- [Express.js Guide](https://expressjs.com/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Nginx Configuration](https://nginx.org/en/docs/)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)

### Related Scripts & Guides

- `IMPLEMENTATION_AUTO.sh` - Main deployment automation script (946 lines)
- `terraform/terraform.tfvars.example` - Configuration template with comments
- `backend/.env.example` - Backend environment template
- Database migrations in `backend/migrations/`

### Getting Help

**Common Questions:**

1. **"Terraform apply fails with authentication error"**
   - Check: `aws sts get-caller-identity --profile <profile>`
   - Verify AWS credentials are valid and profile name matches

2. **"Application deployed but can't access from browser"**
   - Check security group allows HTTP (port 80) from your IP
   - Verify public IP is correct: `terraform output instance_public_ip`
   - Check Nginx is running: `sudo systemctl status nginx`

3. **"Backend service won't start"**
   - Check logs: `sudo journalctl -u bmi-backend -n 100`
   - Verify Node.js path in systemd service file
   - Test manual start: `cd ~/bmi-health-tracker/backend && node src/server.js`

4. **"Database connection refused"**
   - Check PostgreSQL is running: `sudo systemctl status postgresql`
   - Verify credentials in backend/.env match database user
   - Check pg_hba.conf has md5 auth rule for bmi_user

### Support Contacts

- **Infrastructure Issues:** DevOps Team
- **Application Bugs:** Development Team  
- **Security Concerns:** Security Team

---

## Change Log

### v1.0.0 (2026-02-24)
- Initial production release
- Terraform modular architecture
- Automated deployment via IMPLEMENTATION_AUTO.sh
- Non-interactive mode via environment variables
- Cloud-init zero-touch provisioning
- Systemd service management
- Nginx reverse proxy configuration
- PostgreSQL database migrations
- React + Vite frontend build
- S3 backend for Terraform state

---

## 🧑‍💻 Author

*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---

**Last Updated:** February 24, 2026  
**Terraform Version:** >= 1.0  
**AWS Provider Version:** ~> 5.0  
**Node.js Version:** 20 LTS  
**Tested On:** Ubuntu 22.04 LTS, AWS EC2 t3.medium
