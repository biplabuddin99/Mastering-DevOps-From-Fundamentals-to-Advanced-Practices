# ==============================================================================
# 01 — Terraform Fundamentals
# First EC2 instance using Terraform.
# Demonstrates: init, plan, apply, destroy workflow.
# ==============================================================================

# First EC2 instance
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  iam_instance_profile        = var.iam_instance_profile

  tags = {
    Name        = "${var.project_name}-first-instance"
    Environment = "learning"
    ManagedBy   = "terraform"
  }
}
