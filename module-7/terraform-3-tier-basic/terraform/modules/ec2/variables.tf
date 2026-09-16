# EC2 Module - Variables
# This module creates an EC2 instance with userdata for BMI Health Tracker

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for the instance"
  type        = string
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address"
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database user"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "deployment_script_path" {
  description = "Path to the deployment script"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
