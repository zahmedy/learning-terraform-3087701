data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner] # Bitnami
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"

  name = "${var.environment.name}-blog-asg"
  min_size = var.asg_min_size
  max_size = var.asg_max_size

  vpc_zone_identifier = module.blog_vpc.public_subnets
  load_balancers   = [module.blog_elb.elb_id]
  security_groups = [module.blog_sg.security_group_id]

  image_id        = data.aws_ami.app_ami.id
  instance_type   = var.instance_type

  depends_on = [
    module.blog_elb
  ]

}

module "blog_elb" {
  source  = "terraform-aws-modules/elb/aws"

  name = "${var.environment.name}-blog-elb"

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

  tags = {
    Environment = var.environment.name
  }
}

module "blog_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"
  name = "${var.environment.name}-blog-sg"
  vpc_id = module.blog_vpc.vpc_id

  ingress_rules     = ["http-80-tcp", "https-443-tcp"]
  egress_rules      = ["all-all"]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.environment.name}-blog-vpc"
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = var.environment.name
  }
}
