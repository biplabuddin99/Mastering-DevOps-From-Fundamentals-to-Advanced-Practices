resource "aws_security_group" "main" {
  name        = var.security_group_name
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name = var.security_group_name
    },
    var.tags
  )
}

# SSH Access
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.main.id
  description       = "Allow SSH access"
  
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_ssh_cidr[0]

  tags = merge(
    {
      Name = "SSH Access"
    },
    var.tags
  )
}

# HTTP Access
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.main.id
  description       = "Allow HTTP access"
  
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_http_cidr[0]

  tags = merge(
    {
      Name = "HTTP Access"
    },
    var.tags
  )
}

# HTTPS Access
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.main.id
  description       = "Allow HTTPS access"
  
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_http_cidr[0]

  tags = merge(
    {
      Name = "HTTPS Access"
    },
    var.tags
  )
}

# Outbound - Allow all
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.main.id
  description       = "Allow all outbound traffic"
  
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = merge(
    {
      Name = "All Outbound"
    },
    var.tags
  )
}
