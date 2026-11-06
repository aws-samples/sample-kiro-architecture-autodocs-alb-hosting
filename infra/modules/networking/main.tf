locals {
  # /24 subnets: public at index 0..n, private at index 10..10+n.
  subnet_newbits = 24 - tonumber(split("/", var.cidr)[1])

  public_subnets  = [for index, _ in var.azs : cidrsubnet(var.cidr, local.subnet_newbits, index)]
  private_subnets = [for index, _ in var.azs : cidrsubnet(var.cidr, local.subnet_newbits, index + 10)]
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  create_vpc = var.create

  name = var.name
  cidr = var.cidr
  azs  = var.azs

  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Private subnets only host interface endpoints, which need no internet egress.
  enable_nat_gateway = false
  enable_vpn_gateway = false

  map_public_ip_on_launch = false

  # Adopt the default security group and leave it without rules.
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  tags = var.tags
}

################################################################################
# Flow Log
################################################################################

module "flow_log" {
  source  = "terraform-aws-modules/vpc/aws//modules/flow-log"
  version = "6.7.3"

  create = var.create

  name   = var.name
  vpc_id = module.vpc.vpc_id

  traffic_type             = "ALL"
  max_aggregation_interval = 60

  cloudwatch_log_group_retention_in_days = var.flow_log_retention_in_days

  tags = var.tags
}
