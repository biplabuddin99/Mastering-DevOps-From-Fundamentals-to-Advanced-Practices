# Guide: Create Jenkins Server on AWS EC2 Ubuntu 24.04

This comprehensive guide walks you through creating a dedicated Jenkins server on AWS EC2 running Ubuntu 24.04 LTS, installing Jenkins with a web GUI, and configuring it for CI/CD pipelines.

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Create AWS EC2 Instance](#create-aws-ec2-instance)
3. [Configure Security Groups](#configure-security-groups)
4. [Connect to EC2 Instance](#connect-to-ec2-instance)
5. [Install Jenkins on Ubuntu 24.04](#install-jenkins-on-ubuntu-2404)
6. [Access Jenkins Web GUI](#access-jenkins-web-gui)
7. [Initial Jenkins Setup Wizard](#initial-jenkins-setup-wizard)
8. [Install Essential Plugins](#install-essential-plugins)
9. [Configure Jenkins Global Settings](#configure-jenkins-global-settings)
10. [Create First Admin User](#create-first-admin-user)
11. [Security Best Practices](#security-best-practices)
12. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:
- **AWS Account** with permissions to create EC2 instances
- **SSH Key Pair** for EC2 access (create one in AWS Console if needed)
- **Basic Linux Command Knowledge**
- **Credit Card** (for AWS billing, though free tier is sufficient)

**Recommended Resources:**
- EC2 Instance: **t2.medium** or **t3.medium** (2 vCPU, 4 GB RAM minimum for Jenkins)
- Storage: **20-30 GB** GP3 SSD
- Region: Choose closest to your location for better latency

---

## Create AWS EC2 Instance

### Step 1: Launch EC2 Instance

1. **Login to AWS Console**: https://console.aws.amazon.com/
2. **Navigate to EC2**: Services → EC2 → Instances
3. **Click "Launch Instance"**

### Step 2: Configure Instance Settings

#### **Name and Tags**
```
Name: Jenkins-Server-Production
Environment: CI/CD
Purpose: Jenkins Master
```

#### **Application and OS Images (AMI)**
- **Quick Start**: Ubuntu
- **AMI**: Ubuntu Server 24.04 LTS (HVM), SSD Volume Type
- **Architecture**: 64-bit (x86)
- **AMI ID**: `ami-0e2c8caa4b6378d8c` (may vary by region)

#### **Instance Type**
- **Recommended**: `t3.medium` (2 vCPU, 4 GB RAM) - $0.0416/hour
- **Minimum**: `t2.small` (1 vCPU, 2 GB RAM) - for testing only
- **Production**: `t3.large` (2 vCPU, 8 GB RAM) - for heavy workloads

> **Note**: Jenkins requires at least 2 GB RAM. Using t2.micro (1 GB) will cause performance issues.

#### **Key Pair (Login)**
- **Select existing key pair** or **Create new key pair**
- If creating new:
  - Name: `jenkins-server-key`
  - Key pair type: RSA
  - Private key format: `.pem` (for Mac/Linux) or `.ppk` (for Windows PuTTY)
  - **Download and save securely** - cannot retrieve later!

#### **Network Settings**
- **VPC**: Default VPC (or your custom VPC)
- **Subnet**: No preference (auto-assign)
- **Auto-assign public IP**: **Enable**
- **Firewall (Security Groups)**: Create new or use existing (configure in next step)

#### **Configure Storage**
- **Size**: `25 GB` (minimum 20 GB recommended)
- **Volume Type**: `gp3` (General Purpose SSD - better performance)
- **IOPS**: 3000 (default)
- **Throughput**: 125 MB/s
- **Delete on Termination**: Checked (or uncheck if you want to preserve data)
- **Encrypted**: Optional (recommended for sensitive data)

#### **Advanced Details** (Optional but Recommended)
- **IAM Instance Profile**: None (or attach role if Jenkins needs AWS access)
- **Monitoring**: Enable detailed monitoring (extra cost)
- **Termination Protection**: Enable (prevents accidental deletion)
- **User Data**: Leave empty (we'll manually install Jenkins)

### Step 3: Review and Launch

1. **Review all settings** in the summary panel
2. **Click "Launch Instance"**
3. **Wait 2-3 minutes** for instance to reach "Running" state
4. **Note the Public IPv4 Address** (e.g., `3.87.45.123`)

---

## Configure Security Groups

Jenkins requires specific ports to be accessible. Configure the Security Group attached to your EC2 instance.

### Step 1: Navigate to Security Groups

1. **EC2 Dashboard** → **Security Groups** (left sidebar)
2. **Find your instance's security group** (e.g., `launch-wizard-1` or custom name)
3. **Click the Security Group ID**

### Step 2: Add Inbound Rules

Click **"Edit inbound rules"** → **"Add Rule"** for each entry:

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | My IP | SSH access from your IP only |
| Custom TCP | TCP | 8080 | 0.0.0.0/0 | Jenkins Web UI (temporary - restrict after setup) |
| HTTP | TCP | 80 | 0.0.0.0/0 | Optional: If using Nginx reverse proxy |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Optional: If configuring SSL/TLS |

**Security Recommendations:**
- **SSH (Port 22)**: Restrict to your IP address only (use "My IP" option)
- **Jenkins (Port 8080)**: Initially open to 0.0.0.0/0, but restrict to office/VPN IP after initial setup
- **Never expose SSH to 0.0.0.0/0** in production!

### Step 3: Save Rules

Click **"Save rules"** and verify changes are applied.

---

## Connect to EC2 Instance

### Method 1: Using SSH (Mac/Linux/Windows PowerShell)

#### Step 1: Set Key Permissions
```bash
# Navigate to directory containing your .pem key
cd ~/Downloads

# Set correct permissions (required for SSH)
chmod 400 jenkins-server-key.pem
```

#### Step 2: Connect to EC2
```bash
# Replace <PUBLIC_IP> with your EC2 public IP
ssh -i jenkins-server-key.pem ubuntu@<PUBLIC_IP>

# Example:
ssh -i jenkins-server-key.pem ubuntu@3.87.45.123
```

#### Step 3: Accept Fingerprint
```
The authenticity of host '3.87.45.123' can't be established.
ECDSA key fingerprint is SHA256:xxx...
Are you sure you want to continue connecting (yes/no)? yes
```

### Method 2: Using EC2 Instance Connect (Browser-Based)

1. **EC2 Dashboard** → **Instances**
2. **Select your Jenkins instance**
3. **Click "Connect"** button
4. **Choose "EC2 Instance Connect"** tab
5. **Username**: `ubuntu`
6. **Click "Connect"** (opens browser terminal)

### Method 3: Using PuTTY (Windows)

1. **Convert .pem to .ppk** using PuTTYgen
2. **Open PuTTY**:
   - Host: `ubuntu@<PUBLIC_IP>`
   - Port: `22`
   - Connection → SSH → Auth → Browse for .ppk file
3. **Click "Open"**

---

## Install Jenkins on Ubuntu 24.04

Once connected to your EC2 instance, follow these steps to install Jenkins LTS (Long-Term Support).

### Step 1: Update System Packages

```bash
# Update package list
sudo apt update

# Upgrade installed packages (optional but recommended)
sudo apt upgrade -y
```

**Expected Output:**
```
Hit:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble InRelease
Reading package lists... Done
Building dependency tree... Done
```

### Step 2: Install Java (Jenkins Requirement)

Jenkins requires Java 11 or Java 17. We'll install OpenJDK 17 (LTS).

```bash
# Install OpenJDK 17 JRE
sudo apt install -y fontconfig openjdk-17-jre

# Verify Java installation
java -version
```

**Expected Output:**
```
openjdk version "17.0.10" 2024-01-16
OpenJDK Runtime Environment (build 17.0.10+7-Ubuntu-1ubuntu1)
OpenJDK 64-Bit Server VM (build 17.0.10+7-Ubuntu-1ubuntu1, mixed mode, sharing)
```

### Step 3: Add Jenkins Repository

```bash
# Add Jenkins repository key
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# Add Jenkins repository to sources list
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list with Jenkins repo
sudo apt update
```

**Expected Output:**
```
Get:1 https://pkg.jenkins.io/debian-stable binary/ InRelease [2,044 B]
Get:2 https://pkg.jenkins.io/debian-stable binary/ Packages [23.4 kB]
Fetched 25.4 kB in 1s
```

### Step 4: Install Jenkins

```bash
# Install Jenkins LTS
sudo apt install -y jenkins

# Check Jenkins service status
sudo systemctl status jenkins
```

**Expected Output:**
```
● jenkins.service - Jenkins Continuous Integration Server
     Loaded: loaded (/lib/systemd/system/jenkins.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2025-12-30 10:15:23 UTC; 30s ago
   Main PID: 12345 (java)
```

### Step 5: Start and Enable Jenkins

```bash
# Start Jenkins service
sudo systemctl start jenkins

# Enable Jenkins to start on boot
sudo systemctl enable jenkins

# Verify Jenkins is running
sudo systemctl status jenkins
```

### Step 6: Retrieve Initial Admin Password

Jenkins generates a random admin password on first installation.

```bash
# Display initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Example Output:**
```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

**⚠️ IMPORTANT**: Copy this password - you'll need it in the next step!

---

## Access Jenkins Web GUI

### Step 1: Open Jenkins in Browser

1. **Open your web browser** (Chrome, Firefox, Edge)
2. **Navigate to**: `http://<EC2_PUBLIC_IP>:8080`
   - Example: `http://3.87.45.123:8080`

### Step 2: Unlock Jenkins Screen

You should see the **"Unlock Jenkins"** page with a password field.

![Unlock Jenkins Screen]
- **Heading**: "Unlock Jenkins"
- **Message**: "To ensure Jenkins is securely set up by the administrator, a password has been written to the log..."
- **Password field**: Paste the initial admin password you retrieved earlier

**Paste the password** from `/var/lib/jenkins/secrets/initialAdminPassword` and click **"Continue"**.

### Troubleshooting Connection Issues

**If you cannot access Jenkins:**

1. **Check Security Group**: Ensure port 8080 is open in EC2 Security Group
2. **Check Jenkins Service**: 
   ```bash
   sudo systemctl status jenkins
   # If stopped, start it:
   sudo systemctl start jenkins
   ```
3. **Check Firewall on EC2**:
   ```bash
   sudo ufw status
   # If active and blocking port 8080:
   sudo ufw allow 8080
   ```
4. **Check Jenkins Log**:
   ```bash
   sudo journalctl -u jenkins -f
   ```

---

## Initial Jenkins Setup Wizard

After unlocking Jenkins, you'll go through a setup wizard.

### Step 1: Customize Jenkins - Plugin Installation

You'll see two options:

#### **Option A: Install Suggested Plugins** (Recommended for beginners)
- Automatically installs ~20 commonly used plugins
- Includes: Git, Pipeline, Credentials, SSH Agents, etc.
- Takes 3-5 minutes

**Click "Install suggested plugins"**

Plugins being installed:
- Folders Plugin
- OWASP Markup Formatter
- Build Timeout
- Credentials Binding
- Timestamper
- Workspace Cleanup
- Pipeline (all sub-plugins)
- GitHub Branch Source
- Git (client and server)
- SSH Build Agents
- Email Extension
- And more...

**Wait for installation to complete** (progress bar will show each plugin).

#### **Option B: Select Plugins to Install** (For advanced users)
- Choose specific plugins manually
- More control but requires knowledge of what's needed

### Step 2: Plugin Installation Progress

Monitor the installation screen:
- **Green checkmarks**: Successfully installed
- **Red X**: Failed (can retry or skip)
- **Progress bar**: Overall completion

**If any plugins fail:**
- Click "Retry" or continue without them
- Can install manually later from Manage Jenkins → Plugins

---

## Install Essential Plugins

After initial setup, install additional plugins required for our three-tier application deployment.

### Step 1: Navigate to Plugin Manager

1. **Jenkins Dashboard** → **Manage Jenkins** (left sidebar)
2. **Click "Plugins"** (under System Configuration)
3. **Click "Available plugins"** tab

### Step 2: Install Required Plugins

Search for and install each plugin (check the box, then click "Install"):

#### **Core Deployment Plugins**
1. **SSH Agent Plugin**
   - Name: `SSH Agent Plugin`
   - Purpose: Execute commands on remote servers via SSH
   - Version: Latest stable

2. **Publish Over SSH**
   - Name: `Publish Over SSH`
   - Purpose: Transfer files and execute commands over SSH
   - Alternative to SSH Agent for file transfers

3. **NodeJS Plugin**
   - Name: `NodeJS Plugin`
   - Purpose: Install and use Node.js in Jenkins pipelines
   - Allows configuring multiple Node.js versions

#### **Version Control Plugins**
4. **Git Plugin** (usually pre-installed)
   - Purpose: Clone and manage Git repositories
   - Supports GitHub, GitLab, Bitbucket

5. **GitHub Plugin**
   - Purpose: Enhanced GitHub integration, webhooks
   - Required for automatic builds on push

#### **Pipeline Plugins** (Most pre-installed)
6. **Pipeline Plugin**
7. **Pipeline: Stage View Plugin**
8. **Blue Ocean** (Optional - modern UI)
   - Purpose: Beautiful pipeline visualization
   - Recommended for better user experience

#### **Notification Plugins** (Optional)
9. **Email Extension Plugin** (usually pre-installed)
10. **Slack Notification Plugin** (if using Slack)
11. **Discord Notifier** (if using Discord)

#### **Utility Plugins**
12. **Credentials Plugin** (pre-installed)
13. **Credentials Binding Plugin** (pre-installed)
14. **Timestamper Plugin** (pre-installed)
15. **Environment Injector Plugin**
    - Purpose: Inject environment variables into builds

### Step 3: Install Plugins

1. **Check all required plugins** from the list
2. **Click "Install"** button at the bottom
3. **Choose**: 
   - "Download now and install after restart" (recommended)
   - "Install without restart" (if you want immediate access)
4. **Optional**: Check "Restart Jenkins when installation is complete"

### Step 4: Restart Jenkins

```bash
# Option 1: Via browser
# Navigate to: http://<EC2_IP>:8080/restart
# Click "Yes" to confirm restart

# Option 2: Via SSH on EC2
sudo systemctl restart jenkins

# Option 3: Via Jenkins CLI
# Navigate to: http://<EC2_IP>:8080/safeRestart
```

**Wait 30-60 seconds** for Jenkins to restart, then refresh the page.

---

## Configure Jenkins Global Settings

Configure global tools and settings for our deployment pipelines.

### Step 1: Configure NodeJS Installation

1. **Manage Jenkins** → **Tools**
2. **Scroll to "NodeJS installations"**
3. **Click "Add NodeJS"**

**Configuration:**
```
Name: NodeJS-LTS
Version: NodeJS 20.11.0 (or latest LTS)
☑ Install automatically
  Install from nodejs.org
  Version: 20.11.0
Global npm packages to install: pm2
Global npm packages refresh hours: 72
```

**Click "Save"**

### Step 2: Configure Git

1. **Manage Jenkins** → **Tools**
2. **Scroll to "Git installations"**
3. **Usually auto-configured**, verify:

```
Name: Default
Path to Git executable: git
☑ Install automatically
```

### Step 3: Configure SSH Remote Hosts (Optional)

If using "Publish Over SSH" plugin:

1. **Manage Jenkins** → **System**
2. **Scroll to "Publish over SSH"**
3. **Click "Add" under SSH Servers**

**For Target EC2 (where app will be deployed):**
```
Name: Production-EC2
Hostname: <Target EC2 Public IP or Private IP if in same VPC>
Username: ubuntu
Remote Directory: /home/ubuntu

Advanced:
☑ Use password authentication, or use a different key
  Key: [Paste contents of jenkins-server-key.pem]
  OR
  Passphrase: [leave empty if key has no passphrase]
  
Port: 22
Timeout: 300000 (5 minutes)
```

**Click "Test Configuration"** to verify connection.

### Step 4: Configure System Properties

1. **Manage Jenkins** → **System**
2. **Configure key settings**:

#### **Jenkins Location**
```
Jenkins URL: http://<EC2_PUBLIC_IP>:8080
System Admin e-mail address: your-email@example.com
```

#### **Global Properties** (Environment Variables)
Click "Add" to create environment variables accessible in all pipelines:

```
☑ Environment variables
  List of variables:
  - Name: DEPLOY_USER
    Value: ubuntu
  - Name: DEFAULT_BRANCH
    Value: main
```

**Click "Save"**

---

## Create First Admin User

During the setup wizard, you'll be prompted to create an admin user.

### Step 1: Create Admin User Form

Fill in the form with your details:

```
Username: admin
  (or your preferred username, e.g., jenkins-admin)

Password: <Strong Password>
  (Use password manager, min 12 characters)

Confirm password: <Same Strong Password>

Full name: Jenkins Administrator
  (or your actual name)

E-mail address: your-email@example.com
  (for notifications and alerts)
```

**Click "Save and Continue"**

### Step 2: Instance Configuration

Confirm the Jenkins URL:

```
Jenkins URL: http://<EC2_PUBLIC_IP>:8080
```

**Options:**
- Keep as-is for direct IP access
- Change to domain name if you've configured DNS (e.g., `http://jenkins.yourdomain.com`)

**Click "Save and Finish"**

### Step 3: Start Using Jenkins

You'll see a success message: **"Jenkins is ready!"**

**Click "Start using Jenkins"** to access the main dashboard.

---

## Security Best Practices

Secure your Jenkins server to prevent unauthorized access and attacks.

### 1. Change Default Port (Optional but Recommended)

By default, Jenkins runs on port 8080. Change it to a custom port:

```bash
# Edit Jenkins configuration
sudo nano /etc/default/jenkins

# Find line: HTTP_PORT=8080
# Change to: HTTP_PORT=9090 (or any port > 1024)

# Save and exit (Ctrl+X, Y, Enter)

# Update Security Group to allow new port
# Then restart Jenkins
sudo systemctl restart jenkins
```

### 2. Set Up Nginx Reverse Proxy (Production Recommendation)

Run Jenkins behind Nginx for better security and SSL support.

```bash
# Install Nginx
sudo apt install -y nginx

# Create Jenkins configuration
sudo nano /etc/nginx/sites-available/jenkins
```

**Nginx Configuration:**
```nginx
server {
    listen 80;
    server_name jenkins.yourdomain.com;  # Or use EC2 IP

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_read_timeout 90;
        proxy_redirect http://127.0.0.1:8080 https://jenkins.yourdomain.com;
    }
}
```

**Enable and Test:**
```bash
# Create symlink
sudo ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Now access Jenkins via: http://<EC2_IP> (port 80)
```

### 3. Enable HTTPS with Let's Encrypt (Recommended)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate (requires domain name)
sudo certbot --nginx -d jenkins.yourdomain.com

# Certbot will automatically configure Nginx for HTTPS
# Auto-renewal is enabled by default
```

### 4. Configure Security Realm and Authorization

1. **Manage Jenkins** → **Security**
2. **Security Realm**: Jenkins' own user database
   - ☑ Allow users to sign up (uncheck in production!)
3. **Authorization**: Matrix-based security
   - Grant admin full permissions
   - Create separate users for developers with limited access

### 5. Restrict Jenkins to Private Network (Production)

**Best Practice**: Run Jenkins in private subnet, access via VPN.

1. **Change Security Group** for Jenkins EC2:
   - Port 8080/80: Allow only from office IP or VPN IP range
   - Port 22: Allow only from bastion host or your IP

2. **Use AWS Systems Manager Session Manager** instead of SSH:
   - No need to expose port 22 publicly
   - Encrypted connections via AWS infrastructure

### 6. Enable Audit Trail

Install "Audit Trail" plugin to log all Jenkins activities:

1. **Plugins** → **Available** → Search "Audit Trail"
2. **Install and restart**
3. **Manage Jenkins** → **System** → **Audit Trail**
4. **Add Logger**: Log to file `/var/log/jenkins/audit.log`

### 7. Regular Backups

```bash
# Jenkins home directory contains all configuration
JENKINS_HOME=/var/lib/jenkins

# Option 1: Simple backup script
sudo tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz $JENKINS_HOME

# Option 2: Use ThinBackup plugin (recommended)
# Install from Plugins → Available → "ThinBackup"
# Configure: Manage Jenkins → ThinBackup → Settings
```

### 8. Update Jenkins Regularly

```bash
# Check for updates: Manage Jenkins → System Information
# Update Jenkins:
sudo apt update
sudo apt upgrade jenkins

# Or download latest war file:
sudo systemctl stop jenkins
sudo wget http://updates.jenkins-ci.org/latest/jenkins.war
sudo mv jenkins.war /usr/share/java/jenkins.war
sudo systemctl start jenkins
```

---

## Troubleshooting

### Issue 1: Cannot Access Jenkins on Port 8080

**Symptoms**: Browser shows "Connection refused" or "Timeout"

**Solutions:**
```bash
# 1. Check if Jenkins is running
sudo systemctl status jenkins

# If not running, start it
sudo systemctl start jenkins

# 2. Check if Jenkins is listening on port 8080
sudo netstat -tuln | grep 8080
# Should show: tcp6  0  0 :::8080  :::*  LISTEN

# 3. Check Security Group in AWS Console
# Ensure port 8080 is open to your IP (0.0.0.0/0 for testing)

# 4. Check UFW firewall (if enabled)
sudo ufw status
sudo ufw allow 8080

# 5. Check Jenkins logs
sudo journalctl -u jenkins -n 50 --no-pager
```

### Issue 2: Jenkins Slow or Unresponsive

**Cause**: Insufficient memory (running on t2.micro/t2.small)

**Solutions:**
```bash
# 1. Check memory usage
free -h
top

# 2. Increase Java heap size
sudo nano /etc/default/jenkins
# Add or modify:
JAVA_ARGS="-Xmx2048m -Xms512m"

# 3. Restart Jenkins
sudo systemctl restart jenkins

# 4. Consider upgrading EC2 instance type to t3.medium (4GB RAM)
```

### Issue 3: Forgot Admin Password

**Solution:**
```bash
# Option 1: Disable security temporarily
sudo nano /var/lib/jenkins/config.xml
# Change: <useSecurity>true</useSecurity>
# To: <useSecurity>false</useSecurity>

sudo systemctl restart jenkins
# Access Jenkins without password, create new admin user
# Re-enable security: Manage Jenkins → Security

# Option 2: Reset password via Jenkins console
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
# Use this password to login as admin
```

### Issue 4: Plugin Installation Fails

**Symptoms**: Red X on plugin installation, timeout errors

**Solutions:**
```bash
# 1. Check internet connectivity
ping google.com

# 2. Update plugin site URL
# Manage Jenkins → Plugins → Advanced
# Update Site: https://updates.jenkins.io/update-center.json
# Click "Check now"

# 3. Clear plugin cache
sudo rm -rf /var/lib/jenkins/plugins/*.jpi.tmp
sudo systemctl restart jenkins

# 4. Manual plugin installation
# Download .hpi file from https://plugins.jenkins.io
# Upload: Manage Jenkins → Plugins → Advanced → Upload Plugin
```

### Issue 5: "Java Not Found" Error

**Solution:**
```bash
# Install Java 17
sudo apt install -y openjdk-17-jre

# Set JAVA_HOME
echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" | sudo tee -a /etc/environment
source /etc/environment

# Verify
java -version
echo $JAVA_HOME

# Restart Jenkins
sudo systemctl restart jenkins
```

### Issue 6: Jenkins Service Won't Start

**Check logs for specific error:**
```bash
# View Jenkins system logs
sudo journalctl -u jenkins -e

# Common issues:
# - Port 8080 already in use (another service using it)
sudo lsof -i :8080
# Kill conflicting process or change Jenkins port

# - Corrupted Jenkins home directory
sudo chown -R jenkins:jenkins /var/lib/jenkins
sudo chmod -R 755 /var/lib/jenkins

# - Disk space full
df -h
# Clean up if needed
```

---

## Summary Checklist

✅ **EC2 Instance Created**: Ubuntu 24.04, t3.medium, 25 GB storage  
✅ **Security Groups Configured**: Ports 22, 8080, 80, 443 open appropriately  
✅ **SSH Access Working**: Can connect to EC2 instance  
✅ **Java 17 Installed**: OpenJDK 17 JRE  
✅ **Jenkins Installed**: LTS version from official repository  
✅ **Jenkins Running**: Service active and enabled  
✅ **Initial Password Retrieved**: From `/var/lib/jenkins/secrets/initialAdminPassword`  
✅ **Web GUI Accessible**: `http://<EC2_IP>:8080`  
✅ **Plugins Installed**: Suggested plugins + NodeJS, SSH Agent, Publish Over SSH  
✅ **Admin User Created**: Strong password set  
✅ **Global Tools Configured**: NodeJS, Git, SSH  
✅ **Security Hardened**: Reverse proxy, HTTPS, restricted access  

---

## Next Steps

Now that your Jenkins server is ready, proceed to:

1. **[StartJenkins.md](./StartJenkins.md)** - Learn basic Jenkins pipeline syntax with sample pipelines
2. **[ThreeTierWithJenkins.md](./ThreeTierWithJenkins.md)** - Deploy the BMI Health Tracker application
3. **Create your first pipeline job** in Jenkins Dashboard

---

## Additional Resources

- **Official Jenkins Documentation**: https://www.jenkins.io/doc/
- **Jenkins Pipeline Syntax**: https://www.jenkins.io/doc/book/pipeline/syntax/
- **Jenkins Plugins Index**: https://plugins.jenkins.io/
- **Jenkins Community**: https://community.jenkins.io/
- **AWS EC2 Documentation**: https://docs.aws.amazon.com/ec2/

---

**Document Version**: 1.0  
**Last Updated**: December 30, 2025  
**Author**: DevOps Team  
**Project**: BMI Health Tracker - Jenkins Integration
