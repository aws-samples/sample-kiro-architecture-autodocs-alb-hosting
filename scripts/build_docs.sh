#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DOCS_DIR="$ROOT_DIR/docs"
BUILD_DIR="$DOCS_DIR/_build"
OUTPUT_DIR="$BUILD_DIR/html"
DOCTREE_DIR="$BUILD_DIR/doctrees"
sphinx_build_bin="${SPHINXBUILD:-sphinx-build}"

if ! command -v "$sphinx_build_bin" >/dev/null 2>&1; then
  printf 'sphinx-build is required. Run uv sync --locked first.\n' >&2
  exit 1
fi

if [[ "${SKIP_DIAGRAMS:-0}" == "1" ]]; then
  # For hosts without draw.io Desktop. The committed PNGs are used as-is, so
  # a .drawio edit is not reflected until someone runs make diagrams.
  printf 'SKIP_DIAGRAMS=1: using committed diagram PNGs without re-export.\n' >&2
else
  bash "$SCRIPT_DIR/build_diagrams.sh"
fi

rm -rf "$OUTPUT_DIR" "$DOCTREE_DIR"
"$sphinx_build_bin" -W --keep-going -b html -d "$DOCTREE_DIR" "$@" "$DOCS_DIR" "$OUTPUT_DIR"

if [[ ! -s "$OUTPUT_DIR/index.html" ]]; then
  printf 'Sphinx did not create %s\n' "$OUTPUT_DIR/index.html" >&2
  exit 1
fi
printf 'Built documentation at %s\n' "$OUTPUT_DIR"
