# Web Server Outputs
output "web_server_id" {
  description = "ID of the web server instance"
  value       = module.web_server.instance_id
}

output "web_server_public_ip" {
  description = "Public IP of the web server"
  value       = module.web_server.public_ip
}

output "web_server_private_ip" {
  description = "Private IP of the web server"
  value       = module.web_server.private_ip
}

# Application Server Outputs
output "app_server_id" {
  description = "ID of the app server instance"
  value       = module.app_server.instance_id
}

output "app_server_private_ip" {
  description = "Private IP of the app server"
  value       = module.app_server.private_ip
}

# Database Server Outputs
output "db_server_id" {
  description = "ID of the database server instance"
  value       = module.db_server.instance_id
}

output "db_server_private_ip" {
  description = "Private IP of the database server"
  value       = module.db_server.private_ip
}

# Bastion Host Outputs
output "bastion_host_id" {
  description = "ID of the bastion host instance"
  value       = module.bastion_host.instance_id
}

output "bastion_host_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion_host.public_ip
}

# SSH Connection Strings
output "ssh_to_web_server" {
  description = "SSH command to connect to web server"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.web_server.public_ip}"
}

output "ssh_to_bastion" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.bastion_host.public_ip}"
}

output "ssh_to_app_via_bastion" {
  description = "SSH to app server via bastion (ProxyJump)"
  value       = "ssh -i ${var.key_name}.pem -J ec2-user@${module.bastion_host.public_ip} ec2-user@${module.app_server.private_ip}"
}

# Summary Output
output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    environment = var.environment
    web_server = {
      id         = module.web_server.instance_id
      public_ip  = module.web_server.public_ip
      private_ip = module.web_server.private_ip
      type       = var.web_instance_type
    }
    app_server = {
      id         = module.app_server.instance_id
      private_ip = module.app_server.private_ip
      type       = var.app_instance_type
    }
    db_server = {
      id         = module.db_server.instance_id
      private_ip = module.db_server.private_ip
      type       = var.db_instance_type
    }
    bastion_host = {
      id        = module.bastion_host.instance_id
      public_ip = module.bastion_host.public_ip
      type      = "t2.micro"
    }
  }
}
