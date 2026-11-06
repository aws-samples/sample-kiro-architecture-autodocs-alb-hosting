output "url" {
  description = "Authenticated documentation URL."
  value       = module.static_site.url
}

output "oidc_callback_url" {
  description = "Exact callback to register with the existing OIDC application."
  value       = module.static_site.oidc_callback_url
}

output "vpc_id" {
  description = "VPC hosting the load balancer and the S3 interface endpoint."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public ALB subnets for a separately approved network-control workflow."
  value       = module.networking.public_subnet_ids
}

output "flow_log_cloudwatch_log_group_name" {
  description = "CloudWatch log group receiving VPC flow logs."
  value       = module.networking.flow_log_cloudwatch_log_group_name
}

output "s3_bucket_id" {
  description = "Private bucket that receives the generated documentation."
  value       = module.static_site.s3_bucket_id
}

output "logs_s3_bucket_id" {
  description = "Bucket receiving ALB access logs and S3 access logs."
  value       = module.static_site.logs_s3_bucket_id
}

output "deployment_iam_policy_json" {
  description = "Least-privilege policy for the role that publishes the site."
  value       = module.static_site.deployment_iam_policy_json
}

output "waf_log_group_name" {
  description = "CloudWatch log group receiving redacted WAF request logs."
  value       = aws_cloudwatch_log_group.waf.name
}

output "certificate_arn" {
  description = "DNS-validated ACM certificate used by the HTTPS listener."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "web_acl_arn" {
  description = "Baseline WAFv2 WebACL associated with the ALB."
  value       = aws_wafv2_web_acl.this.arn
}

output "aws_region" {
  description = "Region of the site bucket, used by make publish."
  value       = var.aws_region
}
