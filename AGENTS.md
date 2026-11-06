# Agent instructions

This repository builds a team's internal documentation with Sphinx and hosts it
behind SSO. The agent keeps the documentation current: it writes pages, keeps
architecture diagrams in sync with the code they describe, and verifies the
build.

## Layout

- `docs/` holds Sphinx sources (Markdown via MyST, or reST) and `conf.py`.
- `docs/diagrams/` holds Mermaid architecture intent, editable `.drawio`
  sources, and rendered `.png` files. All three are committed for the project
  architecture.
- `infra/` is the Terraform root that hosts the site. It composes
  `infra/modules/networking/` (VPC and flow logs) with
  `infra/modules/authenticated-static-site/` (ALB, OIDC, S3 endpoint, buckets).
- `.kiro/skills/drawio-aws-architecture/` is the diagram skill.

## Writing documentation

- Add new pages under `docs/` and list them in a `toctree`, usually in
  `docs/index.md`. Sphinx runs with `-W`, so an orphaned page fails the build.
- Embed diagrams with a MyST `figure` directive that points at the `.png`,
  includes descriptive `:alt:` text, and sets `:class: expandable-diagram` for
  the standard full-screen control. State the `.drawio` source path below it.
- Use synthetic or placeholder values only. Never write account IDs, real
  domains, client IDs, or secrets into the docs.

## Keeping diagrams current

- When a change alters the architecture a diagram shows, update the Mermaid
  intent and draw.io source in the same change. For example, a change under
  `infra/` that adds, removes, or reconnects resources must update
  `docs/diagrams/authenticated-static-site.mmd` and
  `docs/diagrams/authenticated-static-site.drawio`.
- Create or edit diagrams with the `drawio-aws-architecture` skill. Write a
  Mermaid sketch of the architecture first, then follow the skill checklist.
- Every edge needs exactly one non-empty label, and every `mxCell` ID must be
  numeric. `make check` enforces both.
- Edit the `.drawio` source, not the `.png`. `make diagrams` regenerates PNGs
  that are older than their source.

## Verifying

Run before finishing any change:

```bash
make check      # diagram XML and labels, lockfile, shell syntax, pytest
make html       # Sphinx build with warnings as errors
```

Also run `make tf-check` after changing anything under `infra/`. It validates
Terraform and runs mocked tests without AWS credentials.

## Terraform module conventions

The module follows the terraform-aws-modules style:

- All resources live in `main.tf`, grouped under `####` banner comments. Keep
  `variables.tf` and `outputs.tf` in the same section order.
- Every resource honors `var.create` through `count = local.create ? 1 : 0` or
  an empty `for_each`. Optional features use `create_*` toggles.
- Name the single resource of a type `this`. Outputs wrap references in
  `try(..., null)` and never echo inputs.
- Modules declare minimum versions (`>=`) and commit no lock file. Only the
  `infra/` root pins exact provider versions. Registry module sources are
  pinned to exact versions.
- Keep the S3 interface endpoint in `authenticated-static-site`. The site
  bucket trusts every request through it, so it must never become shared
  networking.
- After changing variables or outputs, regenerate the README tables with
  `terraform-docs markdown table --output-file README.md --output-mode inject --lockfile=false infra/modules/<module>`,
  or run `pre-commit run -a`.

Never run `terraform plan`, `terraform apply`, `terraform destroy`, or
`make publish`. Live infrastructure changes and uploads to the site bucket are
operator actions that need explicit approval.
