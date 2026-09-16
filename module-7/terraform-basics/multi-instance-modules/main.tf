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

# Web Server Instance
module "web_server" {
  source = "./modules/ec2"

  instance_name     = "web-server-${var.environment}"
  ami_id            = var.ami_id
  instance_type     = var.web_instance_type
  subnet_id         = var.public_subnet_id
  security_group_id = var.web_security_group_id
  key_name          = var.key_name
  vpc_id            = var.vpc_id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Web Server - ${var.environment}</h1>" > /var/www/html/index.html
              echo "<p>Instance: $(ec2-metadata --instance-id | cut -d ' ' -f 2)</p>" >> /var/www/html/index.html
              EOF

  tags = merge(
    var.common_tags,
    {
      Role = "WebServer"
      Tier = "Frontend"
    }
  )
}

# Application Server Instance
module "app_server" {
  source = "./modules/ec2"

  instance_name     = "app-server-${var.environment}"
  ami_id            = var.ami_id
  instance_type     = var.app_instance_type
  subnet_id         = var.private_subnet_id
  security_group_id = var.app_security_group_id
  key_name          = var.key_name
  vpc_id            = var.vpc_id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-11-openjdk
              echo "Application Server Initialized"
              EOF

  tags = merge(
    var.common_tags,
    {
      Role = "AppServer"
      Tier = "Backend"
    }
  )
}

# Database Server Instance
module "db_server" {
  source = "./modules/ec2"

  instance_name     = "db-server-${var.environment}"
  ami_id            = var.ami_id
  instance_type     = var.db_instance_type
  subnet_id         = var.private_subnet_id
  security_group_id = var.db_security_group_id
  key_name          = var.key_name
  vpc_id            = var.vpc_id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              # Database would be installed here
              echo "Database Server Initialized"
              EOF

  tags = merge(
    var.common_tags,
    {
      Role = "DatabaseServer"
      Tier = "Data"
    }
  )
}

# Bastion Host Instance
module "bastion_host" {
  source = "./modules/ec2"

  instance_name     = "bastion-host-${var.environment}"
  ami_id            = var.ami_id
  instance_type     = "t2.micro"
  subnet_id         = var.public_subnet_id
  security_group_id = var.bastion_security_group_id
  key_name          = var.key_name
  vpc_id            = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Role = "BastionHost"
      Tier = "Management"
    }
  )
}
