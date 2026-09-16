terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "your-terraform-state-bucket"  # Replace with your S3 bucket name
    key     = "complete-infrastructure/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
    profile = "sarowar-ostad"  # Replace with your AWS profile
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.common_tags
}

# Security Group Module
module "security_group" {
  source = "./modules/security-group"

  vpc_id             = module.vpc.vpc_id
  security_group_name = var.security_group_name
  allowed_ssh_cidr   = var.allowed_ssh_cidr
  allowed_http_cidr  = var.allowed_http_cidr
  tags               = var.common_tags
}

# EC2 Instance Module
module "ec2_instance" {
  source = "./modules/ec2"

  instance_name     = var.instance_name
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security_group.security_group_id
  key_name          = var.key_name
  vpc_id            = module.vpc.vpc_id
  tags              = var.common_tags
}
