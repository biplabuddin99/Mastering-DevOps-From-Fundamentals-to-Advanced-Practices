terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

module "ec2_instance" {
  source = "./modules/ec2"

  instance_name     = var.instance_name
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id
  key_name          = var.key_name
  vpc_id            = var.vpc_id
  user_data         = file("${path.module}/user-data.sh")

  tags = var.tags
}


module "ec2_instance_inline_userdata" {
  source = "./modules/ec2"

  instance_name     = "${var.instance_name}-inline"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id
  key_name          = var.key_name
  vpc_id            = var.vpc_id
  user_data         = <<-EOF
    #!/bin/bash
    # Update system packages
    apt update -y
    
    # Install Apache web server
    apt install -y apache2
    
    # Start and enable Apache
    systemctl start apache2
    systemctl enable apache2
    
    # Create a simple web page
    echo "<h1>Hello from EC2 with Inline User Data!</h1>" > /var/www/html/index.html
    echo "<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" >> /var/www/html/index.html
    echo "<p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>" >> /var/www/html/index.html
  EOF
  tags = merge(var.tags, {
    UserDataType = "Inline"
  })
}