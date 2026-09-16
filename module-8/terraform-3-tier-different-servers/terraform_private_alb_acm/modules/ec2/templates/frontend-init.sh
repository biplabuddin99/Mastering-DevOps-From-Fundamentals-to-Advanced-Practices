#!/bin/bash
################################################################################
# Frontend Server Initialization Script
# This script sets up Nginx and builds/deploys the React frontend
#
# To re-run this script after initial boot:
#   sudo bash /usr/local/bin/init-frontend.sh
################################################################################

# Exit on errors — certbot section uses targeted || true where optional
set -e

# Logging
exec > >(tee -a /var/log/user-data.log)
exec 2>&1

echo "=================================="
echo "Frontend Server Initialization"
echo "Started: $(date)"
echo "=================================="

# Save this script to /usr/local/bin for manual re-runs
if [ ! -f /usr/local/bin/init-frontend.sh ]; then
    cat <<'SCRIPT_EOF' > /usr/local/bin/init-frontend.sh
#!/bin/bash
# This is a saved copy of the user-data script
# Run with: sudo bash /usr/local/bin/init-frontend.sh
exec > >(tee -a /var/log/user-data-manual.log)
exec 2>&1
set -e
SCRIPT_EOF
    
    # Append the rest of this script
    tail -n +32 "$$0" >> /usr/local/bin/init-frontend.sh 2>/dev/null || true
    chmod +x /usr/local/bin/init-frontend.sh
    echo "Script saved to /usr/local/bin/init-frontend.sh for manual re-runs"
fi

# Update system
echo "Updating system packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
apt-get install -y git curl build-essential nginx

# Install Certbot and Route53 plugin
echo "Installing Certbot with Route53 plugin..."
apt-get install -y certbot python3-certbot-dns-route53 python3-certbot-nginx awscli

# Install Node.js 22.x LTS (needed for building)
echo "Installing Node.js 22.x LTS..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Verify installations
node --version
npm --version
nginx -v

# Create application directory
echo "Setting up application..."
APP_DIR="/home/ubuntu/bmi-health-tracker"
mkdir -p $${APP_DIR}
cd $${APP_DIR}

# Clone repository
echo "Cloning repository..."
git clone -b ${git_branch} ${git_repo} . || { echo "ERROR: git clone failed"; exit 1; }

# Navigate to frontend directory
cd frontend

# Install dependencies
echo "Installing frontend dependencies..."
npm install

# Build production bundle
echo "Building frontend for production..."
npm run build

# Deploy to Nginx web root
echo "Deploying frontend to Nginx..."
WEB_ROOT="/var/www/bmi-health-tracker"
mkdir -p $${WEB_ROOT}
cp -r dist/* $${WEB_ROOT}/
chown -R www-data:www-data $${WEB_ROOT}
chmod -R 755 $${WEB_ROOT}

# Configure Nginx
echo "Configuring Nginx..."
cat > /etc/nginx/sites-available/bmi-health-tracker << 'NGINX_EOF'
server {
    listen 80;
    listen [::]:80;
    server_name ${domain_name};

    root /var/www/bmi-health-tracker;
    index index.html;

    # Hide Nginx version
    server_tokens off;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Frontend - React SPA routing
    location / {
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Backend API proxy
    location /api/ {
        proxy_pass http://${backend_host}:${backend_port}/api/;
        proxy_http_version 1.1;
        
        # Proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Disable buffering for real-time responses
        proxy_buffering off;
        
        # Don't cache API responses
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # Health check endpoint (for ALB)
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logs
    access_log /var/log/nginx/bmi-access.log;
    error_log /var/log/nginx/bmi-error.log;
}
NGINX_EOF

# Enable site
ln -sf /etc/nginx/sites-available/bmi-health-tracker /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo "Testing Nginx configuration..."
nginx -t

# Restart Nginx
echo "Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx

# Verify Nginx is running
systemctl status nginx --no-pager

# Test frontend
echo "Testing frontend..."
sleep 5
curl -f http://localhost/health || echo "Warning: Frontend health check failed"

# Change ownership
chown -R ubuntu:ubuntu $${APP_DIR} || echo "Warning: Could not change ownership"

# ============================================================================
# Let's Encrypt Certificate Generation
# ============================================================================

echo "=================================="
echo "Generating Let's Encrypt Certificate"
echo "=================================="

echo "Domain: ${domain_name}"

# Poll until IAM role credentials are available (instance profile propagation)
echo "Waiting for IAM role credentials to be available..."
for i in $(seq 1 12); do
  aws sts get-caller-identity --region ${aws_region} > /dev/null 2>&1 && echo "IAM credentials ready!" && break
  echo "Attempt $i/12 — IAM credentials not ready, waiting 10s..."
  [ $i -eq 12 ] && { echo "ERROR: IAM credentials unavailable after 2 minutes"; exit 1; }
  sleep 10
done

# ============================================================================
# Check ACM for an existing valid certificate before requesting a new one.
# If a certificate exists with >= 10 days remaining, skip certbot entirely.
# ============================================================================
echo "Checking ACM for existing certificate for ${domain_name}..."
EXISTING_CERT_ARN=$(aws acm list-certificates \
  --region ${aws_region} \
  --query "CertificateSummaryList[?DomainName=='${domain_name}'].CertificateArn" \
  --output text 2>/dev/null | head -n1)

SKIP_CERTBOT=false

if [ -n "$EXISTING_CERT_ARN" ]; then
  echo "Found ACM certificate: $EXISTING_CERT_ARN"
  EXPIRY=$(aws acm describe-certificate \
    --certificate-arn "$EXISTING_CERT_ARN" \
    --region ${aws_region} \
    --query "Certificate.NotAfter" \
    --output text 2>/dev/null)

  if [ -n "$EXPIRY" ]; then
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null)
    NOW_EPOCH=$(date +%s)
    DAYS_REMAINING=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
    echo "Certificate expires: $EXPIRY ($DAYS_REMAINING days remaining)"

    if [ "$DAYS_REMAINING" -ge 10 ]; then
      echo "Certificate has $DAYS_REMAINING days remaining (>= 10) — skipping certbot request."
      echo "$EXISTING_CERT_ARN" > /tmp/certificate-arn.txt
      SKIP_CERTBOT=true
    else
      echo "Certificate expires in $DAYS_REMAINING days (< 10) — requesting a new certificate."
    fi
  fi
else
  echo "No existing ACM certificate found — requesting new certificate."
fi

if [ "$SKIP_CERTBOT" = "false" ]; then
  echo "Requesting Let's Encrypt certificate via Certbot..."
  certbot certonly \
    --dns-route53 \
    -d ${domain_name} \
    --preferred-challenges dns \
    --agree-tos \
    --non-interactive \
    --email admin@${domain_name} \
    --keep-until-expiring || echo "Warning: Certificate generation failed, will retry later"
fi

# Check if certificate is available locally (new or pre-existing from previous run)
if [ -f "/etc/letsencrypt/live/${domain_name}/fullchain.pem" ]; then
    echo "Certificate available locally — importing to ACM..."

    # ========================================================================
    # Export Certificate to AWS ACM
    # ========================================================================

    echo "Exporting certificate to AWS ACM..."

    # Re-read ARN (may have been set above or saved from previous run)
    EXISTING_CERT_ARN=""
    if [ -f "/tmp/certificate-arn.txt" ]; then
        EXISTING_CERT_ARN=$(cat /tmp/certificate-arn.txt)
        echo "Using saved certificate ARN: $EXISTING_CERT_ARN"
    else
        echo "Searching for existing certificate in ACM..."
        EXISTING_CERT_ARN=$(aws acm list-certificates \
          --region ${aws_region} \
          --query "CertificateSummaryList[?DomainName=='${domain_name}'].CertificateArn" \
          --output text 2>/dev/null | head -n1)
        [ -n "$EXISTING_CERT_ARN" ] && echo "Found existing certificate in ACM: $EXISTING_CERT_ARN"
    fi

    # Import or update certificate
    if [ -n "$EXISTING_CERT_ARN" ]; then
        echo "Updating existing certificate: $EXISTING_CERT_ARN"
        CERT_ARN=$(aws acm import-certificate \
          --certificate-arn "$EXISTING_CERT_ARN" \
          --certificate fileb:///etc/letsencrypt/live/${domain_name}/cert.pem \
          --certificate-chain fileb:///etc/letsencrypt/live/${domain_name}/chain.pem \
          --private-key fileb:///etc/letsencrypt/live/${domain_name}/privkey.pem \
          --region ${aws_region} \
          --query 'CertificateArn' \
          --output text 2>&1) || echo "Warning: Certificate update failed"
    else
        echo "Importing new certificate to ACM..."
        CERT_ARN=$(aws acm import-certificate \
          --certificate fileb:///etc/letsencrypt/live/${domain_name}/cert.pem \
          --certificate-chain fileb:///etc/letsencrypt/live/${domain_name}/chain.pem \
          --private-key fileb:///etc/letsencrypt/live/${domain_name}/privkey.pem \
          --tags Key=Name,Value=${domain_name}-letsencrypt Key=ManagedBy,Value=Certbot Key=Domain,Value=${domain_name} Key=Project,Value=bmi-health-tracker Key=TerraformManaged,Value=true \
          --region ${aws_region} \
          --query 'CertificateArn' \
          --output text 2>&1) || echo "Warning: Certificate import failed"
    fi
    
    if [ ! -z "$CERT_ARN" ]; then
        echo "Certificate imported to ACM!"
        echo "Certificate ARN: $CERT_ARN"
        echo "$CERT_ARN" > /tmp/certificate-arn.txt
        echo "Note: ALB will use this certificate for HTTPS termination"
        echo "Nginx continues serving on HTTP - ALB forwards traffic on HTTP"
    fi
    
    # Setup automatic certificate renewal
    echo "Setting up automatic certificate renewal..."
    cat > /etc/cron.d/certbot-renew << 'CRON_EOF'
0 0,12 * * * root certbot renew --quiet --deploy-hook "systemctl reload nginx && /usr/local/bin/update-acm-cert.sh"
CRON_EOF
    
    # Create ACM update script
    cat > /usr/local/bin/update-acm-cert.sh << 'ACM_UPDATE_EOF'
#!/bin/bash
# Update ACM certificate after renewal
DOMAIN="${domain_name}"
CERT_ARN_FILE="/tmp/certificate-arn.txt"

if [ -f "$${CERT_ARN_FILE}" ]; then
    CERT_ARN=$$(cat "$${CERT_ARN_FILE}")
    aws acm import-certificate \
      --certificate-arn "$${CERT_ARN}" \
      --certificate fileb:///etc/letsencrypt/live/$${DOMAIN}/cert.pem \
      --certificate-chain fileb:///etc/letsencrypt/live/$${DOMAIN}/chain.pem \
      --private-key fileb:///etc/letsencrypt/live/$${DOMAIN}/privkey.pem \
      --region ${aws_region} || echo "Failed to update ACM certificate"
else
    echo "Certificate ARN file not found"
fi
ACM_UPDATE_EOF
    
    chmod +x /usr/local/bin/update-acm-cert.sh
    
else
    echo "Warning: Certificate generation failed. System will retry on next reboot."
fi

echo "=================================="
echo "Frontend Server Initialization Complete"
echo "Completed: $(date)"
echo "=================================="
echo "Frontend URL: http://localhost"
echo "HTTPS URL: https://${domain_name}"
echo "Web Root: $${WEB_ROOT}"
echo "Nginx Config: /etc/nginx/sites-available/bmi-health-tracker"
echo "Certificate: /etc/letsencrypt/live/${domain_name}/"
echo "=================================="
echo "Nginx Status:"
systemctl status nginx --no-pager | head -n 10
echo "=================================="
