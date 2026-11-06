variable "create" {
  description = "Controls if resources should be created (affects all resources)"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name used on all resources as an identifier"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# VPC
################################################################################

variable "cidr" {
  description = "IPv4 CIDR block for the VPC (/16 to /19). One /24 public and one /24 private subnet are carved per availability zone"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition = (
      can(cidrnetmask(var.cidr)) &&
      can(tonumber(split("/", var.cidr)[1])) &&
      try(tonumber(split("/", var.cidr)[1]) >= 16 && tonumber(split("/", var.cidr)[1]) <= 19, false)
    )
    error_message = "cidr must be a valid IPv4 CIDR between /16 and /19 so that the /24 subnet layout fits."
  }
}

variable "azs" {
  description = "Availability zones for one public and one private subnet each. At least two are required for an ALB"
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2 && length(distinct(var.azs)) == length(var.azs) && length(var.azs) <= 10
    error_message = "azs must contain between two and ten distinct availability zones."
  }
}

################################################################################
# Flow Log
################################################################################

variable "flow_log_retention_in_days" {
  description = "Number of days to retain VPC flow log events in CloudWatch Logs. Must be at least 365 (CKV_AWS_338), or 0 to never expire"
  type        = number
  default     = 365

  validation {
    condition     = var.flow_log_retention_in_days == 0 || var.flow_log_retention_in_days >= 365
    error_message = "flow_log_retention_in_days must be at least 365, or 0 to never expire (CKV_AWS_338)."
  }
}
