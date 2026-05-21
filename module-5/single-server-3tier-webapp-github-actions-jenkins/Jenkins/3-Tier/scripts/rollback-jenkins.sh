#!/bin/bash
# rollback-jenkins.sh
# Rollback to a previous deployment backup
# Designed for use with Jenkins pipelines

set -e

# Configuration
DEPLOY_PATH="/home/ubuntu/single-server-3tier-webapp"
BACKUP_PATH="/home/ubuntu/bmi_deployments_backup"
PM2_PROCESS_NAME="bmi-backend"
NGINX_SITE_PATH="/var/www/bmi-health-tracker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================"
echo "  BMI Application Rollback Tool"
echo "================================================"
echo ""

# Load NVM if it exists
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Check if backup directory exists
if [ ! -d "$BACKUP_PATH" ]; then
    echo -e "${RED}❌ Backup directory not found: $BACKUP_PATH${NC}"
    echo "No backups available for rollback."
    exit 1
fi

# List available backups
echo "Available backups:"
echo ""
BACKUPS=($(ls -t "$BACKUP_PATH" | grep "^backup_"))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo -e "${RED}❌ No backups found in $BACKUP_PATH${NC}"
    exit 1
fi

# Display backups with details
counter=1
for backup in "${BACKUPS[@]}"; do
    backup_path="$BACKUP_PATH/$backup"
    backup_size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)
    backup_date=$(echo "$backup" | sed 's/backup_//' | sed 's/_/ /')
    
    echo -e "${BLUE}[$counter]${NC} $backup"
    echo "    Date: $backup_date"
    echo "    Size: $backup_size"
    
    # Show git commit info if available
    if [ -d "$backup_path/.git" ]; then
        cd "$backup_path"
        git_commit=$(git log -1 --pretty=format:"%h - %s" 2>/dev/null || echo "N/A")
        git_author=$(git log -1 --pretty=format:"%an" 2>/dev/null || echo "N/A")
        git_date=$(git log -1 --pretty=format:"%ad" --date=short 2>/dev/null || echo "N/A")
        echo "    Git: $git_commit"
        echo "    Author: $git_author ($git_date)"
    fi
    
    # Show backup info if available
    if [ -f "$backup_path/backup_info.txt" ]; then
        echo "    Info:"
        sed 's/^/      /' "$backup_path/backup_info.txt"
    fi
    
    echo ""
    ((counter++))
done

# Determine which backup to restore
BACKUP_TO_RESTORE=""

# Check for --auto-latest flag (for automated rollback)
if [ "$1" = "--auto-latest" ]; then
    BACKUP_TO_RESTORE="${BACKUPS[0]}"
    echo -e "${YELLOW}⚠️  Auto-rollback mode: Using latest backup${NC}"
    echo "Selected: $BACKUP_TO_RESTORE"
else
    # Interactive mode
    echo -n "Select backup to restore [1-${#BACKUPS[@]}] or 'q' to quit: "
    read selection
    
    if [ "$selection" = "q" ] || [ "$selection" = "Q" ]; then
        echo "Rollback cancelled."
        exit 0
    fi
    
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#BACKUPS[@]} ]; then
        echo -e "${RED}❌ Invalid selection${NC}"
        exit 1
    fi
    
    BACKUP_TO_RESTORE="${BACKUPS[$((selection-1))]}"
fi

echo ""
echo -e "${YELLOW}⚠️  WARNING: This will restore the application to a previous state!${NC}"
echo "Current deployment will be backed up before rollback."
echo ""

# Confirm rollback (skip in auto mode)
if [ "$1" != "--auto-latest" ]; then
    echo -n "Are you sure you want to rollback? [y/N]: "
    read confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Rollback cancelled."
        exit 0
    fi
fi

echo ""
echo "================================================"
echo "  Starting Rollback Process"
echo "================================================"
echo ""

# Step 1: Create backup of current deployment
echo "Step 1/7: Creating backup of current deployment..."
ROLLBACK_BACKUP="backup_rollback_$(date +%Y%m%d_%H%M%S)"

if [ -d "$DEPLOY_PATH" ]; then
    cp -r "$DEPLOY_PATH" "$BACKUP_PATH/$ROLLBACK_BACKUP"
    echo -e "${GREEN}✅ Current deployment backed up to: $ROLLBACK_BACKUP${NC}"
else
    echo -e "${YELLOW}⚠️  No current deployment found, skipping backup${NC}"
fi

# Step 2: Stop PM2 process
echo ""
echo "Step 2/7: Stopping PM2 process..."
if pm2 describe "$PM2_PROCESS_NAME" > /dev/null 2>&1; then
    pm2 stop "$PM2_PROCESS_NAME"
    echo -e "${GREEN}✅ PM2 process stopped${NC}"
else
    echo -e "${YELLOW}⚠️  PM2 process not running${NC}"
fi

# Step 3: Remove current deployment
echo ""
echo "Step 3/7: Removing current deployment..."
if [ -d "$DEPLOY_PATH" ]; then
    rm -rf "$DEPLOY_PATH"
    echo -e "${GREEN}✅ Current deployment removed${NC}"
else
    echo -e "${YELLOW}⚠️  No current deployment found${NC}"
fi

# Step 4: Restore backup
echo ""
echo "Step 4/7: Restoring backup..."
cp -r "$BACKUP_PATH/$BACKUP_TO_RESTORE" "$DEPLOY_PATH"
echo -e "${GREEN}✅ Backup restored to $DEPLOY_PATH${NC}"

# Step 5: Reinstall backend dependencies
echo ""
echo "Step 5/7: Reinstalling backend dependencies..."
cd "$DEPLOY_PATH/backend"
npm install --production
echo -e "${GREEN}✅ Backend dependencies installed${NC}"

# Step 6: Restart PM2 process
echo ""
echo "Step 6/7: Restarting PM2 process..."
if [ -f "ecosystem.config.js" ]; then
    pm2 start ecosystem.config.js
else
    pm2 start src/server.js --name "$PM2_PROCESS_NAME"
fi
pm2 save
echo -e "${GREEN}✅ PM2 process restarted${NC}"

# Step 7: Rebuild and redeploy frontend
echo ""
echo "Step 7/7: Rebuilding and redeploying frontend..."
cd "$DEPLOY_PATH/frontend"

# Check if node_modules exists, if not install dependencies
if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install
fi

# Build frontend
echo "Building frontend..."
npm run build

# Deploy to Nginx
echo "Deploying to Nginx..."
sudo cp -r dist/* "$NGINX_SITE_PATH/"
sudo chown -R www-data:www-data "$NGINX_SITE_PATH"
sudo chmod -R 755 "$NGINX_SITE_PATH"
sudo systemctl reload nginx
echo -e "${GREEN}✅ Frontend rebuilt and deployed${NC}"

# Step 8: Health checks
echo ""
echo "================================================"
echo "  Performing Health Checks"
echo "================================================"
echo ""

sleep 5  # Give services time to start

# Check PM2 status
echo "PM2 Status:"
pm2 status

# Check backend health
echo ""
echo "Backend Health Check:"
BACKEND_HEALTH=$(curl -sf http://localhost:3000/health 2>&1 || echo "FAILED")
if echo "$BACKEND_HEALTH" | grep -q '"status":"ok"'; then
    echo -e "${GREEN}✅ Backend health check passed${NC}"
    echo "Response: $BACKEND_HEALTH"
else
    echo -e "${RED}❌ Backend health check failed${NC}"
    echo "Response: $BACKEND_HEALTH"
    echo "Check PM2 logs: pm2 logs $PM2_PROCESS_NAME"
fi

# Check Nginx status
echo ""
echo "Nginx Status:"
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx is running${NC}"
else
    echo -e "${RED}❌ Nginx is not running${NC}"
fi

# Summary
echo ""
echo "================================================"
echo "  Rollback Complete"
echo "================================================"
echo ""
echo -e "${GREEN}✅ Successfully rolled back to: $BACKUP_TO_RESTORE${NC}"
echo ""
echo "Restored deployment details:"
cd "$DEPLOY_PATH"
if [ -d ".git" ]; then
    echo "  Git Commit: $(git log -1 --pretty=format:'%h - %s' 2>/dev/null || echo 'N/A')"
    echo "  Author: $(git log -1 --pretty=format:'%an' 2>/dev/null || echo 'N/A')"
    echo "  Date: $(git log -1 --pretty=format:'%ad' --date=short 2>/dev/null || echo 'N/A')"
fi
echo ""
echo "Current deployment backed up to: $ROLLBACK_BACKUP"
echo ""
echo "Application should now be accessible at:"
echo "  Frontend: http://$(hostname -I | awk '{print $1}')/"
echo "  Backend:  http://$(hostname -I | awk '{print $1}'):3000/health"
echo ""
echo "If issues persist, check logs:"
echo "  PM2 logs:   pm2 logs $PM2_PROCESS_NAME"
echo "  Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "================================================"

exit 0
