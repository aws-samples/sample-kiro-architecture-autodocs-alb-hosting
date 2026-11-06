# Generating architecture diagrams

The bundled `drawio-aws-architecture` skill turns a Mermaid description of a
system into an editable draw.io diagram that uses official AWS icons. This page
shows the skill applied to this repository. The hosting design itself is
documented in [authenticated hosting](hosting.md).

## Workflow

```{figure} diagrams/drawio-skill-prompt-to-presentation-workflow.png
:alt: Four-stage workflow. A free-text prompt describing a static site on Amazon S3 behind Amazon CloudFront produces a Mermaid diagram in about 30 seconds. Applying the drawio-aws-architecture skill converts it into an editable draw.io diagram with official AWS icons in about 2 more minutes. The diagram is then refined through follow-up prompts, such as moving a label that an arrow crosses, iterating until it is ready.
:align: center
:class: expandable-diagram

From prompt to presentation-ready diagram: a simple example.
```

This workflow illustration is a static image with no editable draw.io source.

```text
Mermaid architecture intent
        -> drawio-aws-architecture skill
        -> editable draw.io source
        -> make html exports PNG
        -> Sphinx page
```

1. Describe services, boundaries, and connections in Mermaid. Treat the
   implementation, such as Terraform, as the source of truth.
2. Ask the agent to apply the skill. It resolves official service names and
   icons from the skill's icon reference, plans rows and routing corridors, and
   writes the `.drawio` source.
3. `make html` exports a PNG whenever the `.drawio` source is newer.
4. `make check` enforces valid XML, numeric cell IDs, exactly one label per
   edge, and perpendicular edge entry.
5. Review the rendered diagram. Layout adjustments are made in the `.drawio`
   source, never in the PNG.

Generation is not deterministic, so regression checks compare structure and
meaning rather than pixels: the same services, boundaries, and labeled flows
should appear when the skill is rerun from the Mermaid source alone.

## Example: simple flow with descriptive labels

Diagrams with a few short interactions label each edge directly.

```{figure} diagrams/architecture.png
:alt: Author edits documentation sources, runs the Sphinx and draw.io build, creates a versioned static archive, and previews or imports the artifact.
:align: center
:class: expandable-diagram

Build and release flow.
```

The editable source is `docs/diagrams/architecture.drawio`.

## Example: dense architecture with numbered flows

Diagrams with many interactions use compact identifiers such as `1a` and `5b`.
The page that embeds the diagram explains each identifier in an accessible
flow-key table; see the
[authenticated hosting flow key](hosting.md#flow-key).

### Mermaid input

```{mermaid} diagrams/authenticated-static-site.mmd
:align: center
:caption: Architecture intent supplied to the skill.
```

### Generated draw.io output

```{figure} diagrams/authenticated-static-site.png
:alt: Generated draw.io rendering of the authenticated hosting architecture, with numbered flows between the viewer, Application Load Balancer, AWS WAF, OIDC provider, Amazon S3 interface endpoint, private Amazon S3 bucket, and logging services.
:align: center
:class: expandable-diagram

Presentation-ready output generated from the Mermaid input above.
```

Source files:

- Mermaid input: `docs/diagrams/authenticated-static-site.mmd`
- Editable output: `docs/diagrams/authenticated-static-site.drawio`
