# Jenkins Integration for BMI Health Tracker

This directory contains all Jenkins-related files for deploying the BMI Health Tracker three-tier web application to AWS EC2 servers.

**✅ SECURITY CONFIRMED:** All credentials use Jenkins Credentials Manager. No passwords, keys, or tokens are hardcoded in this repository. See [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md) for complete details.

---

## 📖 **START HERE**: [GUIDE.md](./GUIDE.md)

**New to this project?** Read [GUIDE.md](./GUIDE.md) for a complete navigation guide organized by your objectives:
1. **AWS server creation & Jenkins setup** → How to create and configure Jenkins server
2. **Jenkins pipeline examples & basics** → How to create and execute pipelines  
3. **Three-tier application deployment** → Deploy BMI app with all credentials in Jenkins

**Quick answers in GUIDE.md:**
- ✅ How to add Git to Jenkins
- ✅ How to add Git credentials to Jenkins  
- ✅ How to create pipeline jobs
- ✅ How to execute pipelines
- ✅ Where all secrets are stored (Jenkins Credentials Manager)

---

## 📁 Directory Structure

```
Jenkins/
├── README.md                      # This file
├── CREDENTIALS_GUIDE.md           # Complete guide to Jenkins credentials usage
├── CreateJenkinsServer.md         # Guide: Set up Jenkins server on AWS EC2
├── StartJenkins.md                # Guide: Basic Jenkins pipeline examples
├── examples/                      # Groovy pipeline examples
│   ├── 01-hello-world.groovy
│   ├── 02-parameterized-build.groovy
│   ├── 03-multi-stage-pipeline.groovy
│   ├── 04-git-integration.groovy
│   ├── 05-environment-variables.groovy
│   ├── 06-conditional-execution.groovy
│   └── 07-advanced-patterns.groovy
└── 3-Tier/                        # Three-tier application deployment
    ├── ThreeTierWithJenkins.md    # Guide: Deploy three-tier app with Jenkins
    ├── Jenkinsfile                # Main deployment pipeline
    ├── Jenkinsfile.multibranch    # Multi-environment deployment pipeline
    └── scripts/
        ├── check-prerequisites.sh # Check if prerequisites are installed
        ├── health-check.sh        # Health check with retry logic
        └── rollback-jenkins.sh    # Rollback to previous deployment
```

## 🚀 Quick Start

### For First-Time Setup

1. **Set up Jenkins Server**
   - Follow [CreateJenkinsServer.md](./CreateJenkinsServer.md)
   - Install Jenkins on AWS EC2 Ubuntu 24.04
   - Install required plugins (SSH Agent, NodeJS, Git)

2. **Learn Jenkins Basics** (Optional)
   - Follow [StartJenkins.md](./StartJenkins.md)
   - Run sample pipelines to understand Jenkins syntax
   - Familiarize yourself with pipeline structure

3. **Deploy the Application**
   - Follow [ThreeTierWithJenkins.md](./3-Tier/ThreeTierWithJenkins.md)
   - Configure credentials in Jenkins
   - Create pipeline job
   - Deploy to EC2

### For Existing Jenkins Setup

If you already have Jenkins running:

1. **Add Credentials**:
   - SSH private key for EC2 access (ID: `ec2-ssh-key`)
   - Database password (ID: `db-password`)

2. **Create Pipeline Job**:
   - New Item → Pipeline
   - Name: `bmi-app-deployment`
   - Pipeline from SCM → Git
   - Repository: Your repo URL
   - Script Path: `Jenkins/Jenkinsfile`

3. **Build with Parameters**:
   - TARGET_EC2_IP: Your EC2 public IP
   - DB_PASSWORD: PostgreSQL password
   - Click "Build"

## 📖 Documentation

### 1. CreateJenkinsServer.md
**Purpose**: Complete guide for setting up a Jenkins server on AWS EC2.

**Contents**:
- AWS EC2 instance creation (Ubuntu 24.04)
- Security group configuration
- Jenkins installation and setup
- Plugin installation (SSH Agent, NodeJS, Git)
- Initial configuration and security

**When to use**: First time setting up Jenkins, or setting up a new Jenkins server.

### 2. StartJenkins.md
**Purpose**: Learn Jenkins pipeline basics with practical examples.

**Contents**:
- Pipeline syntax introduction
- Example 1: Hello World pipeline
- Example 2: Parameterized builds
- Example 3: Multi-stage pipeline
- Example 4: Git integration
- Example 5: Environment variables
- Example 6: Conditional execution
- Common patterns and troubleshooting

**When to use**: Learning Jenkins, understanding pipeline concepts before deployment.

### 3. ThreeTierWithJenkins.md (in 3-Tier/)
**Purpose**: Complete guide for deploying the BMI application with Jenkins.

**Contents**:
- Architecture overview
- Prerequisites and requirements
- Credentials setup in Jenkins
- Pipeline creation and configuration
- Fresh deployment vs. update deployment
- Webhook configuration (auto-deploy on push)
- Advanced features (approvals, notifications, rollback)
- Comparison: GitHub Actions vs. Jenkins
- Troubleshooting common issues

**When to use**: Deploying the application, configuring CI/CD, troubleshooting deployments.

**Location**: [3-Tier/ThreeTierWithJenkins.md](./3-Tier/ThreeTierWithJenkins.md)

## 🔧 Pipeline Files (in 3-Tier/)

### Jenkinsfile
**Purpose**: Main deployment pipeline for single-environment deployment.

**Location**: [3-Tier/Jenkinsfile](./3-Tier/Jenkinsfile)

**Features**:
- Deploys to a single target EC2 server
- Parameterized builds (backend-only, frontend-only)
- Automatic prerequisite installation (fresh deployments)
- Database setup and migrations
- Backup creation before updates
- Health checks with retry logic
- Rollback on failure

**Parameters**:
- `TARGET_EC2_IP`: Target server IP address
- `DB_PASSWORD`: PostgreSQL password
- `DEPLOY_BACKEND_ONLY`: Deploy only backend
- `DEPLOY_FRONTEND_ONLY`: Deploy only frontend
- `SKIP_HEALTH_CHECK`: Skip health checks
- `SKIP_BACKUP`: Skip backup creation

**Use case**: Standard deployment to production or single environment.

### Jenkinsfile.multibranch
**Purpose**: Multi-branch pipeline for deploying to different environments.

**Location**: [3-Tier/Jenkinsfile.multibranch](./3-Tier/Jenkinsfile.multibranch)

**Features**:
- Automatic environment detection based on Git branch
  - `main` branch → Production environment
  - `staging` branch → Staging environment
  - `develop` branch → Development environment
- Separate EC2 servers per environment
- Separate database credentials per environment
- Approval gate for production deployments
- Parallel backend/frontend deployment
- Environment-specific configuration

**Branch Mapping**:
```
main     → Production (54.123.45.67) [requires approval]
staging  → Staging   (54.123.45.68) [auto-deploy]
develop  → Development (54.123.45.69) [auto-deploy]
```

**Use case**: Teams with multiple environments (dev/staging/prod).

## 🛠️ Scripts (in 3-Tier/scripts/)

### check-prerequisites.sh
**Purpose**: Verify required software is installed on target EC2.

**Location**: [3-Tier/scripts/check-prerequisites.sh](./3-Tier/scripts/check-prerequisites.sh)

**Checks**:
- Node.js and npm
- PostgreSQL (and service status)
- Nginx (and service status)
- PM2
- Git
- Disk space and memory
- Deployment directory existence

**Exit codes**:
- `0`: All prerequisites installed
- `1`: Some prerequisites missing

**Usage**:
```bash
ssh ubuntu@<EC2_IP> 'bash -s' < Jenkins/3-Tier/scripts/check-prerequisites.sh
```

### health-check.sh
**Purpose**: Perform comprehensive health checks with retry logic.

**Location**: [3-Tier/scripts/health-check.sh](./3-Tier/scripts/health-check.sh)

**Checks**:
- Backend API health endpoint
- Frontend HTTP response
- PM2 process status
- Nginx service status
- PostgreSQL service status

**Parameters**:
```bash
./health-check.sh <TARGET_IP> <BACKEND_PORT> <MAX_RETRIES> <RETRY_DELAY>
```

**Example**:
```bash
./health-check.sh 54.123.45.67 3000 5 10
```

**Exit codes**:
- `0`: All critical health checks passed
- `1`: Some health checks failed

### rollback-jenkins.sh
**Purpose**: Rollback to a previous deployment backup.

**Location**: [3-Tier/scripts/rollback-jenkins.sh](./3-Tier/scripts/rollback-jenkins.sh)

**Features**:
- Lists available backups with details
- Interactive or automated rollback (`--auto-latest`)
- Creates backup of current state before rollback
- Restores code, dependencies, and configuration
- Restarts services (PM2, Nginx)
- Performs health checks after rollback

**Usage**:
```bash
# Interactive mode (manual selection)
./rollback-jenkins.sh

# Automated mode (restore latest backup)
./rollback-jenkins.sh --auto-latest
```

## 🔑 Credentials Required

**✅ All credentials use Jenkins Credentials Manager - no secrets hardcoded in code.**

Configure these credentials in Jenkins before deploying. See [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md) for detailed setup instructions.

### Single Environment (Jenkinsfile)

1. **ec2-ssh-key** (SSH Username with private key)
   - Type: SSH Username with private key
   - Username: `ubuntu`
   - Private Key: Your EC2 SSH private key
   - Used for: Connecting to target EC2 server
   - Usage: `sshagent([env.EC2_SSH_KEY_ID])`

2. **db-password** (Secret text)
   - Type: Secret text
   - Secret: PostgreSQL password for `bmi_user`
   - Used for: Database authentication
   - Usage: `withCredentials([string(credentialsId: 'db-password', variable: 'DB_PASS')])`

3. **github-token** (Secret text) - Optional
   - Type: Secret text
   - Secret: GitHub Personal Access Token
   - Used for: Private repository access
   - Usage: `credentialsId: 'github-token'` in Git checkout

### Multi-Environment (Jenkinsfile.multibranch)

Additional environment-specific credentials:
- **db-password-production** (Secret text) - Production DB password
- **db-password-staging** (Secret text) - Staging DB password
- **db-password-dev** (Secret text) - Development DB password

**Security Note:** Credentials are automatically masked in console output and stored encrypted in Jenkins. Never commit credentials to Git.

## 🎯 Deployment Workflows

### Workflow 1: Fresh Deployment to New EC2

```
Jenkins Pipeline Execution:
1. Validate parameters (EC2 IP, DB password)
2. Checkout code from Git
3. Check prerequisites on EC2
4. Install missing prerequisites (Node, PostgreSQL, Nginx, PM2)
5. Setup database (create user, database, run migrations)
6. Deploy to EC2 (clone repository)
7. Deploy backend (npm install, create .env, PM2 start)
8. Deploy frontend (npm build, copy to Nginx)
9. Perform health checks
10. Send success notification

Duration: ~10-15 minutes (first deployment)
```

### Workflow 2: Update Existing Deployment

```
Jenkins Pipeline Execution:
1. Validate parameters
2. Checkout code from Git
3. Check prerequisites (already installed)
4. Create backup of current deployment
5. Deploy to EC2 (git pull latest code)
6. Deploy backend (npm install, PM2 restart)
7. Deploy frontend (npm build, update Nginx)
8. Perform health checks
9. Send success notification
(10. Rollback on failure - if health checks fail)

Duration: ~5-8 minutes (update)
```

### Workflow 3: Multibranch Deployment

```
Git Push to Branch:
1. Developer pushes code to branch (main/staging/develop)
2. GitHub webhook triggers Jenkins
3. Jenkins determines environment based on branch
4. Production: Requires manual approval
5. Staging/Dev: Auto-deploy
6. Deploy to environment-specific EC2 server
7. Health checks
8. Environment-specific notifications

Duration: Varies + approval time for production
```

## 🔄 Comparison with GitHub Actions

| Feature | Jenkins | GitHub Actions |
|---------|---------|----------------|
| **Setup** | Manual server setup | Zero setup (cloud-hosted) |
| **Cost** | EC2 cost (~$30-60/mo) | Free tier: 2000 min/mo |
| **Flexibility** | Highly customizable | Limited to GitHub |
| **Plugins** | 1800+ plugins | Actions marketplace |
| **On-premise** | ✅ Supported | ❌ Cloud only |
| **Multiple SCM** | ✅ Git, SVN, etc. | ❌ GitHub only |
| **Build history** | Unlimited | 90 days |
| **Concurrent builds** | Based on server resources | Based on plan |
| **GUI** | Advanced (Blue Ocean) | Basic |
| **Learning curve** | Steeper | Easier |

**Recommendation**:
- **Use Jenkins if**: Enterprise environment, multiple SCM sources, on-premise requirement, complex workflows
- **Use GitHub Actions if**: GitHub-centric, small team, minimal maintenance, quick setup

## 🐛 Troubleshooting

### Issue: SSH Connection Fails
**Solution**: 
- Verify SSH key in Jenkins credentials
- Check EC2 security group allows Jenkins IP on port 22
- Test SSH manually: `ssh -i key.pem ubuntu@<IP>`

### Issue: Node.js Not Found
**Solution**:
- Configure NodeJS plugin in Jenkins (Manage Jenkins → Tools)
- Or install manually via NVM in pipeline

### Issue: PM2 Process Not Starting
**Solution**:
- Check PM2 logs: `pm2 logs bmi-backend`
- Verify `.env` file exists and has correct values
- Check if port 3000 is available

### Issue: Health Check Fails
**Solution**:
- Increase retry count and delay in health-check.sh
- Check backend logs: `pm2 logs`
- Check Nginx logs: `sudo tail /var/log/nginx/error.log`
- Verify services are running: `pm2 status`, `sudo systemctl status nginx`

### Issue: Pipeline Hangs
**Solution**:
- Add timeout to stages: `timeout(time: 10, unit: 'MINUTES')`
- Check for interactive prompts (apt asking for confirmation)
- Use non-interactive flags: `apt-get install -y`

For more troubleshooting, see [ThreeTierWithJenkins.md](./3-Tier/ThreeTierWithJenkins.md#troubleshooting).

## 📚 Additional Resources

### Jenkins Integration Documentation
- [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md) - Complete guide to Jenkins Credentials Manager usage
- [CreateJenkinsServer.md](./CreateJenkinsServer.md) - Set up Jenkins server on AWS EC2
- [StartJenkins.md](./StartJenkins.md) - Learn Jenkins pipeline basics
- [ThreeTierWithJenkins.md](./3-Tier/ThreeTierWithJenkins.md) - Deploy three-tier application

### Example Groovy Pipelines
- [examples/01-hello-world.groovy](./examples/01-hello-world.groovy) - Basic pipeline verification
- [examples/02-parameterized-build.groovy](./examples/02-parameterized-build.groovy) - User input parameters
- [examples/03-multi-stage-pipeline.groovy](./examples/03-multi-stage-pipeline.groovy) - Build/Test/Deploy workflow
- [examples/04-git-integration.groovy](./examples/04-git-integration.groovy) - Git checkout with credentials
- [examples/05-environment-variables.groovy](./examples/05-environment-variables.groovy) - Variable management
- [examples/06-conditional-execution.groovy](./examples/06-conditional-execution.groovy) - When directives, approvals
- [examples/07-advanced-patterns.groovy](./examples/07-advanced-patterns.groovy) - Parallel execution, error handling

### Official Jenkins Resources
- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **Pipeline Syntax**: https://www.jenkins.io/doc/book/pipeline/syntax/
- **Jenkins Plugins**: https://plugins.jenkins.io/
- **Blue Ocean (Modern UI)**: https://www.jenkins.io/projects/blueocean/
- **Best Practices**: https://www.jenkins.io/doc/book/pipeline/pipeline-best-practices/
- **Credentials Plugin**: https://plugins.jenkins.io/credentials/

## 🤝 Contributing

When adding new Jenkins files or updating pipelines:

1. Update this README.md
2. Add comments to Jenkinsfiles
3. Create/update documentation in markdown files
4. Test thoroughly before committing
5. Update version info in files

## 📝 License

This Jenkins integration follows the same license as the main BMI Health Tracker project.

---

**Version**: 1.0  
**Last Updated**: December 30, 2025  
**Maintained by**: DevOps Team  
**Project**: BMI Health Tracker - Jenkins Integration
