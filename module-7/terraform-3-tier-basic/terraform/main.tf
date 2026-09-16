# Main Terraform Configuration for BMI Health Tracker Application
# This deploys a single EC2 instance with the full 3-tier stack

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider Configuration with Named Profile
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  
  default_tags {
    tags = {
      Project     = "BMI-Health-Tracker"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# EC2 Instance Module
module "ec2_instance" {
  source = "./modules/ec2"
  
  # Instance Configuration
  instance_name        = var.instance_name
  instance_type        = var.instance_type
  ami_id               = var.ami_id
  key_name             = var.key_name
  
  # Network Configuration
  vpc_id               = var.vpc_id
  subnet_id            = var.subnet_id
  security_group_id    = var.security_group_id
  associate_public_ip  = true  # Enable public IP for public subnet
  
  # Database Configuration (passed to userdata)
  db_name              = var.db_name
  db_user              = var.db_user
  db_password          = var.db_password
  
  # Application Configuration
  deployment_script_path = var.deployment_script_path
  
  # Tags
  environment          = var.environment
  additional_tags      = var.additional_tags
}
