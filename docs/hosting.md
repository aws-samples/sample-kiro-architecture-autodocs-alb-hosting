# Authenticated hosting

The Terraform under `infra/` hosts the generated site behind an
internet-facing
[Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html).
The load balancer signs viewers in through an OpenID Connect (OIDC)
application that you own, then serves pages from a private Amazon S3 bucket.
This page is the architecture reference for that deployment; the diagram
matches the Terraform, which remains the source of truth. To see how the
diagram was generated from Mermaid, read
[generating architecture diagrams](diagram-generation.md).

```{figure} diagrams/authenticated-static-site.png
:alt: Approved viewers connect directly to an internet-facing Application Load Balancer on HTTP or HTTPS, an associated AWS WAF WebACL inspects requests, OIDC protects HTTPS content, and private Amazon S3 is reached through interface endpoint network interfaces.
:align: center
:class: expandable-diagram

Authenticated static documentation hosting flow.
```

The editable source is `docs/diagrams/authenticated-static-site.drawio`.

## Flow key

The flow key reflects the Terraform defaults and deployed resource
relationships.

| ID | Interaction |
|---|---|
| 1a | Approved viewer to Application Load Balancer: HTTP port 80 request receives a 301 redirect to HTTPS. |
| 1b | Approved viewer to Application Load Balancer: HTTPS port 443 request. |
| 2 | AWS WAF WebACL association: inspect requests handled by the Application Load Balancer. |
| 3 | Application Load Balancer and OIDC provider: authorization, callback, tokens, and user information. |
| 4a | Amazon Route 53 to Application Load Balancer: public alias record. |
| 4b | AWS Certificate Manager to Application Load Balancer: regional TLS certificate. |
| 5a | Application Load Balancer to Amazon S3 interface endpoint: post-OIDC HTTPS content request to endpoint network interfaces. |
| 5b | Application Load Balancer to endpoint network interfaces: HTTP reachability health check; responses from 200 through 499 are healthy. |
| 6 | Amazon S3 interface endpoint to private Amazon S3 bucket: AWS PrivateLink REST `GetObject`. |
| 7a | Application Load Balancer to Amazon CloudWatch: authentication and target metrics and alarms. |
| 7b | Application Load Balancer to Amazon S3 log bucket: load balancer access logs. |
| 7c | AWS WAF to Amazon CloudWatch Logs: request logs with configured fields redacted. |
| 7d | Private Amazon S3 site bucket to Amazon S3 log bucket: server access logs. |
| 7e | Amazon VPC to Amazon CloudWatch Logs: Flow Logs for all accepted and rejected traffic. |

## Consumer prerequisites

The consumer supplies:

- A public hosted zone and domain in the deployment account; the `infra/` root
  creates and DNS-validates an AWS Certificate Manager certificate in that zone
- A threat-model review of the baseline AWS WAF WebACL created with AWS managed
  IP reputation, common, and known bad inputs rule groups
- Explicit CIDR and/or managed prefix-list viewer sources
- An OIDC provider, application, assignment, and secret-rotation process
- Protected remote Terraform state
- An AWS account, deployment role, content, monitoring response, and cleanup
  owner

The repository contains synthetic sample content and generic placeholders only.

## Authentication boundary

The load balancer, not Amazon S3, decides who can read the site. It uses the
built-in
[OIDC authentication action](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-authenticate-users.html):

- HTTP requests on port 80 are redirected to HTTPS.
- Every HTTPS listener rule signs the viewer in before doing anything else.
  After sign-in, `/` redirects to `/index.html`, site pages are forwarded to
  Amazon S3, and any other path returns 404.
- Viewers without a valid session are redirected to your identity provider.

Your OIDC application must:

- Support the authorization code flow with a client ID and client secret.
- Expose its issuer, authorization, token, and user-information endpoints on
  public HTTPS port 443, because the load balancer calls them over the
  internet.
- Register this exact callback URL:

  ```text
  https://<domain>/oauth2/idpresponse
  ```

The load balancer checks only that sign-in succeeded. It does not check group
membership, so assign the application only to the users or groups that should
read the site.

## Network and origin boundary

No viewer source is allowed by default. The caller must explicitly supply at
least one IPv4 CIDR or managed prefix list. Terraform permits those sources to
reach the Application Load Balancer on HTTPS port 443 and, while the default
HTTP redirect listener is enabled, HTTP port 80. Both paths terminate at the
load balancer. The regional AWS WAF WebACL is associated with that resource and
inspects its requests; it is not a separate proxy or network endpoint. Terraform
creates viewer ingress only after the association and authenticated HTTPS rules
exist.

The Application Load Balancer sends post-OIDC content requests over HTTPS port
443 to private network-interface addresses from an Amazon S3 interface endpoint.
This origin request does not carry OIDC claims or an AWS Signature Version 4
credential. Endpoint security-group rules restrict it to the load balancer, and
the bucket policy restricts `GetObject` to the dedicated endpoint. The target
group also sends HTTP port 80 reachability health checks and considers responses
from 200 through 499 healthy because an unauthenticated Amazon S3 response still
proves that the endpoint is reachable.

The bucket disables website hosting, enables Block Public Access, versioning,
and server-side encryption with Amazon S3 managed keys, and denies insecure
transport.

The HTTPS listener adds security headers to every response:
`Strict-Transport-Security: max-age=31536000; includeSubDomains`,
`X-Content-Type-Options: nosniff`, and `X-Frame-Options: DENY`. It does not set
`Content-Security-Policy`, because the Sphinx theme and Mermaid use inline
scripts and styles that a strict policy would block. The HTTP listener only
redirects to HTTPS, so browsers receive the headers on the first HTTPS
response.

### Why the endpoint is an interface endpoint

An Application Load Balancer target group supports registered targets such as
instances, IP addresses, and Lambda functions. An Amazon S3 interface endpoint
provides private network interfaces whose IP addresses can be registered as
`ip` targets. An Amazon S3 gateway endpoint changes route tables for clients
that call Amazon S3, but it exposes no network interfaces or private IP targets.
See the primary [Application Load Balancer target-type documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-type).

Changing this endpoint to a gateway endpoint would therefore break the selected
Application Load Balancer-to-Amazon S3 architecture. A gateway endpoint is
appropriate for workloads inside a VPC that call Amazon S3 directly, not for
this reverse-proxy pattern.

Account-level network protections and exceptions remain outside this module.
Public subnet IDs are output for a separately approved process when required.

## Observability

The Application Load Balancer writes access logs to the private Amazon S3 log
bucket, and the site bucket writes server access logs to a separate prefix in
that bucket. AWS WAF writes request logs to Amazon CloudWatch Logs with query
strings, authorization headers, and cookies redacted. Amazon VPC Flow Logs send
accepted and rejected traffic records to a separate Amazon CloudWatch Logs log
group. Three Amazon CloudWatch alarms monitor unhealthy endpoint targets, load
balancer 5xx responses, and OIDC authentication errors.

## Terraform layout

- `infra/` is the deployment root. It composes existing prerequisites and
  accepts the OIDC secret outside committed tfvars.
- `infra/modules/networking/` creates the Amazon VPC with two public and two
  private subnets, no NAT gateway, and Amazon VPC Flow Logs in Amazon CloudWatch
  Logs.
- `infra/modules/authenticated-static-site/` contains the Application Load
  Balancer, OIDC actions, Amazon S3 interface endpoint, and private Amazon S3
  resources. The endpoint is dedicated to the site because the bucket trusts
  every request that arrives through it.

## Validation

```bash
make tf-check
```

This performs formatting, schema validation, module composition checks, and
mocked plan tests without AWS credentials. It does not run a live plan or apply
and does not call AWS service APIs.

## AWS service references

| Service or feature | Documentation |
|---|---|
| Application Load Balancer | [What is an Application Load Balancer?](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html) |
| Application Load Balancer target types | [Target type](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-type) |
| Application Load Balancer OIDC authentication | [Authenticate users using an Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-authenticate-users.html) |
| Application Load Balancer with Amazon S3 and AWS PrivateLink | [Hosting internal HTTPS static websites with ALB, S3, and PrivateLink](https://aws.amazon.com/blogs/networking-and-content-delivery/hosting-internal-https-static-websites-with-alb-s3-and-privatelink/) |
| Amazon S3 interface endpoints | [AWS PrivateLink for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/privatelink-interface-endpoints.html) |
| Amazon S3 Block Public Access | [Blocking public access to Amazon S3 storage](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html) |
| AWS WAF managed rules | [AWS managed rule groups](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html) |
| AWS WAF logging | [Logging AWS WAF traffic](https://docs.aws.amazon.com/waf/latest/developerguide/logging.html) |
| AWS Certificate Manager DNS validation | [DNS validation](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html) |
| Amazon Route 53 alias to an Application Load Balancer | [Routing traffic to an ELB load balancer](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-elb-load-balancer.html) |
| Amazon VPC Flow Logs | [Logging IP traffic using VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html) |

## Cost

The Application Load Balancer, Amazon S3 interface endpoint network interfaces,
AWS WAF, and Amazon CloudWatch Logs ingestion incur charges. Calculate current
regional costs before applying and remove temporary resources promptly.

## Teardown

The stack has two safeguards against accidental deletion: load balancer
deletion protection is on, and Terraform will not delete the versioned site and
log buckets while they contain objects. Turn both off, then destroy:

```bash
cd infra
export TF_VAR_oidc_client_secret='<from your approved secret source>'

# 1. Turn off the safeguards. Only these two settings change.
terraform plan -var enable_deletion_protection=false -var force_destroy=true -out=unprotect.tfplan
terraform apply unprotect.tfplan

# 2. Review and apply the destroy plan.
terraform plan -destroy -var enable_deletion_protection=false -var force_destroy=true -out=destroy.tfplan
terraform apply destroy.tfplan
```

The destroy removes the site and log buckets, including all object versions,
and the AWS WAF log group. Export any logs you must retain first. The Terraform
state backend, the Route 53 hosted zone, and the OIDC application are not
managed by this stack and remain in place.

To redeploy, run a normal `terraform plan` and `terraform apply`, which restore
both safeguards, then run `make publish`. A redeploy typically takes 15 to 25
minutes, most of it load balancer and endpoint provisioning and certificate
validation.
