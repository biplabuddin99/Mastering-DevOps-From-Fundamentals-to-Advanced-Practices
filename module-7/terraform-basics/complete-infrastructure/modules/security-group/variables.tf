variable "vpc_id" {
  description = "VPC ID where security group will be created"
  type        = string
}

variable "security_group_name" {
  description = "Name for the security group"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidr" {
  description = "CIDR blocks allowed for HTTP/HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags for security group"
  type        = map(string)
  default     = {}
}
