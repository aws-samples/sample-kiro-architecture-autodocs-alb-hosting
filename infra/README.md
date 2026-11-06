# Documentation hosting

This is the Terraform root that hosts the generated documentation behind SSO.
It composes [`modules/authenticated-static-site`](modules/authenticated-static-site/)
with prerequisites you already own:

```text
Explicit viewer source -> existing WAF -> internet-facing ALB
                       -> OIDC authentication (your SSO)
                       -> S3 interface endpoint -> private S3 REST bucket
```

Provide an existing domain and public hosted zone, an ALB-compatible OIDC
application, and explicit CIDR or managed prefix-list viewer sources. This root
creates:

- An ACM certificate, validated through a DNS record in your hosted zone
- A regional WAF WebACL with the AWS managed IP reputation, common, and known
  bad inputs rule groups, plus redacted request logging in CloudWatch Logs

The module adds the Route 53 alias to its ALB.

Set `ingress_cidr_blocks` or `ingress_prefix_list_ids` to the narrowest
sources your viewers use, such as your corporate VPN egress ranges or a managed
prefix list for them. Do not allow `0.0.0.0/0`: it exposes the load balancer to
every internet scanner and leaves sign-in as the only control on that path.

## Layout

```text
infra/
  main.tf, variables.tf, ...          Deployment root (edit this)
  modules/networking/                 VPC, subnets, and CloudWatch flow logs
  modules/authenticated-static-site/  ALB, OIDC, S3 interface endpoint, private S3
  tests/                              Mocked plan of the full composition
```

`networking` wraps the community `terraform-aws-modules/vpc/aws` module and its
standalone flow-log submodule: two AZs, no NAT or VPN gateway. The S3 interface
endpoint stays in `authenticated-static-site` because the site bucket trusts
every request that arrives through it.

The root pins exact Terraform and provider versions and commits its lock file.
The module only declares minimum versions. See its
[README](modules/authenticated-static-site/README.md) for all inputs and outputs.

## Private configuration

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
export TF_VAR_oidc_client_secret='<retrieve from approved secret source>'
```

Replace all placeholders. Do not put the OIDC client secret in `terraform.tfvars`
or source control. Terraform state still contains the secret after apply, so use
an encrypted, versioned, access-restricted remote backend.

## Static validation

From the repository root:

```bash
make tf-check
```

This runs formatting, initialization, schema validation, and mocked Terraform
tests without AWS credentials. It does not run plan or apply.

## Live workflow

> This sample is for demonstration and education, not production use without
> your own review, and it creates billed AWS resources. See the
> [disclaimer](../README.md#disclaimer).

Before any live action, complete the applicable identity, domain, WAF, security
review, account, network-control, state, cost, and cleanup prerequisites. Then:

1. Verify the explicit account and role.
2. Initialize with `terraform init -backend-config=backend.hcl`.
3. Create and review a saved Terraform plan.
4. Apply only after explicit approval.
5. Publish the site from the repository root with `make publish`. Until the
   bucket has an `index.html`, S3 answers `AccessDenied` after login.
6. Verify WAF, authentication on every HTTPS path, private S3, target health,
   logs, and alarms before widening access.
7. Destroy only after separate confirmation and remove temporary external
   network-control exceptions. Set `enable_deletion_protection=false` and
   `force_destroy=true` in a reviewed plan first; see the teardown section of
   `docs/hosting.md`.

The site bucket only grants `s3:GetObject` through the endpoint, so a missing
page returns `AccessDenied` instead of 404.

This public sample intentionally contains no organization-specific identity or
security-review instructions.

## Cost

The ALB, two interface endpoint ENIs, and CloudWatch Logs ingestion for VPC flow
logs incur charges. Calculate current regional costs before applying and assign
a cleanup owner.
