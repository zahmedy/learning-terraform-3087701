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


module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"

  name = "blog"
  min_size = 1
  max_size = 2

  vpc_zone_identifier = module.blog_vpc.public_subnets
  target_group_arns   = [module.blog_elb.elb_arn]
  security_groups = [module.blog_sg.security_group_id]

  image_id        = data.aws_ami.app_ami.id
  instance_type   = var.instance_type

  depends_on = [
    module.blog_elb
  ]

}

module "blog_elb" {
  source  = "terraform-aws-modules/elb/aws"

  name = "blog-elb"

  subnets         = module.blog_vpc.public_subnets
  security_groups = [module.blog_sg.security_group_id]
  internal        = false

  listener = [
    {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
    }
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  // ELB attachments
  number_of_instances = 1
  // instances           = [aws_instance.blog.id]

  tags = {
    Environment = "dev"
  }
}

module "blog_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"
  name = "blog"
  vpc_id = module.blog_vpc.vpc_id

  ingress_rules     = ["http-80-tcp", "https-443-tcp"]
  egress_rules      = ["all-all"]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
