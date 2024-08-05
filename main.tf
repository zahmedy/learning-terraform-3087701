data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = module.blog_new_sg.security_group_id

  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_eip" "blog" {
  instance = aws_instance.blog.id
  vpc      = true
}

module "blog_new_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name = "blog-new-sg"
  vpc_id = data.aws_vpc.default.id

  ingress_rules     = ["http-80-tcp", "http-8080-tcp", "https-443-tcp"]
  egress_rules      = ["all-all"]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}