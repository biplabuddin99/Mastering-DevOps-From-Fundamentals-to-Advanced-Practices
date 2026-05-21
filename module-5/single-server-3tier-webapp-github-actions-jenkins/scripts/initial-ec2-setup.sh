#!/bin/bash

################################################################################
# BMI Health Tracker - Minimal EC2 Initial Setup
# 
# This script performs ONLY the minimal setup required on a fresh EC2 instance
# to prepare for GitHub Actions automated deployment.
#
# What this script does:
#   - Updates system packages
#   - Installs Git (if not present)
#   - Configures SSH for GitHub Actions
#
# What GitHub Actions will do (automatically):
#   - Install Node.js, PostgreSQL, Nginx, PM2
#   - Setup database
#   - Clone repository
#   - Deploy application
#
# Usage:
#   chmod +x scripts/initial-ec2-setup.sh
#   ./scripts/initial-ec2-setup.sh
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    print_message "$BLUE" "═══════════════════════════════════════════════════"
    print_message "$BLUE" "  BMI Health Tracker - Minimal EC2 Setup"
    print_message "$BLUE" "  Preparing for GitHub Actions Deployment"
    print_message "$BLUE" "═══════════════════════════════════════════════════"
    echo ""
}

main() {
    print_header
    
    print_message "$YELLOW" "📋 This script will prepare your EC2 instance for GitHub Actions deployment"
    print_message "$YELLOW" "   GitHub Actions will automatically install all required software"
    echo ""
    
    # Update system
    print_message "$BLUE" "📦 Step 1/3: Updating system packages..."
    sudo apt update -qq
    sudo apt upgrade -y -qq
    print_message "$GREEN" "✅ System updated"
    echo ""
    
    # Install Git
    print_message "$BLUE" "📦 Step 2/3: Installing Git..."
    if command -v git &> /dev/null; then
        print_message "$GREEN" "✅ Git is already installed ($(git --version))"
    else
        sudo apt install -y git
        print_message "$GREEN" "✅ Git installed successfully"
    fi
    echo ""
    
    # Configure SSH
    print_message "$BLUE" "🔑 Step 3/3: Configuring SSH..."
    
    # Ensure .ssh directory exists with correct permissions
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    
    print_message "$GREEN" "✅ SSH directory configured"
    echo ""
    
    # Display setup completion
    print_message "$GREEN" "═══════════════════════════════════════════════════"
    print_message "$GREEN" "  ✅ EC2 Instance Ready for GitHub Actions!"
    print_message "$GREEN" "═══════════════════════════════════════════════════"
    echo ""
    
    print_message "$YELLOW" "📝 Next Steps:"
    echo ""
    echo "1. Add GitHub Actions SSH public key to this server:"
    print_message "$BLUE" "   echo 'YOUR_GITHUB_ACTIONS_PUBLIC_KEY' >> ~/.ssh/authorized_keys"
    echo ""
    echo "2. Configure GitHub Secrets (in your repository):"
    print_message "$BLUE" "   - EC2_HOST: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'YOUR_EC2_IP')"
    print_message "$BLUE" "   - EC2_USER: $(whoami)"
    print_message "$BLUE" "   - EC2_SSH_KEY: (private key content)"
    print_message "$BLUE" "   - DB_PASSWORD: (choose a secure password for PostgreSQL)"
    echo ""
    echo "3. Push your code to GitHub main branch"
    print_message "$BLUE" "   GitHub Actions will automatically:"
    echo "   - Install Node.js, PostgreSQL, Nginx, PM2"
    echo "   - Setup database and run migrations"
    echo "   - Clone your repository"
    echo "   - Deploy your application"
    echo ""
    
    print_message "$GREEN" "═══════════════════════════════════════════════════"
    echo ""
    
    print_message "$YELLOW" "ℹ️  For detailed instructions, see GITHUB_ACTIONS_SETUP.md"
}

main "$@"
