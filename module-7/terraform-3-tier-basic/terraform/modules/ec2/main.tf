# EC2 Module - Main Configuration
# Creates an EC2 instance with userdata for automated deployment

# Render the userdata script with variables
locals {
  userdata_script = templatefile("${path.module}/user-data.sh", {
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  })
}

# Create the EC2 instance
resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = var.associate_public_ip
  
  # Userdata script for automated deployment
  user_data = local.userdata_script
  
  # Ensure userdata runs on every boot (optional)
  user_data_replace_on_change = true
  
  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20  # GB - enough for OS, Node.js, PostgreSQL, and app
    delete_on_termination = true
    encrypted             = true
    
    tags = {
      Name = "${var.instance_name}-root-volume"
    }
  }
  
  # Instance metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Require IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  
  # Monitoring
  monitoring = true
  
  # Tags
  tags = merge(
    {
      Name        = var.instance_name
      Environment = var.environment
      Application = "BMI-Health-Tracker"
      Tier        = "Full-Stack"
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
  
  # Lifecycle
  lifecycle {
    create_before_destroy = false
    ignore_changes       = [ami]  # Prevent replacement on AMI updates
  }
}
