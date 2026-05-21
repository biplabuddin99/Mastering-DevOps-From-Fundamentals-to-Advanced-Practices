# GitHub Actions CI/CD Setup Guide --- 

This guide explains how to configure GitHub Actions for automated deployment of the BMI Health Tracker application to your AWS EC2 server.

## Overview

The GitHub Actions workflow automatically deploys your application whenever you push code to the `main` branch. The workflow intelligently handles:

- **First-time deployment:** Installs all prerequisites (NVM, Node.js, Nginx, PM2), deploys application
- **Update deployments:** Creates backup, pulls latest code, restarts services
- **Health checks:** Verifies deployment success automatically
- **Rollback support:** Quick recovery if something goes wrong
- **Automated configuration:** Creates Nginx config, sets up PM2, handles server.js location

---

## 🎯 Two Deployment Scenarios

### Scenario 1: Existing Deployment (Update Only)

**When to use:** Your application is already running at http://44.245.64.25

**Prerequisites:**
1. ✅ EC2 server is set up and application is working
2. ✅ SSH access to the EC2 server is configured
3. ✅ Application is already deployed using existing scripts
4. ✅ Repository is pushed to GitHub

**→ Skip to [Step 1: Generate SSH Key](#step-1-generate-ssh-key-for-github-actions)**

---

### Scenario 2: Fresh EC2 Instance (Everything Automated)

**When to use:** Starting from a brand new EC2 instance

**What you need:**
1. Fresh EC2 instance launched (Ubuntu 22.04 or 24.04 LTS)
2. Security group allows SSH (22), HTTP (80), HTTPS (443)
3. SSH key pair to access EC2
4. Repository pushed to GitHub

**What GitHub Actions will do automatically:**
- Install NVM and Node.js LTS
- Install PM2 for process management
- Install and configure Nginx
- Clone repository
- Deploy backend (detects server.js location automatically)
- Deploy frontend with build
- Configure Nginx as reverse proxy with API forwarding
- Start services with PM2 and health checks

**→ Follow [Complete Setup for Fresh EC2](#complete-setup-for-fresh-ec2-instance)**

---

## Complete Setup for Fresh EC2 Instance

### Prerequisites

1. **Launch EC2 Instance**
   - AMI: Ubuntu 22.04 or 24.04 LTS
   - Instance Type: t2.micro or larger
   - Storage: 8GB minimum (20GB recommended)
   
2. **Configure Security Group**
   ```
   Inbound Rules:
   - SSH (22)    - Your IP (or 0.0.0.0/0 for GitHub Actions)
   - HTTP (80)   - 0.0.0.0/0
   - HTTPS (443) - 0.0.0.0/0 (optional, for future SSL)
   ```

3. **Connect to EC2**
   ```bash
   ssh -i your-key.pem ubuntu@YOUR_EC2_IP
   ```

**Note:** The workflow automatically installs NVM, Node.js, PM2, and Nginx. No manual installation needed!

### Step 1: Prepare EC2 Instance

On your **fresh EC2 instance**, you only need to ensure basic connectivity:

```bash
# Update system (optional but recommended)
sudo apt update

# Verify you can connect
whoami
pwd
```

**That's it!** GitHub Actions will install:
- NVM (Node Version Manager)
- Node.js LTS
- PM2 (Process Manager)
- Nginx (Web Server)

No manual installation required!

### Step 2: Setup GitHub Actions SSH Key

On your **local machine** (not EC2), generate a dedicated SSH key:

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github-actions-key -N ""

# Display the public key
cat ~/.ssh/github-actions-key.pub
```

Copy the public key output, then on your **EC2 instance**:

```bash
# Add the public key to authorized_keys
echo "PASTE_YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**Test the connection** from your local machine:

```bash
ssh -i ~/.ssh/github-actions-key ubuntu@YOUR_EC2_IP
```

### Step 3: Configure GitHub Repository Secrets

Go to your GitHub repository:
1. Click **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**

Add these **4 required secrets**:

#### 1. `EC2_HOST`
```
YOUR_EC2_IP
Example: 44.245.64.25
```

#### 2. `EC2_USER`
```
ubuntu
```

#### 3. `EC2_SSH_KEY`
Get the private key content:
```bash
cat ~/.ssh/github-actions-key
```
Copy **everything** including `-----BEGIN` and `-----END` lines.

**Note:** `DB_PASSWORD` is optional. Only add it if you plan to enable database migration features in the future.

### Step 4: Push Code to Trigger Deployment

```bash
# On your local machine, in your project directory
git add .
git commit -m "Initial deployment with GitHub Actions"
git push origin main
```

### Step 5: Monitor Deployment

1. Go to your GitHub repository
2. Click **Actions** tab
3. Click on the running workflow "Deploy to AWS EC2"
4. Watch the deployment progress in real-time

The first deployment will take **3-5 minutes** as it installs NVM, Node.js, PM2, and Nginx.

### Step 6: Verify Deployment

After the workflow completes successfully:

```bash
# Visit your application
http://YOUR_EC2_IP

# Check backend health
http://YOUR_EC2_IP/api/health
```

**Congratulations!** Your application is now deployed and future updates will happen automatically!

---

## Update Existing Deployment (Scenario 1)

If you already have a working deployment and just want to add GitHub Actions:

---

## Setup for Existing Deployments

### Step 1: Generate SSH Key for GitHub Actions

You need to create a dedicated SSH key pair for GitHub Actions to connect to your EC2 server.

#### Option A: Generate a new SSH key pair (Recommended)

On your **local machine**, run:

```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github-actions-key -N ""
```

This creates:
- **Private key**: `~/.ssh/github-actions-key` (keep this secret!)
- **Public key**: `~/.ssh/github-actions-key.pub`

### Option B: Use existing key

If you already have an SSH key that can access your EC2 server (e.g., `~/.ssh/id_rsa`), you can use that.

---

## Step 2: Add Public Key to EC2 Server

Copy the **public key** to your EC2 server's authorized keys:

```bash
# If you generated a new key
cat ~/.ssh/github-actions-key.pub

# Copy the output and add it to your EC2 server
ssh ubuntu@44.245.64.25
echo "PASTE_YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit
```

**Test the connection:**

```bash
ssh -i ~/.ssh/github-actions-key ubuntu@44.245.64.25
```

If you can connect without a password prompt, the key is configured correctly!

---

### Step 3: Add GitHub Repository Secrets

Go to your GitHub repository and add the following secrets:

#### Navigate to Secrets Settings

1. Open your repository on GitHub
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

#### Add Required Secrets

**1. `EC2_HOST`**
```
44.245.64.25
```

**2. `EC2_USER`**
```
ubuntu
```

**3. `EC2_SSH_KEY`**

The **entire contents** of your **private key** file.

To get the private key content:

```bash
# Display the private key
cat ~/.ssh/github-actions-key

# Or if using existing key
cat ~/.ssh/id_rsa
```.

**4. `DB_PASSWORD`** *(Required for first-time deployments, optional for updates)*

If doing a fresh deployment, provide the PostgreSQL database password:
```
YourSecurePassword123!
```

For existing deployments, this is optional (database already configured).

---

### Step 4: Test Deployment
```bash
git add .
git commit -m "Enable GitHub Actions deployment"
git push origin main
```

Watch the deployment in **GitHub Actions** tab.

---

## Manual Deployment Trigger

You can also trigger deployments manually from GitHub:
git commit -m "Test automated deployment"
git push origin main
```

### Method 2: Manual Trigger

1. Go to **Actions** tab in your GitHub repository
2. Click on **Deploy to AWS EC2** workflow
3. Click **Run workflow** button
4. Select options (if needed):
   - Deploy backend only
   - Deploy frontend only
   - Skip health check
2. Click **Deploy to AWS EC2**
3. Click **Run workflow**
4. Choose options:
   - **backend_only:** Deploy only backend changes
   - **frontend_only:** Deploy only frontend changes
   - **skip_health_check:** Skip post-deployment verification
   - **force_fresh_install:** Force complete reinstallation
5. Click **Run workflow**

---

## Monitoring Deployment

**View Workflow Logs:**tatus
- Go to **Actions** tab → Click workflow → Expand steps

**Check Deployment Status:**
- ✅ Success/failure indicator
- 📊 PM2 status
- 🌐 Application URL
- 📌 Git commit info

**Verify on Server:**.25

# Check PM2 status
pm2 status

# Check backend logs
pm2 logs bmi-backend --lines 50

# Check Nginx status
sudo systemctl status nginx

# Test health endpoint
curl http://localhost:3000/health
```

### Test Application

Open your browser and visit:
- **Application:** http://44.245.64.25
- **Backend Health:** http://44.245.64.25/api/health

---

## Workflow Options
**Test Application:**
- http://YOUR_EC2_IP
- http://YOUR_EC2_IP/api/healtherify the public key is in `~/.ssh/authorized_keys` on the EC2 server
- Ensure the private key is correctly added to GitHub secrets (entire key including BEGIN/END lines)
- Check that the key format is correct (no extra spaces or line breaks)

### Issue: "Host key verification failed"

**Solution:**
The workflow automatically adds the host to known_hosts. If this fails:
- Ensure EC2 security group allows SSH (port 22)
- Verify the EC2_HOST secret is correct (44.245.64.25)

### Issue: "npm command not found" or "pm2 command not found"

**Solution:**
The workflow automatically installs NVM, Node.js, and PM2. If you see this error:
- Re-run the workflow (it will detect and install missing components)
- SSH to EC2 and verify: `which node` and `which pm2`
- Check the "Install Prerequisites" step in the workflow logs
- Manually verify NVM is loaded:
  ```bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  node --version
  pm2 --version
  ```

### Issue: Frontend not updating

**Solution:**
- Check Nginx configuration: `sudo nginx -t`
- Verify deployment path: `ls -la /var/www/bmi-health-tracker`
- Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`
- Restart Nginx: `sudo systemctl restart nginx`

### Issue: Backend health check fails

**Solution:**
- Check PM2 logs: `pm2 logs bmi-backend --lines 50`
- Verify server.js location (workflow auto-detects `src/server.js` or `server.js`)
- Check if process is running: `pm2 status`
- Test health endpoint directly: `curl http://localhost:3000/health`
- Restart backend manually: `pm2 restart bmi-backend`
- Check backend directory: `ls -la ~/single-server-3tier-webapp/backend/`

### Issue: Nginx not found or frontend not deploying

**Solution:**
The workflow automatically installs Nginx. If deployment fails:
- Check if Nginx is installed: `which nginx`
- Verify Nginx is running: `sudo systemctl status nginx`
- Check Nginx configuration: `sudo nginx -t`
- View Nginx logs: `sudo tail -f /var/log/nginx/error.log`
- Restart Nginx: `sudo systemctl restart nginx`
- The workflow creates Nginx config automatically at `/etc/nginx/sites-available/bmi-health-tracker`

---

## Rollback Procedure

If deployment fails or causes issues:

### Automatic Rollback

The workflow creates backups before each deployment. To rollback:

```bash
ssh ubuntu@44.245.64.25

# List available backups
ls -la ~/bmi_deployments_backup/

# Find the backup you want to restore (e.g., backup_20251218_143025)
cd ~/bmi_deployments_backup/

# Copy the backup over current deployment
cp -r backup_20251218_143025/* ~/single-server-3tier-webapp/

# Restart services
cd ~/single-server-3tier-webapp/backend
pm2 restart bmi-backend

cd ~/single-server-3tier-webapp/frontend
npm run build
sudo cp -r dist/* /var/www/bmi-health-tracker/
```

### Manual Rollback Script

A rollback script is available at [`scripts/rollback.sh`](scripts/rollback.sh) for quick recovery.

---

## Deployment Path Configuration

The workflow uses these default paths:

```yaml
DEPLOY_PATH: /home/ubuntu/single-server-3tier-webapp
FRONTEND_DEPLOY_PATH: /var/www/bmi-health-tracker
```

If your paths are different, update them in [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml):

```yaml
env:
  DEPLOY_PATH: /your/custom/path
  FRONTEND_DEPLOY_PATH: /your/custom/nginx/path
```

---

## Security Best Practices

1. ✅ **Never commit SSH private keys** to your repository
2. ✅ **Use dedicated SSH keys** for GitHub Actions (not your personal key)
3. ✅ **Rotate SSH keys** periodically
4. ✅ **Limit EC2 security group** to only necessary IPs for SSH
5. ✅ **Use GitHub Environment Secrets** for production (optional, more secure)
6. ✅ **Enable branch protection** on `main` to require reviews before deployment

---

## Advanced Configuration

### Deploy to Multiple Environments

Create separate workflows for staging and production:

- `.github/workflows/deploy-staging.yml` - deploys to staging server
- `.github/workflows/deploy-production.yml` - deploys to production server

Use different secrets for each environment:
- `STAGING_HOST`, `STAGING_USER`, `STAGING_SSH_KEY`
- `PROD_HOST`, `PROD_USER`, `PROD_SSH_KEY`

### Add Slack/Discord Notifications

Add notification steps to the workflow:

```yaml
- name: Notify on Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Add Testing Before Deployment

Add a test job before deployment:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test Backend
        run: |
          cd backend
          npm install
          npm test
          
  deploy:
    needs: test
    runs-on: ubuntu-latest
    # ... existing deploy steps
```

---

## Support

If you encounter issues:

1. Check the **Actions** tab for detailed error logs
2. Review the [Troubleshooting](#troubleshooting) section
3. SSH into the server and check logs manually
4. Consult existing deployment documentation:
   - [`IMPLEMENTATION_GUIDE.md`](IMPLEMENTATION_GUIDE.md)
   - [`AppUpdate.md`](AppUpdate.md)

---

## Summary

**GitHub Actions workflow created:** [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)  
**Secrets configured:** EC2_HOST, EC2_USER, EC2_SSH_KEY  
**Prerequisites automated:** NVM, Node.js, PM2, Nginx installed automatically  
**Deployment automated:** Push to `main` → automatic deployment  
**Manual deployment available:** Trigger from GitHub Actions UI  
**Health checks enabled:** Automatic verification after deployment  
**Backups automated:** Created before each deployment  
**Nginx auto-configured:** Reverse proxy and static file serving  

**Your CI/CD pipeline is ready!** Push your changes and deployment happens automatically.

---

🧑‍💻 **Author**  
**Md. Sarowar Alam**  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: linkedin.com/in/sarowar
