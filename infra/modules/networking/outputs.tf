################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, for example for a separately approved VPC Block Public Access exclusion"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "natgw_ids" {
  description = "IDs of the NAT gateways. Empty by design"
  value       = module.vpc.natgw_ids
}

################################################################################
# Flow Log
################################################################################

output "flow_log_id" {
  description = "The ID of the VPC flow log"
  value       = module.flow_log.id
}

output "flow_log_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group receiving VPC flow logs"
  value       = module.flow_log.cloudwatch_log_group_name
}
