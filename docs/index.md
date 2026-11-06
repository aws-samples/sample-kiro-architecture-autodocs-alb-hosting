# Sphinx and draw.io Documentation Kit

This site demonstrates an agent-maintained documentation workflow. Sphinx
builds Markdown and Python docstrings into a static site, while the bundled
`drawio-aws-architecture` skill turns Mermaid architecture intent into an
editable draw.io source and a generated PNG.

```{toctree}
:maxdepth: 2
:caption: Contents

getting-started
hosting
api
diagram-generation
```

## What is automated

- Sphinx builds documentation and API references with warnings treated as
  errors.
- The diagram skill translates a Mermaid service-and-connection description
  into an editable draw.io architecture using official AWS icons.
- `make html` regenerates PNGs when their draw.io sources change.
- `make release` packages the same deterministic HTML tree for deployment.
- `make publish` synchronizes the generated site to the optional private Amazon
  S3 origin.

[Authenticated hosting](hosting.md) documents the deployed architecture.
[Generating architecture diagrams](diagram-generation.md) shows how the skill
turned that architecture's Mermaid description into the editable draw.io
diagram.

## Build contract

The same commands run locally and in consumer-managed CI:

```bash
make check
make html
make release VERSION=example
```

The HTML site is written to `docs/_build/html/`. Release archives and SHA-256
checksums are written to `dist/`.

## Deployment profile

The generated archive can be previewed locally, imported into an existing
internal documentation platform, or published through the optional
[authenticated AWS hosting profile](hosting.md).
