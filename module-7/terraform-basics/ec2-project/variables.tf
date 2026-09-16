variable "aws_profile" {
  description = "AWS named profile to use"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID to attach to the instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the instance will be launched"
  type        = string
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for the EC2 instance"
  type        = map(string)
  default     = {}
}
