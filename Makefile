UV ?= uv
# Release name defaults to the short Git commit, with -dirty for uncommitted
# changes, or "local" outside a Git checkout.
VERSION ?= $(shell git rev-parse --short=12 HEAD 2>/dev/null || echo local)$(shell git status --porcelain 2>/dev/null | grep -q . && echo -dirty)

.PHONY: install diagrams html release preview publish check tf-check clean

install:
	$(UV) sync --locked

diagrams:
	bash scripts/build_diagrams.sh

html:
	$(UV) run --locked bash scripts/build_docs.sh

release: html
	$(UV) run --locked python scripts/package_docs.py --version "$(VERSION)"

preview: html
	$(UV) run --locked python scripts/preview_docs.py

# Uploads to the live site bucket. Set SKIP_DIAGRAMS=1 without draw.io Desktop.
publish: html
	bash scripts/publish_docs.sh

check: diagrams
	$(UV) lock --check
	bash -n scripts/build_diagrams.sh scripts/build_docs.sh scripts/publish_docs.sh
	$(UV) run --locked pytest

TF_MODULES := infra/modules/networking infra/modules/authenticated-static-site

tf-check:
	terraform -chdir=infra fmt -check -recursive
	set -e; for module in $(TF_MODULES); do \
		terraform -chdir=$$module init -backend=false; \
		terraform -chdir=$$module validate; \
		terraform -chdir=$$module test; \
	done
	terraform -chdir=infra init -backend=false -lockfile=readonly
	terraform -chdir=infra validate
	terraform -chdir=infra test

clean:
	rm -rf .pytest_cache docs/_build dist
