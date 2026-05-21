# Deploy Three-Tier BMI Application with Jenkins

This comprehensive guide demonstrates how to deploy the BMI Health Tracker three-tier web application to AWS EC2 using Jenkins CI/CD pipelines. You'll learn to configure Jenkins, create deployment pipelines, manage credentials, and automate the entire deployment process.

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Jenkins Configuration](#jenkins-configuration)
4. [Credentials Setup](#credentials-setup)
5. [Pipeline Strategy](#pipeline-strategy)
6. [Create Deployment Pipeline](#create-deployment-pipeline)
7. [Deploy to Fresh EC2 Server](#deploy-to-fresh-ec2-server)
8. [Deploy to Existing Server](#deploy-to-existing-server)
9. [Webhook Configuration](#webhook-configuration)
10. [Advanced Features](#advanced-features)
11. [Comparison: GitHub Actions vs Jenkins](#comparison-github-actions-vs-jenkins)
12. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Application Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    USER BROWSER                              │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP/HTTPS
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  EC2 TARGET SERVER (Ubuntu 24.04)                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  NGINX (Port 80)                                      │   │
│  │  - Serves React frontend (static files)              │   │
│  │  - Reverse proxy /api/* → localhost:3000             │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────▼───────────────────────────────┐   │
│  │  EXPRESS BACKEND (Port 3000)                          │   │
│  │  - REST API endpoints                                 │   │
│  │  - BMI/BMR calculations                               │   │
│  │  - PM2 process management                             │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────▼───────────────────────────────┐   │
│  │  POSTGRESQL (Port 5432)                               │   │
│  │  - Database: bmidb                                    │   │
│  │  - User: bmi_user                                     │   │
│  │  - Table: measurements                                │   │
│  └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Jenkins CI/CD Flow

```
┌──────────────────────────────────────────────────────────────┐
│  DEVELOPER WORKFLOW                                          │
└───────────────┬──────────────────────────────────────────────┘
                │
                ▼ (git push)
┌─────────────────────────────────────────────────────────────┐
│  GITHUB REPOSITORY                                          │
│  - Source code (React + Express)                            │
│  - Jenkinsfile                                              │
│  - Deployment scripts                                        │
└───────────────┬─────────────────────────────────────────────┘
                │
                ▼ (webhook/poll SCM)
┌─────────────────────────────────────────────────────────────┐
│  JENKINS SERVER (EC2 Ubuntu 24.04)                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  PIPELINE STAGES:                                     │   │
│  │  1. Checkout Code from Git                           │   │
│  │  2. Install Prerequisites (Node, PostgreSQL, PM2)    │   │
│  │  3. Setup Database (create DB, run migrations)       │   │
│  │  4. Create Backup (existing deployment)              │   │
│  │  5. Deploy Backend (npm install, PM2 restart)        │   │
│  │  6. Deploy Frontend (npm build, copy to Nginx)       │   │
│  │  7. Health Checks (backend API, frontend page)       │   │
│  │  8. Notifications (email/Slack on success/failure)   │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────┬─────────────────────────────────────────────┘
                │
                ▼ (SSH connection)
┌─────────────────────────────────────────────────────────────┐
│  TARGET EC2 SERVER                                          │
│  - Application deployed                                     │
│  - Services running (PM2, Nginx, PostgreSQL)                │
│  - Health checks passing                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### 1. Jenkins Server Requirements

Ensure you have a Jenkins server set up (see [CreateJenkinsServer.md](./CreateJenkinsServer.md)):
- **OS**: Ubuntu 24.04 LTS
- **Instance Type**: t3.medium minimum (2 vCPU, 4 GB RAM)
- **Jenkins Version**: LTS (2.440+)
- **Java**: OpenJDK 17
- **Installed Plugins**:
  - SSH Agent Plugin
  - Publish Over SSH (optional)
  - NodeJS Plugin
  - Git Plugin
  - Pipeline Plugin
  - Credentials Plugin

### 2. Target EC2 Server Requirements

The server where the application will be deployed:
- **OS**: Ubuntu 22.04 or 24.04 LTS
- **Instance Type**: t2.medium or larger
- **Storage**: 20+ GB
- **Security Groups**:
  - Port 22 (SSH) - accessible from Jenkins server
  - Port 80 (HTTP) - accessible from internet (0.0.0.0/0)
  - Port 443 (HTTPS) - optional for SSL
  - Port 3000 - internal only (backend)
  - Port 5432 - internal only (PostgreSQL)

### 3. Required Information

Collect these details before proceeding:
- **Target EC2 Public IP**: `e.g., 54.123.45.67`
- **SSH Private Key**: For connecting from Jenkins to target EC2
- **GitHub Repository URL**: `https://github.com/your-username/single-server-3tier-webapp`
- **Database Password**: For PostgreSQL `bmi_user` account

### 4. Network Configuration

- **Jenkins → Target EC2**: SSH access (port 22)
- **Users → Target EC2**: HTTP access (port 80)
- Ensure Jenkins server can reach target EC2 (same VPC or public IP with security group rules)

---

## Jenkins Configuration

Configure Jenkins global tools and settings before creating pipelines.

### Step 1: Configure NodeJS

1. **Manage Jenkins** → **Tools** (or **Global Tool Configuration**)
2. **Scroll to "NodeJS installations"**
3. **Click "Add NodeJS"**

**Configuration:**
```
Name: NodeJS-20-LTS
☑ Install automatically
  Install from nodejs.org
  Version: NodeJS 20.11.0 (or latest LTS)

Global npm packages to install:
  pm2

Global npm packages refresh hours: 72
```

4. **Click "Save"**

### Step 2: Configure Git (Usually Pre-configured)

Verify Git is configured:
1. **Manage Jenkins** → **Tools**
2. **Scroll to "Git installations"**
3. Should show:
   ```
   Name: Default
   Path to Git executable: git
   ```

### Step 3: Install GitHub Repository Plugin

If you want webhook integration:
1. **Manage Jenkins** → **Plugins** → **Available plugins**
2. **Search**: `GitHub Plugin`
3. **Install** and **restart Jenkins**

---

## Credentials Setup

Store sensitive information securely in Jenkins credentials.

### Credential 1: SSH Private Key (EC2 Access)

1. **Manage Jenkins** → **Credentials** → **System** → **Global credentials (unrestricted)**
2. **Click "Add Credentials"**

**Configuration:**
```
Kind: SSH Username with private key
Scope: Global
ID: ec2-ssh-key
Description: SSH key for target EC2 server
Username: ubuntu
Private Key: ☑ Enter directly
  ┌─────────────────────────────────────┐
  │ -----BEGIN RSA PRIVATE KEY-----     │
  │ MIIEpAIBAAKCAQEA...                 │
  │ ... (paste full private key)        │
  │ -----END RSA PRIVATE KEY-----       │
  └─────────────────────────────────────┘
Passphrase: (leave empty if key has no passphrase)
```

3. **Click "Create"**

**How to get private key:**
```bash
# On your local machine, display your .pem key
cat ~/path/to/your-key.pem

# Copy the entire output including BEGIN/END lines
```

### Credential 2: Database Password

1. **Add Credentials** (same location as above)

**Configuration:**
```
Kind: Secret text
Scope: Global
Secret: YourStrongDatabasePassword123!
ID: db-password
Description: PostgreSQL password for bmi_user
```

2. **Click "Create"**

### Credential 3: GitHub Personal Access Token (Optional)

Only needed for private repositories or to avoid rate limits:

1. **Generate token on GitHub**:
   - GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate new token
   - Scopes: `repo` (full repository access)
   - Copy the token (shown only once!)

2. **Add to Jenkins**:
   ```
   Kind: Secret text
   Scope: Global
   Secret: ghp_xxxxxxxxxxxxxxxxxxxx (your token)
   ID: github-token
   Description: GitHub Personal Access Token
   ```

### Credential 4: Target EC2 Host (String Parameter)

While not a "secret", store it as a credential for easy updates:

```
Kind: Secret text
Scope: Global
Secret: 54.123.45.67 (your target EC2 public IP)
ID: target-ec2-host
Description: Target EC2 server IP address
```

**Or**, use it as a pipeline parameter (see pipeline examples below).

---

## Pipeline Strategy

### Deployment Scenarios

We'll create pipelines for two common scenarios:

#### Scenario 1: Fresh EC2 Server Deployment
- Target EC2 has no prerequisites installed
- First-time deployment
- Pipeline installs: Node.js, PostgreSQL, Nginx, PM2
- Creates database, user, tables
- Deploys application from scratch

#### Scenario 2: Existing Deployment Update
- Prerequisites already installed
- Application already running
- Pipeline: creates backup, pulls latest code, restarts services
- Zero-downtime deployment using PM2 reload

### Pipeline Stages

Both pipelines follow this general flow:

```
1. Checkout Code        → Clone Git repository
2. Check Prerequisites  → Verify Node, PostgreSQL, Nginx installed
3. Install Missing      → Install any missing prerequisites
4. Setup Database       → Create DB, user, run migrations
5. Create Backup        → Backup existing deployment (if exists)
6. Deploy Backend       → npm install, create .env, PM2 restart
7. Deploy Frontend      → npm install, npm build, copy to Nginx
8. Health Checks        → Verify backend API and frontend page
9. Rollback (on fail)   → Restore backup if health checks fail
10. Notify              → Send email/Slack notification
```

### Pipeline Files Structure

```
Jenkins/
├── Jenkinsfile                    # Main deployment pipeline
├── Jenkinsfile.multibranch        # Multi-branch pipeline
├── scripts/
│   ├── check-prerequisites.sh     # Check if Node, PostgreSQL installed
│   ├── deploy-backend-jenkins.sh  # Backend deployment logic
│   ├── deploy-frontend-jenkins.sh # Frontend deployment logic
│   ├── health-check.sh            # Health check with retry logic
│   └── rollback-jenkins.sh        # Rollback to previous deployment
```

---

## Create Deployment Pipeline

### Method 1: Pipeline Job (Simple)

Create a basic pipeline job that reads Jenkinsfile from repository.

#### Step 1: Create Pipeline Job

1. **Jenkins Dashboard** → **New Item**
2. **Enter name**: `bmi-app-deployment`
3. **Select**: **Pipeline**
4. **Click OK**

#### Step 2: Configure Pipeline

**General Section:**
```
☑ Discard old builds
  Strategy: Log Rotation
  Max # of builds to keep: 10
```

**Build Triggers:**
```
☑ Poll SCM
  Schedule: H/5 * * * *
  (Check for changes every 5 minutes)
```

**Or for webhook (preferred):**
```
☑ GitHub hook trigger for GITScm polling
```

**Pipeline Section:**
```
Definition: Pipeline script from SCM

SCM: Git
  Repository URL: https://github.com/your-username/single-server-3tier-webapp-github-actions.git
  Credentials: (none for public repo, or select github-token)
  Branch Specifier: */main

Script Path: Jenkins/Jenkinsfile

☑ Lightweight checkout
```

#### Step 3: Add Parameters

Click **"This project is parameterized"** and add:

**Parameter 1: Target EC2 IP**
```
Type: String Parameter
Name: TARGET_EC2_IP
Default Value: 54.123.45.67 (or use credential)
Description: Public IP address of target EC2 server
```

**Parameter 2: Deploy Backend Only**
```
Type: Boolean Parameter
Name: DEPLOY_BACKEND_ONLY
Default Value: false
Description: Deploy only backend (skip frontend)
```

**Parameter 3: Deploy Frontend Only**
```
Type: Boolean Parameter
Name: DEPLOY_FRONTEND_ONLY
Default Value: false
Description: Deploy only frontend (skip backend)
```

**Parameter 4: Skip Health Check**
```
Type: Boolean Parameter
Name: SKIP_HEALTH_CHECK
Default Value: false
Description: Skip health checks (use with caution)
```

**Parameter 5: Database Password**
```
Type: Password Parameter
Name: DB_PASSWORD
Default Value: (leave empty - will use credential)
Description: PostgreSQL database password
```

#### Step 4: Save and Build

1. **Click "Save"**
2. **Click "Build with Parameters"**
3. **Fill in parameters** and click **"Build"**

### Method 2: Multibranch Pipeline (Advanced)

For projects with multiple branches (dev, staging, main):

1. **New Item** → Name: `bmi-app-multibranch` → **Multibranch Pipeline**
2. **Branch Sources** → **Add source** → **Git**
   - Project Repository: `https://github.com/your-username/repo.git`
   - Credentials: (if private repo)
3. **Build Configuration**:
   - Mode: by Jenkinsfile
   - Script Path: `Jenkins/Jenkinsfile.multibranch`
4. **Scan Multibranch Pipeline Triggers**:
   - ☑ Periodically if not otherwise run
   - Interval: 5 minutes
5. **Save**

Jenkins will automatically discover branches with Jenkinsfile and create pipelines for each.

---

## Deploy to Fresh EC2 Server

This scenario deploys to a brand-new EC2 instance with no prerequisites installed.

### Prerequisites

- **Fresh EC2 Ubuntu 24.04** instance running
- **SSH access** from Jenkins server
- **Security groups** configured (ports 22, 80, 3000, 5432)

### The Jenkinsfile

The main `Jenkins/Jenkinsfile` handles fresh deployment. Here's an overview (full file created in next step):

```groovy
pipeline {
    agent any
    
    parameters {
        string(name: 'TARGET_EC2_IP', defaultValue: '', description: 'Target EC2 public IP')
        password(name: 'DB_PASSWORD', defaultValue: '', description: 'Database password')
        booleanParam(name: 'DEPLOY_BACKEND_ONLY', defaultValue: false)
        booleanParam(name: 'DEPLOY_FRONTEND_ONLY', defaultValue: false)
        booleanParam(name: 'SKIP_HEALTH_CHECK', defaultValue: false)
    }
    
    environment {
        REPO_URL = 'https://github.com/your-username/single-server-3tier-webapp-github-actions.git'
        BRANCH = 'main'
        EC2_USER = 'ubuntu'
        DEPLOY_PATH = '/home/ubuntu/single-server-3tier-webapp'
    }
    
    stages {
        stage('Validate Parameters') { /* ... */ }
        stage('Checkout Code') { /* ... */ }
        stage('Check Prerequisites') { /* ... */ }
        stage('Install Prerequisites') { /* ... */ }
        stage('Setup Database') { /* ... */ }
        stage('Create Backup') { /* ... */ }
        stage('Deploy Backend') { /* ... */ }
        stage('Deploy Frontend') { /* ... */ }
        stage('Health Checks') { /* ... */ }
    }
    
    post {
        success { /* Send success notification */ }
        failure { /* Rollback and notify */ }
    }
}
```

### Execute Deployment

1. **Open pipeline job**: `bmi-app-deployment`
2. **Click "Build with Parameters"**
3. **Fill in parameters**:
   - TARGET_EC2_IP: `54.123.45.67`
   - DB_PASSWORD: `YourStrongPassword123!`
   - Others: Leave defaults (false)
4. **Click "Build"**

### Monitor Progress

1. **Build appears** in "Build History"
2. **Click on build number** (e.g., #1)
3. **Click "Console Output"** to see real-time logs
4. **Or click "Pipeline Steps"** for visual stage view

### Expected Output (Abbreviated)

```
Started by user admin
[Pipeline] Start of Pipeline
[Pipeline] node
[Pipeline] stage (Validate Parameters)
✅ Parameter validation passed
[Pipeline] stage (Checkout Code)
Checking out from Git: https://github.com/...
✅ Code checked out successfully
[Pipeline] stage (Check Prerequisites)
Checking for Node.js... NOT FOUND
Checking for PostgreSQL... NOT FOUND
Checking for Nginx... NOT FOUND
Checking for PM2... NOT FOUND
[Pipeline] stage (Install Prerequisites)
Installing NVM and Node.js LTS...
✅ Node.js v20.11.0 installed
Installing PostgreSQL...
✅ PostgreSQL 14.10 installed
Installing Nginx...
✅ Nginx 1.24.0 installed
Installing PM2...
✅ PM2 5.3.0 installed
[Pipeline] stage (Setup Database)
Creating database user 'bmi_user'...
Creating database 'bmidb'...
Running migrations...
✅ Database setup completed
[Pipeline] stage (Deploy Backend)
Installing backend dependencies...
Creating .env file...
Starting PM2 process 'bmi-backend'...
✅ Backend deployed successfully
[Pipeline] stage (Deploy Frontend)
Installing frontend dependencies...
Building frontend (npm run build)...
Copying to /var/www/bmi-health-tracker...
Configuring Nginx...
✅ Frontend deployed successfully
[Pipeline] stage (Health Checks)
Testing backend: http://54.123.45.67:3000/health
✅ Backend health check passed
Testing frontend: http://54.123.45.67/
✅ Frontend health check passed
[Pipeline] End of Pipeline
✅ Pipeline succeeded! 🎉
Finished: SUCCESS
```

### Verify Deployment

1. **Open browser**: `http://54.123.45.67`
2. **You should see**: BMI Health Tracker application
3. **Test functionality**:
   - Enter weight, height, age, sex, activity level
   - Click "Calculate"
   - View results and trend chart

---

## Deploy to Existing Server

Update an already-deployed application with new code changes.

### Prerequisites

- Application already deployed (prerequisites installed)
- PM2 process `bmi-backend` running
- Nginx serving frontend

### Pipeline Behavior

When deploying to existing server, the pipeline:
1. **Skips prerequisite installation** (detects already installed)
2. **Creates backup** before updating
3. **Pulls latest code** from Git
4. **Reinstalls dependencies** (npm install)
5. **Restarts PM2 process** (zero-downtime)
6. **Rebuilds frontend** and updates Nginx
7. **Performs health checks**
8. **Rolls back on failure**

### Execute Update

1. **Make changes** to your application code
2. **Commit and push** to GitHub:
   ```bash
   git add .
   git commit -m "Update BMI calculation logic"
   git push origin main
   ```
3. **Jenkins pipeline** triggers automatically (if webhook configured)
4. **Or manually trigger**: "Build with Parameters" → Build

### Selective Deployment

**Backend Only Update:**
```
DEPLOY_BACKEND_ONLY: ☑ true
DEPLOY_FRONTEND_ONLY: ☐ false
```
Use when: Only backend code changed (e.g., API routes, database logic)

**Frontend Only Update:**
```
DEPLOY_BACKEND_ONLY: ☐ false
DEPLOY_FRONTEND_ONLY: ☑ true
```
Use when: Only frontend code changed (e.g., React components, styling)

**Full Deployment:**
```
DEPLOY_BACKEND_ONLY: ☐ false
DEPLOY_FRONTEND_ONLY: ☐ false
```
Use when: Both backend and frontend changed

### Backup Management

Backups are stored in: `/home/ubuntu/bmi_deployments_backup/`

**List backups:**
```bash
ssh ubuntu@54.123.45.67
ls -lh ~/bmi_deployments_backup/
```

**Output:**
```
backup_20251230_103045/  # Created before deployment
backup_20251229_150230/
backup_20251228_092145/
backup_20251227_173022/
backup_20251226_114538/
```

Pipeline keeps **last 5 backups**, automatically deleting older ones.

### Rollback

If deployment fails or issues arise, rollback to previous version:

#### Option 1: Via Pipeline Parameter

Add this parameter to your pipeline:
```groovy
booleanParam(name: 'ROLLBACK', defaultValue: false, description: 'Rollback to previous deployment')
```

Then build with `ROLLBACK: true`

#### Option 2: Manual Rollback Script

SSH into target EC2 and run:
```bash
cd /home/ubuntu/single-server-3tier-webapp/scripts
./rollback.sh
```

Follow prompts to select backup and restore.

#### Option 3: Jenkins Rollback Job

Create separate Jenkins job:
1. **New Item** → Name: `bmi-app-rollback` → Pipeline
2. **Pipeline script**:
   ```groovy
   pipeline {
       agent any
       parameters {
           string(name: 'TARGET_EC2_IP', description: 'EC2 IP')
           choice(name: 'BACKUP_TO_RESTORE', choices: ['latest', 'select'], description: 'Which backup?')
       }
       stages {
           stage('Rollback') {
               steps {
                   sshagent(['ec2-ssh-key']) {
                       sh """
                           ssh -o StrictHostKeyChecking=no ubuntu@${params.TARGET_EC2_IP} '
                               cd /home/ubuntu/single-server-3tier-webapp/scripts
                               ./rollback.sh --auto-latest
                           '
                       """
                   }
               }
           }
       }
   }
   ```

---

## Webhook Configuration

Automatically trigger Jenkins pipeline when code is pushed to GitHub.

### Step 1: Configure GitHub Webhook

1. **GitHub Repository** → **Settings** → **Webhooks** → **Add webhook**

**Webhook Configuration:**
```
Payload URL: http://<JENKINS_IP>:8080/github-webhook/
  Example: http://3.87.45.123:8080/github-webhook/

Content type: application/json

Secret: (leave empty or set matching Jenkins)

Which events:
  ☑ Just the push event

Active: ☑ Enabled
```

2. **Click "Add webhook"**
3. **Verify**: GitHub shows ✅ green checkmark after first delivery

### Step 2: Configure Jenkins Job

In your pipeline job configuration:

**Build Triggers:**
```
☑ GitHub hook trigger for GITScm polling
```

**Save the job**

### Step 3: Test Webhook

1. **Make a code change** and push to GitHub:
   ```bash
   echo "// Test webhook" >> backend/src/server.js
   git add .
   git commit -m "Test webhook trigger"
   git push origin main
   ```

2. **Watch Jenkins**: Build should start automatically within seconds
3. **Verify on GitHub**: Settings → Webhooks → Click webhook → "Recent Deliveries" shows success

### Troubleshooting Webhook

**Webhook not triggering:**

1. **Check Jenkins is publicly accessible**:
   ```bash
   curl http://<JENKINS_IP>:8080/
   ```

2. **Check Jenkins GitHub plugin installed**:
   - Manage Jenkins → Plugins → Installed → Search "GitHub"

3. **Check webhook deliveries on GitHub**:
   - Repository → Settings → Webhooks → Click webhook
   - See response codes (should be 200)

4. **Check Jenkins logs**:
   - Manage Jenkins → System Log → Add new recorder
   - Name: `github-webhook`
   - Loggers: `com.cloudbees.jenkins.GitHubWebHook` (ALL)

5. **Security Group**: Ensure Jenkins port 8080 accessible from GitHub IPs

**Alternative: Poll SCM**

If webhook doesn't work (Jenkins behind firewall):
```
Build Triggers:
  ☑ Poll SCM
  Schedule: H/5 * * * *  (every 5 minutes)
```

---

## Advanced Features

### Feature 1: Multi-Environment Deployment

Deploy to different environments (dev, staging, production) from same pipeline.

**Add parameter:**
```groovy
parameters {
    choice(
        name: 'ENVIRONMENT',
        choices: ['dev', 'staging', 'production'],
        description: 'Target environment'
    )
}
```

**Use in pipeline:**
```groovy
environment {
    TARGET_IP = "${params.ENVIRONMENT == 'production' ? '54.1.2.3' : params.ENVIRONMENT == 'staging' ? '54.1.2.4' : '54.1.2.5'}"
}
```

### Feature 2: Approval Gate for Production

Require manual approval before production deployment:

```groovy
stage('Approval for Production') {
    when {
        expression { params.ENVIRONMENT == 'production' }
    }
    steps {
        timeout(time: 1, unit: 'HOURS') {
            input message: 'Deploy to PRODUCTION?',
                  ok: 'Deploy',
                  submitter: 'admin,ops-team'
        }
    }
}
```

### Feature 3: Slack Notifications

Send deployment notifications to Slack channel:

1. **Install Slack Notification Plugin**:
   - Manage Jenkins → Plugins → Available → "Slack Notification"

2. **Configure Slack**:
   - Create Slack app: https://api.slack.com/apps
   - Add "Incoming Webhooks"
   - Copy webhook URL

3. **Add to Jenkins**:
   - Manage Jenkins → System → Slack
   - Workspace: `your-workspace`
   - Credential: Add webhook URL as secret text
   - Default channel: `#deployments`
   - Test connection

4. **Use in pipeline**:
   ```groovy
   post {
       success {
           slackSend(
               color: 'good',
               message: "✅ Deployment succeeded! ${env.JOB_NAME} #${env.BUILD_NUMBER}\nURL: ${env.BUILD_URL}"
           )
       }
       failure {
           slackSend(
               color: 'danger',
               message: "❌ Deployment failed! ${env.JOB_NAME} #${env.BUILD_NUMBER}\nURL: ${env.BUILD_URL}"
           )
       }
   }
   ```

### Feature 4: Email Notifications

Send email alerts on deployment status:

1. **Configure Email**:
   - Manage Jenkins → System → Extended E-mail Notification
   - SMTP server: `smtp.gmail.com`
   - SMTP port: `465`
   - Use SSL: ☑
   - Credentials: Add Gmail app password

2. **Use in pipeline**:
   ```groovy
   post {
       always {
           emailext(
               subject: "Jenkins: ${currentBuild.currentResult} - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
               body: """
                   <h2>Deployment ${currentBuild.currentResult}</h2>
                   <p>Job: ${env.JOB_NAME}</p>
                   <p>Build: ${env.BUILD_NUMBER}</p>
                   <p>Duration: ${currentBuild.durationString}</p>
                   <p>URL: ${env.BUILD_URL}</p>
               """,
               to: 'team@example.com',
               mimeType: 'text/html'
           )
       }
   }
   ```

### Feature 5: Parallel Deployment

Deploy backend and frontend simultaneously (faster):

```groovy
stage('Deploy Application') {
    parallel {
        stage('Deploy Backend') {
            when {
                expression { !params.DEPLOY_FRONTEND_ONLY }
            }
            steps {
                script {
                    sshagent(['ec2-ssh-key']) {
                        sh './Jenkins/scripts/deploy-backend-jenkins.sh'
                    }
                }
            }
        }
        
        stage('Deploy Frontend') {
            when {
                expression { !params.DEPLOY_BACKEND_ONLY }
            }
            steps {
                script {
                    sshagent(['ec2-ssh-key']) {
                        sh './Jenkins/scripts/deploy-frontend-jenkins.sh'
                    }
                }
            }
        }
    }
}
```

### Feature 6: Deployment Dashboard

Create a view showing all deployment pipelines:

1. **Jenkins Dashboard** → **New View**
2. **Name**: `Deployment Pipelines`
3. **Type**: List View
4. **Job Filters**: Select your deployment jobs
5. **Columns**: Status, Weather, Name, Last Success, Last Failure, Last Duration
6. **Save**

### Feature 7: Build Artifacts

Archive build artifacts for troubleshooting:

```groovy
post {
    always {
        archiveArtifacts(
            artifacts: 'backend/logs/*.log, frontend/dist/**',
            allowEmptyArchive: true
        )
    }
}
```

---

## Comparison: GitHub Actions vs Jenkins

### Overview

Both tools can deploy the BMI application, but they have different strengths.

| Aspect | GitHub Actions | Jenkins |
|--------|----------------|---------|
| **Hosting** | Cloud-hosted (free for public repos) | Self-hosted (requires EC2 instance) |
| **Cost** | Free tier: 2,000 min/month<br>After: $0.008/min | EC2 cost only (~$30-60/month for t3.medium) |
| **Setup Complexity** | Minimal (yaml file in repo) | Moderate (server setup, plugins) |
| **Maintenance** | None (managed by GitHub) | Required (updates, backups, security) |
| **Integration** | Native GitHub integration | Requires webhook/plugin configuration |
| **Flexibility** | Limited to GitHub ecosystem | Can integrate with any SCM (Git, SVN, etc.) |
| **Pipeline Syntax** | YAML | Groovy (Declarative or Scripted) |
| **GUI** | Basic (Actions tab) | Advanced (Blue Ocean, custom views) |
| **Secrets Management** | GitHub Secrets | Jenkins Credentials (more flexible) |
| **Concurrent Builds** | Limited by plan | Unlimited (limited by server resources) |
| **Plugins** | Actions marketplace | 1800+ Jenkins plugins |
| **Build History** | 90 days retention | Unlimited (configurable) |
| **Access Control** | Repository permissions | Fine-grained RBAC |
| **Debugging** | Re-run with debug logging | Full console access, job replay |
| **Notifications** | Limited (email, webhooks) | Extensive (email, Slack, Discord, etc.) |

### When to Use GitHub Actions

✅ **Best for:**
- **Small to medium projects** with GitHub repositories
- **Open source projects** (free unlimited minutes)
- **Teams without DevOps expertise** (easier setup)
- **Minimal maintenance** requirements
- **Quick prototyping** and simple CI/CD needs
- **GitHub-centric workflow** (issues, PRs, releases)

❌ **Not ideal for:**
- **Complex multi-stage pipelines** with many conditionals
- **Multiple SCM sources** (GitLab, Bitbucket, internal Git)
- **High-frequency builds** (can hit minute limits)
- **On-premise deployments** (no cloud connectivity)
- **Advanced customization** needs

### When to Use Jenkins

✅ **Best for:**
- **Enterprise environments** with complex requirements
- **Multiple projects** and repositories (all SCMs)
- **High build frequency** (hundreds of builds/day)
- **On-premise infrastructure** requirements
- **Advanced workflows** (approvals, manual triggers, complex conditionals)
- **Custom integrations** (internal tools, proprietary systems)
- **Long build history** retention
- **Teams with Jenkins expertise**

❌ **Not ideal for:**
- **Small teams** without dedicated DevOps
- **Projects requiring minimal CI/CD**
- **Quick setup** needs (takes time to configure properly)
- **No maintenance budget**

### Migration Path

**From GitHub Actions to Jenkins:**
1. Set up Jenkins server (this guide)
2. Convert `.github/workflows/deploy.yml` to `Jenkins/Jenkinsfile`
3. Move secrets from GitHub to Jenkins credentials
4. Configure webhook for automatic triggers
5. Test thoroughly before disabling GitHub Actions
6. Keep GitHub Actions as backup initially

**From Jenkins to GitHub Actions:**
1. Convert `Jenkinsfile` to `.github/workflows/*.yml`
2. Move Jenkins credentials to GitHub secrets
3. Remove webhook, enable GitHub Actions
4. Test deployments
5. Decommission Jenkins server (if no other uses)

### Hybrid Approach

Use both for different purposes:
- **GitHub Actions**: PR validation, unit tests, linting
- **Jenkins**: Production deployments, integration tests, scheduled jobs

**Example:**
```
Developer pushes code
  ↓
GitHub Actions: Run tests, lint code
  ↓ (if passed)
Trigger Jenkins via webhook
  ↓
Jenkins: Deploy to staging/production
```

---

## Troubleshooting

### Issue 1: SSH Connection Fails

**Symptoms:**
```
ERROR: Permission denied (publickey)
```

**Solutions:**

1. **Verify SSH key credential**:
   ```bash
   # On Jenkins server, test SSH manually
   ssh -i /path/to/key.pem ubuntu@54.123.45.67
   ```

2. **Check credential ID matches**:
   ```groovy
   sshagent(['ec2-ssh-key']) {  // Must match credential ID
       // ...
   }
   ```

3. **Verify key format**:
   - Jenkins needs complete key including headers
   - `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`

4. **Check security group**:
   - Target EC2 port 22 must allow Jenkins server IP

5. **StrictHostKeyChecking**:
   ```groovy
   sh """
       ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_IP} 'commands'
   """
   ```

### Issue 2: "Node.js Not Found" in Pipeline

**Symptoms:**
```
sh: npm: command not found
```

**Solutions:**

1. **Configure NodeJS plugin**:
   - Manage Jenkins → Tools → NodeJS installations
   - Add installation with name (e.g., "NodeJS-20-LTS")

2. **Use tools block in pipeline**:
   ```groovy
   tools {
       nodejs 'NodeJS-20-LTS'  // Must match name in global config
   }
   ```

3. **Or install manually in pipeline**:
   ```groovy
   stage('Install Node') {
       steps {
           sshagent(['ec2-ssh-key']) {
               sh """
                   ssh ubuntu@${TARGET_IP} '
                       curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
                       source ~/.nvm/nvm.sh
                       nvm install --lts
                       nvm use --lts
                   '
               """
           }
       }
   }
   ```

### Issue 3: Database Connection Fails

**Symptoms:**
```
ERROR: password authentication failed for user "bmi_user"
```

**Solutions:**

1. **Verify credential binding**:
   ```groovy
   withCredentials([string(credentialsId: 'db-password', variable: 'DB_PASS')]) {
       sh """
           ssh ubuntu@${TARGET_IP} '
               echo "DB_PASSWORD=${DB_PASS}" >> /path/to/.env
           '
       """
   }
   ```

2. **Check PostgreSQL authentication**:
   ```bash
   # On target EC2
   sudo nano /etc/postgresql/14/main/pg_hba.conf
   
   # Should have:
   local   all   bmi_user   md5
   host    all   bmi_user   127.0.0.1/32   md5
   ```

3. **Test connection manually**:
   ```bash
   ssh ubuntu@54.123.45.67
   psql -U bmi_user -d bmidb -h localhost
   # Enter password when prompted
   ```

4. **Check database exists**:
   ```bash
   sudo -u postgres psql -c "\l" | grep bmidb
   ```

### Issue 4: PM2 Process Not Starting

**Symptoms:**
```
[PM2] Process bmi-backend not found
```

**Solutions:**

1. **Check PM2 list**:
   ```bash
   ssh ubuntu@54.123.45.67
   pm2 list
   ```

2. **Start manually to see error**:
   ```bash
   cd /home/ubuntu/single-server-3tier-webapp/backend
   pm2 start src/server.js --name bmi-backend
   pm2 logs bmi-backend
   ```

3. **Common issues**:
   - Missing `.env` file
   - Wrong Node version
   - Port 3000 already in use
   - Missing dependencies

4. **Kill conflicting process**:
   ```bash
   sudo lsof -i :3000
   sudo kill -9 <PID>
   ```

### Issue 5: Nginx 403 Forbidden

**Symptoms:**
```
403 Forbidden when accessing http://<IP>
```

**Solutions:**

1. **Check permissions**:
   ```bash
   ssh ubuntu@54.123.45.67
   ls -lh /var/www/bmi-health-tracker
   # Should be owned by www-data or have 755 permissions
   ```

2. **Fix permissions**:
   ```bash
   sudo chown -R www-data:www-data /var/www/bmi-health-tracker
   sudo chmod -R 755 /var/www/bmi-health-tracker
   ```

3. **Check Nginx config**:
   ```bash
   sudo nginx -t
   cat /etc/nginx/sites-available/bmi-health-tracker
   ```

4. **Check Nginx error logs**:
   ```bash
   sudo tail -50 /var/log/nginx/error.log
   ```

5. **Verify index.html exists**:
   ```bash
   ls /var/www/bmi-health-tracker/index.html
   ```

### Issue 6: Health Check Fails

**Symptoms:**
```
ERROR: Health check failed after 3 attempts
```

**Solutions:**

1. **Check backend manually**:
   ```bash
   curl http://54.123.45.67:3000/health
   # Should return: {"status":"ok"}
   ```

2. **Check backend logs**:
   ```bash
   ssh ubuntu@54.123.45.67
   pm2 logs bmi-backend --lines 50
   ```

3. **Increase timeout in health check**:
   ```bash
   # In Jenkins/scripts/health-check.sh
   TIMEOUT=10  # Increase from 5 to 10 seconds
   ```

4. **Check if services running**:
   ```bash
   pm2 status
   sudo systemctl status nginx
   sudo systemctl status postgresql
   ```

### Issue 7: Pipeline Hangs

**Symptoms:**
- Pipeline stuck on a stage indefinitely
- No output in console

**Solutions:**

1. **Add timeout to stages**:
   ```groovy
   stage('Deploy') {
       steps {
           timeout(time: 10, unit: 'MINUTES') {
               // deployment steps
           }
       }
   }
   ```

2. **Check for interactive prompts**:
   - SSH commands waiting for password
   - sudo requiring password
   - Apt waiting for confirmation

3. **Use non-interactive flags**:
   ```bash
   sudo apt-get install -y package  # -y flag
   npm install --loglevel=error     # reduce output
   ```

4. **Check Jenkins executor**:
   - Manage Jenkins → Manage Nodes and Clouds
   - Verify executor not stuck on previous build

### Issue 8: Git Checkout Fails

**Symptoms:**
```
ERROR: Failed to checkout from Git
```

**Solutions:**

1. **Verify repository URL**:
   ```groovy
   environment {
       REPO_URL = 'https://github.com/username/repo.git'  // Correct URL?
   }
   ```

2. **For private repos, add credentials**:
   ```groovy
   checkout([
       $class: 'GitSCM',
       branches: [[name: "*/main"]],
       userRemoteConfigs: [[
           url: "${REPO_URL}",
           credentialsId: 'github-token'
       ]]
   ])
   ```

3. **Check Jenkins Git plugin**:
   - Manage Jenkins → Plugins → Installed → "Git Plugin"

4. **Increase timeout**:
   ```groovy
   checkout([
       $class: 'GitSCM',
       branches: [[name: "*/main"]],
       userRemoteConfigs: [[url: "${REPO_URL}"]],
       extensions: [
           [$class: 'CloneOption', timeout: 30]  // 30 minutes
       ]
   ])
   ```

---

## Summary Checklist

✅ **Jenkins Server Configured**:
- NodeJS plugin installed and configured
- SSH Agent plugin installed
- Git plugin working

✅ **Credentials Added**:
- SSH private key for EC2 access
- Database password
- GitHub token (if private repo)

✅ **Pipeline Created**:
- Job configured with parameters
- Jenkinsfile in repository
- Build triggers set up

✅ **Target EC2 Ready**:
- Security groups allow SSH from Jenkins
- SSH key allows connection
- Port 80 accessible from internet

✅ **First Deployment Successful**:
- Prerequisites installed
- Database created and migrated
- Backend running on PM2
- Frontend served by Nginx
- Health checks passing

✅ **Automation Working**:
- Webhook configured (or polling)
- Builds trigger on code push
- Notifications working

✅ **Backup & Rollback Tested**:
- Backups created before deployment
- Rollback tested and working
- Old backups cleaned up

---

## Next Steps

1. **Test full deployment cycle**: Code change → Push → Auto-deploy → Verify
2. **Configure notifications**: Set up Slack/email alerts
3. **Create multi-environment pipelines**: Deploy to dev/staging/production
4. **Implement blue-green deployment**: Zero-downtime production releases
5. **Add monitoring**: Integrate with CloudWatch, Datadog, or Prometheus
6. **Document runbooks**: Create incident response procedures
7. **Train team**: Ensure everyone can deploy and troubleshoot

---

## Additional Resources

- **Jenkins Pipeline Documentation**: https://www.jenkins.io/doc/book/pipeline/
- **Jenkins SSH Agent Plugin**: https://plugins.jenkins.io/ssh-agent/
- **Jenkins Credentials**: https://www.jenkins.io/doc/book/using/using-credentials/
- **Blue Ocean (Modern UI)**: https://www.jenkins.io/projects/blueocean/
- **Jenkins Best Practices**: https://www.jenkins.io/doc/book/pipeline/pipeline-best-practices/

---

**Document Version**: 1.0  
**Last Updated**: December 30, 2025  
**Author**: DevOps Team  
**Project**: BMI Health Tracker - Jenkins Integration
