# Three-Tier Application Jenkins Deployment

This folder contains all files specific to deploying the BMI Health Tracker three-tier application using Jenkins CI/CD.

## 📁 Contents

### Documentation
- **[ThreeTierWithJenkins.md](./ThreeTierWithJenkins.md)** - Complete deployment guide for the BMI Health Tracker application

### Pipeline Files
- **[Jenkinsfile](./Jenkinsfile)** - Main deployment pipeline (single environment)
- **[Jenkinsfile.multibranch](./Jenkinsfile.multibranch)** - Multi-environment deployment pipeline (dev/staging/production)

### Support Scripts
Located in [scripts/](./scripts/) directory:
- **[check-prerequisites.sh](./scripts/check-prerequisites.sh)** - Verify prerequisites on target EC2
- **[health-check.sh](./scripts/health-check.sh)** - Health checks with retry logic
- **[rollback-jenkins.sh](./scripts/rollback-jenkins.sh)** - Rollback to previous deployment

## 🚀 Quick Start

### 1. Prerequisites
- Jenkins server running (see [../CreateJenkinsServer.md](../CreateJenkinsServer.md))
- AWS EC2 target server (Ubuntu 24.04)
- Jenkins credentials configured (see [../CREDENTIALS_GUIDE.md](../CREDENTIALS_GUIDE.md))

### 2. Create Jenkins Pipeline Job

**Option A: Single Environment Pipeline**
```
1. Jenkins Dashboard → New Item
2. Name: "BMI-Deployment"
3. Type: Pipeline
4. Pipeline → Definition: Pipeline script from SCM
5. SCM: Git
6. Repository URL: [Your repository URL]
7. Script Path: Jenkins/3-Tier/Jenkinsfile
8. Save
```

**Option B: Multi-Environment Pipeline**
```
1. Jenkins Dashboard → New Item
2. Name: "BMI-MultiEnv"
3. Type: Multibranch Pipeline
4. Branch Sources → Add source → Git
5. Project Repository: [Your repository URL]
6. Build Configuration → Script Path: Jenkins/3-Tier/Jenkinsfile.multibranch
7. Save
```

### 3. Configure Credentials

Add these in Jenkins → Manage Jenkins → Credentials:
- `ec2-ssh-key` - SSH Username with private key for EC2 access
- `db-password` - Secret text for PostgreSQL password
- (For multibranch: `db-password-production`, `db-password-staging`, `db-password-dev`)

See [../CREDENTIALS_GUIDE.md](../CREDENTIALS_GUIDE.md) for detailed setup.

### 4. Run Pipeline

**Single Environment:**
- Click "Build with Parameters"
- Enter target EC2 IP
- Click "Build"

**Multi-Environment:**
- Push code to appropriate branch (main/staging/develop)
- Pipeline triggers automatically (if webhook configured)

## 📖 Application Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS EC2 Instance                      │
│                                                          │
│  ┌────────────┐     ┌─────────────┐    ┌───────────┐  │
│  │   Nginx    │────▶│   Express   │───▶│PostgreSQL │  │
│  │ (Frontend) │     │  (Backend)  │    │ (Database)│  │
│  │  Port 80   │     │  Port 3000  │    │  Port 5432│  │
│  └────────────┘     └─────────────┘    └───────────┘  │
│       │                    │                   │        │
│    Static             PM2 Managed         Local DB     │
│    React              Node.js             Connection   │
└─────────────────────────────────────────────────────────┘
```

## 🔄 Deployment Workflow

### Fresh Deployment (New EC2)
```
1. Validate Parameters → Credentials, EC2 IP
2. Checkout Code → Clone from Git
3. Check Prerequisites → Node.js, PostgreSQL, Nginx, PM2
4. Install Prerequisites → If missing, install automatically
5. Setup Database → Create user, database, run migrations
6. Deploy Backend → npm install, configure .env, PM2 start
7. Deploy Frontend → npm build, copy to Nginx
8. Health Checks → Verify all services running
9. Notify Success → Build passes
```

### Update Deployment (Existing EC2)
```
1. Validate Parameters
2. Checkout Code
3. Backup Current → Create snapshot of running app
4. Deploy Backend → Pull code, npm install, PM2 restart
5. Deploy Frontend → Build and update Nginx
6. Health Checks → Verify deployment
7. Success → Keep new version
8. Failure → Auto-rollback to backup
```

## 🎯 Features

### ✅ Jenkinsfile Features
- Single target environment
- Parameterized builds (EC2 IP, DB password)
- Optional backend-only or frontend-only deployment
- Automatic prerequisite installation
- Database setup and migrations
- Pre-deployment backup
- Comprehensive health checks
- Automatic rollback on failure

### ✅ Jenkinsfile.multibranch Features
- Multi-environment support (dev/staging/production)
- Branch-based deployment
  - `main` → Production (with approval gate)
  - `staging` → Staging (auto-deploy)
  - `develop` → Development (auto-deploy)
- Environment-specific credentials
- Parallel backend/frontend deployment
- Production approval gate
- Automatic webhook triggering

## 🔧 Configuration

### Jenkinsfile Parameters

```groovy
TARGET_EC2_IP       // Target server IP address
DB_PASSWORD         // PostgreSQL password
DEPLOY_BACKEND_ONLY // Deploy only backend (skip frontend)
DEPLOY_FRONTEND_ONLY// Deploy only frontend (skip backend)
SKIP_HEALTH_CHECK   // Skip health checks
SKIP_BACKUP         // Skip backup creation
```

### Jenkinsfile.multibranch Environment Variables

```groovy
// Set automatically based on branch
ENVIRONMENT         // production/staging/development
TARGET_EC2_IP       // Environment-specific EC2 IP
DB_PASSWORD_CREDENTIAL // Environment-specific credential ID
NODE_ENV            // production/staging/development
DEPLOY_PATH         // Deployment directory path
```

## 🛠️ Scripts Usage

### check-prerequisites.sh
Verify prerequisites on target EC2:
```bash
ssh ubuntu@54.123.45.67 'bash -s' < scripts/check-prerequisites.sh
echo $?  # 0 = all installed, 1 = missing prerequisites
```

### health-check.sh
Run health checks with retry:
```bash
./scripts/health-check.sh 54.123.45.67 3000 5 10
# Parameters: <EC2_IP> <BACKEND_PORT> <MAX_RETRIES> <RETRY_DELAY_SECONDS>
```

### rollback-jenkins.sh
Rollback to previous deployment:
```bash
# Interactive mode - select backup
./scripts/rollback-jenkins.sh

# Automatic mode - latest backup
./scripts/rollback-jenkins.sh --auto-latest
```

## 📊 Comparison: Single vs Multi-Environment

| Feature | Jenkinsfile | Jenkinsfile.multibranch |
|---------|-------------|------------------------|
| Environments | Single | Multiple (dev/staging/prod) |
| Trigger | Manual/Webhook | Branch-based automatic |
| Target EC2 | Parameterized | Branch-determined |
| Credentials | Single set | Per-environment |
| Approval Gate | Optional | Production only |
| Use Case | Simple deployments | Team with multiple envs |

## 🔐 Security

All credentials use **Jenkins Credentials Manager**:
- ✅ No hardcoded passwords or keys
- ✅ Encrypted storage in Jenkins
- ✅ Automatic masking in logs
- ✅ Access control and audit logging

See [../CREDENTIALS_GUIDE.md](../CREDENTIALS_GUIDE.md) for details.

## 🐛 Troubleshooting

### Common Issues

**1. SSH Connection Failed**
```bash
# Verify SSH key in Jenkins
# Test manually: ssh -i key.pem ubuntu@<EC2_IP>
# Check security group allows SSH from Jenkins server
```

**2. Database Connection Failed**
```bash
# Verify PostgreSQL is running
ssh ubuntu@<EC2_IP> 'sudo systemctl status postgresql'

# Check database credentials
# Verify credential ID matches in pipeline
```

**3. Health Checks Failing**
```bash
# Check backend logs
ssh ubuntu@<EC2_IP> 'pm2 logs bmi-backend'

# Check Nginx logs
ssh ubuntu@<EC2_IP> 'sudo tail -f /var/log/nginx/error.log'

# Verify ports are open
ssh ubuntu@<EC2_IP> 'sudo netstat -tlnp | grep -E "(3000|80)"'
```

**4. PM2 Process Not Starting**
```bash
# Check PM2 status
ssh ubuntu@<EC2_IP> 'pm2 status'

# View logs
ssh ubuntu@<EC2_IP> 'pm2 logs bmi-backend --lines 50'

# Restart manually
ssh ubuntu@<EC2_IP> 'cd /home/ubuntu/bmi-app/backend && pm2 restart bmi-backend'
```

For more troubleshooting, see [ThreeTierWithJenkins.md](./ThreeTierWithJenkins.md#troubleshooting).

## 📚 Documentation

- **[ThreeTierWithJenkins.md](./ThreeTierWithJenkins.md)** - Complete deployment guide
- **[../CREDENTIALS_GUIDE.md](../CREDENTIALS_GUIDE.md)** - Credentials setup and security
- **[../CreateJenkinsServer.md](../CreateJenkinsServer.md)** - Jenkins server setup
- **[../StartJenkins.md](../StartJenkins.md)** - Jenkins basics and examples

## 📞 Support

For issues or questions:
1. Check [ThreeTierWithJenkins.md](./ThreeTierWithJenkins.md) troubleshooting section
2. Review Jenkins console output for error messages
3. Verify credentials in Jenkins Credentials Manager
4. Check EC2 instance logs and service status

---

**Version:** 1.0  
**Last Updated:** December 2025  
**Application:** BMI Health Tracker Three-Tier Web Application
