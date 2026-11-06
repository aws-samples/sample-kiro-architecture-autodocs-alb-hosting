---
name: drawio-aws-architecture
description: >
  Generate editable draw.io AWS architecture diagrams from Mermaid source
  with standard AWS4 icons (sketch=0, strokeColor=#ffffff, 78x78
  resourceIcon), orthogonal edge routing, labeled connections, and
  layout strategies to prevent arrow-text overlap. Includes icon name
  validation, north/south label positioning based on edge direction,
  and PNG export via the draw.io CLI or web app.
category: standards
---

# Architecture Diagrams

## Purpose

Produce presentation-quality, editable AWS architecture diagrams from Mermaid source in the system architecture document. The output is a `.drawio` XML file using the standard AWS4 icon set, with orthogonal edge routing, labeled connections, and a layout designed to prevent arrow-text overlap.

## Why This Skill Exists

The AWS Diagram MCP Server (`awslabs.aws-diagram-mcp-server`) can generate architecture PNGs directly. However, its output uses the Python `diagrams` library icon set, which has a different visual style from the official AWS Architecture Icons. The output is a static PNG with no ability to edit layout, adjust labels, or refine routing after generation.

This skill produces draw.io files that:

- Use the official AWS4 icon shapes (the same icons you get dragging from the AWS panel in draw.io)
- Are fully editable (drag nodes, adjust edges, change labels, add annotations)
- Export to PNG, SVG, or PDF at any scale
- Can be opened in draw.io desktop, the free web app (app.diagrams.net), or the VS Code extension

## Prerequisites

| Tool | Required | Purpose |
|------|----------|---------|
| xmllint | Yes | Automated verification of .drawio node and edge counts |
| draw.io Desktop | Required for automated PNG export | CLI conversion of .drawio to PNG |
| AWS Diagram MCP Server | Optional | Fallback icon name discovery via `list_icons` when service is not in the reference file |

### AWS Diagram MCP Server

Used only for discovering AWS service icon names via `list_icons`. The skill does not use the MCP server to generate diagrams.

The server must be configured in your MCP settings. Example configuration for `.kiro/settings/mcp.json` or `~/.kiro/settings/mcp.json`:

```json
{
  "mcpServers": {
    "aws-diagram": {
      "command": "uvx",
      "args": ["awslabs.aws-diagram-mcp-server@latest"],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

This configuration uses `uvx` to run the server. If `uvx` is not installed, see [uv installation](https://docs.astral.sh/uv/getting-started/installation/).

### draw.io Desktop

Required for automated CLI PNG export from .drawio files. Without the desktop app, the .drawio file is still generated and can be exported manually (see Working Without draw.io Desktop below).

Download from [github.com/jgraph/drawio-desktop](https://github.com/jgraph/drawio-desktop/releases). On macOS the CLI is at:

```text
/Applications/draw.io.app/Contents/MacOS/draw.io
```

## Prerequisite Verification

Before starting, verify the required tools are available:

| Check | Command | Expected |
|-------|---------|----------|
| xmllint installed | `which xmllint` | Returns a path (pre-installed on macOS) |
| draw.io desktop (for CLI export) | `ls /Applications/draw.io.app/Contents/MacOS/draw.io` (macOS) or `which drawio` (Linux) | File exists |
| MCP server (optional) | Call `list_icons` with any category | Returns a list of icon names |

If xmllint is missing, install via `apt install libxml2-utils` (Debian/Ubuntu) or `yum install libxml2` (RHEL/Amazon Linux). If draw.io desktop is missing, the .drawio file is still generated but automated PNG export is not available. The MCP server is only needed if a service is not covered by the validated table or `reference/drawio-icon-reference.md`.

## Implementation Checklist

### Step 1: Read the Architecture Source

- [ ] Read the system architecture document containing Mermaid diagrams
- [ ] Identify all AWS services, external actors, external dependencies, and connection labels
- [ ] Note the layer groupings (Frontend, Auth, Agent, API, Data, Observability)

### Step 2: Resolve Names and Icons

- [ ] For each AWS service identified in Step 1, look up its official label, draw.io `resIcon` value, and `fillColor` in `reference/drawio-icon-reference.md`. Treat its **AWS Display Name** column as the naming source of truth, including when the MCP or icon identifier uses a legacy product name.
- [ ] The Validated Icon Names table below is a quick subset, not a separate naming authority.
- [ ] For any service not in the reference, generate a candidate `resIcon` value by converting the service name to lowercase with underscores, prefixed with `mxgraph.aws4.` (e.g., `ElastiCache` becomes `mxgraph.aws4.elasticache`). Only call `list_icons` on the MCP server if you cannot determine the service name from the reference.
- [ ] Record the official display name, `resIcon` value, and `fillColor` for each service before proceeding to Step 3.

### Step 3: Create draw.io Diagram

- [ ] Create a `.drawio` XML file with the full architecture
- [ ] Write the file in sections: use `fsWrite` for the first section (XML header, actors, cloud boundary), then `fsAppend` for each subsequent section (one cluster per append, then all edges as a final append). Do not attempt to write the entire XML in a single call.
- [ ] Use the standard AWS4 icon style (see Icon Style Reference below)
- [ ] Group services into named clusters using `mxgraph.aws4.group` shapes with dashed borders. Containment must be structural, not only visual: set each cluster's `parent` to the AWS Cloud cell, each clustered service's `parent` to its cluster cell, each unclustered AWS service's `parent` to the AWS Cloud cell, and each external actor's `parent` to the root layer.
- [ ] Place the entire architecture inside an AWS Cloud group boundary. Use this exact style (single line):

  ```text
  points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=1;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_aws_cloud_alt;stroke=#232F3E;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;spacingTop=5;dashed=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;
  ```

  `grIcon=mxgraph.aws4.group_aws_cloud_alt` renders the AWS cloud icon in the top-left corner. `verticalAlign=top;align=left` anchors the label next to it. Size the boundary geometry to fit the content with reasonable padding. Avoid large empty regions that make the icon and label appear to float in the middle.
- [ ] Place external actors and services outside the cloud boundary

### Step 4: Layout and Edge Routing

#### Row-Based Layout Planning

Before writing any coordinates, plan the layout as horizontal rows with vertical corridors between them. Each row holds nodes at the same y-coordinate. Corridors are the vertical gaps between rows where edges can route without crossing nodes.

Concrete example for a 5-service architecture (WAF, CloudFront, ACM, S3, Cognito):

```text
Row 1 (y=60):   ACM                          ← supporting service, label on top (north)
                  |  corridor ~130px
Row 2 (y=270):  WAF ——→ CloudFront ——→ S3     ← main request flow, left to right
                  |  corridor ~130px
Row 3 (y=490):  Cognito                       ← auth flow, label on bottom (south)
```

Place the main request flow on the middle row. Place supporting services (certs, monitoring) above. Place auth and data services below. Use at least 130px between row centers to leave room for edge labels and routing. Use at least 280px between column centers for the same reason.

Size the cloud boundary to fit the planned rows with 60-80px padding on each side. Do not create an oversized boundary with empty space.

#### Node and Edge Placement

- [ ] Plan rows and columns on paper before writing coordinates. Assign each service to a row and column position. Identify which edges need to cross rows (vertical) vs stay in-row (horizontal).
- [ ] Place nodes on the planned grid. Use dedicated corridors between rows/columns for edge routing. Corridors are a planning tool for choosing waypoint coordinates, not a routing constraint. The draw.io orthogonal router ignores declared corridors and routes through whatever space exists between node bounding boxes. Every edge that needs to avoid a node or share a lane with other edges must have explicit `<Array as="points">` waypoints pinning it to the intended corridor. Auto-routing (no waypoints) is only safe for direct point-to-point edges with no nodes in between.
- [ ] Use `edgeStyle=orthogonalEdgeStyle;rounded=1` on all edges for right-angle routing with curved corners at bend points
- [ ] Control edge direction with exit/entry port constraints on the edge style. For horizontal edges: `exitX=1;exitY=0.5` (right side) to `entryX=0;entryY=0.5` (left side). For vertical edges going up: `exitX=0.5;exitY=0` (top) to `entryX=0.5;entryY=1` (bottom). For vertical edges going down: `exitX=0.5;exitY=1` (bottom) to `entryX=0.5;entryY=0` (top). Always include `exitDx=0;exitDy=0;entryDx=0;entryDy=0`.
- [ ] Ensure the first and final edge segments meet each icon perpendicularly. When an edge routes through a corridor below two nodes, use bottom ports on both nodes and center-aligned first and last waypoints; for a corridor above, use top ports. Never select side ports if that makes the route run parallel to or behind the icon boundary before turning.
- [ ] Add explicit waypoint arrays (`<Array as="points">`) to all edges except direct point-to-point connections with no nodes in between. Each waypoint must be a distinct coordinate. Never use two identical points (this is a no-op that the router ignores). Example:

  ```xml
  <mxCell id="e5" style="edgeStyle=orthogonalEdgeStyle;html=1;strokeColor=#DD344C;strokeWidth=1.5;exitX=0.5;exitY=1;exitDx=0;exitDy=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;fontSize=10;" edge="1" source="user" target="cognito" parent="1">
    <mxGeometry relative="1" as="geometry">
      <Array as="points">
        <mxPoint x="99" y="559"/>
        <mxPoint x="591" y="559"/>
      </Array>
    </mxGeometry>
  </mxCell>
  ```

#### Edge Labels

- [ ] Give every edge exactly one non-empty label. For diagrams with a few short interactions, label edges directly with descriptive text. For diagrams with many or long interactions, use compact identifiers such as `1`, `2`, `3a`, and `3b`, then add a complete legend inside the diagram.
- [ ] Keep identifiers stable and group related interactions with letter suffixes. The in-diagram legend must map every identifier to one concise description, and documentation that embeds the diagram should repeat the mapping as an accessible table.
- [ ] When a direct descriptive label is longer than roughly 24 characters, wrap it at a semantic boundary. Use `&#10;` in draw.io XML and `<br/>` in Mermaid. Do not wrap compact identifiers.
- [ ] Use the official full service name from `reference/drawio-icon-reference.md` when a description names a service. Introduce an acronym only after the full name.
- [ ] Add `labelBackgroundColor=#FFFFFF` to all edge-label styles so labels are readable over crossing edges.
- [ ] Use separate `edgeLabel` child cells for labels instead of putting the label text in the edge's `value` attribute. This gives draw.io better control over label placement and prevents labels from drifting when edges are rerouted. Example:

  ```xml
  <mxCell id="e2" style="edgeStyle=orthogonalEdgeStyle;html=1;strokeColor=#8C4FFF;strokeWidth=1.5;exitX=1;exitY=0.5;exitDx=0;exitDy=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;fontSize=10;" edge="1" source="waf" target="cf" parent="aws-cloud">
    <mxGeometry relative="1" as="geometry"/>
  </mxCell>
  <mxCell id="e2-label" value="Filtered requests" style="edgeLabel;html=1;align=center;verticalAlign=middle;resizable=0;points=[];fontSize=10;labelBackgroundColor=#FFFFFF;" vertex="1" connectable="0" parent="e2">
    <mxGeometry x="-0.1" relative="1" as="geometry">
      <mxPoint as="offset"/>
    </mxGeometry>
  </mxCell>
  ```

#### Node Labels and Visual Style

- [ ] Use the **AWS Display Name** from `reference/drawio-icon-reference.md` in every service node label. Do not derive labels from MCP names or `resIcon` values. Do not use acronym-only labels such as `S3`, `VPC`, `ACM`, or `ALB`. Add an acronym in parentheses only after the full name when it helps later references.
- [ ] Break long official names at a natural boundary instead of abbreviating them. For compact 78x78 nodes, prefer labels such as `Amazon&#10;S3` or `AWS Certificate&#10;Manager (ACM)` and verify the exported text does not overlap edges.
- [ ] Default node labels to south position (`verticalLabelPosition=bottom;verticalAlign=top`)
- [ ] Choose the final label side after routing edges. A single shared edge track may use the label side when the text remains readable, but two or more distinct top or bottom tracks must never pass through the same node label. Move the label to the opposite side or reroute those edges.
- [ ] Visually inspect arrowheads that terminate on the label side even when they share one track; move the label if the arrowhead obscures meaningful text.
- [ ] Color-code edges by service category for visual clarity (e.g., `strokeColor=#8C4FFF` for networking, `#DD344C` for security, `#3F8624` for storage). Match the `fillColor` of the target or source service.
- [ ] Use `dashed=1` on return/response edges (e.g., JWT token flowing back from Cognito) to visually distinguish them from request edges

### Step 5: Verify Translation

- [ ] Count the number of service nodes in the source Mermaid diagram
- [ ] Count the number of service nodes in the generated .drawio file using `xmllint`:

  ```bash
  # Count service icon nodes (resIcon style)
  xmllint --xpath 'count(//mxCell[contains(@style,"resIcon=")])' diagram.drawio

  # Count general shape nodes (user, internet icons)
  xmllint --xpath 'count(//mxCell[contains(@style,"shape=mxgraph.aws4.user") or contains(@style,"shape=mxgraph.aws4.internet")])' diagram.drawio

  # Count edges
  xmllint --xpath 'count(//mxCell[@edge="1"])' diagram.drawio

  # List all child edge labels to verify none are empty
  xmllint --xpath '//mxCell[contains(concat(";",@style),";edgeLabel;")]/@value' diagram.drawio
  ```

- [ ] Confirm node counts match the source Mermaid diagram. If the .drawio has fewer nodes, identify which services were dropped and add them
- [ ] Confirm edge counts match. If the .drawio has fewer edges, identify which connections were dropped and add them
- [ ] Verify every edge has exactly one child `edgeLabel` cell with a non-empty `value`. Do not require a `value` on the edge cell itself.

`xmllint` is pre-installed on macOS. On Linux, install via `apt install libxml2-utils` or `yum install libxml2`.

### Step 6: Export to PNG

- [ ] Export using the draw.io desktop CLI (requires draw.io desktop installed):

  ```bash
  /Applications/draw.io.app/Contents/MacOS/draw.io \
    --export --format png --scale 2 --border 20 \
    --output output.png input.drawio
  ```

- [ ] After export, ask the user: "Please check the diagram. Are any icons showing as plain colored squares without an icon inside them? If so, tell me which service names are affected." Do not use `read_image` or any image-reading tool to verify the PNG. It is unreliable (may silently return no content) and wastes thousands of tokens on base64 image data per call. The user prompt is the intended verification mechanism.
- [ ] For layout refinement after icon verification, the user can either review the PNG and describe changes (e.g., "move Cognito below the main flow", "straighten the edge between Lambda and DynamoDB").
- [ ] If draw.io desktop is not installed, see Working Without draw.io Desktop below
- [ ] Optionally create a second copy with the simple icon style (60x60, no white stroke) for compact views

## Icon Style Reference

### Standard Style (recommended)

Produces clean square icons with white outlines matching the current AWS Architecture Icon set. Use 78x78 size. Copy this style string exactly (it must be a single line in the XML `style` attribute):

```text
sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;fillColor=#ED7100;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=10;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.lambda
```

Replace `fillColor=#ED7100` with the service category color and `resIcon=mxgraph.aws4.lambda` with the service icon name.

### Simple Style (compact)

Smaller icons without the white outline. Use 60x60 size. Copy this style string exactly (single line):

```text
outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#ED7100;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=10;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.lambda
```

### Validated Icon Names (Common Services)

This table covers the most frequently used services in AWS architecture diagrams. All entries have been tested by PNG export. For services not listed, check `reference/drawio-icon-reference.md` or follow the Icon Discovery Process below.

| AWS Service | resIcon value | fillColor |
|-------------|--------------|-----------|
| AWS Lambda | `mxgraph.aws4.lambda` | #ED7100 |
| Amazon EC2 | `mxgraph.aws4.ec2` | #ED7100 |
| Amazon ECS | `mxgraph.aws4.ecs` | #ED7100 |
| Amazon EKS | `mxgraph.aws4.eks` | #ED7100 |
| Amazon CloudFront | `mxgraph.aws4.cloudfront` | #8C4FFF |
| Amazon API Gateway | `mxgraph.aws4.api_gateway` | #E7157B |
| Amazon Route 53 | `mxgraph.aws4.route_53` | #8C4FFF |
| Amazon S3 | `mxgraph.aws4.s3` | #3F8624 |
| Amazon DynamoDB | `mxgraph.aws4.dynamodb` | #C925D1 |
| Amazon RDS | `mxgraph.aws4.rds` | #C925D1 |
| Amazon ElastiCache | `mxgraph.aws4.elasticache` | #C925D1 |
| Amazon Cognito | `mxgraph.aws4.cognito` | #DD344C |
| AWS WAF | `mxgraph.aws4.waf` | #DD344C |
| AWS Certificate Manager | `mxgraph.aws4.certificate_manager` | #DD344C |
| AWS Secrets Manager | `mxgraph.aws4.secrets_manager` | #DD344C |
| Amazon CloudWatch | `mxgraph.aws4.cloudwatch` | #E7157B |
| AWS CloudTrail | `mxgraph.aws4.cloudtrail` | #E7157B |
| AWS Budgets | `mxgraph.aws4.budgets` | #277116 |
| Amazon Bedrock | `mxgraph.aws4.bedrock` | #01A88D |
| Amazon SageMaker | `mxgraph.aws4.sagemaker` | #01A88D |
| Amazon Kinesis | `mxgraph.aws4.kinesis` | #8C4FFF |
| AWS Glue | `mxgraph.aws4.glue` | #8C4FFF |
| AWS X-Ray | `mxgraph.aws4.xray` | #C7131F |
| Amazon EventBridge | `mxgraph.aws4.eventbridge` | #E7157B |
| AWS Step Functions | `mxgraph.aws4.step_functions` | #E7157B |
| Amazon SNS | `mxgraph.aws4.sns` | #E7157B |
| Amazon SQS | `mxgraph.aws4.sqs` | #E7157B |
| Internet (external) | `mxgraph.aws4.internet_alt1` | #232F3E |
| User actor | `mxgraph.aws4.user` | #232F3E |

Note: AgentCore does not have a dedicated draw.io icon as of April 2026. Use `mxgraph.aws4.bedrock` for Bedrock-related services including AgentCore Runtime and AgentCore Memory.

For the full list of AWS services and their draw.io icon mappings, see `reference/drawio-icon-reference.md`. The reference covers 166 service-level icons and general architecture shapes with an official display name, MCP server name, draw.io `resIcon` or shape value, and fill color. Its **AWS Display Name** column is authoritative for generated service labels.

### What Is and Isn't in the Reference

The reference includes one entry per distinct AWS service (e.g., Lambda, DynamoDB, Kinesis). It excludes:

- Sub-resource icons within a service (e.g., `DynamodbItem`, `EC2Ami`, `CloudwatchAlarm`, `S3GlacierVault`)
- IoT device type icons (e.g., `IotCamera`, `IotLightbulb`, `IotCoffeePot`)
- Duplicate aliases (e.g., `DDB` is the same as `Dynamodb`, `SF` is the same as `StepFunctions`)
- EMR engine sub-variants (e.g., `EMREngineMaprM3`, `EMREngineMaprM5`)

The MCP server returns approximately 350 icons total. The 166 included are the ones you would place as nodes in an architecture diagram.

### Adding Icons to the Reference

If you need an icon not in the reference:

1. Call `list_icons` on the MCP server with the relevant service category
2. Find the Python class name for the service
3. Convert to a candidate `resIcon` value: lowercase, underscores, prefixed with `mxgraph.aws4.`
4. Test by creating a small `.drawio` file with the candidate, export to PNG, and verify it renders
5. Add the confirmed entry to `reference/drawio-icon-reference.md` with its official AWS display name and the Validated column set to Yes

### Icon Discovery Process (for services not in the table)

The MCP server icon names (Python class names) do not directly match draw.io `resIcon` values. Use this process to find the correct draw.io name for any AWS service:

1. Check `reference/drawio-icon-reference.md` first. It covers 166 services using the standard naming convention.
2. If the service is not in the reference, call `list_icons` on the MCP server with the relevant service category to get the Python class name.
3. Generate a candidate `resIcon` value by converting to lowercase with underscores: `mxgraph.aws4.<name>`.
4. Use the candidate in the main diagram.
5. After the final PNG export, ask the user: "Please check the diagram. Are any icons showing as plain colored squares without an icon inside them? If so, tell me which service names are affected."

### Icon Fix Loop

If the user reports an icon rendering as a colored blob:

1. The reported `resIcon` name is wrong. Generate alternative candidates by trying common variations:
   - Add underscores between words: `secretsmanager` → `secrets_manager`
   - Remove underscores: `secrets_manager` → `secretsmanager`
   - Try the full service name: `certificate_manager` instead of `acm`
   - Try the short alias: `acm` instead of `certificate_manager`
   - Check the MCP server `list_icons` output for the exact Python class name and try its lowercase form
2. Update the `.drawio` file with the new candidate `resIcon` value for the affected node
3. Re-export to PNG
4. Ask the user again: "Does [service name] render correctly now?"
5. Repeat until the user confirms all icons are correct
6. Add the confirmed `resIcon` value to `reference/drawio-icon-reference.md` with Validated set to Yes

Discovered `resIcon` values work in both the standard and simple icon styles. The two styles differ only in the surrounding style properties (`sketch=0`, `strokeColor`, size), not the icon name. Do not use `shape=mxgraph.aws4.productIcon;prIcon=` as an alternative. It renders as colored blobs without icons.

## Working Without draw.io Desktop

If draw.io desktop is not installed, the .drawio file is still fully usable:

1. Open [app.diagrams.net](https://app.diagrams.net) in a browser
2. Drag the .drawio file onto the page, or use File > Open from > Device
3. Edit the diagram (drag nodes, adjust edges, change labels)
4. Export to PNG via File > Export as > PNG (select 2x scale for retina quality)

This is a manual process. The draw.io desktop CLI automates step 4 but is not required for the core workflow.

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Icons render as colored blobs | Missing `sketch=0` or wrong `strokeColor` | Use the exact standard style string from this document |
| Specific icon is a blank square | Invalid `resIcon` name | Test candidates in a small `.drawio` file and export to PNG |
| Arrows cross through text labels | No explicit waypoints | Add `<Array as="points">` with coordinates routed through corridors between nodes |
| Edge labels unreadable | Missing label background | Add `labelBackgroundColor=#FFFFFF` to edge styles |
| draw.io CLI crashes after export | Known Electron cleanup issue | Check if the output PNG exists with non-zero size. The crash is harmless. |
| CLI export fails silently with string mxCell IDs | draw.io CLI requires numeric `id` attributes on all `mxCell` elements. String IDs (e.g., `id="incident"`) work in the draw.io editor but cause `Error: Export failed` on CLI export with no further detail. | Use numeric IDs for all `mxCell` elements (e.g., `id="3"`, `id="20"`). Keep `id="0"` and `id="1"` for the root cells. |

## Reference

See `reference/drawio-icon-reference.md` for the full icon lookup table (166 AWS services).

## Tested With

Developed and validated on Claude Opus 4.6, on macOS.
