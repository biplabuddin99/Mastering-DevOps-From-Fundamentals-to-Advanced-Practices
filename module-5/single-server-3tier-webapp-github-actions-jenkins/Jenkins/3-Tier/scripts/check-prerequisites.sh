#!/bin/bash
# check-prerequisites.sh
# Check if required software is installed on target EC2 server
# Returns exit code 0 if all prerequisites are met, 1 otherwise

set -e

echo "================================================"
echo "  Checking Prerequisites on EC2 Server"
echo "================================================"

# Initialize status flags
ALL_OK=true
NODE_OK=false
POSTGRESQL_OK=false
NGINX_OK=false
PM2_OK=false
GIT_OK=false

# Check Node.js
echo -n "Checking Node.js... "
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo "✅ INSTALLED ($NODE_VERSION)"
    NODE_OK=true
else
    echo "❌ NOT INSTALLED"
    ALL_OK=false
fi

# Check npm
echo -n "Checking npm... "
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    echo "✅ INSTALLED (v$NPM_VERSION)"
else
    echo "❌ NOT INSTALLED"
    ALL_OK=false
fi

# Check PostgreSQL
echo -n "Checking PostgreSQL... "
if command -v psql &> /dev/null; then
    PG_VERSION=$(psql --version | awk '{print $3}')
    echo "✅ INSTALLED (v$PG_VERSION)"
    POSTGRESQL_OK=true
    
    # Check if PostgreSQL service is running
    if sudo systemctl is-active --quiet postgresql; then
        echo "   PostgreSQL service: ✅ RUNNING"
    else
        echo "   PostgreSQL service: ⚠️  NOT RUNNING"
        echo "   Attempting to start..."
        sudo systemctl start postgresql || echo "   ❌ Failed to start PostgreSQL"
    fi
else
    echo "❌ NOT INSTALLED"
    ALL_OK=false
fi

# Check Nginx
echo -n "Checking Nginx... "
if command -v nginx &> /dev/null; then
    NGINX_VERSION=$(nginx -v 2>&1 | awk -F'/' '{print $2}')
    echo "✅ INSTALLED (v$NGINX_VERSION)"
    NGINX_OK=true
    
    # Check if Nginx service is running
    if sudo systemctl is-active --quiet nginx; then
        echo "   Nginx service: ✅ RUNNING"
    else
        echo "   Nginx service: ⚠️  NOT RUNNING"
        echo "   Attempting to start..."
        sudo systemctl start nginx || echo "   ❌ Failed to start Nginx"
    fi
else
    echo "❌ NOT INSTALLED"
    ALL_OK=false
fi

# Check PM2
echo -n "Checking PM2... "
# Load NVM if it exists
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v pm2 &> /dev/null; then
    PM2_VERSION=$(pm2 -v)
    echo "✅ INSTALLED (v$PM2_VERSION)"
    PM2_OK=true
    
    # List running PM2 processes
    echo "   PM2 processes:"
    pm2 list | tail -n +4 | head -n -1 || echo "   No PM2 processes running"
else
    echo "❌ NOT INSTALLED"
    ALL_OK=false
fi

# Check Git
echo -n "Checking Git... "
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo "✅ INSTALLED (v$GIT_VERSION)"
    GIT_OK=true
else
    echo "❌ NOT INSTALLED"
    ALL_OK=false
fi

# Check disk space
echo ""
echo "Disk Space:"
df -h / | awk 'NR==1 {print "   "$0} NR==2 {printf "   "$0; if ($5+0 > 80) print " ⚠️  WARNING: Disk usage > 80%"; else print " ✅"}'

# Check memory
echo ""
echo "Memory:"
free -h | awk 'NR==1 {print "   "$0} NR==2 {print "   "$0}'

# Check if deployment directory exists
DEPLOY_PATH="/home/ubuntu/single-server-3tier-webapp"
echo ""
echo -n "Checking deployment directory... "
if [ -d "$DEPLOY_PATH" ]; then
    echo "✅ EXISTS"
    echo "   Path: $DEPLOY_PATH"
    echo "   Size: $(du -sh $DEPLOY_PATH 2>/dev/null | cut -f1)"
    echo "   DEPLOYMENT_TYPE=update"
else
    echo "❌ NOT FOUND (Fresh deployment)"
    echo "   DEPLOYMENT_TYPE=fresh"
fi

# Summary
echo ""
echo "================================================"
echo "  Prerequisites Check Summary"
echo "================================================"
echo "Node.js:    $([ "$NODE_OK" = true ] && echo "✅" || echo "❌")"
echo "PostgreSQL: $([ "$POSTGRESQL_OK" = true ] && echo "✅" || echo "❌")"
echo "Nginx:      $([ "$NGINX_OK" = true ] && echo "✅" || echo "❌")"
echo "PM2:        $([ "$PM2_OK" = true ] && echo "✅" || echo "❌")"
echo "Git:        $([ "$GIT_OK" = true ] && echo "✅" || echo "❌")"
echo "================================================"

if [ "$ALL_OK" = true ]; then
    echo "✅ All prerequisites are installed!"
    exit 0
else
    echo "⚠️  Some prerequisites are missing and need to be installed."
    exit 1
fi
