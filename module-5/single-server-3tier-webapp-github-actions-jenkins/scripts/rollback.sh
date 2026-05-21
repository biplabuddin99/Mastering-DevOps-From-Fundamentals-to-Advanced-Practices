#!/bin/bash

################################################################################
# BMI Health Tracker - Quick Rollback Script
# 
# This script provides a quick rollback mechanism to restore a previous
# deployment backup in case of deployment failures.
#
# Usage:
#   ./scripts/rollback.sh                    # Interactive mode
#   ./scripts/rollback.sh backup_20251218    # Rollback to specific backup
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="$HOME/bmi_deployments_backup"
DEPLOY_PATH="$HOME/single-server-3tier-webapp"
FRONTEND_DEPLOY_PATH="/var/www/bmi-health-tracker"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    print_message "$BLUE" "═══════════════════════════════════════════════════"
    print_message "$BLUE" "  BMI Health Tracker - Deployment Rollback"
    print_message "$BLUE" "═══════════════════════════════════════════════════"
    echo ""
}

# Function to list available backups
list_backups() {
    print_message "$YELLOW" "📦 Available Backups:"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_message "$RED" "❌ No backup directory found at $BACKUP_DIR"
        exit 1
    fi
    
    local backups=($(ls -dt "$BACKUP_DIR"/backup_* 2>/dev/null))
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_message "$RED" "❌ No backups found in $BACKUP_DIR"
        exit 1
    fi
    
    local i=1
    for backup in "${backups[@]}"; do
        local backup_name=$(basename "$backup")
        local backup_date=$(echo "$backup_name" | sed 's/backup_//' | sed 's/_/ /g')
        local backup_size=$(du -sh "$backup" | cut -f1)
        
        # Get git commit info if available
        local git_info=""
        if [ -d "$backup/.git" ]; then
            cd "$backup" 2>/dev/null
            git_info=$(git log -1 --pretty=format:" (Commit: %h - %s)" 2>/dev/null || echo "")
            cd - > /dev/null
        fi
        
        echo "  $i) $backup_name"
        echo "     Date: $backup_date | Size: $backup_size"
        [ -n "$git_info" ] && echo "     $git_info"
        echo ""
        ((i++))
    done
    
    echo "${backups[@]}"
}

# Function to perform rollback
perform_rollback() {
    local backup_path=$1
    local backup_name=$(basename "$backup_path")
    
    print_message "$YELLOW" "🔄 Starting rollback to: $backup_name"
    echo ""
    
    # Confirm rollback
    read -p "Are you sure you want to rollback to this backup? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_message "$YELLOW" "❌ Rollback cancelled"
        exit 0
    fi
    
    # Create a backup of current state before rollback
    print_message "$BLUE" "📦 Creating backup of current state..."
    local current_backup="${BACKUP_DIR}/pre_rollback_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    if [ -d "$DEPLOY_PATH" ]; then
        cp -r "$DEPLOY_PATH" "$current_backup"
        print_message "$GREEN" "✅ Current state backed up to: $(basename $current_backup)"
    fi
    
    # Stop backend service
    print_message "$BLUE" "🛑 Stopping backend service..."
    pm2 stop bmi-backend 2>/dev/null || true
    
    # Restore backend files
    print_message "$BLUE" "📥 Restoring backend files..."
    if [ -d "$DEPLOY_PATH" ]; then
        rm -rf "$DEPLOY_PATH"
    fi
    cp -r "$backup_path" "$DEPLOY_PATH"
    
    # Restore backend dependencies and restart
    print_message "$BLUE" "📦 Installing backend dependencies..."
    cd "$DEPLOY_PATH/backend"
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    npm install --production
    
    print_message "$BLUE" "🚀 Starting backend service..."
    pm2 restart bmi-backend || pm2 start ecosystem.config.js
    pm2 save
    
    # Restore frontend
    print_message "$BLUE" "🎨 Restoring frontend..."
    cd "$DEPLOY_PATH/frontend"
    
    # Check if dist directory exists in backup
    if [ -d "dist" ]; then
        print_message "$BLUE" "   Using pre-built frontend from backup..."
        sudo rm -rf "$FRONTEND_DEPLOY_PATH"/*
        sudo cp -r dist/* "$FRONTEND_DEPLOY_PATH"/
    else
        print_message "$BLUE" "   Rebuilding frontend..."
        npm install
        npm run build
        sudo rm -rf "$FRONTEND_DEPLOY_PATH"/*
        sudo cp -r dist/* "$FRONTEND_DEPLOY_PATH"/
    fi
    
    # Set proper permissions
    sudo chown -R www-data:www-data "$FRONTEND_DEPLOY_PATH"
    sudo chmod -R 755 "$FRONTEND_DEPLOY_PATH"
    
    # Restart Nginx
    print_message "$BLUE" "🌐 Restarting Nginx..."
    sudo systemctl restart nginx
    
    # Health check
    print_message "$BLUE" "🏥 Running health check..."
    sleep 3
    
    local health_check=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)
    if [ "$health_check" = "200" ]; then
        print_message "$GREEN" "✅ Backend health check passed"
    else
        print_message "$RED" "⚠️  Backend health check returned HTTP $health_check"
    fi
    
    local frontend_check=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
    if [ "$frontend_check" = "200" ]; then
        print_message "$GREEN" "✅ Frontend health check passed"
    else
        print_message "$YELLOW" "⚠️  Frontend health check returned HTTP $frontend_check"
    fi
    
    # Display rollback summary
    echo ""
    print_message "$GREEN" "═══════════════════════════════════════════════════"
    print_message "$GREEN" "  ✅ Rollback Completed Successfully!"
    print_message "$GREEN" "═══════════════════════════════════════════════════"
    echo ""
    print_message "$BLUE" "📌 Rolled back to: $backup_name"
    
    # Show git commit info if available
    if [ -d "$DEPLOY_PATH/.git" ]; then
        cd "$DEPLOY_PATH"
        print_message "$BLUE" "📌 Current commit:"
        git log -1 --pretty=format:"   %h - %s (%an, %ar)" 2>/dev/null || echo "   Unable to retrieve git info"
        echo ""
    fi
    
    echo ""
    print_message "$BLUE" "🔧 PM2 Status:"
    pm2 info bmi-backend | grep -E "status|uptime|restarts" || true
    echo ""
    print_message "$GREEN" "═══════════════════════════════════════════════════"
}

# Main script logic
main() {
    print_header
    
    # Check if specific backup was provided
    if [ -n "$1" ]; then
        local backup_path="$BACKUP_DIR/$1"
        if [ ! -d "$backup_path" ]; then
            print_message "$RED" "❌ Backup not found: $backup_path"
            exit 1
        fi
        perform_rollback "$backup_path"
    else
        # Interactive mode
        local backups=($(list_backups))
        
        echo ""
        read -p "Select backup number to rollback (or 'q' to quit): " selection
        
        if [ "$selection" = "q" ] || [ "$selection" = "Q" ]; then
            print_message "$YELLOW" "❌ Rollback cancelled"
            exit 0
        fi
        
        if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
            print_message "$RED" "❌ Invalid selection"
            exit 1
        fi
        
        if [ "$selection" -lt 1 ] || [ "$selection" -gt "${#backups[@]}" ]; then
            print_message "$RED" "❌ Invalid backup number"
            exit 1
        fi
        
        local selected_backup="${backups[$((selection-1))]}"
        perform_rollback "$selected_backup"
    fi
}

# Run main function
main "$@"
