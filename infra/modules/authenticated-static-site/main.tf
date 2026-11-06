data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  create = var.create

  name       = coalesce(var.name, substr(replace(var.domain_name, ".", "-"), 0, 32))
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  create_alarms = local.create && var.create_alarms
}

################################################################################
# Input Checks
################################################################################

check "ingress_sources" {
  assert {
    condition     = !local.create || length(var.ingress_cidr_blocks) + length(var.ingress_prefix_list_ids) > 0
    error_message = "Set at least one ingress_cidr_blocks or ingress_prefix_list_ids value."
  }
}

################################################################################
# Security Groups
################################################################################

resource "aws_security_group" "alb" {
  count = local.create ? 1 : 0

  name_prefix = "${local.name}-alb-"
  description = "Public viewer, OIDC, and private S3 endpoint traffic"
  vpc_id      = var.vpc_id

  # Rules are separate aws_vpc_security_group_*_rule resources. Do not set
  # inline ingress or egress here: Terraform would delete those rules.

  tags = merge({ Name = "${local.name}-alb" }, var.tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "endpoint" {
  count = local.create ? 1 : 0

  name_prefix = "${local.name}-s3-endpoint-"
  description = "S3 interface endpoint traffic from the ALB only"
  vpc_id      = var.vpc_id

  # Rules are separate aws_vpc_security_group_*_rule resources. Do not set
  # inline ingress or egress here: Terraform would delete those rules.

  tags = merge({ Name = "${local.name}-s3-endpoint" }, var.tags)

  lifecycle {
    create_before_destroy = true
  }
}

# Viewer ingress depends on the WebACL association and authenticated listener
# rules so the ALB is never reachable before both controls exist.
resource "aws_vpc_security_group_ingress_rule" "alb_https_cidr" {
  for_each = local.create ? toset(var.ingress_cidr_blocks) : toset([])

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTPS viewers from an explicitly approved IPv4 source"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value

  depends_on = [
    aws_lb_listener_rule.content,
    aws_lb_listener_rule.root,
    aws_wafv2_web_acl_association.this,
  ]
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_prefix_list" {
  for_each = local.create ? toset(var.ingress_prefix_list_ids) : toset([])

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTPS viewers from an explicitly approved prefix list"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = each.value

  depends_on = [
    aws_lb_listener_rule.content,
    aws_lb_listener_rule.root,
    aws_wafv2_web_acl_association.this,
  ]
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_cidr" {
  for_each = local.create && var.create_http_listener ? toset(var.ingress_cidr_blocks) : toset([])

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTP viewers redirected to HTTPS from an approved IPv4 source"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener_rule.content,
    aws_lb_listener_rule.root,
    aws_wafv2_web_acl_association.this,
  ]
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_prefix_list" {
  for_each = local.create && var.create_http_listener ? toset(var.ingress_prefix_list_ids) : toset([])

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTP viewers redirected to HTTPS from an approved prefix list"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  prefix_list_id    = each.value

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener_rule.content,
    aws_lb_listener_rule.root,
    aws_wafv2_web_acl_association.this,
  ]
}

resource "aws_vpc_security_group_egress_rule" "alb_https" {
  count = local.create ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTPS to public OIDC endpoints and S3 interface endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_health_check" {
  count = local.create ? 1 : 0

  security_group_id            = aws_security_group.alb[0].id
  description                  = "HTTP health checks to S3 interface endpoint"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.endpoint[0].id
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_https" {
  count = local.create ? 1 : 0

  security_group_id            = aws_security_group.endpoint[0].id
  description                  = "HTTPS origin requests from ALB"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.alb[0].id
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_health_check" {
  count = local.create ? 1 : 0

  security_group_id            = aws_security_group.endpoint[0].id
  description                  = "HTTP health checks from ALB"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb[0].id
}

################################################################################
# S3 Interface Endpoint
################################################################################

resource "aws_vpc_endpoint" "s3" {
  count = local.create ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.endpoint_subnet_ids
  security_group_ids  = [aws_security_group.endpoint[0].id]
  private_dns_enabled = false

  tags = merge({ Name = "${local.name}-s3" }, var.tags)
}

data "aws_network_interface" "s3_endpoint" {
  count = local.create ? length(var.endpoint_subnet_ids) : 0

  id = sort(aws_vpc_endpoint.s3[0].network_interface_ids)[count.index]
}

################################################################################
# Load Balancer
################################################################################

resource "aws_lb" "this" {
  count = local.create ? 1 : 0

  name                       = "${substr(local.name, 0, 28)}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb[0].id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "strictest"
  enable_deletion_protection = var.enable_deletion_protection
  preserve_host_header       = true

  access_logs {
    bucket  = aws_s3_bucket.logs[0].id
    prefix  = "alb"
    enabled = true
  }

  tags = merge({ Name = "${local.name}-alb" }, var.tags)

  depends_on = [aws_s3_bucket_policy.logs]
}

resource "aws_lb_target_group" "this" {
  count = local.create ? 1 : 0

  name        = "${substr(local.name, 0, 25)}-s3"
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = var.vpc_id

  # S3 answers unauthenticated transport probes with 4xx, so any non-5xx
  # response proves the endpoint ENI is reachable.
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-499"
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "this" {
  count = length(data.aws_network_interface.s3_endpoint)

  target_group_arn = aws_lb_target_group.this[0].arn
  target_id        = data.aws_network_interface.s3_endpoint[count.index].private_ip
  port             = 443
}

# Every HTTPS path, including the terminal 404, authenticates first.
resource "aws_lb_listener" "https" {
  count = local.create ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 443
  protocol          = "HTTPS"
  # var.ssl_policy is validated to TLS 1.2 or later; Semgrep cannot resolve it.
  ssl_policy      = var.ssl_policy # nosemgrep: terraform.aws.security.insecure-load-balancer-tls-version
  certificate_arn = var.certificate_arn

  # Added to every HTTPS response, including redirects and the 404.
  routing_http_response_strict_transport_security_header_value = var.security_response_headers.strict_transport_security
  routing_http_response_x_content_type_options_header_value    = var.security_response_headers.x_content_type_options
  routing_http_response_x_frame_options_header_value           = var.security_response_headers.x_frame_options

  lifecycle {
    # A precondition, unlike a check block, defers silently when the ARN is
    # created in the same apply and blocks when it is known to be wrong.
    precondition {
      condition     = split(":", var.certificate_arn)[3] == local.region
      error_message = "certificate_arn must be in the provider region."
    }
  }

  default_action {
    order = 1
    type  = "authenticate-oidc"

    authenticate_oidc {
      authorization_endpoint     = var.authenticate_oidc.authorization_endpoint
      client_id                  = var.authenticate_oidc.client_id
      client_secret              = var.authenticate_oidc.client_secret
      issuer                     = var.authenticate_oidc.issuer
      on_unauthenticated_request = "authenticate"
      scope                      = var.authenticate_oidc.scope
      session_cookie_name        = var.authenticate_oidc.session_cookie_name
      session_timeout            = var.authenticate_oidc.session_timeout
      token_endpoint             = var.authenticate_oidc.token_endpoint
      user_info_endpoint         = var.authenticate_oidc.user_info_endpoint
    }
  }

  default_action {
    order = 2
    type  = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  count = local.create && var.create_http_listener ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "root" {
  count = local.create ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 10

  action {
    order = 1
    type  = "authenticate-oidc"

    authenticate_oidc {
      authorization_endpoint     = var.authenticate_oidc.authorization_endpoint
      client_id                  = var.authenticate_oidc.client_id
      client_secret              = var.authenticate_oidc.client_secret
      issuer                     = var.authenticate_oidc.issuer
      on_unauthenticated_request = "authenticate"
      scope                      = var.authenticate_oidc.scope
      session_cookie_name        = var.authenticate_oidc.session_cookie_name
      session_timeout            = var.authenticate_oidc.session_timeout
      token_endpoint             = var.authenticate_oidc.token_endpoint
      user_info_endpoint         = var.authenticate_oidc.user_info_endpoint
    }
  }

  action {
    order = 2
    type  = "redirect"

    redirect {
      path        = "/index.html"
      status_code = "HTTP_302"
    }
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "content" {
  count = local.create ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 20

  action {
    order = 1
    type  = "authenticate-oidc"

    authenticate_oidc {
      authorization_endpoint     = var.authenticate_oidc.authorization_endpoint
      client_id                  = var.authenticate_oidc.client_id
      client_secret              = var.authenticate_oidc.client_secret
      issuer                     = var.authenticate_oidc.issuer
      on_unauthenticated_request = "authenticate"
      scope                      = var.authenticate_oidc.scope
      session_cookie_name        = var.authenticate_oidc.session_cookie_name
      session_timeout            = var.authenticate_oidc.session_timeout
      token_endpoint             = var.authenticate_oidc.token_endpoint
      user_info_endpoint         = var.authenticate_oidc.user_info_endpoint
    }
  }

  action {
    order            = 2
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }

  tags = var.tags
}

################################################################################
# WAF
################################################################################

resource "aws_wafv2_web_acl_association" "this" {
  count = local.create ? 1 : 0

  resource_arn = aws_lb.this[0].arn
  web_acl_arn  = var.web_acl_arn

  lifecycle {
    precondition {
      condition     = split(":", var.web_acl_arn)[3] == local.region
      error_message = "web_acl_arn must be in the provider region."
    }
  }
}

################################################################################
# Route53
################################################################################

resource "aws_route53_record" "this" {
  count = local.create ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.this[0].dns_name
    zone_id                = aws_lb.this[0].zone_id
    evaluate_target_health = true
  }
}

################################################################################
# S3 Site Bucket
################################################################################

# The bucket name must equal domain_name: the ALB preserves the Host header and
# S3 routes virtual-hosted requests by bucket name.
resource "aws_s3_bucket" "site" {
  count = local.create ? 1 : 0

  bucket        = var.domain_name
  force_destroy = var.force_destroy

  tags = merge({ Name = var.domain_name }, var.tags)
}

resource "aws_s3_bucket_ownership_controls" "site" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.site[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.site[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "site" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.site[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.site[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "site" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.site[0].id

  rule {
    id     = "site-version-retention"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "site" {
  count = local.create ? 1 : 0

  bucket        = aws_s3_bucket.site[0].id
  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "s3-access/site/"

  depends_on = [aws_s3_bucket_policy.logs]
}

data "aws_iam_policy_document" "site" {
  count = local.create ? 1 : 0

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.site[0].arn,
      "${aws_s3_bucket.site[0].arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowServingReadsFromEndpoint"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site[0].arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3[0].id]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.site[0].id
  policy = data.aws_iam_policy_document.site[0].json

  depends_on = [aws_s3_bucket_public_access_block.site]
}

# Policy for a caller-created role that publishes the generated site.
data "aws_iam_policy_document" "deployment" {
  count = local.create ? 1 : 0

  statement {
    sid = "ListSiteBucket"
    actions = [
      "s3:GetBucketVersioning",
      "s3:ListBucket",
      "s3:ListBucketVersions",
    ]
    resources = [aws_s3_bucket.site[0].arn]
  }

  statement {
    sid = "ManageSiteObjects"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.site[0].arn}/*"]
  }
}

################################################################################
# S3 Logs Bucket
################################################################################

resource "aws_s3_bucket" "logs" {
  count = local.create ? 1 : 0

  bucket_prefix = "${substr(local.name, 0, 20)}-logs-"
  force_destroy = var.force_destroy

  tags = merge({ Name = "${local.name}-logs" }, var.tags)
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "log-retention"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.log_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "logs" {
  count = local.create ? 1 : 0

  statement {
    sid    = "AllowALBLogDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs[0].arn}/alb/AWSLogs/${local.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "AllowS3ServerAccessLogDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs[0].arn}/s3-access/site/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.site[0].arn]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.logs[0].arn,
      "${aws_s3_bucket.logs[0].arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  count = local.create ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id
  policy = data.aws_iam_policy_document.logs[0].json

  depends_on = [aws_s3_bucket_public_access_block.logs]
}

################################################################################
# CloudWatch Alarms
################################################################################

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${local.name}-unhealthy-targets"
  alarm_description   = "One or more S3 interface endpoint targets are unhealthy."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.this[0].arn_suffix
    TargetGroup  = aws_lb_target_group.this[0].arn_suffix
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${local.name}-alb-5xx"
  alarm_description   = "The ALB returned five or more 5xx responses in five minutes."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.this[0].arn_suffix
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "oidc_errors" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${local.name}-oidc-errors"
  alarm_description   = "The ALB encountered one or more OIDC authentication errors."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "ELBAuthError"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.this[0].arn_suffix
  }

  tags = var.tags
}
