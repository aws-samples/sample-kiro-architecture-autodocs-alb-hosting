#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DEFAULT_MACOS_DRAWIO="/Applications/draw.io.app/Contents/MacOS/draw.io"

if ! command -v xmllint >/dev/null 2>&1; then
  printf 'xmllint is required but was not found.\n' >&2
  exit 1
fi

if [[ -n "${DRAWIO_BIN:-}" ]]; then
  drawio_bin="$DRAWIO_BIN"
elif [[ -x "$DEFAULT_MACOS_DRAWIO" ]]; then
  drawio_bin="$DEFAULT_MACOS_DRAWIO"
elif command -v drawio >/dev/null 2>&1; then
  drawio_bin="$(command -v drawio)"
else
  printf 'draw.io Desktop is required. Set DRAWIO_BIN to its executable.\n' >&2
  exit 1
fi

if [[ ! -x "$drawio_bin" ]]; then
  printf 'draw.io executable is not executable: %s\n' "$drawio_bin" >&2
  exit 1
fi

if [[ "$#" -eq 0 ]]; then
  search_roots=("$ROOT_DIR/docs")
else
  search_roots=()
  for requested_root in "$@"; do
    if [[ "$requested_root" = /* ]]; then
      search_root="$requested_root"
    else
      search_root="$ROOT_DIR/$requested_root"
    fi
    if [[ ! -d "$search_root" ]]; then
      printf 'Diagram search root does not exist: %s\n' "$search_root" >&2
      exit 1
    fi
    search_roots+=("$search_root")
  done
fi

diagram_count=0
for search_root in "${search_roots[@]}"; do
  while IFS= read -r -d '' source; do
    diagram_count=$((diagram_count + 1))
    output="${source%.drawio}.png"

    xmllint --noout "$source"
    unlabeled_edges="$(xmllint --xpath 'count(//mxCell[@edge="1" and not(@id = //mxCell[contains(@style,"edgeLabel") and normalize-space(@value)]/@parent)])' "$source")"
    if [[ "$unlabeled_edges" != "0" ]]; then
      printf 'Diagram contains %s unlabeled edge(s): %s\n' "$unlabeled_edges" "$source" >&2
      exit 1
    fi

    if [[ -s "$output" && ! "$source" -nt "$output" ]]; then
      printf 'Current %s\n' "$output"
      continue
    fi

    "$drawio_bin" \
      --export \
      --format png \
      --scale 2 \
      --border 20 \
      --output "$output" \
      "$source"

    if [[ ! -s "$output" ]]; then
      printf 'draw.io did not create a non-empty PNG: %s\n' "$output" >&2
      exit 1
    fi
    printf 'Generated %s\n' "$output"
  done < <(find "$search_root" -type f -name '*.drawio' -print0)
done

if [[ "$diagram_count" -eq 0 ]]; then
  printf 'No .drawio sources were found in the requested roots.\n' >&2
  exit 1
fi
