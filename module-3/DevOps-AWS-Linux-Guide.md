# AWS & Linux Fundamentals for DevOps Engineers
## Practical Guide for Developers Transitioning to DevOps

---

## Table of Contents
1. [Introduction to AWS EC2](#introduction-to-aws-ec2)
2. [Security Groups & Key Pairs](#security-groups--key-pairs)
3. [Basic Linux Commands](#basic-linux-commands)
4. [Package Manager (apt)](#package-manager-apt)
5. [Process Manager (systemctl)](#process-manager-systemctl)

---

## Introduction to AWS EC2

### What is EC2?
Amazon Elastic Compute Cloud (EC2) is a web service that provides resizable compute capacity in the cloud. Think of it as renting virtual servers on-demand.

### Key Concepts

#### 1. **Instance Types**
- **t2.micro / t3.micro**: Free tier eligible, good for testing and small applications
- **t2.small / t2.medium**: Light production workloads
- **m5.large / m5.xlarge**: Balanced compute, memory, and networking
- **c5.large**: Compute-optimized (CPU-intensive tasks)
- **r5.large**: Memory-optimized (databases, caching)

#### 2. **AMI (Amazon Machine Image)**
Pre-configured templates for your instances:
- Ubuntu 22.04 LTS
- Amazon Linux 2023
- Red Hat Enterprise Linux
- Custom AMIs (your own snapshots)

#### 3. **Instance States**
- **Pending**: Starting up
- **Running**: Active and billing
- **Stopping**: Shutting down
- **Stopped**: Not billing for compute (still billing for storage)
- **Terminated**: Deleted permanently

### Practical Exercise 1: Launch Your First EC2 Instance

```bash
# Step-by-step process:

1. Login to AWS Console → Navigate to EC2 Dashboard
2. Click "Launch Instance"
3. Configure:
   - Name: dev-server-01
   - AMI: Ubuntu Server 22.04 LTS
   - Instance Type: t2.micro
   - Key Pair: Create new (save .pem file securely)
   - Network: Default VPC
   - Storage: 8 GB gp3
   - Security Group: Allow SSH (port 22) from your IP
4. Click "Launch Instance"
5. Wait 2-3 minutes for instance to be "Running"
```

### Practical Exercise 2: Connect to Your Instance

**From Windows (PowerShell):**
```powershell
# Navigate to your key pair location
cd C:\Users\YourName\Downloads

# Set permissions (if needed)
icacls "your-key.pem" /inheritance:r
icacls "your-key.pem" /grant:r "$($env:USERNAME):(R)"

# Connect via SSH
ssh -i "your-key.pem" ubuntu@your-instance-public-ip
```

**From Linux/Mac:**
```bash
# Set correct permissions
chmod 400 your-key.pem

# Connect
ssh -i your-key.pem ubuntu@your-instance-public-ip
```

### Cost Management Tips
- ⚠️ **Always stop instances when not in use**
- Use t2.micro for learning (free tier eligible)
- Set up billing alarms (AWS Budget)
- Tag resources for tracking
- Terminate unused instances

### Real-World Scenario
**Problem**: Your team needs to deploy a Node.js application for testing.

**Solution**:
1. Launch t2.small Ubuntu instance
2. Install Node.js and PM2
3. Deploy application
4. Stop instance after testing hours (save 60% cost)
5. Start again when needed (data persists on EBS volume)

---

## Security Groups & Key Pairs

### Security Groups (SG)

Security Groups are **virtual firewalls** that control inbound and outbound traffic for your instances.

#### Key Concepts
- **Stateful**: If you allow inbound traffic, the response is automatically allowed
- **Default Deny**: Everything is blocked unless explicitly allowed
- **Rules**: Only allow rules (no deny rules)
- **Changes**: Apply immediately

#### Common Port Configurations

| Service | Port | Protocol | Use Case |
|---------|------|----------|----------|
| SSH | 22 | TCP | Remote server access |
| HTTP | 80 | TCP | Web traffic |
| HTTPS | 443 | TCP | Secure web traffic |
| Custom App | 3000 | TCP | Node.js/React dev server |
| MySQL | 3306 | TCP | Database access |
| PostgreSQL | 5432 | TCP | Database access |
| MongoDB | 27017 | TCP | Database access |
| Redis | 6379 | TCP | Caching server |

### Practical Exercise 3: Configure Security Group for Web Server

```bash
# Scenario: Setting up a full-stack application

Inbound Rules:
1. SSH Access (for management)
   - Type: SSH
   - Protocol: TCP
   - Port: 22
   - Source: Your IP (123.45.67.89/32)  # ⚠️ NEVER use 0.0.0.0/0 for SSH

2. HTTP Access (for web traffic)
   - Type: HTTP
   - Protocol: TCP
   - Port: 80
   - Source: 0.0.0.0/0 (anywhere)

3. HTTPS Access (for secure web traffic)
   - Type: HTTPS
   - Protocol: TCP
   - Port: 443
   - Source: 0.0.0.0/0 (anywhere)

4. Custom Application (backend API)
   - Type: Custom TCP
   - Protocol: TCP
   - Port: 3000
   - Source: Security Group of Frontend Server OR specific IP

Outbound Rules:
- Default: Allow all (0.0.0.0/0) - needed for updates and external APIs
```

### Security Best Practices

#### ✅ DO:
- Use specific IP addresses for SSH access
- Create separate security groups for different tiers (web, app, database)
- Use descriptive names: `web-server-sg`, `database-sg`, `bastion-host-sg`
- Regularly audit and remove unused rules
- Use security group chaining (reference other SGs in rules)

#### ❌ DON'T:
- Open SSH (port 22) to 0.0.0.0/0
- Use default security groups for production
- Open all ports (0-65535)
- Share security groups across environments (dev/staging/prod)

### Key Pairs

Key pairs are used for **secure SSH authentication** to EC2 instances.

#### Components:
- **Private Key** (.pem file): Keep this SECRET, never commit to Git
- **Public Key**: Stored on EC2 instance in `~/.ssh/authorized_keys`

### Practical Exercise 4: Managing Key Pairs

```bash
# Create a new key pair using AWS CLI
aws ec2 create-key-pair \
  --key-name devops-batch09 \
  --query 'KeyMaterial' \
  --output text > devops-batch09.pem

# Set correct permissions
chmod 400 devops-batch09.pem

# Verify the key
ssh-keygen -l -f devops-batch09.pem

# Add multiple team members' SSH keys to an instance
# Connect to instance first, then:
echo "ssh-rsa AAAAB3Nz... user@email.com" >> ~/.ssh/authorized_keys
```

### Real-World Scenario: Three-Tier Architecture Security

```
Internet → [Load Balancer]
              ↓
    [Web Servers SG]
    - Port 80, 443 from 0.0.0.0/0
    - Port 22 from Bastion SG
              ↓
    [App Servers SG]
    - Port 8080 from Web SG only
    - Port 22 from Bastion SG
              ↓
    [Database SG]
    - Port 3306 from App SG only
    - Port 22 from Bastion SG

[Bastion Host SG]
    - Port 22 from Office IP only
```

---

## Basic Linux Commands

### File System Navigation

```bash
# Present Working Directory
pwd
# Output: /home/ubuntu

# List files and directories
ls                  # Basic listing
ls -l               # Long format (permissions, owner, size, date)
ls -la              # Include hidden files (starting with .)
ls -lh              # Human-readable sizes (KB, MB, GB)
ls -lt              # Sort by modification time
ls -ltr             # Sort by time, reverse (oldest first)

# Change directory
cd /var/log         # Absolute path
cd ..               # Parent directory
cd ~                # Home directory
cd -                # Previous directory

# Create directories
mkdir projects
mkdir -p projects/backend/src    # Create nested directories
```

### File Operations

```bash
# Create files
touch app.js                    # Create empty file
touch file1.txt file2.txt       # Create multiple files

# View file contents
cat /etc/os-release             # Display entire file
less /var/log/syslog            # View large files (q to quit)
head -n 20 /var/log/syslog      # First 20 lines
tail -n 50 /var/log/syslog      # Last 50 lines
tail -f /var/log/syslog         # Follow file in real-time (Ctrl+C to stop)

# Copy files
cp source.txt destination.txt
cp -r /source/folder /destination/folder    # Copy directories
cp -p file.txt backup.txt                   # Preserve permissions

# Move/Rename files
mv old-name.txt new-name.txt
mv file.txt /another/directory/

# Delete files
rm file.txt                     # Remove file
rm -r folder/                   # Remove directory
rm -rf folder/                  # Force remove (⚠️ dangerous!)
```

### Search and Find

```bash
# Find files
find /var/log -name "*.log"                     # Find all .log files
find /home -type f -mtime -7                    # Files modified in last 7 days
find . -type f -size +100M                      # Files larger than 100MB
find /etc -name "nginx.conf" 2>/dev/null        # Ignore errors

# Search inside files
grep "error" /var/log/syslog                    # Search for "error"
grep -i "error" /var/log/syslog                 # Case-insensitive
grep -r "TODO" /home/ubuntu/projects/           # Recursive search
grep -n "function" app.js                       # Show line numbers
grep -v "info" /var/log/app.log                 # Invert match (exclude)

# Combined search
find /var/log -name "*.log" -exec grep -l "error" {} \;
```

### File Permissions

```bash
# Understanding permissions: rwxrwxrwx (user, group, others)
# r=4, w=2, x=1

ls -l file.txt
# -rw-r--r-- 1 ubuntu ubuntu 1234 Jan 10 10:30 file.txt
# └─┬─┘ └┬─┘ └┬─┘
#   │    │    └─ others: read (4)
#   │    └────── group: read (4)
#   └─────────── user: read(4) + write(2) = 6

# Change permissions
chmod 644 file.txt              # rw-r--r--
chmod 755 script.sh             # rwxr-xr-x (executable)
chmod +x script.sh              # Add execute permission
chmod -w file.txt               # Remove write permission

# Change ownership
chown ubuntu:ubuntu file.txt
sudo chown root:root /etc/config.conf
```

### System Information

```bash
# Disk usage
df -h                           # Disk space
du -sh /var/log/*               # Directory sizes
du -h --max-depth=1 /home       # Size of subdirectories

# Memory and CPU
free -h                         # Memory usage
top                             # Real-time process monitor
htop                            # Better process monitor (install first)
uptime                          # System uptime and load

# System information
uname -a                        # Kernel and system info
cat /etc/os-release             # OS version
hostname                        # Server name
whoami                          # Current user
w                               # Who is logged in
```

### Practical Exercise 5: DevOps Daily Tasks

```bash
# Scenario: Troubleshooting a web application

# 1. Check disk space (application might be failing due to full disk)
df -h

# 2. Find large log files
du -sh /var/log/* | sort -hr | head -10

# 3. Check application logs
tail -f /var/log/nginx/error.log

# 4. Find recent errors
grep -i "error" /var/log/application.log | tail -20

# 5. Check application process
ps aux | grep node

# 6. Find which process is using port 3000
sudo lsof -i :3000
# OR
sudo netstat -tulpn | grep 3000

# 7. Check system load
top
# Press 'q' to quit

# 8. Clear old log files (older than 30 days)
find /var/log -name "*.log" -type f -mtime +30 -delete
```

### Text Processing

```bash
# Count lines, words, characters
wc -l file.txt                  # Count lines
wc -w file.txt                  # Count words

# Sort and unique
sort file.txt                   # Sort lines
sort -u file.txt                # Sort and remove duplicates
uniq file.txt                   # Remove adjacent duplicates

# Cut and paste
cut -d ',' -f 1,3 data.csv      # Extract columns 1 and 3
cut -d ':' -f 1 /etc/passwd     # Get all usernames

# Sed (stream editor)
sed 's/old/new/' file.txt       # Replace first occurrence per line
sed 's/old/new/g' file.txt      # Replace all occurrences
sed -i 's/old/new/g' file.txt   # Edit file in-place

# Awk (pattern scanning)
awk '{print $1}' file.txt       # Print first column
awk -F ',' '{print $2}' data.csv # Use comma as delimiter
```

### Pipes and Redirection

```bash
# Redirect output
echo "Hello" > file.txt         # Overwrite file
echo "World" >> file.txt        # Append to file

# Redirect errors
command 2> error.log            # Redirect stderr
command &> all.log              # Redirect stdout and stderr

# Pipes
ls -la | grep ".log"            # Filter output
cat /var/log/syslog | grep "error" | wc -l    # Count errors
ps aux | sort -k 3 -rn | head -5              # Top 5 CPU-consuming processes
```

---

## Package Manager (apt)

### What is APT?

APT (Advanced Package Tool) is the package manager for Debian-based Linux distributions (Ubuntu, Debian, Linux Mint).

### Core Commands

```bash
# Update package index (always do this first!)
sudo apt update

# Upgrade installed packages
sudo apt upgrade                    # Interactive upgrade
sudo apt upgrade -y                 # Auto-confirm

# Full system upgrade
sudo apt full-upgrade

# Install packages
sudo apt install nginx
sudo apt install nginx mysql-server redis    # Multiple packages
sudo apt install nginx=1.18.0-0ubuntu1       # Specific version

# Remove packages
sudo apt remove nginx               # Remove but keep config files
sudo apt purge nginx                # Remove including config files
sudo apt autoremove                 # Remove unused dependencies

# Search packages
apt search nginx
apt-cache search "web server"

# Show package information
apt show nginx
apt-cache policy nginx              # Available versions
```

### Practical Exercise 6: Setting Up a Web Server

```bash
# Complete setup of NGINX web server

# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install NGINX
sudo apt install nginx -y

# 3. Verify installation
nginx -v
# Output: nginx version: nginx/1.18.0 (Ubuntu)

# 4. Check if running
sudo systemctl status nginx

# 5. Get server's public IP
curl ifconfig.me

# 6. Test in browser: http://your-ip
# You should see "Welcome to nginx!" page
```

### Practical Exercise 7: LAMP Stack Installation

```bash
# Install Linux, Apache, MySQL, PHP

# 1. Update system
sudo apt update

# 2. Install Apache
sudo apt install apache2 -y

# 3. Install MySQL
sudo apt install mysql-server -y

# 4. Secure MySQL (optional but recommended)
sudo mysql_secure_installation

# 5. Install PHP
sudo apt install php libapache2-mod-php php-mysql -y

# 6. Verify installations
apache2 -v
mysql --version
php -v

# 7. Test PHP
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php

# 8. Visit: http://your-ip/info.php
```

### Practical Exercise 8: Node.js Setup

```bash
# Install Node.js (Latest LTS version)

# 1. Install Node.js repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# 2. Install Node.js
sudo apt install nodejs -y

# 3. Verify
node -v    # v20.x.x
npm -v     # 10.x.x

# 4. Install global packages
sudo npm install -g pm2 yarn

# 5. Deploy a simple app
mkdir myapp && cd myapp
npm init -y
npm install express
```

### Package Management Best Practices

```bash
# Keep system updated
sudo apt update && sudo apt upgrade -y

# Clean up
sudo apt autoremove                 # Remove unused packages
sudo apt autoclean                  # Clear old package cache
sudo apt clean                      # Clear entire package cache

# List installed packages
apt list --installed
apt list --installed | grep nginx

# Check for broken dependencies
sudo apt --fix-broken install

# Hold a package (prevent updates)
sudo apt-mark hold nginx
sudo apt-mark unhold nginx          # Release hold
```

### Real-World Scenario: Server Maintenance

```bash
#!/bin/bash
# Monthly server maintenance script

echo "=== Starting Monthly Maintenance ==="

# Update package lists
echo "Updating package lists..."
sudo apt update

# Upgrade packages
echo "Upgrading packages..."
sudo apt upgrade -y

# Remove unused packages
echo "Cleaning up..."
sudo apt autoremove -y
sudo apt autoclean

# Check disk space
echo "Disk usage:"
df -h

# Check for services that need restart
echo "Services needing restart:"
sudo checkrestart

echo "=== Maintenance Complete ==="
```

### Troubleshooting Common Issues

```bash
# Problem: "Unable to acquire the dpkg frontend lock"
# Solution: Wait or remove lock
sudo rm /var/lib/dpkg/lock-frontend
sudo dpkg --configure -a
sudo apt update

# Problem: Broken packages
sudo apt --fix-broken install
sudo dpkg --configure -a

# Problem: Repository errors
sudo apt update --fix-missing

# Check package dependencies
apt-cache depends nginx
apt-cache rdepends nginx            # Reverse dependencies
```

---

## Process Manager (systemctl)

### Understanding systemd & systemctl

`systemd` is the init system and service manager for modern Linux distributions. `systemctl` is the command to control systemd.

### Service Management

```bash
# Start a service
sudo systemctl start nginx

# Stop a service
sudo systemctl stop nginx

# Restart a service
sudo systemctl restart nginx

# Reload configuration (without full restart)
sudo systemctl reload nginx

# Restart only if running
sudo systemctl try-restart nginx

# Reload or restart if reload not available
sudo systemctl reload-or-restart nginx
```

### Service Status and Information

```bash
# Check service status
sudo systemctl status nginx
# Output shows:
# - Active/Inactive/Failed
# - Process ID (PID)
# - Memory usage
# - Recent logs

# Check if service is active
sudo systemctl is-active nginx

# Check if service is enabled
sudo systemctl is-enabled nginx

# Show all properties
sudo systemctl show nginx

# Show service file location
sudo systemctl cat nginx
```

### Enable/Disable Services

```bash
# Enable service to start at boot
sudo systemctl enable nginx

# Disable service from starting at boot
sudo systemctl disable nginx

# Enable and start immediately
sudo systemctl enable --now nginx

# Disable and stop immediately
sudo systemctl disable --now nginx
```

### Listing Services

```bash
# List all services
sudo systemctl list-units --type=service

# List running services
sudo systemctl list-units --type=service --state=running

# List failed services
sudo systemctl list-units --type=service --state=failed

# List all installed service files
sudo systemctl list-unit-files --type=service
```

### Practical Exercise 9: Deploy Node.js App with systemd

```bash
# Step 1: Create a simple Node.js app
mkdir -p /home/ubuntu/myapp
cd /home/ubuntu/myapp

cat > app.js << 'EOF'
const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello from systemd managed app!\n');
});

server.listen(3000, () => {
  console.log('Server running on port 3000');
});
EOF

# Step 2: Create systemd service file
sudo nano /etc/systemd/system/myapp.service
```

```ini
[Unit]
Description=My Node.js Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/myapp
ExecStart=/usr/bin/node /home/ubuntu/myapp/app.js
Restart=on-failure
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=myapp

[Install]
WantedBy=multi-user.target
```

```bash
# Step 3: Reload systemd to recognize new service
sudo systemctl daemon-reload

# Step 4: Start the service
sudo systemctl start myapp

# Step 5: Check status
sudo systemctl status myapp

# Step 6: Enable auto-start on boot
sudo systemctl enable myapp

# Step 7: Test the application
curl http://localhost:3000

# Step 8: View logs
sudo journalctl -u myapp -f
```

### Practical Exercise 10: Managing Multiple Services

```bash
# Scenario: LEMP Stack (Linux, Nginx, MySQL, PHP)

# Install all components
sudo apt install nginx mysql-server php-fpm -y

# Start all services
sudo systemctl start nginx mysql php8.1-fpm

# Check status of all
sudo systemctl status nginx mysql php8.1-fpm

# Enable all to start at boot
sudo systemctl enable nginx mysql php8.1-fpm

# Restart all services
sudo systemctl restart nginx mysql php8.1-fpm

# Check which services are listening
sudo ss -tulpn
```

### Viewing Logs with journalctl

```bash
# View all logs for a service
sudo journalctl -u nginx

# Follow logs in real-time
sudo journalctl -u nginx -f

# View logs since today
sudo journalctl -u nginx --since today

# View logs for last hour
sudo journalctl -u nginx --since "1 hour ago"

# View logs between time ranges
sudo journalctl -u nginx --since "2024-01-10 10:00:00" --until "2024-01-10 11:00:00"

# Show only errors
sudo journalctl -u nginx -p err

# Show last 50 entries
sudo journalctl -u nginx -n 50

# Show logs in reverse (newest first)
sudo journalctl -u nginx -r

# Export logs to file
sudo journalctl -u nginx > nginx-logs.txt
```

### Creating Custom Services

```bash
# Example: Backup service that runs periodically

# Create backup script
sudo nano /usr/local/bin/backup.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
tar -czf $BACKUP_DIR/backup_$DATE.tar.gz /var/www/html

# Keep only last 7 days
find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed at $(date)"
```

```bash
# Make executable
sudo chmod +x /usr/local/bin/backup.sh

# Create service file
sudo nano /etc/systemd/system/backup.service
```

```ini
[Unit]
Description=Backup Service
Wants=backup.timer

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh

[Install]
WantedBy=multi-user.target
```

```bash
# Create timer file (runs daily at 2 AM)
sudo nano /etc/systemd/system/backup.timer
```

```ini
[Unit]
Description=Run backup daily
Requires=backup.service

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
# Reload and enable
sudo systemctl daemon-reload
sudo systemctl enable backup.timer
sudo systemctl start backup.timer

# Check timer status
sudo systemctl list-timers
```

### Troubleshooting Services

```bash
# Service failed to start
sudo systemctl status myapp
sudo journalctl -u myapp -n 50
sudo journalctl -xe                 # Last entries with explanations

# Check service configuration
sudo systemctl cat myapp

# Verify service file syntax
sudo systemd-analyze verify /etc/systemd/system/myapp.service

# Reset failed state
sudo systemctl reset-failed myapp

# Kill a stuck service
sudo systemctl kill myapp
```

### Real-World Scenario: Production Deployment

```bash
# Complete production deployment workflow

# 1. Pull latest code
cd /var/www/myapp
git pull origin main

# 2. Install dependencies
npm install --production

# 3. Run database migrations
npm run migrate

# 4. Restart application
sudo systemctl restart myapp

# 5. Check if service started successfully
sleep 2
sudo systemctl is-active myapp

# 6. Check logs for errors
sudo journalctl -u myapp -n 20

# 7. Test application endpoint
curl http://localhost:3000/health

# 8. If everything OK, clear old logs
sudo journalctl --vacuum-time=7d

echo "Deployment completed successfully!"
```

### System Boot Analysis

```bash
# Check boot time
systemd-analyze

# Show service startup times
systemd-analyze blame

# Critical chain (slowest path)
systemd-analyze critical-chain

# Visualize boot process (generates SVG)
systemd-analyze plot > boot.svg
```

---

## Hands-On Lab: Complete Setup

### Lab Scenario: Deploy a Full-Stack Application

You've been tasked with deploying a Node.js + MongoDB + Nginx application on AWS EC2.

#### Requirements:
- Ubuntu 22.04 EC2 instance
- Node.js backend on port 3000
- MongoDB database
- Nginx as reverse proxy
- All services managed by systemd
- Proper security groups

#### Step-by-Step Solution:

```bash
# ========================================
# PART 1: EC2 & Security Group Setup
# ========================================

# In AWS Console:
# 1. Launch t2.small Ubuntu 22.04 instance
# 2. Create security group:
#    - SSH (22) from your IP
#    - HTTP (80) from anywhere
#    - Custom TCP (3000) from localhost only
# 3. Connect via SSH

# ========================================
# PART 2: System Update & Basic Tools
# ========================================

sudo apt update && sudo apt upgrade -y
sudo apt install curl wget git htop -y

# ========================================
# PART 3: Install Node.js
# ========================================

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install nodejs -y
node -v && npm -v

# ========================================
# PART 4: Install MongoDB
# ========================================

wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
sudo apt install mongodb-org -y

# Start and enable MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
sudo systemctl status mongod

# ========================================
# PART 5: Create Application
# ========================================

cd /home/ubuntu
git clone https://github.com/your-repo/myapp.git
cd myapp
npm install

# ========================================
# PART 6: Create systemd Service
# ========================================

sudo tee /etc/systemd/system/myapp.service > /dev/null <<EOF
[Unit]
Description=Node.js Application
After=network.target mongod.service
Requires=mongod.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/myapp
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=MONGODB_URI=mongodb://localhost:27017/myapp
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start myapp
sudo systemctl enable myapp
sudo systemctl status myapp

# ========================================
# PART 7: Install & Configure Nginx
# ========================================

sudo apt install nginx -y

sudo tee /etc/nginx/sites-available/myapp > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# ========================================
# PART 8: Verify Everything
# ========================================

# Check all services
sudo systemctl status mongod myapp nginx

# Test application
curl http://localhost:3000
curl http://localhost

# Get public IP
curl ifconfig.me

# Test from browser: http://your-public-ip

# ========================================
# PART 9: Monitoring & Logs
# ========================================

# View application logs
sudo journalctl -u myapp -f

# View nginx access logs
sudo tail -f /var/log/nginx/access.log

# View nginx error logs
sudo tail -f /var/log/nginx/error.log

# Check system resources
htop
```

---

## Best Practices Summary

### 🔒 Security
- Never open SSH to 0.0.0.0/0
- Keep systems updated regularly
- Use key-based SSH authentication only
- Disable root login
- Implement least privilege principle
- Regular security audits

### 💰 Cost Optimization
- Stop instances when not in use
- Use appropriate instance types
- Clean up unused resources
- Set up billing alerts
- Use reserved instances for production

### 📊 Monitoring
- Enable CloudWatch metrics
- Set up log aggregation
- Monitor disk space regularly
- Track service health
- Set up alerting

### 🔄 Automation
- Use systemd for service management
- Create maintenance scripts
- Automate backups
- Use configuration management tools
- Document everything

### 📝 Documentation
- Maintain runbooks
- Document architecture
- Track changes
- Keep security group rules documented
- Maintain incident logs

---

## Common Troubleshooting Scenarios

### Scenario 1: Cannot Connect to EC2 Instance

```bash
# Check:
1. Security group allows SSH (port 22) from your IP
2. Instance is in "running" state
3. Using correct key pair
4. Using correct username (ubuntu for Ubuntu, ec2-user for Amazon Linux)
5. Network ACLs are not blocking traffic

# Solution:
# Update security group to allow your current IP
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 22 \
  --cidr your-ip/32
```

### Scenario 2: Application Not Accessible from Internet

```bash
# Debug steps:
# 1. Check if application is running locally
curl http://localhost:3000

# 2. Check if process is listening
sudo ss -tulpn | grep 3000

# 3. Check security group
# - Ensure port 3000 (or 80/443) is open
# - Source should be 0.0.0.0/0 for public access

# 4. Check nginx configuration (if using reverse proxy)
sudo nginx -t
sudo systemctl status nginx

# 5. Check logs
sudo journalctl -u myapp -n 50
```

### Scenario 3: Service Keeps Crashing

```bash
# Debug steps:
# 1. Check service status
sudo systemctl status myapp

# 2. View detailed logs
sudo journalctl -u myapp -xe

# 3. Check resource usage
free -h
df -h

# 4. Check for port conflicts
sudo ss -tulpn | grep 3000

# 5. Test application manually
cd /path/to/app
node server.js  # Check for errors

# Common fixes:
# - Increase memory (upgrade instance type)
# - Fix application code errors
# - Check environment variables
# - Verify dependencies installed
```

---

## Quick Reference Cheat Sheet

### EC2 Commands
```bash
# Connect to instance
ssh -i key.pem ubuntu@ip-address

# Transfer files
scp -i key.pem file.txt ubuntu@ip:/path/
scp -i key.pem -r folder/ ubuntu@ip:/path/
```

### Systemctl Quick Commands
```bash
sudo systemctl start|stop|restart|status SERVICE
sudo systemctl enable|disable SERVICE
sudo journalctl -u SERVICE -f
```

### APT Quick Commands
```bash
sudo apt update                  # Update package lists
sudo apt install PACKAGE         # Install package
sudo apt remove PACKAGE          # Remove package
sudo apt autoremove             # Clean up
```

### Linux One-Liners
```bash
# Find large files
find / -type f -size +100M 2>/dev/null

# Check port usage
sudo ss -tulpn | grep :PORT

# Monitor logs
tail -f /var/log/syslog | grep ERROR

# Disk usage by directory
du -sh /*  | sort -hr

# Top 10 CPU processes
ps aux | sort -nrk 3,3 | head -n 10

# Top 10 memory processes
ps aux | sort -nrk 4,4 | head -n 10
```

---

## Additional Resources

### Official Documentation
- AWS EC2: https://docs.aws.amazon.com/ec2/
- Ubuntu Server Guide: https://ubuntu.com/server/docs
- systemd Manual: https://www.freedesktop.org/software/systemd/man/
- Nginx Documentation: https://nginx.org/en/docs/

### Practice Platforms
- AWS Free Tier: https://aws.amazon.com/free/
- Linux Journey: https://linuxjourney.com/
- OverTheWire Bandit: https://overthewire.org/wargames/bandit/

### Communities
- r/devops on Reddit
- DevOps Stack Exchange
- AWS Community Forums
- Linux Questions Forums

---

## Next Steps

After mastering these fundamentals:

1. **CI/CD Pipelines** - Jenkins, GitHub Actions, GitLab CI
2. **Infrastructure as Code** - Terraform, CloudFormation
3. **Configuration Management** - Ansible, Chef, Puppet
4. **Containerization** - Docker, Kubernetes
5. **Monitoring & Logging** - Prometheus, Grafana, ELK Stack
6. **Cloud Services** - S3, RDS, Lambda, CloudWatch
7. **Security** - IAM, Secrets Manager, Security Hub

---

**Good luck with your DevOps journey! 🚀**

*Remember: The best way to learn is by doing. Practice these commands daily, break things in a safe environment, and learn from failures.*

---

## 🧑‍💻 Author

**Md. Sarowar Alam**  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: [linkedin.com/in/sarowar](https://www.linkedin.com/in/sarowar/)  
🐙 GitHub: [@sarowar-alam-hogarth](https://github.com/sarowar-alam-hogarth)

---

### License

This guide is provided as educational material for DevOps engineers.

---

**© 2026 Md. Sarowar Alam. All rights reserved.**
