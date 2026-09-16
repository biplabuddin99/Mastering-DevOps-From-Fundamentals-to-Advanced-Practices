provider "aws" {
  region     = "us-west-2"
  access_key = "ID"
  secret_key = "ID"
}

resource "aws_instance" "myec2" {
  ami                    = "ami-00f46ccd1cbfb363e"
  instance_type          = "t3.medium"
  key_name               = "ostad-batch-08"
  iam_instance_profile   = "SSM"
  vpc_security_group_ids = ["sg-07cc5ad28f68e8e55"]
  subnet_id              = "subnet-03672544009e3c40e"

  associate_public_ip_address = true
  tags = {
    Name = "MyFirstEC2Instance"
  }

}
