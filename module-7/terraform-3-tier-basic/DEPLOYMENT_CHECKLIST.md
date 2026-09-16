# Deployment Checklist

Pre-deployment, deployment, and post-deployment verification checklist for BMI Health Tracker.

---

## Pre-Deployment Checklist

### AWS Prerequisites

- [ ] **AWS CLI configured**
  ```bash
  aws sts get-caller-identity --profile sarowar-ostad
  # Should show your account ID
  ```

- [ ] **S3 bucket created for state**
  ```bash
  aws s3 ls s3://batch09-ostad --profile sarowar-ostad
  # Should list bucket contents
  ```

- [ ] **VPC and subnet identified**
  ```bash
  aws ec2 describe-vpcs --profile sarowar-ostad
  aws ec2 describe-subnets --profile sarowar-ostad
  ```

- [ ] **Security group configured**
  - Port 22 (SSH) from admin IP
  - Port 80 (HTTP) from 0.0.0.0/0
  - Port 443 (HTTPS) from 0.0.0.0/0 (optional)

- [ ] **EC2 key pair downloaded**
  ```bash
  ls -la ~/.ssh/sarowar-ostad-mumbai.pem
  chmod 400 ~/.ssh/sarowar-ostad-mumbai.pem
  ```

### Local Environment

- [ ] **Terraform installed**
  ```bash
  terraform version
  # Should be >= 1.0
  ```

- [ ] **Git repository cloned**
  ```bash
  pwd
  # Should show: .../terraform-3-tier-basic
  ```

- [ ] **terraform.tfvars configured**
  ```bash
  cd terraform
  test -f terraform.tfvars && echo "✅ Exists" || echo "❌ Missing"
  ```

### Configuration Values

- [ ] **aws_profile** matches your AWS CLI profile name
- [ ] **aws_region** matches your deployment region
- [ ] **vpc_id** is valid VPC ID (vpc-xxxxxxxxxxxx)
- [ ] **subnet_id** is public subnet with internet gateway
- [ ] **security_group_id** has required inbound rules
- [ ] **key_name** matches your EC2 key pair name
- [ ] **db_password** is strong (16+ characters)
- [ ] **ami_id** is Ubuntu 22.04 for your region

**Validation commands:**
```bash
cd terraform

# Validate configuration
terraform validate

# Check formatting
terraform fmt -check

# Review variables
grep -v "^#" terraform.tfvars | grep -v "^$"
```

---

## Deployment Execution

### Phase 1: Initialize Terraform (1 minute)

```bash
cd terraform
terraform init
```

**Expected output:**
```
Initializing the backend...
Successfully configured the backend "s3"!
Initializing provider plugins...
Terraform has been successfully initialized!
```

**Checkpoints:**
- [ ] Backend initialized successfully
- [ ] AWS provider downloaded (~400MB)
- [ ] No error messages

**Troubleshooting:**
- If "bucket does not exist" → Create S3 bucket first
- If "access denied" → Check AWS credentials and profile
- If "region mismatch" → Verify backend.tf region matches bucket region

### Phase 2: Plan Infrastructure (30 seconds)

```bash
terraform plan
```

**Review plan output:**
- [ ] Shows **1 resource to add** (aws_instance.this)
- [ ] No resources to destroy (unless redeploying)
- [ ] Userdata script preview looks correct
- [ ] Instance type matches configuration
- [ ] AMI ID is correct for Ubuntu 22.04

**Red flags to investigate:**
- ⚠️ Resources marked for destruction (unintended)
- ⚠️ Instance will be replaced (causes data loss)
- ⚠️ Security group changes (may break access)

### Phase 3: Apply Infrastructure (2 minutes)

```bash
terraform apply
```

**Monitor:**
- [ ] Terraform creates EC2 instance
- [ ] Public IP assigned
- [ ] Output values displayed

**Expected outputs:**
```
Outputs:

application_url = "http://13.234.56.78"
instance_id = "i-0123456789abcdef"
instance_public_ip = "13.234.56.78"
ssh_command = "ssh -i ~/.ssh/sarowar-ostad-mumbai.pem ubuntu@13.234.56.78"
```

**Checkpoints:**
- [ ] Apply completed without errors
- [ ] Instance ID starts with `i-`
- [ ] Public IP is valid (can ping)
- [ ] SSH command displayed

**Save outputs:**
```bash
terraform output > deployment-outputs-$(date +%Y%m%d-%H%M%S).txt
```

### Phase 4: Monitor Bootstrap (12-15 minutes)

```bash
# Get SSH command from output
eval $(terraform output -raw ssh_command)

# Once connected, monitor deployment
sudo tail -f /var/log/user-data.log
```

**Watch for key milestones:**
- [ ] "Starting BMI Health Tracker Deployment" (t=0)
- [ ] "Updating package lists..." (t=30s)
- [ ] "Cloning application from GitHub..." (t=1min)
- [ ] "Application cloned successfully!" (t=2min)
- [ ] "Starting automated deployment..." (t=2min)
- [ ] "Using database credentials from environment variables" (t=3min)
- [ ] "Installing NVM..." (t=3-5min)
- [ ] "Installing Node.js LTS..." (t=5-7min)
- [ ] "PostgreSQL installed successfully" (t=7min)
- [ ] "Installing backend dependencies..." (t=8-10min)
- [ ] "Building frontend for production..." (t=10-12min)
- [ ] "BMI Backend service started successfully" (t=13min)
- [ ] "Nginx configuration is valid" (t=13min)
- [ ] "Deployment completed successfully!" (t=13-15min)

**In parallel terminal, watch application deployment:**
```bash
sudo tail -f /var/log/bmi-deployment.log
```

**Checkpoints per phase:**

**Phase 4a: Prerequisites (0-7 min)**
- [ ] NVM installed successfully
- [ ] Node.js LTS installed
- [ ] PostgreSQL installed and running
- [ ] Nginx installed and running

**Phase 4b: Database Setup (7-8 min)**
- [ ] Database 'bmidb' created
- [ ] User 'bmi_user' created
- [ ] Privileges granted
- [ ] Authentication configured
- [ ] Database connection successful

**Phase 4c: Backend Deployment (8-11 min)**
- [ ] .env file created
- [ ] Backend dependencies installed
- [ ] Database migrations applied
- [ ] Systemd service created
- [ ] Backend service started

**Phase 4d: Frontend Deployment (11-13 min)**
- [ ] Frontend dependencies installed
- [ ] Production build completed
- [ ] Files deployed to /var/www/bmi-health-tracker
- [ ] Nginx configuration created
- [ ] Nginx reloaded successfully

**Phase 4e: Health Checks (13-15 min)**
- [ ] Backend API responding
- [ ] Frontend serving correctly
- [ ] Database connection OK
- [ ] All services running

---

## Post-Deployment Verification

### Automated Verification (from local machine)

```bash
# Get instance IP
PUBLIC_IP=$(terraform output -raw instance_public_ip)

# Test HTTP access
curl -I http://$PUBLIC_IP
# Expected: HTTP/1.1 200 OK

# Test API endpoint
curl http://$PUBLIC_IP/api/measurements
# Expected: [] or [{"id": 1, ...}]

# Test frontend loads
curl -s http://$PUBLIC_IP | grep -q "<title>" && echo "✅ Frontend OK" || echo "❌ Frontend failed"
```

### Manual Verification (on EC2 instance)

**1. Service Status:**
```bash
sudo systemctl status bmi-backend
sudo systemctl status nginx
sudo systemctl status postgresql
```
- [ ] All services show "active (running)" in green
- [ ] No errors in status output

**2. Service Logs (last 20 lines):**
```bash
sudo journalctl -u bmi-backend -n 20
sudo tail -20 /var/log/nginx/bmi-access.log
sudo tail -20 /var/log/nginx/bmi-error.log
```
- [ ] No ERROR or FATAL messages
- [ ] Backend shows "Server running on port 3000"

**3. Database Verification:**
```bash
PGPASSWORD=0stad2025 psql -U bmi_user -d bmidb -h localhost -c "\dt"
```
- [ ] Table 'measurements' exists
- [ ] Can connect without errors

```bash
PGPASSWORD=0stad2025 psql -U bmi_user -d bmidb -h localhost -c "SELECT COUNT(*) FROM measurements;"
```
- [ ] Query executes successfully (count = 0 initially)

**4. Network Verification:**
```bash
sudo netstat -tlnp | grep -E ":(80|3000|5432)"
```
- [ ] Port 80 - nginx (0.0.0.0:80)
- [ ] Port 3000 - node (0.0.0.0:3000 or 127.0.0.1:3000)
- [ ] Port 5432 - postgres (127.0.0.1:5432)

**5. API Functionality Test:**
```bash
# Test GET measurements
curl http://localhost:3000/api/measurements
# Expected: []

# Test POST measurement
curl -X POST http://localhost:3000/api/measurements \
  -H "Content-Type: application/json" \
  -d '{"weight": 70, "height": 1.75, "date": "2026-02-24"}'
# Expected: {"id": 1, "weight": 70, ...}

# Verify in database
PGPASSWORD=0stad2025 psql -U bmi_user -d bmidb -h localhost \
  -c "SELECT * FROM measurements;"
# Should show the inserted record
```
- [ ] GET returns array
- [ ] POST creates record
- [ ] Data persists in database

### Browser Testing (from your machine)

**1. Access Application:**
```
URL: http://<PUBLIC_IP from terraform output>
```

- [ ] Page loads without errors
- [ ] React app renders correctly
- [ ] No console errors (F12 Developer Tools)

**2. Test Form Submission:**
- [ ] Enter weight: 70
- [ ] Enter height: 175
- [ ] Click "Add Measurement"
- [ ] Success message appears
- [ ] Data appears in chart/list

**3. Test Data Persistence:**
- [ ] Refresh browser (F5)
- [ ] Submitted data still visible
- [ ] Chart renders with data points

**4. Test API from Browser Console:**
```javascript
// F12 → Console tab
fetch('/api/measurements').then(r => r.json()).then(console.log)
// Should show array with measurement objects
```

---

## Post-Deployment Tasks

### Security Hardening (Optional but Recommended)

```bash
# 1. Tighten security group (SSH from specific IP only)
aws ec2 authorize-security-group-ingress \
  --group-id sg-097d6afb08616ba09 \
  --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges="[{CidrIp=YOUR_IP/32}]" \
  --profile sarowar-ostad

# 2. Enable UFW firewall
ssh ubuntu@<IP>
sudo ufw allow from YOUR_IP to any port 22
sudo ufw allow 80/tcp
sudo ufw enable

# 3. Set up automated backups
# Follow backup script in OPERATIONS.md

# 4. Configure CloudWatch monitoring
# Follow CloudWatch setup in README.md
```

### Documentation Updates

- [ ] Update team wiki with instance details
- [ ] Share application URL with stakeholders
- [ ] Document any deployment issues encountered
- [ ] Update runbook with environment-specific notes

### Notification

- [ ] Notify development team deployment is complete
- [ ] Share monitoring dashboard URL (if configured)
- [ ] Confirm on-call rotation updated
- [ ] Update deployment calendar

---

## Rollback Checklist

### If Deployment Fails

**1. Check error location:**
```bash
# Terraform errors (infra level)
terraform show
terraform state list

# Userdata errors (bootstrap level)
ssh ubuntu@<IP>
sudo cat /var/log/user-data.log
sudo cat /var/log/cloud-init-output.log

# Application errors (app level)
sudo tail -100 /var/log/bmi-deployment.log
```

**2. Quick rollback:**
```bash
# Destroy failed deployment
cd terraform
terraform destroy -auto-approve

# Fix issues in code
git log --oneline
git checkout <previous-working-commit>

# Redeploy
terraform apply -auto-approve
```

**3. If previous instance still exists:**
```bash
# Restore to previous instance
terraform import module.ec2_instance.aws_instance.this i-OLD_INSTANCE_ID
# Update terraform.tfvars to match old instance config
```

---

## Maintenance Window Checklist

### Planned Maintenance

**Before maintenance:**
- [ ] Schedule maintenance window (low-traffic time)
- [ ] Notify users 24-48 hours in advance
- [ ] Create full backup (database + config)
- [ ] Test changes in dev environment
- [ ] Prepare rollback plan
- [ ] Have team member on standby

**During maintenance:**
- [ ] Mark system as "under maintenance" (status page)
- [ ] Take final backup before changes
- [ ] Execute changes systematically
- [ ] Monitor logs continuously
- [ ] Test each component after change

**After maintenance:**
- [ ] Run full verification checklist (above)
- [ ] Monitor for 30 minutes post-change
- [ ] Update documentation
- [ ] Mark system as operational
- [ ] Send completion notification

---

## Emergency Rollback

### Critical Issue Detected

**Immediate actions (< 5 minutes):**

```bash
# 1. Revert to previous code version
ssh ubuntu@<IP>
cd /home/ubuntu/bmi-health-tracker
git log --oneline | head -5
git checkout <previous-commit-hash>

# 2. Restart services
sudo systemctl restart bmi-backend
sudo systemctl restart nginx

# 3. If database changes were made:
# Restore from backup
aws s3 cp s3://batch09-ostad/backups/bmi-app/latest.sql.gz .
gunzip latest.sql.gz
PGPASSWORD=0stad2025 psql -U bmi_user -d bmidb -h localhost < latest.sql

# 4. Verify rollback
curl http://localhost:3000/api/measurements
curl -I http://localhost

# 5. Monitor logs
sudo tail -f /var/log/bmi-backend.log
```

**Post-rollback:**
- [ ] Confirm application is working
- [ ] Notify users issue is resolved
- [ ] Document what went wrong
- [ ] Plan proper fix and redeployment

---

## Sign-Off

### Deployment Sign-Off

**Deployment Details:**
- Date: _______________________
- Deployed By: __________________
- Version/Commit: _______________
- Instance ID: __________________
- Public IP: ____________________

**Verification:**
- [ ] All services running
- [ ] Application accessible from browser
- [ ] API endpoints responding
- [ ] Database operational
- [ ] Logs show no errors
- [ ] Monitoring configured
- [ ] Backups scheduled
- [ ] Documentation updated

**Approvals:**
- [ ] Technical Lead: _________________ Date: _________
- [ ] Operations Lead: _______________ Date: _________

---

## Quick Reference

**Most Common Commands:**

```bash
# Check status
ssh ubuntu@<IP>
sudo systemctl status bmi-backend nginx postgresql

# View logs
sudo tail -f /var/log/bmi-backend.log
sudo tail -f /var/log/nginx/bmi-error.log

# Restart services
sudo systemctl restart bmi-backend
sudo systemctl restart nginx

# Emergency: Destroy and recreate
cd terraform
terraform destroy -auto-approve && terraform apply -auto-approve

# Get instance details
terraform output
```

---

## 🧑‍💻 Author

*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
