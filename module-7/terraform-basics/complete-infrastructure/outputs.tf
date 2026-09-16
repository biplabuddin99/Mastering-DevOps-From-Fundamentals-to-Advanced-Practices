# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

# Security Group Outputs
output "security_group_id" {
  description = "ID of the security group"
  value       = module.security_group.security_group_id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = module.security_group.security_group_name
}

# EC2 Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2_instance.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2_instance.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = module.ec2_instance.private_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.ec2_instance.public_dns
}

output "ssh_connection_string" {
  description = "SSH connection string"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.ec2_instance.public_ip}"
}
