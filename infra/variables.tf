variable "aws_region" {
  description = "Explicit AWS region for the deployment."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC (/16 to /19)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones in aws_region. Two are enough for this sample; each adds a billed endpoint ENI."
  type        = list(string)
}

variable "domain_name" {
  description = "Public documentation host used by Route 53, S3, and the OIDC callback."
  type        = string
}

variable "route53_zone_id" {
  description = "Public Route 53 hosted zone containing domain_name."
  type        = string
}

variable "ingress_cidr_blocks" {
  description = "Explicit IPv4 viewer sources."
  type        = list(string)
  default     = []
}

variable "ingress_prefix_list_ids" {
  description = "Explicit managed prefix-list viewer sources."
  type        = list(string)
  default     = []
}

variable "oidc_issuer" {
  description = "OIDC issuer URL."
  type        = string
}

variable "oidc_authorization_endpoint" {
  description = "OIDC authorization endpoint."
  type        = string
}

variable "oidc_token_endpoint" {
  description = "OIDC token endpoint."
  type        = string
}

variable "oidc_user_info_endpoint" {
  description = "OIDC user-info endpoint."
  type        = string
}

variable "oidc_client_id" {
  description = "OIDC application client ID."
  type        = string
  sensitive   = true
}

variable "oidc_client_secret" {
  description = "OIDC application client secret. Supply through TF_VAR_oidc_client_secret."
  type        = string
  sensitive   = true
}

variable "oidc_scope" {
  description = "OIDC scopes requested by ALB."
  type        = string
  default     = "openid"
}

variable "oidc_session_timeout" {
  description = "ALB authentication session duration in seconds."
  type        = number
  default     = 900
}

variable "waf_log_retention_days" {
  description = "Days to retain redacted WAF request logs in CloudWatch Logs."
  type        = number
  default     = 365

  validation {
    condition     = var.waf_log_retention_days >= 1
    error_message = "waf_log_retention_days must be at least 1."
  }
}

variable "alarm_sns_topic_arn" {
  description = "Optional existing SNS topic for alarms."
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Protect the ALB from deletion. Set to false only for a reviewed teardown."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Delete all object versions in the site and log buckets on destroy. Set to true only for a reviewed teardown."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional default tags applied to every resource through the provider."
  type        = map(string)
  default     = {}
}
