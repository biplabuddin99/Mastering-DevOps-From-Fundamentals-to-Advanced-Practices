#!/bin/bash

# Get a token for IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

# Get the public IPv4 address
PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "EC2 Public IP: $PUBLIC_IP"
