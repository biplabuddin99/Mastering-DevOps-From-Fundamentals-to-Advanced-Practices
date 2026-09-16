resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [var.security_group_id]

  key_name = var.key_name

  user_data = var.user_data != "" ? var.user_data : null

  tags = merge(
    {
      Name = var.instance_name
    },
    var.tags
  )

  root_block_device {
    volume_size           = var.root_volume_size
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
