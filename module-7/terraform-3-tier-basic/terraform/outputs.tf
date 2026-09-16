# Outputs for BMI Health Tracker Infrastructure

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2_instance.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2_instance.instance_public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.ec2_instance.instance_public_dns
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.ec2_instance.instance_private_ip
}

output "application_url" {
  description = "URL to access the BMI Health Tracker application"
  value       = "http://${module.ec2_instance.instance_public_ip}"
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i <your-key.pem> ubuntu@${module.ec2_instance.instance_public_ip}"
}

output "deployment_notes" {
  description = "Important notes about the deployment"
  value       = <<-EOT
    ================================================================================
    BMI Health Tracker Deployment Information
    ================================================================================
    
    Application URL: http://${module.ec2_instance.instance_public_ip}
    
    SSH Access:
      ssh -i <your-key.pem> ubuntu@${module.ec2_instance.instance_public_ip}
    
    Deployment Status:
      The deployment script will run automatically via userdata.
      It may take 5-10 minutes for the application to be fully deployed.
    
    Check Deployment Progress:
      ssh -i <your-key.pem> ubuntu@${module.ec2_instance.instance_public_ip}
      sudo tail -f /var/log/cloud-init-output.log
    
    Useful Commands on Server:
      - Check backend: sudo systemctl status bmi-backend
      - View backend logs: sudo tail -f /var/log/bmi-backend.log
      - Check Nginx: sudo systemctl status nginx
      - View Nginx logs: sudo tail -f /var/log/nginx/bmi-*.log
    
    Database:
      - Name: ${var.db_name}
      - User: ${var.db_user}
      - Connect: psql -U ${var.db_user} -d ${var.db_name} -h localhost
    
    Security:
      - Ensure your security group allows inbound traffic on ports 22, 80, and 443
      - Consider setting up SSL/TLS with Let's Encrypt
    
    ================================================================================
  EOT
}
