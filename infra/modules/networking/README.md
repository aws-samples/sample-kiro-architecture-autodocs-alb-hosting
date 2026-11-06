# Networking

Terraform module that creates a VPC with one public and one private subnet per
availability zone, plus VPC flow logs in CloudWatch Logs. It composes the
community [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws)
module and its standalone
[`flow-log`](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/modules/flow-log)
submodule. The root module's built-in flow log is deprecated and will be removed
in v7.

## Usage

```hcl
module "networking" {
  source = "./modules/networking"

  name = "docs-example-com"
  azs  = ["eu-west-1a", "eu-west-1b"]

  tags = {
    Environment = "dev"
  }
}
```

## Design decisions

- No NAT or VPN gateway. The private subnets only host interface endpoints,
  which need no internet egress.
- The default security group is adopted and left without rules.
- Subnets are /24 blocks: public subnets start at index 0, private subnets at
  index 10. With the default `10.0.0.0/16` that gives `10.0.0.0/24`,
  `10.0.1.0/24`, `10.0.10.0/24`, and `10.0.11.0/24`.
- Flow logs capture all traffic at one-minute aggregation. The flow-log
  submodule creates the CloudWatch log group and its IAM role.

Workload-specific endpoints do not belong here. The S3 interface endpoint that
serves the documentation stays in `authenticated-static-site` because its
bucket policy trusts every request that arrives through it. Add shared
endpoints for other workloads with the
[`vpc-endpoints`](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/modules/vpc-endpoints)
submodule.

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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.28 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_flow_log"></a> [flow\_log](#module\_flow\_log) | terraform-aws-modules/vpc/aws//modules/flow-log | 6.7.3 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 6.7.3 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_azs"></a> [azs](#input\_azs) | Availability zones for one public and one private subnet each. At least two are required for an ALB | `list(string)` | n/a | yes |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | IPv4 CIDR block for the VPC (/16 to /19). One /24 public and one /24 private subnet are carved per availability zone | `string` | `"10.0.0.0/16"` | no |
| <a name="input_create"></a> [create](#input\_create) | Controls if resources should be created (affects all resources) | `bool` | `true` | no |
| <a name="input_flow_log_retention_in_days"></a> [flow\_log\_retention\_in\_days](#input\_flow\_log\_retention\_in\_days) | Number of days to retain VPC flow log events in CloudWatch Logs. Must be at least 365 (CKV\_AWS\_338), or 0 to never expire | `number` | `365` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used on all resources as an identifier | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_flow_log_cloudwatch_log_group_name"></a> [flow\_log\_cloudwatch\_log\_group\_name](#output\_flow\_log\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group receiving VPC flow logs |
| <a name="output_flow_log_id"></a> [flow\_log\_id](#output\_flow\_log\_id) | The ID of the VPC flow log |
| <a name="output_natgw_ids"></a> [natgw\_ids](#output\_natgw\_ids) | IDs of the NAT gateways. Empty by design |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | IDs of the private subnets |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | IDs of the public subnets, for example for a separately approved VPC Block Public Access exclusion |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
<!-- END_TF_DOCS -->
