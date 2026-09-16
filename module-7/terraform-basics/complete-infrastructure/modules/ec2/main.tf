resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [var.security_group_id]

  key_name = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform EC2 Instance</h1>" > /var/www/html/index.html
              echo "<p>Instance ID: $(ec2-metadata --instance-id | cut -d ' ' -f 2)</p>" >> /var/www/html/index.html
              echo "<p>Availability Zone: $(ec2-metadata --availability-zone | cut -d ' ' -f 2)</p>" >> /var/www/html/index.html
              EOF

  tags = merge(
    {
      Name = var.instance_name
    },
    var.tags
  )

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true

    tags = merge(
      {
        Name = "${var.instance_name}-root"
      },
      var.tags
    )
  }

  lifecycle {
    create_before_destroy = false
  }
}
