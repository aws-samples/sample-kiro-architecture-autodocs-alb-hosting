"""Static repository checks for the portable Terraform profile."""

from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
INFRA_DIR = ROOT_DIR / "infra"
MODULE_DIR = INFRA_DIR / "modules" / "authenticated-static-site"


def test_module_leaves_consumer_prerequisites_external() -> None:
    """Verify content, identity, certificate, and WebACL creation stay external."""
    module_text = "\n".join(
        path.read_text(encoding="utf-8") for path in MODULE_DIR.glob("*.tf")
    )

    assert 'resource "aws_s3_object"' not in module_text
    assert 'resource "aws_cognito_user"' not in module_text
    assert 'resource "aws_iam_user"' not in module_text
    assert 'resource "aws_acm_certificate"' not in module_text
    assert 'resource "aws_wafv2_web_acl"' not in module_text
    assert 'resource "aws_wafv2_web_acl_association" "this"' in module_text


def test_sensitive_oidc_values_are_not_outputs() -> None:
    """Verify outputs do not expose the OIDC object or client secret."""
    outputs = (MODULE_DIR / "outputs.tf").read_text(encoding="utf-8")

    assert "client_secret" not in outputs
    assert 'output "oidc"' not in outputs


def test_deployment_root_keeps_secret_out_of_tfvars() -> None:
    """Verify the deployment root obtains its OIDC secret separately."""
    tfvars = (INFRA_DIR / "terraform.tfvars.example").read_text(encoding="utf-8")
    readme = (INFRA_DIR / "README.md").read_text(encoding="utf-8")

    assert "oidc_client_secret" not in tfvars
    assert "TF_VAR_oidc_client_secret" in readme


def test_default_oidc_session_is_fifteen_minutes() -> None:
    """Verify the reusable module defaults to a short authentication session."""
    variables = (MODULE_DIR / "variables.tf").read_text(encoding="utf-8")

    assert 'session_timeout        = optional(number, 900)' in variables
