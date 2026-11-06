# Plans the full composition with mocked AWS responses. This proves that
# networking outputs feed the site module without unknown-count errors.
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-west-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  aws_region      = "eu-west-1"
  azs             = ["eu-west-1a", "eu-west-1b"]
  domain_name     = "docs.example.com"
  route53_zone_id = "Z0123456789EXAMPLE"

  ingress_cidr_blocks = ["203.0.113.10/32"]

  oidc_issuer                 = "https://id.example.com"
  oidc_authorization_endpoint = "https://id.example.com/authorize"
  oidc_token_endpoint         = "https://id.example.com/token"
  oidc_user_info_endpoint     = "https://id.example.com/userinfo"
  oidc_client_id              = "synthetic-test-client"
  oidc_client_secret          = "placeholder" # pragma: allowlist secret
}

run "composition_plans" {
  command = plan

  # Certificate and WebACL ARNs are only known after apply. Pin them at plan
  # time so the site module's region preconditions are evaluated, not deferred.
  override_resource {
    target          = aws_wafv2_web_acl.this
    override_during = plan
    values = {
      arn = "arn:aws:wafv2:eu-west-1:123456789012:regional/webacl/docs-example-com-waf/00000000-0000-0000-0000-000000000000"
    }
  }

  override_resource {
    target          = aws_acm_certificate.this
    override_during = plan
    values = {
      arn = "arn:aws:acm:eu-west-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
      domain_validation_options = [{
        domain_name           = "docs.example.com"
        resource_record_name  = "_00000000000000000000000000000000.docs.example.com."
        resource_record_type  = "CNAME"
        resource_record_value = "_00000000000000000000000000000000.acm-validations.aws."
      }]
    }
  }

  assert {
    condition     = length(module.networking.public_subnet_ids) == 2 && length(module.networking.private_subnet_ids) == 2
    error_message = "The networking module must provide two public and two private subnets."
  }

  assert {
    condition     = length(module.networking.natgw_ids) == 0
    error_message = "The sample VPC must not create NAT gateways."
  }

  assert {
    condition     = output.url == "https://docs.example.com"
    error_message = "The root must expose the authenticated site URL."
  }

  assert {
    condition = (
      aws_acm_certificate.this.domain_name == var.domain_name &&
      aws_acm_certificate.this.validation_method == "DNS" &&
      aws_route53_record.certificate_validation.zone_id == var.route53_zone_id
    )
    error_message = "The root must DNS-validate a certificate for the site domain in the site hosted zone."
  }

  assert {
    condition = (
      aws_wafv2_web_acl.this.scope == "REGIONAL" &&
      length(aws_wafv2_web_acl.this.default_action[0].allow) == 1 &&
      toset([for rule in aws_wafv2_web_acl.this.rule : rule.statement[0].managed_rule_group_statement[0].name]) == toset([
        "AWSManagedRulesAmazonIpReputationList",
        "AWSManagedRulesCommonRuleSet",
        "AWSManagedRulesKnownBadInputsRuleSet",
      ]) &&
      alltrue([for rule in aws_wafv2_web_acl.this.rule : length(rule.override_action[0].none) == 1])
    )
    error_message = "The baseline WebACL must be regional and enforce the three AWS managed rule groups."
  }

  assert {
    condition = (
      aws_wafv2_web_acl_logging_configuration.this.resource_arn == aws_wafv2_web_acl.this.arn &&
      length(aws_wafv2_web_acl_logging_configuration.this.log_destination_configs) == 1 &&
      length(aws_wafv2_web_acl_logging_configuration.this.redacted_fields) == 3 &&
      length([
        for field in aws_wafv2_web_acl_logging_configuration.this.redacted_fields : field
        if length(field.query_string) == 1
      ]) == 1 &&
      toset(flatten([
        for field in aws_wafv2_web_acl_logging_configuration.this.redacted_fields : [
          for header in field.single_header : header.name
        ]
      ])) == toset(["authorization", "cookie"])
    )
    error_message = "WAF logging must redact query strings and authentication headers."
  }

  assert {
    condition = (
      aws_cloudwatch_log_group.waf.name == "aws-waf-logs-docs-example-com" &&
      aws_cloudwatch_log_group.waf.retention_in_days == 365
    )
    error_message = "WAF request logs must use a valid destination name and bounded retention."
  }

  assert {
    condition     = output.web_acl_arn == aws_wafv2_web_acl.this.arn
    error_message = "The root must associate its own WebACL with the ALB."
  }
}

# Same as a real first plan: certificate and WebACL ARNs are unknown. The site
# module's region preconditions must defer instead of failing the plan.
run "first_plan_with_unknown_arns" {
  command = plan

  assert {
    condition     = output.url == "https://docs.example.com"
    error_message = "The first plan must succeed while generated ARNs are unknown."
  }
}
