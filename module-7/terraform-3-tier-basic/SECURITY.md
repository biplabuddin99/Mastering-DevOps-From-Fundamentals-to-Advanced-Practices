# Security Policy

Security guidelines and vulnerability reporting for BMI Health Tracker.

---

## Table of Contents

- [Supported Versions](#supported-versions)
- [Reporting a Vulnerability](#reporting-a-vulnerability)
- [Security Best Practices](#security-best-practices)
- [Known Security Limitations](#known-security-limitations)
- [Security Hardening Guide](#security-hardening-guide)
- [Compliance](#compliance)

---

## Supported Versions

| Version | Supported | Status |
|---------|-----------|--------|
| 1.x     | ✅ Yes    | Current release, actively maintained |
| < 1.0   | ❌ No     | Development versions, not supported |

---

## Reporting a Vulnerability

**DO NOT** create public GitHub issues for security vulnerabilities.

### Reporting Process

1. **Email:** sarowar@hotmail.com with subject "SECURITY: BMI Health Tracker"
2. **Include:**
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact assessment
   - Suggested fix (if available)
3. **Expected Response:** 
   - Initial response: < 48 hours
   - Status update: Within 7 days
   - Fix timeline: Based on severity

### Severity Classification

| Severity | Examples | Response Time |
|----------|----------|---------------|
| **Critical** | RCE, SQL injection, auth bypass | < 24 hours |
| **High** | XSS, CSRF, data exposure | < 7 days |
| **Medium** | Information disclosure, DoS | < 30 days |
| **Low** | Minor info leaks, config issues | < 90 days |

---

## Security Best Practices

### For Operators

**1. Secrets Management:**
```bash
# ✅ DO: Use AWS Secrets Manager (production)
# ✅ DO: Rotate credentials regularly (90 days)
# ✅ DO: Use strong passwords (16+ chars, mixed)
# ❌ DON'T: Commit .env or terraform.tfvars to git
# ❌ DON'T: Share credentials in chat/email
# ❌ DON'T: Use default passwords
```

**2. Access Control:**
```bash
# ✅ DO: Use SSH keys, not passwords
# ✅ DO: Restrict security group to specific IPs
# ✅ DO: Use least-privilege IAM policies
# ❌ DON'T: Open SSH (port 22) to 0.0.0.0/0
# ❌ DON'T: Use root account for operations
# ❌ DON'T: Share SSH private keys
```

**3. State File Security:**
```bash
# ✅ DO: Enable S3 bucket versioning
# ✅ DO: Enable S3 bucket encryption
# ✅ DO: Restrict S3 bucket access via IAM
# ❌ DON'T: Store state in public S3 bucket
# ❌ DON'T: Commit state files to git
```

### For Developers

**1. Input Validation:**
```javascript
// ✅ Good - Validate and sanitize
app.post('/api/measurements', async (req, res) => {
  const { weight, height } = req.body;
  
  if (!weight || !height) {
    return res.status(400).json({ error: 'Missing required fields' });
  }
  
  if (weight <= 0 || height <= 0) {
    return res.status(400).json({ error: 'Invalid values' });
  }
  
  // Proceed with validated data
});

// ❌ Bad - No validation
app.post('/api/measurements', async (req, res) => {
  const { weight, height } = req.body;
  // Direct use without validation
});
```

**2. SQL Injection Prevention:**
```javascript
// ✅ Good - Parameterized queries
const result = await pool.query(
  'INSERT INTO measurements (weight, height, bmi) VALUES ($1, $2, $3)',
  [weight, height, bmi]
);

// ❌ Bad - String concatenation
const result = await pool.query(
  `INSERT INTO measurements (weight, height, bmi) VALUES (${weight}, ${height}, ${bmi})`
);
```

**3. XSS Prevention:**
```javascript
// ✅ Good - React escapes by default
<div>{userInput}</div>

// ❌ Bad - dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// Only use dangerouslySetInnerHTML with sanitized input:
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userInput) }} />
```

**4. CORS Configuration:**
```javascript
// ✅ Good - Specific origins (production)
app.use(cors({
  origin: ['https://bmi-tracker.example.com'],
  credentials: true
}));

// ⚠️ Acceptable for development
app.use(cors({
  origin: '*'
}));
```

---

## Known Security Limitations

### Current Implementation

**⚠️ Development/Testing Setup - Not Production-Ready:**

1. **No Authentication/Authorization**
   - Current: Public API, no user auth
   - Impact: Anyone can read/write data
   - Mitigation: Implement JWT/OAuth before production

2. **Embedded Credentials**
   - Current: DB password in terraform.tfvars, passed via userdata
   - Impact: Visible in Terraform state, EC2 metadata
   - Mitigation: Use AWS Secrets Manager

3. **HTTP Only (No SSL)**
   - Current: Unencrypted traffic
   - Impact: Data visible in transit
   - Mitigation: Configure Let's Encrypt (see below)

4. **Single Instance**
   - Current: No redundancy
   - Impact: Single point of failure
   - Mitigation: Multi-AZ deployment with ALB

5. **No Rate Limiting**
   - Current: Unlimited API requests
   - Impact: Vulnerable to DoS attacks
   - Mitigation: Implement rate limiting middleware

6. **Database on Same Instance**
   - Current: PostgreSQL co-located with application
   - Impact: Resource contention, backup complexity
   - Mitigation: Migrate to RDS

### Production Hardening Checklist

Before going to production, implement:

- [ ] SSL/TLS certificate (Let's Encrypt or ACM)
- [ ] User authentication (JWT or OAuth2)
- [ ] API rate limiting
- [ ] WAF (Web Application Firewall)
- [ ] Secrets Manager for credentials
- [ ] Database on RDS with encryption at rest
- [ ] Regular security scanning (AWS Inspector)
- [ ] Centralized logging (CloudWatch Logs)
- [ ] Automated backups with verification
- [ ] Network segmentation (private subnets)

---

## Security Hardening Guide

### 1. Enable SSL/TLS (Let's Encrypt)

```bash
# SSH to instance
ssh ubuntu@<IP>

# Install Certbot
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Obtain certificate (requires domain pointing to IP)
sudo certbot --nginx -d yourdomain.com

# Auto-renewal is configured by default
sudo systemctl status certbot.timer

# Verify HTTPS
curl -I https://yourdomain.com
```

**Update Terraform security group:**
```hcl
# Add HTTPS rule
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "HTTPS access"
}
```

### 2. Implement API Authentication

**Add JWT middleware:**
```javascript
// backend/src/middleware/auth.js
const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }
  
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
}

// Protect routes
app.post('/api/measurements', authenticateToken, async (req, res) => {
  // Handle request
});
```

### 3. Rate Limiting

```javascript
// backend/src/middleware/rateLimit.js
const rateLimit = require('express-rate-limit');

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: 'Too many requests, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', apiLimiter);
```

### 4. Security Headers

**Add to Nginx configuration:**
```nginx
# In /etc/nginx/sites-available/bmi-health-tracker
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

### 5. Firewall Configuration

```bash
# Install UFW
sudo apt install -y ufw

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (from specific IP only)
sudo ufw allow from YOUR_IP_ADDRESS to any port 22

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

### 6. Audit Logging

**Enable detailed logging:**
```bash
# PostgreSQL query logging
sudo -u postgres psql -c "ALTER SYSTEM SET log_statement = 'all';"
sudo -u postgres psql -c "ALTER SYSTEM SET log_min_duration_statement = 1000;"
sudo systemctl restart postgresql

# Nginx detailed access logs
# Already configured in /etc/nginx/sites-available/bmi-health-tracker

# System audit logs
sudo apt install -y auditd
sudo systemctl enable auditd
sudo systemctl start auditd
```

---

## Compliance

### Data Retention

**Current:** Data retained indefinitely

**Recommended for GDPR/compliance:**
- Implement data retention policy (e.g., 2 years)
- Allow user data deletion requests
- Log data access and modifications

### Regular Security Tasks

**Weekly:**
- [ ] Review access logs for anomalies
- [ ] Check for failed login attempts
- [ ] Verify backups are running

**Monthly:**
- [ ] Update system packages: `sudo apt update && sudo apt upgrade`
- [ ] Review npm audit results
- [ ] Rotate database passwords
- [ ] Review AWS CloudTrail logs

**Quarterly:**
- [ ] Security audit of codebase
- [ ] Penetration testing (external)
- [ ] Review and update security policies
- [ ] Disaster recovery drill

---

## Security Incident Response

### If Compromise Suspected

**Immediate actions:**
```bash
# 1. Isolate instance
# Remove from security group or:
aws ec2 modify-instance-attribute \
  --instance-id i-xxxxx \
  --no-source-dest-check

# 2. Create forensic snapshot
aws ec2 create-snapshot \
  --volume-id vol-xxxxx \
  --description "Forensic snapshot - suspected compromise"

# 3. Collect logs
sudo tar czf incident-logs-$(date +%Y%m%d-%H%M%S).tar.gz \
  /var/log/auth.log \
  /var/log/syslog \
  /var/log/nginx/*.log \
  /var/log/bmi-backend.log

# 4. Change all credentials immediately
# 5. Notify security team
# 6. Begin investigation
```

---

## 🧑‍💻 Author

*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
