provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        ManagedBy = "Terraform"
        Project   = "sphinx-drawio-docs"
      },
      var.tags,
    )
  }
}

locals {
  name = substr(replace(var.domain_name, ".", "-"), 0, 32)
}

################################################################################
# Certificate
################################################################################

# DNS-validated certificate in the provider region, which is where the ALB
# needs it. The validation record goes into the same hosted zone as the site.
resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certificate_validation" {
  zone_id         = var.route53_zone_id
  name            = one(aws_acm_certificate.this.domain_validation_options).resource_record_name
  type            = one(aws_acm_certificate.this.domain_validation_options).resource_record_type
  records         = [one(aws_acm_certificate.this.domain_validation_options).resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

# Waits until ACM has issued the certificate, so the HTTPS listener never
# references a pending certificate.
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [aws_route53_record.certificate_validation.fqdn]
}

################################################################################
# WAF
################################################################################

resource "aws_wafv2_web_acl" "this" {
  name        = "${local.name}-waf"
  description = "Baseline managed rules for the authenticated documentation ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAmazonIpReputationList"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${local.name}"
  retention_in_days = var.waf_log_retention_days
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.this.arn

  redacted_fields {
    query_string {}
  }

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}

################################################################################
# Networking
################################################################################

module "networking" {
  source = "./modules/networking"

  name = local.name
  cidr = var.vpc_cidr
  azs  = var.azs
}

################################################################################
# Static Site
################################################################################

module "static_site" {
  source = "./modules/authenticated-static-site"

  name = local.name

  domain_name     = var.domain_name
  route53_zone_id = var.route53_zone_id
  certificate_arn = aws_acm_certificate_validation.this.certificate_arn
  web_acl_arn     = aws_wafv2_web_acl.this.arn

  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  endpoint_subnet_ids = module.networking.private_subnet_ids

  ingress_cidr_blocks     = var.ingress_cidr_blocks
  ingress_prefix_list_ids = var.ingress_prefix_list_ids

  authenticate_oidc = {
    issuer                 = var.oidc_issuer
    authorization_endpoint = var.oidc_authorization_endpoint
    token_endpoint         = var.oidc_token_endpoint
    user_info_endpoint     = var.oidc_user_info_endpoint
    client_id              = var.oidc_client_id
    client_secret          = var.oidc_client_secret
    scope                  = var.oidc_scope
    session_timeout        = var.oidc_session_timeout
  }

  alarm_actions = var.alarm_sns_topic_arn == null ? [] : [var.alarm_sns_topic_arn]

  enable_deletion_protection = var.enable_deletion_protection
  force_destroy              = var.force_destroy
}
