# Operations Runbook

Day-to-day operational procedures for BMI Health Tracker infrastructure.

---

## Table of Contents

- [Daily Operations](#daily-operations)
- [Service Management](#service-management)
- [Monitoring & Alerts](#monitoring--alerts)
- [Backup & Recovery](#backup--recovery)
- [Incident Response](#incident-response)
- [Maintenance Windows](#maintenance-windows)
- [Capacity Management](#capacity-management)

---

## Daily Operations

### Morning Health Check

```bash
# Connect to instance
ssh -i ~/.ssh/sarowar-ostad-mumbai.pem ubuntu@<PUBLIC_IP>

# Check all services
sudo systemctl status bmi-backend nginx postgresql

# Check for errors in last 24 hours
sudo journalctl -u bmi-backend --since "24 hours ago" | grep -i error

# Check disk space
df -h
# Alert if root partition > 80%

# Check memory
free -h
# Alert if used > 85%

# Check database size
sudo -u postgres psql -d bmidb -c "SELECT pg_size_pretty(pg_database_size('bmidb'));"
```

### Log Rotation

**Automated log rotation configuration:**
```bash
# Create logrotate config
sudo nano /etc/logrotate.d/bmi-backend

/var/log/bmi-backend.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 ubuntu ubuntu
    sharedscripts
    postrotate
        systemctl reload bmi-backend > /dev/null 2>&1 || true
    endscript
}
```

---

## Service Management

### Backend Service (bmi-backend)

```bash
# Status and logs
sudo systemctl status bmi-backend
sudo journalctl -u bmi-backend -f
sudo tail -f /var/log/bmi-backend.log

# Restart (zero-downtime not supported)
sudo systemctl restart bmi-backend

# Check process
ps aux | grep "node.*server.js"

# Check listening port
sudo netstat -tlnp | grep :3000
```

**Service file location:** `/etc/systemd/system/bmi-backend.service`

### Nginx Service

```bash
# Test configuration before reload
sudo nginx -t

# Reload (zero-downtime)
sudo nginx -s reload

# Restart (brief interruption)
sudo systemctl restart nginx

# Check error logs
sudo tail -50 /var/log/nginx/bmi-error.log

# Check access logs
sudo tail -50 /var/log/nginx/bmi-access.log
```

**Configuration location:** `/etc/nginx/sites-available/bmi-health-tracker`

### PostgreSQL Database

```bash
# Status
sudo systemctl status postgresql

# Connect as admin
sudo -u postgres psql

# Connect as app user
PGPASSWORD=<password> psql -U bmi_user -d bmidb -h localhost

# Check active connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity WHERE datname='bmidb';"

# Check database size
sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database WHERE datname='bmidb';"

# Vacuum and analyze (maintenance)
PGPASSWORD=<password> psql -U bmi_user -d bmidb -h localhost -c "VACUUM ANALYZE;"
```

---

## Monitoring & Alerts

### Key Metrics to Track

| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU Usage | > 80% for 10 min | Investigate process, consider scaling |
| Memory Usage | > 85% | Check for memory leaks, restart services |
| Disk Usage | > 80% | Clean logs, expand volume |
| API Response Time | > 500ms | Check database queries, optimize |
| Error Rate | > 5% of requests | Check logs, investigate errors |
| Database Connections | > 80 concurrent | Check connection pooling |

### Manual Monitoring Commands

```bash
# Real-time resource monitoring
htop

# CPU usage per process
ps aux --sort=-%cpu | head -20

# Memory usage per process
ps aux --sort=-%mem | head -20

# Disk I/O
iostat -x 5

# Network connections
sudo netstat -an | grep ESTABLISHED | wc -l

# API response time test
time curl http://localhost:3000/api/measurements
```

### CloudWatch Integration (Optional)

```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Configure
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Start
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl enable amazon-cloudwatch-agent
```

**Metrics to send:**
- CPU, memory, disk utilization
- Custom application metrics
- Log streams for centralized logging

---

## Backup & Recovery

### Automated Backup Script

**Create `/usr/local/bin/backup-bmi.sh`:**
```bash
#!/bin/bash
set -e

BACKUP_DIR="/home/ubuntu/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
S3_BUCKET="s3://batch09-ostad/backups/bmi-app"

mkdir -p $BACKUP_DIR

# Backup database
echo "Backing up database..."
PGPASSWORD=$DB_PASSWORD pg_dump -U bmi_user -d bmidb -h localhost \
  | gzip > $BACKUP_DIR/bmidb-$TIMESTAMP.sql.gz

# Backup Nginx config
echo "Backing up Nginx config..."
sudo cp /etc/nginx/sites-available/bmi-health-tracker \
  $BACKUP_DIR/nginx-config-$TIMESTAMP.conf

# Backup systemd service
sudo cp /etc/systemd/system/bmi-backend.service \
  $BACKUP_DIR/bmi-backend-$TIMESTAMP.service

# Upload to S3
echo "Uploading to S3..."
aws s3 cp $BACKUP_DIR/ $S3_BUCKET/ --recursive --exclude "*" --include "*$TIMESTAMP*"

# Keep only last 7 days locally
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed: $TIMESTAMP"
```

**Schedule backups:**
```bash
# Make executable
sudo chmod +x /usr/local/bin/backup-bmi.sh

# Add to cron (2 AM daily)
sudo crontab -e
0 2 * * * /usr/local/bin/backup-bmi.sh >> /var/log/bmi-backup.log 2>&1
```

### Restore Procedure

```bash
# 1. List available backups
aws s3 ls s3://batch09-ostad/backups/bmi-app/

# 2. Download backup
aws s3 cp s3://batch09-ostad/backups/bmi-app/bmidb-20260224-020000.sql.gz .

# 3. Restore database
gunzip bmidb-20260224-020000.sql.gz
PGPASSWORD=<pass> psql -U bmi_user -d bmidb -h localhost < bmidb-20260224-020000.sql

# 4. Restart backend
sudo systemctl restart bmi-backend

# 5. Verify data
PGPASSWORD=<pass> psql -U bmi_user -d bmidb -h localhost -c "SELECT COUNT(*) FROM measurements;"
```

---

## Incident Response

### Severity Levels

| Level | Description | Response Time | Example |
|-------|-------------|---------------|---------|
| **P1 - Critical** | Complete outage | < 15 min | Application down, database crashed |
| **P2 - High** | Major feature broken | < 1 hour | API errors, can't submit measurements |
| **P3 - Medium** | Minor feature issue | < 4 hours | Chart not loading, slow response |
| **P4 - Low** | Cosmetic issue | < 24 hours | UI alignment, typos |

### P1 - Critical Incident Response

**Application completely down:**

```bash
# 1. Acknowledge incident (update status page if exists)

# 2. Connect to instance
ssh -i ~/.ssh/key.pem ubuntu@<PUBLIC_IP>

# 3. Check services
sudo systemctl status bmi-backend nginx postgresql

# 4. Quick fixes:
# - Restart crashed service
sudo systemctl restart bmi-backend

# - Check disk space
df -h
# If full: sudo journalctl --vacuum-size=500M

# - Check memory
free -h
# If OOM: sudo systemctl restart bmi-backend

# 5. If instance is unresponsive:
# From local machine:
terraform destroy -target=module.ec2_instance.aws_instance.this
terraform apply
# Creates new instance (15 min)

# 6. Document incident
# Create incident report
```

### Database Failure

```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check logs
sudo tail -100 /var/log/postgresql/*.log

# Restart database
sudo systemctl restart postgresql

# If data corruption:
# Restore from latest backup
aws s3 cp s3://batch09-ostad/backups/bmi-app/latest.sql.gz .
# Follow restore procedure

# Test connection
PGPASSWORD=<pass> psql -U bmi_user -d bmidb -h localhost -c "SELECT 1;"
```

---

## Maintenance Windows

### Scheduled Maintenance

**Recommended:** Sunday 2:00 AM - 4:00 AM (low traffic)

**Pre-maintenance checklist:**
- [ ] Notify users (24-48 hours notice)
- [ ] Create database backup
- [ ] Export Terraform state backup
- [ ] Document rollback plan
- [ ] Have team member on standby

### Zero-Downtime Updates

**Application code updates:**
```bash
# 1. SSH to instance
ssh ubuntu@<IP>

# 2. Pull latest code
cd /home/ubuntu/bmi-health-tracker
git pull origin main

# 3. Install dependencies (if changed)
cd backend && npm install
cd frontend && npm install && npm run build

# 4. Update frontend (zero downtime)
sudo rm -rf /var/www/bmi-health-tracker/*
sudo cp -r frontend/dist/* /var/www/bmi-health-tracker/

# 5. Restart backend (brief interruption)
sudo systemctl restart bmi-backend

# 6. Reload Nginx (zero downtime)
sudo nginx -s reload
```

**Database migrations:**
```bash
# Non-breaking migrations (adding columns, indexes)
PGPASSWORD=<pass> psql -U bmi_user -d bmidb -h localhost -f migrations/new.sql
# No downtime

# Breaking migrations (removing columns, changing types)
# Requires blue-green deployment or maintenance window
```

---

## Capacity Management

### Scaling Instance

**Vertical scaling (more CPU/RAM):**
```bash
# 1. Update instance type
cd terraform
nano terraform.tfvars
# Change: instance_type = "t3.large"

# 2. Apply (causes stop/start)
terraform apply
# Downtime: ~2-3 minutes
```

**Storage expansion:**
```bash
# 1. Increase volume size in Terraform
# modules/ec2/main.tf:
root_block_device {
  volume_size = 40  # Increased from 20
}

# 2. Apply change
terraform apply

# 3. On instance, expand filesystem
sudo growpart /dev/nvme0n1 1
sudo resize2fs /dev/nvme0n1p1

# 4. Verify
df -h
```

### Database Optimization

```bash
# Check slow queries
sudo -u postgres psql -d bmidb -c "
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
"

# Add missing indexes
# Review queries and add indexes as needed

# Vacuum and analyze
PGPASSWORD=<pass> psql -U bmi_user -d bmidb -h localhost -c "VACUUM ANALYZE;"

# Update statistics
PGPASSWORD=<pass> psql -U bmi_user -d bmidb -h localhost -c "ANALYZE;"
```

---

## Emergency Contacts

| Role | Contact | Escalation |
|------|---------|------------|
| **Primary On-Call** | DevOps Team | Phone/Slack |
| **Backup On-Call** | Senior DevOps | After 15 min |
| **Database Issues** | DBA Team | For data loss |
| **Security Incidents** | Security Team | Immediately |
| **AWS Support** | AWS Enterprise Support | For AWS outages |

---

## 🧑‍💻 Author

*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
