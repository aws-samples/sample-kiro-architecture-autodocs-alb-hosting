#!/usr/bin/env bash
# Sync the built site to the private S3 bucket created by infra/.
#
# The bucket and region come from the infra/ Terraform outputs. Override them
# with PUBLISH_BUCKET and AWS_REGION, for example when publishing from CI
# without access to the Terraform state.
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SITE_DIR="$ROOT_DIR/docs/_build/html"
INFRA_DIR="$ROOT_DIR/infra"
aws_cli="${AWS_CLI:-aws}"

if [[ ! -s "$SITE_DIR/index.html" ]]; then
  printf 'Built site is missing: %s. Run make html first.\n' "$SITE_DIR/index.html" >&2
  exit 1
fi

if ! command -v "$aws_cli" >/dev/null 2>&1; then
  printf 'AWS CLI is required but was not found: %s\n' "$aws_cli" >&2
  exit 1
fi

terraform_output() {
  terraform -chdir="$INFRA_DIR" output -raw "$1" 2>/dev/null || true
}

bucket="${PUBLISH_BUCKET:-$(terraform_output s3_bucket_id)}"
region="${AWS_REGION:-$(terraform_output aws_region)}"

if [[ -z "$bucket" ]]; then
  printf 'Cannot determine the site bucket. Apply infra/ first or set PUBLISH_BUCKET.\n' >&2
  exit 1
fi

if [[ -z "$region" ]]; then
  printf 'Cannot determine the bucket region. Run terraform apply in infra/ to record the aws_region output, or set AWS_REGION.\n' >&2
  exit 1
fi

printf 'Publishing %s to s3://%s/ in %s\n' "$SITE_DIR" "$bucket" "$region"
# --delete removes pages that no longer exist in the build. Older versions stay
# recoverable because the bucket is versioned.
"$aws_cli" s3 sync "$SITE_DIR/" "s3://$bucket/" --region "$region" --delete

url="$(terraform_output url)"
if [[ -n "$url" ]]; then
  printf 'Published. Open %s\n' "$url"
fi
