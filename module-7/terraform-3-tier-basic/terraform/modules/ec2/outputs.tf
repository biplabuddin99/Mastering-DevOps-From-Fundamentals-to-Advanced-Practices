# EC2 Module - Outputs

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.this.public_dns
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "instance_private_dns" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.this.private_dns
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.this.instance_state
}

output "instance_availability_zone" {
  description = "Availability zone of the EC2 instance"
  value       = aws_instance.this.availability_zone
}
