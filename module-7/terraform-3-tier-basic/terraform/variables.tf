# Variables for BMI Health Tracker Terraform Configuration

# ===========================
# AWS Configuration
# ===========================

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI named profile to use for authentication"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ===========================
# EC2 Instance Configuration
# ===========================

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "bmi-health-tracker-server"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition     = can(regex("^t[2-3]\\.(micro|small|medium)", var.instance_type))
    error_message = "Instance type must be a valid t2 or t3 type (micro, small, or medium recommended)."
  }
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS (must be Ubuntu for the deployment script)"
  type        = string
  
  # Default: Ubuntu 22.04 LTS in us-east-1
  # Find latest: aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" --query 'sort_by(Images, &CreationDate)[-1].ImageId'
  default     = "ami-0e86e20dae9224db8"
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

# ===========================
# Network Configuration
# ===========================

variable "vpc_id" {
  description = "VPC ID where the EC2 instance will be launched"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance (must be a public subnet)"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID for the EC2 instance (should allow ports 22, 80, 443)"
  type        = string
}

# ===========================
# Database Configuration
# ===========================

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "bmidb"
}

variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "bmi_user"
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

# ===========================
# Application Configuration
# ===========================

variable "deployment_script_path" {
  description = "Path to the deployment script (IMPLEMENTATION_AUTO.sh)"
  type        = string
  default     = "../IMPLEMENTATION_AUTO.sh"
}

# ===========================
# Additional Tags
# ===========================

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
