#!/bin/bash
# health-check.sh
# Perform health checks on deployed application
# Supports retry logic and detailed status reporting

set -e

# Configuration
TARGET_IP="${1:-localhost}"
BACKEND_PORT="${2:-3000}"
MAX_RETRIES="${3:-5}"
RETRY_DELAY="${4:-10}"

echo "================================================"
echo "  Health Check for BMI Application"
echo "================================================"
echo "Target: $TARGET_IP"
echo "Backend Port: $BACKEND_PORT"
echo "Max Retries: $MAX_RETRIES"
echo "Retry Delay: ${RETRY_DELAY}s"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check backend health
check_backend() {
    local attempt=$1
    echo "Attempt $attempt/$MAX_RETRIES: Checking backend health..."
    
    # Try to connect to backend health endpoint
    RESPONSE=$(curl -sf "http://${TARGET_IP}:${BACKEND_PORT}/health" 2>&1)
    CURL_EXIT_CODE=$?
    
    if [ $CURL_EXIT_CODE -eq 0 ]; then
        # Check if response contains "ok"
        if echo "$RESPONSE" | grep -q '"status":"ok"'; then
            echo -e "${GREEN}✅ Backend health check passed${NC}"
            echo "Response: $RESPONSE"
            return 0
        else
            echo -e "${YELLOW}⚠️  Backend responded but status not OK${NC}"
            echo "Response: $RESPONSE"
            return 1
        fi
    else
        echo -e "${RED}❌ Backend health check failed${NC}"
        echo "Error: Unable to connect to http://${TARGET_IP}:${BACKEND_PORT}/health"
        return 1
    fi
}

# Function to check frontend health
check_frontend() {
    local attempt=$1
    echo "Attempt $attempt/$MAX_RETRIES: Checking frontend health..."
    
    # Try to connect to frontend
    HTTP_CODE=$(curl -sf -o /dev/null -w '%{http_code}' "http://${TARGET_IP}/" 2>&1)
    CURL_EXIT_CODE=$?
    
    if [ $CURL_EXIT_CODE -eq 0 ] && [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ Frontend health check passed (HTTP $HTTP_CODE)${NC}"
        return 0
    else
        echo -e "${RED}❌ Frontend health check failed (HTTP $HTTP_CODE)${NC}"
        echo "Error: Unable to access http://${TARGET_IP}/"
        return 1
    fi
}

# Function to check PM2 process
check_pm2() {
    echo "Checking PM2 process status..."
    
    # Load NVM if it exists
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command -v pm2 &> /dev/null; then
        PM2_STATUS=$(pm2 jlist 2>/dev/null)
        
        if echo "$PM2_STATUS" | grep -q '"name":"bmi-backend"'; then
            # Check if process is online
            if echo "$PM2_STATUS" | grep -A 5 '"name":"bmi-backend"' | grep -q '"status":"online"'; then
                echo -e "${GREEN}✅ PM2 process 'bmi-backend' is online${NC}"
                
                # Display process details
                pm2 info bmi-backend 2>/dev/null | grep -E "(uptime|restarts|memory|cpu)" || true
                return 0
            else
                echo -e "${RED}❌ PM2 process 'bmi-backend' is not online${NC}"
                pm2 list 2>/dev/null || true
                return 1
            fi
        else
            echo -e "${RED}❌ PM2 process 'bmi-backend' not found${NC}"
            pm2 list 2>/dev/null || true
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  PM2 not found, skipping PM2 check${NC}"
        return 0
    fi
}

# Function to check Nginx
check_nginx() {
    echo "Checking Nginx status..."
    
    if sudo systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✅ Nginx service is running${NC}"
        
        # Test Nginx configuration
        if sudo nginx -t 2>&1 | grep -q "syntax is ok"; then
            echo -e "${GREEN}✅ Nginx configuration is valid${NC}"
        else
            echo -e "${YELLOW}⚠️  Nginx configuration has warnings${NC}"
            sudo nginx -t 2>&1 || true
        fi
        return 0
    else
        echo -e "${RED}❌ Nginx service is not running${NC}"
        sudo systemctl status nginx --no-pager -l || true
        return 1
    fi
}

# Function to check PostgreSQL
check_postgresql() {
    echo "Checking PostgreSQL status..."
    
    if sudo systemctl is-active --quiet postgresql; then
        echo -e "${GREEN}✅ PostgreSQL service is running${NC}"
        
        # Check if database is accessible
        if sudo -u postgres psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "bmidb"; then
            echo -e "${GREEN}✅ Database 'bmidb' exists${NC}"
        else
            echo -e "${YELLOW}⚠️  Database 'bmidb' not found${NC}"
        fi
        return 0
    else
        echo -e "${RED}❌ PostgreSQL service is not running${NC}"
        sudo systemctl status postgresql --no-pager -l || true
        return 1
    fi
}

# Main health check flow
echo "================================================"
echo "  Performing Health Checks"
echo "================================================"
echo ""

# Backend health check with retry
echo "--- Backend Health Check ---"
BACKEND_OK=false
for i in $(seq 1 $MAX_RETRIES); do
    if check_backend $i; then
        BACKEND_OK=true
        break
    fi
    
    if [ $i -lt $MAX_RETRIES ]; then
        echo "Waiting ${RETRY_DELAY}s before retry..."
        sleep $RETRY_DELAY
    fi
done
echo ""

# Frontend health check with retry
echo "--- Frontend Health Check ---"
FRONTEND_OK=false
for i in $(seq 1 $MAX_RETRIES); do
    if check_frontend $i; then
        FRONTEND_OK=true
        break
    fi
    
    if [ $i -lt $MAX_RETRIES ]; then
        echo "Waiting ${RETRY_DELAY}s before retry..."
        sleep $RETRY_DELAY
    fi
done
echo ""

# PM2 health check (no retry)
echo "--- PM2 Process Check ---"
PM2_OK=false
if check_pm2; then
    PM2_OK=true
fi
echo ""

# Nginx health check (no retry)
echo "--- Nginx Service Check ---"
NGINX_OK=false
if check_nginx; then
    NGINX_OK=true
fi
echo ""

# PostgreSQL health check (no retry)
echo "--- PostgreSQL Service Check ---"
POSTGRESQL_OK=false
if check_postgresql; then
    POSTGRESQL_OK=true
fi
echo ""

# Summary
echo "================================================"
echo "  Health Check Summary"
echo "================================================"
echo -n "Backend API:     "
[ "$BACKEND_OK" = true ] && echo -e "${GREEN}✅ HEALTHY${NC}" || echo -e "${RED}❌ UNHEALTHY${NC}"

echo -n "Frontend:        "
[ "$FRONTEND_OK" = true ] && echo -e "${GREEN}✅ HEALTHY${NC}" || echo -e "${RED}❌ UNHEALTHY${NC}"

echo -n "PM2 Process:     "
[ "$PM2_OK" = true ] && echo -e "${GREEN}✅ HEALTHY${NC}" || echo -e "${RED}❌ UNHEALTHY${NC}"

echo -n "Nginx Service:   "
[ "$NGINX_OK" = true ] && echo -e "${GREEN}✅ HEALTHY${NC}" || echo -e "${RED}❌ UNHEALTHY${NC}"

echo -n "PostgreSQL:      "
[ "$POSTGRESQL_OK" = true ] && echo -e "${GREEN}✅ HEALTHY${NC}" || echo -e "${RED}❌ UNHEALTHY${NC}"

echo "================================================"

# Access URLs
echo ""
echo "📍 Access URLs:"
echo "   Frontend:    http://${TARGET_IP}/"
echo "   Backend API: http://${TARGET_IP}:${BACKEND_PORT}/health"
echo "   API Docs:    http://${TARGET_IP}:${BACKEND_PORT}/api/measurements"

# Exit with appropriate code
if [ "$BACKEND_OK" = true ] && [ "$FRONTEND_OK" = true ]; then
    echo ""
    echo -e "${GREEN}✅ All critical health checks passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some health checks failed!${NC}"
    echo "Check the logs above for details."
    exit 1
fi
