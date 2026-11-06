################################################################################
# Site
################################################################################

output "url" {
  description = "Authenticated site URL"
  value       = local.create ? "https://${var.domain_name}" : null
}

output "oidc_callback_url" {
  description = "Callback URL to register with the OIDC application"
  value       = local.create ? "https://${var.domain_name}/oauth2/idpresponse" : null
}

output "route53_record_fqdn" {
  description = "FQDN of the Route53 alias record"
  value       = try(aws_route53_record.this[0].fqdn, null)
}

################################################################################
# S3 Interface Endpoint
################################################################################

output "vpc_endpoint_id" {
  description = "The ID of the S3 interface endpoint"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "vpc_endpoint_private_ips" {
  description = "Private IPs of the S3 interface endpoint, registered as load balancer targets"
  value       = [for interface in data.aws_network_interface.s3_endpoint : interface.private_ip]
}

################################################################################
# Load Balancer
################################################################################

output "lb_id" {
  description = "The ID of the load balancer"
  value       = try(aws_lb.this[0].id, null)
}

output "lb_arn" {
  description = "The ARN of the load balancer"
  value       = try(aws_lb.this[0].arn, null)
}

output "lb_arn_suffix" {
  description = "ARN suffix of the load balancer, for use with CloudWatch metrics"
  value       = try(aws_lb.this[0].arn_suffix, null)
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer. Every HTTPS path authenticates"
  value       = try(aws_lb.this[0].dns_name, null)
}

output "lb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = try(aws_lb.this[0].zone_id, null)
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener"
  value       = try(aws_lb_listener.https[0].arn, null)
}

output "target_group_arn" {
  description = "The ARN of the S3 endpoint target group"
  value       = try(aws_lb_target_group.this[0].arn, null)
}

output "security_group_id" {
  description = "The ID of the load balancer security group"
  value       = try(aws_security_group.alb[0].id, null)
}

################################################################################
# S3
################################################################################

output "s3_bucket_id" {
  description = "The name of the private site bucket"
  value       = try(aws_s3_bucket.site[0].id, null)
}

output "s3_bucket_arn" {
  description = "The ARN of the private site bucket"
  value       = try(aws_s3_bucket.site[0].arn, null)
}

output "logs_s3_bucket_id" {
  description = "The name of the logs bucket"
  value       = try(aws_s3_bucket.logs[0].id, null)
}

output "logs_s3_bucket_arn" {
  description = "The ARN of the logs bucket"
  value       = try(aws_s3_bucket.logs[0].arn, null)
}

output "deployment_iam_policy_json" {
  description = "Least-privilege IAM policy document for a caller-created role that publishes the site"
  value       = try(data.aws_iam_policy_document.deployment[0].json, null)
}

################################################################################
# CloudWatch Alarms
################################################################################

output "cloudwatch_metric_alarm_arns" {
  description = "ARNs of the CloudWatch alarms"
  value = compact([
    try(aws_cloudwatch_metric_alarm.unhealthy_targets[0].arn, null),
    try(aws_cloudwatch_metric_alarm.alb_5xx[0].arn, null),
    try(aws_cloudwatch_metric_alarm.oidc_errors[0].arn, null),
  ])
}
