# Getting started

Version 1 builds and previews documentation locally. It does not require AWS
credentials or Terraform.

## Prerequisites

Install:

- [uv](https://docs.astral.sh/uv/) 0.10 or later
- Python 3.11 or later, managed or selected by uv
- draw.io Desktop for PNG export
- `xmllint`, included with macOS and commonly provided by `libxml2-utils` on
  Linux

## Install the locked environment

```bash
uv sync --locked
```

This creates or updates the ignored `.venv/` directory from `pyproject.toml`
and `uv.lock`.

## Validate the project

```bash
make check
```

The check validates diagram XML and edge labels, verifies the uv lock and shell
syntax, then runs the pytest suite.

## Build the site

```bash
make html
```

Generated pages are written to `docs/_build/html/`.

## Generate an architecture diagram

Describe the architecture in Mermaid and ask the agent to apply the bundled
`drawio-aws-architecture` skill. The skill creates an editable `.drawio` source
with official AWS icons, labeled orthogonal edges, and checked layout. Keep the
Mermaid input and draw.io output together under `docs/diagrams/`.

```text
Mermaid architecture intent
        -> drawio-aws-architecture skill
        -> editable draw.io source
        -> make html exports PNG
        -> Sphinx page
```

[Generating architecture diagrams](diagram-generation.md) shows this project's
Mermaid input beside the generated draw.io result.

## Add an expandable diagram

Use the `expandable-diagram` class for architecture PNGs. The Sphinx build adds
the standard full-screen control without page-specific JavaScript.

````markdown
```{figure} diagrams/example.png
:alt: Describe the architecture and its main flow.
:align: center
:class: expandable-diagram

Short diagram caption.
```
````

Keep the editable `.drawio` source beside the PNG and state its path below the
figure.

## Preview locally

```bash
make preview
```

Open `http://127.0.0.1:8000` and stop the server with `Ctrl+C`. The default
listener is loopback-only. A network-wide listener requires an explicit
`--allow-network` acknowledgement when calling the preview script directly.

## Create a release

```bash
make release VERSION=example
```

The release command writes:

```text
dist/documentation-example.tar.gz
dist/documentation-example.sha256
```

The archive contains the static-site root directly and can be imported into a
consumer-managed documentation platform.

## Publish to the hosted site

After the `infra/` root is deployed, upload the built site to its private
bucket:

```bash
make publish
```

The bucket and region come from the Terraform outputs. Set `PUBLISH_BUCKET`
and `AWS_REGION` to publish without access to the Terraform state, and
`SKIP_DIAGRAMS=1` to build without draw.io Desktop.

## Validate the optional Terraform module

With Terraform 1.16 installed, run static and mocked checks without AWS
credentials:

```bash
make tf-check
```

This initializes only local Terraform working directories, validates the
`infra/` deployment root and its module, and runs Terraform-native mock tests. It does not run
`terraform plan` or `terraform apply`.

Continue with the [authenticated hosting architecture](hosting.md) or see
[how the diagrams are generated](diagram-generation.md).
