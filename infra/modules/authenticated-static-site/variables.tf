variable "create" {
  description = "Controls if resources should be created (affects all resources)"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix for created resources. Defaults to `domain_name` with dots replaced by hyphens"
  type        = string
  default     = null

  validation {
    condition     = var.name == null || can(regex("^[a-z0-9][a-z0-9-]{0,31}$", var.name))
    error_message = "name must be 1-32 lowercase alphanumeric characters or hyphens and start with a letter or digit."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Domain
################################################################################

variable "domain_name" {
  description = "Public HTTPS host. Also used as the site bucket name, the Route53 record, and the OIDC callback host"
  type        = string

  validation {
    condition = (
      length(var.domain_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.domain_name)) &&
      !can(regex("\\.\\.", var.domain_name))
    )
    error_message = "domain_name must also be a valid S3 bucket name of at most 63 characters."
  }
}

variable "route53_zone_id" {
  description = "ID of the public Route53 hosted zone that contains `domain_name`"
  type        = string

  validation {
    condition     = length(trimspace(var.route53_zone_id)) > 0
    error_message = "route53_zone_id must not be empty."
  }
}

variable "certificate_arn" {
  description = "ARN of an existing ACM certificate for `domain_name` in the provider region"
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:acm:[^:]+:[0-9]{12}:certificate/[A-Za-z0-9-]+$", var.certificate_arn))
    error_message = "certificate_arn must be an ACM certificate ARN."
  }
}

variable "web_acl_arn" {
  description = "ARN of an existing regional WAFv2 WebACL to associate with the load balancer"
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:wafv2:[^:]+:[0-9]{12}:regional/webacl/[^/]+/[A-Za-z0-9-]+$", var.web_acl_arn))
    error_message = "web_acl_arn must be a regional WAFv2 WebACL ARN."
  }
}

################################################################################
# Network
################################################################################

variable "vpc_id" {
  description = "ID of the VPC that hosts the load balancer and the S3 interface endpoint"
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id must be a VPC ID."
  }
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the internet-facing load balancer, in at least two availability zones"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2 && alltrue([for id in var.public_subnet_ids : can(regex("^subnet-[0-9a-f]+$", id))])
    error_message = "public_subnet_ids must contain at least two subnet IDs."
  }
}

variable "endpoint_subnet_ids" {
  description = "Private subnet IDs for the S3 interface endpoint. Each subnet adds one endpoint network interface and load balancer target"
  type        = list(string)

  validation {
    condition     = length(var.endpoint_subnet_ids) >= 1 && alltrue([for id in var.endpoint_subnet_ids : can(regex("^subnet-[0-9a-f]+$", id))])
    error_message = "endpoint_subnet_ids must contain at least one subnet ID."
  }
}

################################################################################
# Security Group
################################################################################

variable "ingress_cidr_blocks" {
  description = "IPv4 CIDR blocks allowed to reach the load balancer. No viewer source is allowed by default"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.ingress_cidr_blocks : can(cidrnetmask(cidr))])
    error_message = "ingress_cidr_blocks must contain valid IPv4 CIDRs."
  }
}

variable "ingress_prefix_list_ids" {
  description = "Managed prefix list IDs allowed to reach the load balancer"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.ingress_prefix_list_ids : can(regex("^pl-[0-9a-f]+$", id))])
    error_message = "ingress_prefix_list_ids must contain valid managed prefix list IDs."
  }
}

################################################################################
# Load Balancer
################################################################################

variable "ssl_policy" {
  description = "Name of the SSL policy for the HTTPS listener. Must be a TLS13-1-2 or TLS13-1-3 policy, which require TLS 1.2 or later"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # TLS13-1-0 and TLS13-1-1 policies still allow TLS 1.0 and 1.1, so a plain
  # TLS13 prefix is not enough.
  validation {
    condition     = can(regex("^ELBSecurityPolicy-TLS13-1-[23]-", var.ssl_policy))
    error_message = "ssl_policy must be an ELBSecurityPolicy-TLS13-1-2-* or ELBSecurityPolicy-TLS13-1-3-* policy (TLS 1.2 or later)."
  }
}

variable "security_response_headers" {
  description = "Security headers the HTTPS listener adds to every response. Content-Security-Policy is not set because the Sphinx theme and Mermaid use inline scripts and styles"
  type = object({
    strict_transport_security = optional(string, "max-age=31536000; includeSubDomains")
    x_content_type_options    = optional(string, "nosniff")
    x_frame_options           = optional(string, "DENY")
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.security_response_headers.x_content_type_options == "nosniff"
    error_message = "x_content_type_options must be \"nosniff\"."
  }

  validation {
    condition     = contains(["DENY", "SAMEORIGIN"], var.security_response_headers.x_frame_options)
    error_message = "x_frame_options must be \"DENY\" or \"SAMEORIGIN\"."
  }
}

variable "create_http_listener" {
  description = "Determines whether to create an HTTP listener that redirects to HTTPS"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "If `true`, deletion of the load balancer will be disabled via the AWS API"
  type        = bool
  default     = true
}

################################################################################
# Authentication
################################################################################

variable "authenticate_oidc" {
  description = "Caller-owned, ALB-compatible OIDC application. The whole object is sensitive"
  type = object({
    issuer                 = string
    authorization_endpoint = string
    token_endpoint         = string
    user_info_endpoint     = string
    client_id              = string
    client_secret          = string
    scope                  = optional(string, "openid")
    session_cookie_name    = optional(string, "AWSELBAuthSessionCookie")
    session_timeout        = optional(number, 900)
  })
  sensitive = true

  validation {
    condition = alltrue([
      for endpoint in [
        var.authenticate_oidc.issuer,
        var.authenticate_oidc.authorization_endpoint,
        var.authenticate_oidc.token_endpoint,
        var.authenticate_oidc.user_info_endpoint,
      ] : can(regex("^https://[^/:]+(:443)?(/|$)", endpoint))
    ])
    error_message = "OIDC issuer and endpoints must use public HTTPS on the default port or explicit port 443."
  }

  validation {
    condition = (
      length(trimspace(var.authenticate_oidc.client_id)) > 0 &&
      length(var.authenticate_oidc.client_secret) > 0 &&
      strcontains(var.authenticate_oidc.scope, "openid")
    )
    error_message = "OIDC client credentials must not be empty and scope must include openid."
  }

  validation {
    condition = (
      var.authenticate_oidc.session_timeout >= 1 &&
      var.authenticate_oidc.session_timeout <= 604800 &&
      can(regex("^[A-Za-z0-9_-]+$", var.authenticate_oidc.session_cookie_name))
    )
    error_message = "OIDC session timeout must be 1-604800 seconds and the cookie name must be alphanumeric with underscores or hyphens."
  }
}

################################################################################
# S3
################################################################################

variable "force_destroy" {
  description = "Delete all object versions from the site and logs buckets on destroy so they can be removed"
  type        = bool
  default     = false
}

variable "noncurrent_version_retention_days" {
  description = "Days to retain noncurrent site object versions for rollback"
  type        = number
  default     = 30

  validation {
    condition     = var.noncurrent_version_retention_days >= 1
    error_message = "noncurrent_version_retention_days must be at least 1."
  }
}

variable "log_retention_days" {
  description = "Days to retain ALB access logs and S3 access logs"
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 1
    error_message = "log_retention_days must be at least 1."
  }
}

################################################################################
# CloudWatch Alarms
################################################################################

variable "create_alarms" {
  description = "Determines whether to create CloudWatch alarms for target health, 5xx responses, and OIDC errors"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "ARNs to notify when an alarm changes state, for example an SNS topic"
  type        = list(string)
  default     = []
}
