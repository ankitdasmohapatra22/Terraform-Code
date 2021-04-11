terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  profile = "default"
  shared_credentials_file = "/opt/tf_user/aws_creds/credentials"
  region  = "ap-south-1"
}

module "networking" {
source = "./modules/network"
  region               = "ap-south-1"
  environment          = "development"
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = ["10.0.1.0/24"]
  private_subnets_cidr = ["10.0.2.0/24"]
  availability_zones   = ["ap-south-1a"]
}

module "security-group_mysql" {
  source  = "terraform-aws-modules/security-group/aws//modules/mysql"
  version = "3.18.0"
  name = "mysql-security-group"
  vpc_id = "${module.networking.vpc_id}"
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "security-group_frontend" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.18.0"
  name = "frontend-security-group"
  vpc_id = "${module.networking.vpc_id}"
}

module "security-group_frontend-lb-http" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "3.18.0"
  name = "frontend-lb-http-security-group"
  vpc_id = "${module.networking.vpc_id}"
  ingress_cidr_blocks = ["0.0.0.0/0"]

  # Allow engress HTTP 80 rules to outside
  egress_rules = ["http-80-tcp"]
}

module "banking-solution-servers" {
source = "./modules/ec2-instance"
  ami  = "ami-08ae04824d9fd0094"
  server-name = "banking-solution-web" 
  instance_count = 2
  subnet_id = "${module.networking.public_subnets_id}"
  instance_type = "t2.nano"
  aws_region = "ap-south-1"
  security_group_ids = ["${module.security-group_frontend.this_security_group_id}"]
}

module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 2.0"

  name = "banking-solution-elb"

  subnets         = ["subnet-0c03fbb298f4b02b3"] #hardcoded
  security_groups = ["${module.security-group_frontend-lb-http.this_security_group_id}"]
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
  number_of_instances = 2
  instances           = ["i-00cf4ad45862bfe33", "i-0dd784e14e42978dd"] #hardcoded

  tags = {
    App = "BankingSolution"
    Environment = "Development"
  }
}

module "mysql-server" {
source = "./modules/ec2-instance"
  ami  = "ami-08ae04824d9fd0094"
  server-name = "mysql"
  instance_count = 1
  subnet_id = "${module.networking.private_subnets_id}"
  instance_type = "t2.nano"
  aws_region = "ap-south-1"
  security_group_ids = ["${module.security-group_mysql.this_security_group_id}"]
}
