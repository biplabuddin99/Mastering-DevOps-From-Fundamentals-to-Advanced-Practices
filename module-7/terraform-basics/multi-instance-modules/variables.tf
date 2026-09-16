variable "aws_profile" {
  description = "AWS named profile to use"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Network Variables
variable "vpc_id" {
  description = "VPC ID where instances will be launched"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for web server and bastion"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for app and database servers"
  type        = string
}

# Security Group Variables
variable "web_security_group_id" {
  description = "Security Group ID for web server"
  type        = string
}

variable "app_security_group_id" {
  description = "Security Group ID for app server"
  type        = string
}

variable "db_security_group_id" {
  description = "Security Group ID for database server"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security Group ID for bastion host"
  type        = string
}

# Instance Configuration
variable "ami_id" {
  description = "AMI ID for all EC2 instances"
  type        = string
}

variable "web_instance_type" {
  description = "Instance type for web server"
  type        = string
  default     = "t2.micro"
}

variable "app_instance_type" {
  description = "Instance type for app server"
  type        = string
  default     = "t2.small"
}

variable "db_instance_type" {
  description = "Instance type for database server"
  type        = string
  default     = "t2.medium"
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
