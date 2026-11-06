mock_provider "aws" {
  override_during = plan

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

  mock_data "aws_network_interface" {
    defaults = {
      private_ip = "10.0.10.10"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::mock-bucket"
      id  = "mock-bucket"
    }
  }

  mock_resource "aws_vpc_endpoint" {
    defaults = {
      network_interface_ids = ["eni-00000000000000001", "eni-00000000000000002"]
    }
  }
}

variables {
  domain_name     = "docs.example.com"
  route53_zone_id = "Z0123456789EXAMPLE"

  vpc_id              = "vpc-0123456789abcdef0"
  public_subnet_ids   = ["subnet-0000000000000000a", "subnet-0000000000000000b"]
  endpoint_subnet_ids = ["subnet-0000000000000000c", "subnet-0000000000000000d"]

  certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
  web_acl_arn     = "arn:aws:wafv2:eu-west-1:123456789012:regional/webacl/example/00000000-0000-0000-0000-000000000000"

  ingress_cidr_blocks = ["203.0.113.10/32"]

  authenticate_oidc = {
    issuer                 = "https://id.example.com"
    authorization_endpoint = "https://id.example.com/authorize"
    token_endpoint         = "https://id.example.com/token"
    user_info_endpoint     = "https://id.example.com/userinfo"
    client_id              = "synthetic-test-client"
    client_secret          = "placeholder" # pragma: allowlist secret
    scope                  = "openid email"
  }
}

run "secure_authenticated_site" {
  command = plan

  assert {
    condition     = aws_lb.this[0].internal == false
    error_message = "The selected pattern requires an internet-facing ALB."
  }

  assert {
    condition     = aws_lb.this[0].preserve_host_header
    error_message = "The ALB must preserve the documentation host for S3 routing."
  }

  assert {
    condition     = aws_lb.this[0].enable_deletion_protection
    error_message = "Deletion protection must be enabled by default."
  }

  assert {
    condition     = aws_vpc_endpoint.s3[0].vpc_endpoint_type == "Interface"
    error_message = "The S3 origin must use an interface endpoint."
  }

  assert {
    condition     = aws_vpc_endpoint.s3[0].service_name == "com.amazonaws.eu-west-1.s3"
    error_message = "The S3 endpoint must use the provider region."
  }

  assert {
    condition     = aws_vpc_endpoint.s3[0].private_dns_enabled == false
    error_message = "Private DNS is not required when the ALB targets endpoint ENIs."
  }

  assert {
    condition     = aws_s3_bucket.site[0].bucket == var.domain_name
    error_message = "The site bucket name must match the preserved Host header."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.site[0].block_public_acls &&
      aws_s3_bucket_public_access_block.site[0].block_public_policy &&
      aws_s3_bucket_public_access_block.site[0].ignore_public_acls &&
      aws_s3_bucket_public_access_block.site[0].restrict_public_buckets
    )
    error_message = "Every S3 public-access block control must remain enabled."
  }

  assert {
    condition     = aws_s3_bucket_versioning.site[0].versioning_configuration[0].status == "Enabled"
    error_message = "The site bucket must retain versions for rollback."
  }

  assert {
    condition = (
      aws_s3_bucket_logging.site[0].target_bucket == aws_s3_bucket.logs[0].id &&
      aws_s3_bucket_logging.site[0].target_prefix == "s3-access/site/"
    )
    error_message = "Site access logs must be delivered to the protected log bucket."
  }

  assert {
    condition = anytrue([
      for statement in data.aws_iam_policy_document.logs[0].statement :
      statement.sid == "AllowS3ServerAccessLogDelivery" &&
      contains(statement.actions, "s3:PutObject") &&
      contains(statement.resources, "arn:aws:s3:::mock-bucket/s3-access/site/*") &&
      anytrue([
        for principal in statement.principals :
        principal.type == "Service" &&
        contains(principal.identifiers, "logging.s3.amazonaws.com")
      ]) &&
      anytrue([
        for condition in statement.condition :
        condition.test == "StringEquals" &&
        condition.variable == "aws:SourceAccount" &&
        contains(condition.values, "123456789012")
      ]) &&
      anytrue([
        for condition in statement.condition :
        condition.test == "ArnLike" &&
        condition.variable == "aws:SourceArn" &&
        contains(condition.values, "arn:aws:s3:::mock-bucket")
      ])
    ])
    error_message = "The log bucket policy must authorize source-bound S3 access log delivery."
  }

  assert {
    condition     = aws_lb_target_group.this[0].health_check[0].matcher == "200-499"
    error_message = "S3 transport health checks must accept non-5xx service responses."
  }

  assert {
    condition     = length(aws_lb_target_group_attachment.this) == 2
    error_message = "Both endpoint ENIs must be registered as targets."
  }

  assert {
    condition = (
      aws_s3_bucket.site[0].force_destroy == false &&
      aws_s3_bucket.logs[0].force_destroy == false
    )
    error_message = "Buckets must not force deletion by default."
  }

  assert {
    condition = (
      aws_lb_listener.https[0].certificate_arn == var.certificate_arn &&
      aws_lb_listener.https[0].default_action[0].type == "authenticate-oidc" &&
      aws_lb_listener.https[0].default_action[0].order == 1 &&
      aws_lb_listener.https[0].default_action[1].type == "fixed-response" &&
      aws_lb_listener.https[0].default_action[1].order == 2
    )
    error_message = "The HTTPS default path must use the caller certificate and authenticate before returning 404."
  }

  assert {
    condition = (
      aws_lb_listener_rule.content[0].action[0].type == "authenticate-oidc" &&
      aws_lb_listener_rule.content[0].action[0].order == 1 &&
      aws_lb_listener_rule.content[0].action[1].type == "forward" &&
      aws_lb_listener_rule.content[0].action[1].order == 2
    )
    error_message = "Content requests must authenticate before forwarding."
  }

  assert {
    condition = (
      aws_lb_listener_rule.root[0].action[0].type == "authenticate-oidc" &&
      aws_lb_listener_rule.root[0].action[0].order == 1 &&
      aws_lb_listener_rule.root[0].action[1].type == "redirect" &&
      aws_lb_listener_rule.root[0].action[1].order == 2
    )
    error_message = "Root requests must authenticate before redirecting."
  }

  assert {
    condition     = aws_wafv2_web_acl_association.this[0].web_acl_arn == var.web_acl_arn
    error_message = "The caller-provided WAF WebACL must be associated with the ALB."
  }

  assert {
    condition = (
      toset(aws_lb.this[0].subnets) == toset(var.public_subnet_ids) &&
      toset(aws_vpc_endpoint.s3[0].subnet_ids) == toset(var.endpoint_subnet_ids)
    )
    error_message = "The ALB must use the public subnets and the endpoint the private subnets."
  }

  assert {
    condition = alltrue([
      for statement in data.aws_iam_policy_document.logs[0].statement :
      !startswith(statement.sid, "AllowVPCFlowLog")
    ])
    error_message = "VPC flow logs belong to the networking module, not the site logs bucket."
  }

  assert {
    condition     = output.oidc_callback_url == "https://docs.example.com/oauth2/idpresponse"
    error_message = "The output callback must match ALB's required path."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.unhealthy_targets) == 1
    error_message = "Alarms must be created by default."
  }
}

run "create_false_creates_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition = (
      length(aws_lb.this) == 0 &&
      length(aws_vpc_endpoint.s3) == 0 &&
      length(aws_s3_bucket.site) == 0 &&
      length(aws_s3_bucket.logs) == 0 &&
      length(aws_vpc_security_group_ingress_rule.alb_https_cidr) == 0
    )
    error_message = "create = false must not create any resources."
  }

  assert {
    condition     = output.lb_arn == null && output.url == null
    error_message = "Outputs must be null when create = false."
  }
}

run "disable_optional_resources" {
  command = plan

  variables {
    create_http_listener = false
    create_alarms        = false
  }

  assert {
    condition = (
      length(aws_lb_listener.http) == 0 &&
      length(aws_vpc_security_group_ingress_rule.alb_http_cidr) == 0 &&
      length(aws_cloudwatch_metric_alarm.unhealthy_targets) == 0 &&
      length(output.cloudwatch_metric_alarm_arns) == 0
    )
    error_message = "Optional HTTP listener and alarms must be omitted when disabled."
  }
}

run "custom_name_prefix" {
  command = plan

  variables {
    name = "team-docs"
  }

  assert {
    condition     = aws_lb.this[0].name == "team-docs-alb"
    error_message = "name must override the domain-derived resource prefix."
  }
}

run "allow_public_ingress_when_explicit" {
  command = plan

  variables {
    ingress_cidr_blocks = ["0.0.0.0/0"]
  }

  assert {
    condition = (
      aws_lb.this[0].internal == false &&
      aws_vpc_security_group_ingress_rule.alb_https_cidr["0.0.0.0/0"].cidr_ipv4 == "0.0.0.0/0" &&
      aws_lb_listener.https[0].default_action[0].type == "authenticate-oidc"
    )
    error_message = "Public serving must open HTTPS to any IPv4 source while still authenticating every request."
  }
}

run "accept_managed_prefix_list_ingress" {
  command = plan

  variables {
    ingress_cidr_blocks     = []
    ingress_prefix_list_ids = ["pl-0123456789abcdef0"]
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.alb_https_prefix_list) == 1
    error_message = "A caller-provided managed prefix list must create HTTPS ingress."
  }
}

run "reject_missing_ingress_sources" {
  command = plan

  variables {
    ingress_cidr_blocks     = []
    ingress_prefix_list_ids = []
  }

  expect_failures = [check.ingress_sources]
}

run "reject_cross_region_certificate" {
  command = plan

  variables {
    certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [aws_lb_listener.https]
}

run "reject_cross_region_web_acl" {
  command = plan

  variables {
    web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/example/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [aws_wafv2_web_acl_association.this]
}

run "reject_invalid_name" {
  command = plan

  variables {
    name = "Team_Docs"
  }

  expect_failures = [var.name]
}

run "reject_ssl_policy_below_tls12" {
  command = plan

  variables {
    ssl_policy = "ELBSecurityPolicy-TLS13-1-0-2021-06"
  }

  expect_failures = [var.ssl_policy]
}

run "security_response_headers_default_on" {
  command = plan

  assert {
    condition = (
      aws_lb_listener.https[0].routing_http_response_strict_transport_security_header_value == "max-age=31536000; includeSubDomains" &&
      aws_lb_listener.https[0].routing_http_response_x_content_type_options_header_value == "nosniff" &&
      aws_lb_listener.https[0].routing_http_response_x_frame_options_header_value == "DENY"
    )
    error_message = "The HTTPS listener must add HSTS, X-Content-Type-Options, and X-Frame-Options by default."
  }
}

run "reject_invalid_x_frame_options" {
  command = plan

  variables {
    security_response_headers = {
      x_frame_options = "ALLOWALL"
    }
  }

  expect_failures = [var.security_response_headers]
}

run "accept_tls13_only_ssl_policy" {
  command = plan

  variables {
    ssl_policy = "ELBSecurityPolicy-TLS13-1-3-2021-06"
  }

  assert {
    condition     = aws_lb_listener.https[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-3-2021-06"
    error_message = "A TLS 1.3-only policy must be accepted."
  }
}

run "reject_insecure_oidc_endpoints" {
  command = plan

  variables {
    authenticate_oidc = {
      issuer                 = "http://id.example.com"
      authorization_endpoint = "https://id.example.com/authorize"
      token_endpoint         = "https://id.example.com/token"
      user_info_endpoint     = "https://id.example.com/userinfo"
      client_id              = "synthetic-test-client"
      client_secret          = "placeholder" # pragma: allowlist secret
    }
  }

  expect_failures = [var.authenticate_oidc]
}

run "reject_nonstandard_oidc_port" {
  command = plan

  variables {
    authenticate_oidc = {
      issuer                 = "https://id.example.com:8443"
      authorization_endpoint = "https://id.example.com/authorize"
      token_endpoint         = "https://id.example.com/token"
      user_info_endpoint     = "https://id.example.com/userinfo"
      client_id              = "synthetic-test-client"
      client_secret          = "placeholder" # pragma: allowlist secret
    }
  }

  expect_failures = [var.authenticate_oidc]
}

run "reject_single_public_subnet" {
  command = plan

  variables {
    public_subnet_ids = ["subnet-0000000000000000a"]
  }

  expect_failures = [var.public_subnet_ids]
}

run "single_endpoint_subnet_registers_one_target" {
  command = plan

  variables {
    endpoint_subnet_ids = ["subnet-0000000000000000c"]
  }

  override_resource {
    target = aws_vpc_endpoint.s3
    values = {
      network_interface_ids = ["eni-00000000000000001"]
    }
  }

  assert {
    condition     = length(aws_lb_target_group_attachment.this) == 1
    error_message = "Each endpoint subnet must register exactly one target."
  }
}
