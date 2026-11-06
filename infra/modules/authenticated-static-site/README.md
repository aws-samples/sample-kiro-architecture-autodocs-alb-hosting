# Authenticated static site

Terraform module that serves a static site from a private S3 bucket behind an
internet-facing Application Load Balancer. Every HTTPS request is authenticated
against a caller-owned, ALB-compatible OIDC application (your SSO) before the
ALB forwards it to S3 through an interface VPC endpoint.

```text
Viewer (allowed CIDR / prefix list) -> WAF -> ALB (authenticate-oidc)
                                    -> S3 interface endpoint -> private S3 bucket
```

## Usage

```hcl
module "static_site" {
  source = "./modules/authenticated-static-site"

  domain_name     = "docs.example.com"
  route53_zone_id = "Z0123456789EXAMPLE"
  certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
  web_acl_arn     = "arn:aws:wafv2:eu-west-1:123456789012:regional/webacl/example/00000000-0000-0000-0000-000000000000"

  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  endpoint_subnet_ids = module.networking.private_subnet_ids

  ingress_cidr_blocks = ["203.0.113.10/32"]

  authenticate_oidc = {
    issuer                 = "https://id.example.com"
    authorization_endpoint = "https://id.example.com/authorize"
    token_endpoint         = "https://id.example.com/token"
    user_info_endpoint     = "https://id.example.com/userinfo"
    client_id              = "example-client"
    client_secret          = var.oidc_client_secret
  }

  tags = {
    Environment = "dev"
  }
}
```

The region comes from the AWS provider. The module brings its own security
groups, S3 interface endpoint, load balancer, and buckets, but expects an
existing VPC, for example from [`../networking`](../networking/). See
[`infra/`](../../) for a complete deployment root.

## Prerequisites

The module creates none of these:

- A VPC with at least two public subnets routed to an internet gateway and at
  least one private subnet for the S3 interface endpoint
- A public Route53 hosted zone that contains `domain_name`
- An ACM certificate for `domain_name` in the provider region
- A regional WAFv2 WebACL
- An ALB-compatible OIDC application with user or group assignment
- At least one `ingress_cidr_blocks` or `ingress_prefix_list_ids` entry
- Encrypted, locked, versioned remote Terraform state

## Notes

### OIDC compatibility

The OIDC application must support the authorization code flow and ALB's
client-secret token exchange through publicly resolvable IPv4 HTTPS endpoints
on port 443. Register the `oidc_callback_url` output as the callback:

```text
https://<domain_name>/oauth2/idpresponse
```

ALB authenticates the user; S3 cannot evaluate OIDC claims. Restrict access with
default-deny assignment at the identity provider. The default session is 900
seconds.

### Exposure ordering

The ALB security group starts with no ingress. Viewer ingress rules are created
only after the WebACL association and the authenticated listener rules exist.
The HTTPS default action also authenticates before returning its terminal 404.
`0.0.0.0/0` is only allowed when a caller passes it explicitly.

### Origin

The site bucket is named after `domain_name` because the ALB preserves the
`Host` header and S3 routes virtual-hosted requests by bucket name. The bucket
enables Block Public Access, versioning, and SSE-S3, denies insecure transport,
and allows reads only through the module's interface endpoint. ALB access logs
and S3 access logs go to a separate protected logs bucket.

The S3 interface endpoint is deliberately part of this module, not shared
networking. The bucket policy trusts every request that arrives through it, and
its security group only admits the load balancer. Sharing the endpoint with
other workloads would let them read the site without SSO.

The module does not change account-level network controls such as VPC Block
Public Access.

### State and secrets

The OIDC client secret is stored in Terraform state even though the variable is
sensitive. Use protected remote state and never commit real OIDC values or
saved plan files.

### Cost

The ALB and one interface endpoint ENI per endpoint subnet incur continuous
charges.

## Tests

`tests/module.tftest.hcl` runs mocked plans without AWS credentials:

```bash
terraform init -backend=false
terraform test
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_metric_alarm.alb_5xx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.oidc_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.unhealthy_targets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.content](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_security_group_egress_rule.alb_health_check](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.alb_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.alb_http_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.alb_http_prefix_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.alb_https_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.alb_https_prefix_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.endpoint_health_check](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.endpoint_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_wafv2_web_acl_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_network_interface.s3_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_interface) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alarm_actions"></a> [alarm\_actions](#input\_alarm\_actions) | ARNs to notify when an alarm changes state, for example an SNS topic | `list(string)` | `[]` | no |
| <a name="input_authenticate_oidc"></a> [authenticate\_oidc](#input\_authenticate\_oidc) | Caller-owned, ALB-compatible OIDC application. The whole object is sensitive | <pre>object({<br/>    issuer                 = string<br/>    authorization_endpoint = string<br/>    token_endpoint         = string<br/>    user_info_endpoint     = string<br/>    client_id              = string<br/>    client_secret          = string<br/>    scope                  = optional(string, "openid")<br/>    session_cookie_name    = optional(string, "AWSELBAuthSessionCookie")<br/>    session_timeout        = optional(number, 900)<br/>  })</pre> | n/a | yes |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ARN of an existing ACM certificate for `domain_name` in the provider region | `string` | n/a | yes |
| <a name="input_create"></a> [create](#input\_create) | Controls if resources should be created (affects all resources) | `bool` | `true` | no |
| <a name="input_create_alarms"></a> [create\_alarms](#input\_create\_alarms) | Determines whether to create CloudWatch alarms for target health, 5xx responses, and OIDC errors | `bool` | `true` | no |
| <a name="input_create_http_listener"></a> [create\_http\_listener](#input\_create\_http\_listener) | Determines whether to create an HTTP listener that redirects to HTTPS | `bool` | `true` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Public HTTPS host. Also used as the site bucket name, the Route53 record, and the OIDC callback host | `string` | n/a | yes |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | If `true`, deletion of the load balancer will be disabled via the AWS API | `bool` | `true` | no |
| <a name="input_endpoint_subnet_ids"></a> [endpoint\_subnet\_ids](#input\_endpoint\_subnet\_ids) | Private subnet IDs for the S3 interface endpoint. Each subnet adds one endpoint network interface and load balancer target | `list(string)` | n/a | yes |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Delete all object versions from the site and logs buckets on destroy so they can be removed | `bool` | `false` | no |
| <a name="input_ingress_cidr_blocks"></a> [ingress\_cidr\_blocks](#input\_ingress\_cidr\_blocks) | IPv4 CIDR blocks allowed to reach the load balancer. No viewer source is allowed by default | `list(string)` | `[]` | no |
| <a name="input_ingress_prefix_list_ids"></a> [ingress\_prefix\_list\_ids](#input\_ingress\_prefix\_list\_ids) | Managed prefix list IDs allowed to reach the load balancer | `list(string)` | `[]` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Days to retain ALB access logs and S3 access logs | `number` | `90` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix for created resources. Defaults to `domain_name` with dots replaced by hyphens | `string` | `null` | no |
| <a name="input_noncurrent_version_retention_days"></a> [noncurrent\_version\_retention\_days](#input\_noncurrent\_version\_retention\_days) | Days to retain noncurrent site object versions for rollback | `number` | `30` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Public subnet IDs for the internet-facing load balancer, in at least two availability zones | `list(string)` | n/a | yes |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | ID of the public Route53 hosted zone that contains `domain_name` | `string` | n/a | yes |
| <a name="input_security_response_headers"></a> [security\_response\_headers](#input\_security\_response\_headers) | Security headers the HTTPS listener adds to every response. Content-Security-Policy is not set because the Sphinx theme and Mermaid use inline scripts and styles | <pre>object({<br/>    strict_transport_security = optional(string, "max-age=31536000; includeSubDomains")<br/>    x_content_type_options    = optional(string, "nosniff")<br/>    x_frame_options           = optional(string, "DENY")<br/>  })</pre> | `{}` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | Name of the SSL policy for the HTTPS listener. Must be a TLS13-1-2 or TLS13-1-3 policy, which require TLS 1.2 or later | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC that hosts the load balancer and the S3 interface endpoint | `string` | n/a | yes |
| <a name="input_web_acl_arn"></a> [web\_acl\_arn](#input\_web\_acl\_arn) | ARN of an existing regional WAFv2 WebACL to associate with the load balancer | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloudwatch_metric_alarm_arns"></a> [cloudwatch\_metric\_alarm\_arns](#output\_cloudwatch\_metric\_alarm\_arns) | ARNs of the CloudWatch alarms |
| <a name="output_deployment_iam_policy_json"></a> [deployment\_iam\_policy\_json](#output\_deployment\_iam\_policy\_json) | Least-privilege IAM policy document for a caller-created role that publishes the site |
| <a name="output_https_listener_arn"></a> [https\_listener\_arn](#output\_https\_listener\_arn) | The ARN of the HTTPS listener |
| <a name="output_lb_arn"></a> [lb\_arn](#output\_lb\_arn) | The ARN of the load balancer |
| <a name="output_lb_arn_suffix"></a> [lb\_arn\_suffix](#output\_lb\_arn\_suffix) | ARN suffix of the load balancer, for use with CloudWatch metrics |
| <a name="output_lb_dns_name"></a> [lb\_dns\_name](#output\_lb\_dns\_name) | The DNS name of the load balancer. Every HTTPS path authenticates |
| <a name="output_lb_id"></a> [lb\_id](#output\_lb\_id) | The ID of the load balancer |
| <a name="output_lb_zone_id"></a> [lb\_zone\_id](#output\_lb\_zone\_id) | The canonical hosted zone ID of the load balancer |
| <a name="output_logs_s3_bucket_arn"></a> [logs\_s3\_bucket\_arn](#output\_logs\_s3\_bucket\_arn) | The ARN of the logs bucket |
| <a name="output_logs_s3_bucket_id"></a> [logs\_s3\_bucket\_id](#output\_logs\_s3\_bucket\_id) | The name of the logs bucket |
| <a name="output_oidc_callback_url"></a> [oidc\_callback\_url](#output\_oidc\_callback\_url) | Callback URL to register with the OIDC application |
| <a name="output_route53_record_fqdn"></a> [route53\_record\_fqdn](#output\_route53\_record\_fqdn) | FQDN of the Route53 alias record |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The ARN of the private site bucket |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | The name of the private site bucket |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The ID of the load balancer security group |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | The ARN of the S3 endpoint target group |
| <a name="output_url"></a> [url](#output\_url) | Authenticated site URL |
| <a name="output_vpc_endpoint_id"></a> [vpc\_endpoint\_id](#output\_vpc\_endpoint\_id) | The ID of the S3 interface endpoint |
| <a name="output_vpc_endpoint_private_ips"></a> [vpc\_endpoint\_private\_ips](#output\_vpc\_endpoint\_private\_ips) | Private IPs of the S3 interface endpoint, registered as load balancer targets |
<!-- END_TF_DOCS -->
