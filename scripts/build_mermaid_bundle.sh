#!/usr/bin/env bash
# Rebuild the vendored single-file Mermaid ES module used by Sphinx.
#
# sphinxcontrib-mermaid loads it with `import mermaid from ...`, so the bundle
# must be one self-contained ES module with a default export. Versions are
# pinned; update MERMAID_VERSION and docs/conf.py mermaid_version together, then
# check the release against https://osv.dev before committing.
set -euo pipefail

MERMAID_VERSION="11.17.2"
ESBUILD_VERSION="0.28.2"

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/docs/_static/vendor"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

cd "$work_dir"
npm init -y >/dev/null
# --ignore-scripts prevents dependency install scripts from running.
npm install --ignore-scripts --no-audit --no-fund --save-exact \
  "mermaid@$MERMAID_VERSION" "esbuild@$ESBUILD_VERSION" >/dev/null
# esbuild needs its platform binary, which is installed without scripts.
printf 'import mermaid from "mermaid";\nexport default mermaid;\n' > entry.mjs
npx --no-install esbuild entry.mjs --bundle --minify --format=esm \
  --legal-comments=none --outfile=mermaid.bundle.mjs

cp mermaid.bundle.mjs "$VENDOR_DIR/mermaid.bundle.mjs"
cp node_modules/mermaid/LICENSE "$VENDOR_DIR/mermaid-LICENSE.txt"
printf 'Built Mermaid %s with esbuild %s into %s\n' \
  "$MERMAID_VERSION" "$ESBUILD_VERSION" "$VENDOR_DIR"
