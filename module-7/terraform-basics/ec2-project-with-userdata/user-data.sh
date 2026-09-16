#!/bin/bash
set -e

# Update and upgrade system packages
apt-get update -y
apt-get upgrade -y

# Install essential packages
apt-get install -y \
  net-tools \
  git \
  zip \
  unzip \
  curl \
  wget \
  vim \
  htop

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Log completion
echo "User data script completed successfully at $(date)" >> /var/log/user-data.log
