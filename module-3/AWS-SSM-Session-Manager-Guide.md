# AWS Systems Manager (SSM) Session Manager Guide
## Complete Guide to Enable, Connect, and Manage Access

---

## Table of Contents
1. [Introduction to AWS SSM Session Manager](#introduction-to-aws-ssm-session-manager)
2. [Enable SSM on Ubuntu EC2 Instance](#enable-ssm-on-ubuntu-ec2-instance)
3. [Connect to EC2 via SSM](#connect-to-ec2-via-ssm)
4. [Restrict AWS Users for Specific EC2 Instances](#restrict-aws-users-for-specific-ec2-instances)
5. [Troubleshooting](#troubleshooting)
6. [Best Practices](#best-practices)

---

## Introduction to AWS SSM Session Manager

### What is AWS Systems Manager Session Manager?

AWS Systems Manager Session Manager is a fully managed service that provides secure and auditable instance management without the need to:
- Open inbound ports
- Manage SSH keys
- Use bastion hosts
- Configure VPN connections

### Key Benefits

✅ **No SSH Keys Required** - No need to manage, distribute, or rotate SSH keys
✅ **No Inbound Ports** - No need to open port 22 (SSH) or 3389 (RDP)
✅ **Centralized Access Control** - Manage access using IAM policies
✅ **Audit Trail** - All sessions are logged to CloudWatch and S3
✅ **Port Forwarding** - Tunnel to services running on private instances
✅ **Cross-Platform** - Works on Linux, Windows, and macOS

---

## Enable SSM on Ubuntu EC2 Instance

### Prerequisites

Before enabling SSM, ensure you have:
- An AWS account with appropriate permissions
- An EC2 instance running Ubuntu (18.04, 20.04, 22.04, or later)
- Internet connectivity (via NAT Gateway, Internet Gateway, or VPC Endpoints)

---

### Method 1: Enable SSM During EC2 Launch (Recommended)

#### Step 1: Create IAM Role for EC2

```bash
# Using AWS Console:
1. Go to IAM Console → Roles → Create Role
2. Select "AWS Service" → Choose "EC2"
3. Click "Next: Permissions"
4. Search and select: AmazonSSMManagedInstanceCore
5. Click "Next: Tags" (optional)
6. Click "Next: Review"
7. Name: EC2-SSM-Role
8. Description: Allows EC2 instances to use Systems Manager
9. Click "Create Role"
```

**Using AWS CLI:**

```bash
# Create trust policy file
cat > ec2-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create IAM role
aws iam create-role \
  --role-name EC2-SSM-Role \
  --assume-role-policy-document file://ec2-trust-policy.json

# Attach managed policy
aws iam attach-role-policy \
  --role-name EC2-SSM-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name EC2-SSM-InstanceProfile

# Add role to instance profile
aws iam add-role-to-instance-profile \
  --instance-profile-name EC2-SSM-InstanceProfile \
  --role-name EC2-SSM-Role
```

#### Step 2: Launch EC2 Instance with IAM Role

**AWS Console:**
```
1. Launch EC2 Instance
2. Choose Ubuntu Server 22.04 LTS AMI
3. Select Instance Type (t2.micro for testing)
4. Configure Instance Details:
   - IAM Role: Select "EC2-SSM-Role"
   - Enable "Auto-assign Public IP" if using Internet Gateway
5. Add Storage (default 8 GB is fine)
6. Add Tags (optional):
   - Key: Name, Value: SSM-Test-Instance
7. Configure Security Group:
   - NO need to open port 22 (SSH)
   - Only allow HTTPS outbound (443) for SSM communication
8. Review and Launch (no key pair needed!)
```

**AWS CLI:**

```bash
# Launch instance with IAM role
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t2.micro \
  --iam-instance-profile Name=EC2-SSM-InstanceProfile \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=SSM-Test-Ubuntu}]' \
  --user-data '#!/bin/bash
sudo snap start amazon-ssm-agent' \
  --no-associate-public-ip-address
```

---

### Method 2: Enable SSM on Existing Ubuntu Instance

#### Step 1: Attach IAM Role to Existing Instance

**AWS Console:**
```
1. Go to EC2 Console
2. Select your Ubuntu instance
3. Actions → Security → Modify IAM Role
4. Select "EC2-SSM-Role"
5. Click "Update IAM Role"
```

**AWS CLI:**

```bash
# Get instance ID
INSTANCE_ID="i-1234567890abcdef0"

# Attach IAM role
aws ec2 associate-iam-instance-profile \
  --instance-id $INSTANCE_ID \
  --iam-instance-profile Name=EC2-SSM-InstanceProfile
```

#### Step 2: Install or Update SSM Agent on Ubuntu

**Connect via SSH (traditional method) first:**

```bash
# SSH into your Ubuntu instance
ssh -i your-key.pem ubuntu@your-instance-public-ip
```

**Check if SSM Agent is installed:**

```bash
# Check SSM Agent status
sudo systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service
```

**If not installed, install SSM Agent:**

```bash
# Update package list
sudo apt update

# Install SSM Agent using snap (Ubuntu 18.04+)
sudo snap install amazon-ssm-agent --classic

# Start SSM Agent
sudo snap start amazon-ssm-agent

# Enable auto-start
sudo snap services amazon-ssm-agent
```

**Alternative: Install from package (Ubuntu 16.04 or older):**

```bash
# Download SSM Agent
cd /tmp
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb

# Install package
sudo dpkg -i amazon-ssm-agent.deb

# Start and enable SSM Agent
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent

# Check status
sudo systemctl status amazon-ssm-agent
```

#### Step 3: Verify SSM Agent is Running

```bash
# Check agent status
sudo systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service

# Check agent logs
sudo tail -f /var/log/amazon/ssm/amazon-ssm-agent.log
```

#### Step 4: Verify Instance Appears in SSM

**AWS Console:**
```
1. Go to AWS Systems Manager Console
2. Click "Fleet Manager" or "Session Manager"
3. Wait 5-10 minutes for instance to register
4. Your instance should appear in the list
```

**AWS CLI:**

```bash
# List managed instances
aws ssm describe-instance-information

# Check specific instance
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=i-1234567890abcdef0"
```

---

### Method 3: Enable SSM via User Data (New Instances)

When launching a new Ubuntu EC2 instance, use this User Data script:

```bash
#!/bin/bash
# Update system
apt-get update -y

# Install SSM Agent
snap install amazon-ssm-agent --classic

# Start SSM Agent
snap start amazon-ssm-agent

# Enable auto-start
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service

# Optional: Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
```

---

### Network Requirements for SSM

#### Option 1: Public Subnet with Internet Gateway (Simplest)

Your EC2 instance needs outbound HTTPS (443) access to AWS Systems Manager endpoints:

```
Instance → Internet Gateway → AWS SSM Endpoints
```

**Required Security Group (Outbound Rules):**
```
Type: HTTPS
Protocol: TCP
Port: 443
Destination: 0.0.0.0/0
```

#### Option 2: Private Subnet with NAT Gateway

```
Instance → NAT Gateway → Internet Gateway → AWS SSM Endpoints
```

#### Option 3: Private Subnet with VPC Endpoints (Most Secure)

Create VPC Endpoints for SSM (no internet access required):

```bash
# Required VPC Endpoints:
1. com.amazonaws.region.ssm
2. com.amazonaws.region.ssmmessages
3. com.amazonaws.region.ec2messages

# Optional (for CloudWatch logs):
4. com.amazonaws.region.logs
```

**Create VPC Endpoints using AWS CLI:**

```bash
# Replace with your VPC ID and subnet IDs
VPC_ID="vpc-1234567890abcdef0"
SUBNET_IDS="subnet-12345,subnet-67890"
SG_ID="sg-1234567890abcdef0"

# SSM Endpoint
aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --vpc-endpoint-type Interface \
  --service-name com.amazonaws.us-east-1.ssm \
  --subnet-ids $SUBNET_IDS \
  --security-group-ids $SG_ID

# SSM Messages Endpoint
aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --vpc-endpoint-type Interface \
  --service-name com.amazonaws.us-east-1.ssmmessages \
  --subnet-ids $SUBNET_IDS \
  --security-group-ids $SG_ID

# EC2 Messages Endpoint
aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --vpc-endpoint-type Interface \
  --service-name com.amazonaws.us-east-1.ec2messages \
  --subnet-ids $SUBNET_IDS \
  --security-group-ids $SG_ID
```

---

## Connect to EC2 via SSM

### Prerequisites

Before connecting:
1. SSM Agent installed and running on EC2
2. IAM role attached with `AmazonSSMManagedInstanceCore` policy
3. Your IAM user has SSM permissions
4. Instance registered in SSM Fleet Manager

---

### Method 1: Connect via AWS Console (Easiest)

#### For Linux Instances:

```
1. Go to EC2 Console
2. Select your Ubuntu instance
3. Click "Connect" button
4. Choose "Session Manager" tab
5. Click "Connect"
6. You'll get a browser-based terminal!
```

#### For Windows Instances:

```
1. Go to EC2 Console
2. Select your Windows instance
3. Click "Connect" button
4. Choose "Session Manager" tab
5. Click "Connect"
6. You'll get PowerShell session in browser
```

---

### Method 2: Connect via AWS CLI

#### Install Session Manager Plugin (One-time setup)

**On Ubuntu/Debian:**

```bash
# Download plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"

# Install
sudo dpkg -i session-manager-plugin.deb

# Verify installation
session-manager-plugin --version
```

**On macOS:**

```bash
# Download plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"

# Extract
unzip sessionmanager-bundle.zip

# Install
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin

# Verify
session-manager-plugin --version
```

**On Windows (PowerShell as Administrator):**

```powershell
# Download installer
Invoke-WebRequest -Uri "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe" -OutFile "$env:TEMP\SessionManagerPluginSetup.exe"

# Install
Start-Process -FilePath "$env:TEMP\SessionManagerPluginSetup.exe" -ArgumentList "/quiet" -Wait

# Verify
session-manager-plugin
```

#### Connect to Linux Instance:

```bash
# Basic connection
aws ssm start-session --target i-1234567890abcdef0

# You'll get interactive shell
# Type commands as you would in SSH
sh-4.2$ whoami
ssm-user

sh-4.2$ sudo su - ubuntu
ubuntu@ip-10-0-1-100:~$
```

#### Connect to Windows Instance:

```powershell
# Start PowerShell session
aws ssm start-session --target i-1234567890abcdef0

# You'll get PowerShell prompt
PS C:\Windows\system32> whoami
nt authority\system

PS C:\Windows\system32> Get-ComputerInfo
```

#### Using Specific Profile:

```bash
# Connect using specific AWS profile
aws ssm start-session \
  --target i-1234567890abcdef0 \
  --profile production

# Specify region
aws ssm start-session \
  --target i-1234567890abcdef0 \
  --region us-west-2
```

---

### Method 3: SSH Over SSM (Port Forwarding)

You can use traditional SSH but tunnel through SSM (no Security Group port 22 needed!):

#### Step 1: Configure SSH Client

Add to your `~/.ssh/config`:

```bash
# SSH over Session Manager
host i-* mi-*
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
    User ubuntu
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

#### Step 2: Enable SSH on Instance

Make sure SSH daemon is running:

```bash
# Connect via Session Manager first
aws ssm start-session --target i-1234567890abcdef0

# Enable SSH
sudo systemctl start sshd
sudo systemctl enable sshd
```

#### Step 3: Connect via SSH Over SSM

```bash
# Now you can SSH without opening port 22!
ssh ubuntu@i-1234567890abcdef0

# With specific key
ssh -i ~/.ssh/mykey.pem ubuntu@i-1234567890abcdef0

# Run single command
ssh ubuntu@i-1234567890abcdef0 "df -h"

# Copy files with SCP
scp file.txt ubuntu@i-1234567890abcdef0:/home/ubuntu/

# Use rsync
rsync -av /local/folder ubuntu@i-1234567890abcdef0:/remote/folder/
```

---

### Method 4: Port Forwarding to Private Services

Access services running on private instances (databases, web servers, etc.):

#### Forward RDP Port (Windows):

```bash
# Forward RDP port 3389 to local port 9999
aws ssm start-session \
  --target i-1234567890abcdef0 \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=3389,localPortNumber=9999"

# Connect RDP client to localhost:9999
# In another terminal:
mstsc /v:localhost:9999  # Windows
# OR
rdesktop localhost:9999  # Linux
```

#### Forward MySQL/PostgreSQL:

```bash
# Forward MySQL port 3306
aws ssm start-session \
  --target i-1234567890abcdef0 \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=3306,localPortNumber=3306"

# Connect from another terminal
mysql -h 127.0.0.1 -P 3306 -u root -p

# PostgreSQL
aws ssm start-session \
  --target i-1234567890abcdef0 \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=5432,localPortNumber=5432"

psql -h localhost -p 5432 -U postgres
```

#### Forward Web Application:

```bash
# Forward web server port 8080
aws ssm start-session \
  --target i-1234567890abcdef0 \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=8080,localPortNumber=8080"

# Access in browser: http://localhost:8080
```

---

### Method 5: Run Commands Without Interactive Session

Execute commands remotely without opening a session:

```bash
# Run single command
aws ssm send-command \
  --instance-ids "i-1234567890abcdef0" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["df -h", "free -m"]'

# Check command status
aws ssm list-commands \
  --command-id "command-id-from-previous-output"

# Get command output
aws ssm get-command-invocation \
  --command-id "command-id" \
  --instance-id "i-1234567890abcdef0"
```

---

### Method 6: Connect via Third-Party Tools

#### Using VS Code Remote SSH:

Install "Remote - SSH" extension and use SSH over SSM configuration above.

#### Using MobaXterm (Windows):

Configure SSH tunnel through SSM in session settings.

---

## Restrict AWS Users for Specific EC2 Instances

### Understanding IAM Policies for SSM Access

You can control WHO can access WHICH instances using IAM policies.

---

### Scenario 1: Allow User to Access All Instances

Grant full SSM access to all managed instances:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:instance/*",
        "arn:aws:ssm:*:*:document/AWS-StartSSHSession",
        "arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus",
        "ssm:DescribeInstanceProperties",
        "ssm:DescribeInstanceInformation",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:TerminateSession"
      ],
      "Resource": "arn:aws:ssm:*:*:session/${aws:username}-*"
    }
  ]
}
```

---

### Scenario 2: Restrict User to Specific Instance by Instance ID

Allow access only to specific instance(s):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": [
        "arn:aws:ec2:us-east-1:123456789012:instance/i-1234567890abcdef0",
        "arn:aws:ec2:us-east-1:123456789012:instance/i-0987654321fedcba0",
        "arn:aws:ssm:*:*:document/AWS-StartSSHSession",
        "arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus",
        "ssm:DescribeInstanceInformation",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:TerminateSession"
      ],
      "Resource": "arn:aws:ssm:*:*:session/${aws:username}-*"
    }
  ]
}
```

**Apply Policy:**

```bash
# Create policy
aws iam create-policy \
  --policy-name SSM-Specific-Instance-Access \
  --policy-document file://policy.json

# Attach to user
aws iam attach-user-policy \
  --user-name john.doe \
  --policy-arn arn:aws:iam::123456789012:policy/SSM-Specific-Instance-Access
```

---

### Scenario 3: Restrict by EC2 Tags (Recommended)

Most flexible approach - allow access based on instance tags:

#### Tag Your Instances:

```bash
# Tag instance for environment
aws ec2 create-tags \
  --resources i-1234567890abcdef0 \
  --tags Key=Environment,Value=Development

# Tag for team
aws ec2 create-tags \
  --resources i-1234567890abcdef0 \
  --tags Key=Team,Value=Backend

# Tag for project
aws ec2 create-tags \
  --resources i-1234567890abcdef0 \
  --tags Key=Project,Value=WebApp
```

#### Create IAM Policy for Tag-Based Access:

**Development Team Policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringEquals": {
          "ssm:resourceTag/Environment": "Development"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": [
        "arn:aws:ssm:*:*:document/AWS-StartSSHSession",
        "arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus",
        "ssm:DescribeInstanceInformation",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:TerminateSession"
      ],
      "Resource": "arn:aws:ssm:*:*:session/${aws:username}-*"
    }
  ]
}
```

**Multiple Tag Conditions:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringEquals": {
          "ssm:resourceTag/Team": "Backend",
          "ssm:resourceTag/Environment": ["Development", "Staging"]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": [
        "arn:aws:ssm:*:*:document/AWS-StartSSHSession",
        "arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus",
        "ssm:DescribeInstanceInformation",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:TerminateSession"
      ],
      "Resource": "arn:aws:ssm:*:*:session/${aws:username}-*"
    }
  ]
}
```

---

### Scenario 4: Deny Access to Production (Except for Admins)

Create a deny policy for junior developers:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringEquals": {
          "ssm:resourceTag/Environment": "Production"
        }
      }
    }
  ]
}
```

---

### Scenario 5: Time-Based Access Restrictions

Allow access only during business hours:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "DateGreaterThan": {
          "aws:CurrentTime": "2024-01-01T09:00:00Z"
        },
        "DateLessThan": {
          "aws:CurrentTime": "2024-12-31T18:00:00Z"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": [
        "arn:aws:ssm:*:*:document/AWS-StartSSHSession",
        "arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus",
        "ssm:DescribeInstanceInformation",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### Scenario 6: Read-Only Access (View but Not Connect)

Allow users to see instances but not start sessions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeInstanceInformation",
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### Scenario 7: Restrict by IP Address

Allow SSM access only from specific IP addresses:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": "*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": [
            "203.0.113.0/24",
            "198.51.100.0/24"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus",
        "ssm:DescribeInstanceInformation",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### Creating and Assigning Policies

#### Create IAM Policy:

```bash
# Save policy as json file
cat > ssm-dev-access-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [...]
}
EOF

# Create policy
aws iam create-policy \
  --policy-name SSM-Development-Access \
  --policy-document file://ssm-dev-access-policy.json \
  --description "Allows SSM access to development instances only"
```

#### Attach to User:

```bash
# Attach to specific user
aws iam attach-user-policy \
  --user-name john.doe \
  --policy-arn arn:aws:iam::123456789012:policy/SSM-Development-Access

# Attach to group
aws iam attach-group-policy \
  --group-name Developers \
  --policy-arn arn:aws:iam::123456789012:policy/SSM-Development-Access
```

#### Create IAM Group with Policy:

```bash
# Create group
aws iam create-group --group-name DevOps-Team

# Attach policy to group
aws iam attach-group-policy \
  --group-name DevOps-Team \
  --policy-arn arn:aws:iam::123456789012:policy/SSM-Development-Access

# Add users to group
aws iam add-user-to-group \
  --user-name john.doe \
  --group-name DevOps-Team
```

---

## Troubleshooting

### Instance Not Showing in Session Manager

**Check 1: Verify IAM Role**

```bash
# Check if instance has IAM role
aws ec2 describe-instances \
  --instance-ids i-1234567890abcdef0 \
  --query 'Reservations[].Instances[].IamInstanceProfile'
```

**Solution:**
- Attach IAM role with `AmazonSSMManagedInstanceCore` policy

**Check 2: Verify SSM Agent Status**

```bash
# Connect via SSH first
ssh -i key.pem ubuntu@instance-ip

# Check agent status
sudo systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service

# Check logs
sudo tail -f /var/log/amazon/ssm/amazon-ssm-agent.log
```

**Solution:**
```bash
# Restart agent
sudo snap restart amazon-ssm-agent

# Or reinstall
sudo snap remove amazon-ssm-agent
sudo snap install amazon-ssm-agent --classic
sudo snap start amazon-ssm-agent
```

**Check 3: Network Connectivity**

```bash
# Test connectivity to SSM endpoints
curl -I https://ssm.us-east-1.amazonaws.com
curl -I https://ssmmessages.us-east-1.amazonaws.com
curl -I https://ec2messages.us-east-1.amazonaws.com
```

**Solution:**
- Ensure Security Group allows outbound HTTPS (443)
- Check NAT Gateway or VPC Endpoints configuration

---

### "User is not authorized to perform: ssm:StartSession"

**Check User Permissions:**

```bash
# Check user's policies
aws iam list-attached-user-policies --user-name john.doe

# Check group policies
aws iam list-groups-for-user --user-name john.doe
aws iam list-attached-group-policies --group-name Developers
```

**Solution:**
- Attach appropriate SSM policy to user or group
- Verify instance tags match policy conditions

---

### Session Manager Plugin Not Found

**Error:**
```
SessionManagerPlugin is not found. Please refer to SessionManager Documentation here: http://docs.aws.amazon.com/console/systems-manager/session-manager-plugin-not-found
```

**Solution:**
- Install Session Manager Plugin (see Method 2 above)
- Verify installation: `session-manager-plugin --version`

---

### Port Forwarding Not Working

**Check:**
1. Service is running on target port
2. Firewall allows local connections
3. Correct document name used (`AWS-StartPortForwardingSession`)

**Solution:**
```bash
# Test service is running
aws ssm start-session --target i-1234567890abcdef0
sudo netstat -tulpn | grep 3306

# Retry port forwarding
aws ssm start-session \
  --target i-1234567890abcdef0 \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=3306,localPortNumber=3306"
```

---

### SSM Agent Not Updating

**Force Update:**

```bash
# Via AWS Console:
Systems Manager → Run Command → AWS-UpdateSSMAgent

# Via AWS CLI:
aws ssm send-command \
  --document-name "AWS-UpdateSSMAgent" \
  --instance-ids "i-1234567890abcdef0"
```

---

## Best Practices

### 1. Security Best Practices

✅ **Never Open SSH/RDP Ports**
- Use SSM Session Manager instead of port 22/3389
- Remove Security Group rules allowing public SSH/RDP

✅ **Use IAM Roles, Not Access Keys**
- Attach IAM roles to EC2 instances
- Never hardcode AWS credentials on instances

✅ **Implement Least Privilege**
- Grant minimum necessary permissions
- Use tag-based access control

✅ **Enable Session Logging**
```bash
# Configure session logging to S3 and CloudWatch
aws ssm update-document \
  --name "SSM-SessionManagerRunShell" \
  --content '{
    "schemaVersion": "1.0",
    "description": "Document to hold regional settings for Session Manager",
    "sessionType": "Standard_Stream",
    "inputs": {
      "s3BucketName": "my-session-logs-bucket",
      "s3KeyPrefix": "session-logs/",
      "cloudWatchLogGroupName": "/aws/ssm/session-logs",
      "cloudWatchEncryptionEnabled": true
    }
  }'
```

✅ **Enable MFA for Sensitive Operations**

✅ **Regularly Rotate IAM Credentials**

---

### 2. Operational Best Practices

✅ **Tag All Instances**
```bash
# Standardized tagging
aws ec2 create-tags --resources i-1234567890abcdef0 --tags \
  Key=Name,Value=web-server-01 \
  Key=Environment,Value=Production \
  Key=Team,Value=DevOps \
  Key=Project,Value=WebApp \
  Key=Owner,Value=john.doe@company.com
```

✅ **Monitor SSM Agent Health**
- Set up CloudWatch alarms for agent status
- Auto-update SSM Agent using AWS Systems Manager

✅ **Document Access Patterns**
- Maintain inventory of who needs access to what
- Review permissions quarterly

✅ **Use Session Manager Preferences**
```bash
# Set shell preferences
aws ssm update-document \
  --name "SSM-SessionManagerRunShell" \
  --document-version "\$LATEST" \
  --content '{
    "schemaVersion": "1.0",
    "inputs": {
      "runAsEnabled": true,
      "runAsDefaultUser": "ubuntu",
      "idleSessionTimeout": "20",
      "maxSessionDuration": "60"
    }
  }'
```

---

### 3. Cost Optimization

✅ **No Additional Charges for SSM**
- Session Manager is free (except data transfer)
- No bastion hosts needed (saves EC2 costs)

✅ **Use VPC Endpoints**
- Eliminates NAT Gateway data transfer costs
- More secure than Internet Gateway

---

### 4. Compliance and Auditing

✅ **Enable AWS CloudTrail**
- Logs all SSM API calls
- Track who accessed which instance

✅ **Configure Session Logs**
- Store session transcripts in S3
- Stream to CloudWatch Logs for analysis

✅ **Regular Access Reviews**
```bash
# List recent SSM sessions
aws ssm describe-sessions \
  --state History \
  --max-results 50

# Get session details
aws ssm describe-sessions \
  --filters "key=SessionId,value=session-id"
```

---

### 5. Automation

✅ **Automate Instance Setup**
```bash
# User data script for SSM
#!/bin/bash
snap install amazon-ssm-agent --classic
snap start amazon-ssm-agent
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
```

✅ **Use Infrastructure as Code**
```hcl
# Terraform example
resource "aws_iam_role" "ssm_role" {
  name = "EC2-SSM-Role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "EC2-SSM-InstanceProfile"
  role = aws_iam_role.ssm_role.name
}
```

---

## Quick Reference Commands

### Essential Commands Cheat Sheet

```bash
# List managed instances
aws ssm describe-instance-information

# Start session
aws ssm start-session --target i-1234567890abcdef0

# Port forwarding
aws ssm start-session \
  --target i-1234567890abcdef0 \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=3306,localPortNumber=3306"

# Run command without session
aws ssm send-command \
  --instance-ids i-1234567890abcdef0 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["uptime","df -h"]'

# Check SSM Agent status (on instance)
sudo systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service

# Restart SSM Agent
sudo snap restart amazon-ssm-agent

# Check instance connectivity to SSM
curl -I https://ssm.us-east-1.amazonaws.com
```

---

## Additional Resources

### AWS Documentation
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [IAM Policies for Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-restrict-access-examples.html)
- [SSM Agent Installation](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent.html)

### Related AWS Services
- AWS CloudTrail - Audit SSM access
- Amazon CloudWatch - Monitor sessions
- AWS Config - Track configuration compliance
- AWS IAM - Manage access control

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
