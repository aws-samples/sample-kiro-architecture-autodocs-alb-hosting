"""Tests for the warnings-as-errors Sphinx build."""

from pathlib import Path

import pytest
from sphinx.cmd.build import build_main

ROOT_DIR = Path(__file__).resolve().parent.parent
DOCS_DIR = ROOT_DIR / "docs"


@pytest.fixture(scope="module")
def built_docs(tmp_path_factory: pytest.TempPathFactory) -> Path:
    """Build the complete Sphinx site in an isolated output directory."""
    build_dir = tmp_path_factory.mktemp("sphinx")
    output_dir = build_dir / "html"
    exit_code = build_main(
        [
            "-W",
            "--keep-going",
            "-E",
            "-a",
            "-q",
            "-b",
            "html",
            "-d",
            str(build_dir / "doctrees"),
            str(DOCS_DIR),
            str(output_dir),
        ]
    )
    assert exit_code == 0, "Sphinx build failed; rerun make html for details"
    return output_dir


def test_expected_pages_are_built(built_docs: Path) -> None:
    """Verify the landing, hosting, and diagram-generation pages are generated."""
    assert (built_docs / "index.html").is_file()
    assert (built_docs / "hosting.html").is_file()
    assert (built_docs / "diagram-generation.html").is_file()


def test_navigation_links_to_documentation_pages(built_docs: Path) -> None:
    """Verify the landing page links to the hosting and diagram pages."""
    index_html = (built_docs / "index.html").read_text(encoding="utf-8")
    assert 'href="hosting.html"' in index_html
    assert 'href="diagram-generation.html"' in index_html


def test_diagram_generation_page_embeds_generated_pngs(built_docs: Path) -> None:
    """Verify the diagram-generation page embeds copied, non-empty PNGs."""
    page_html = (built_docs / "diagram-generation.html").read_text(
        encoding="utf-8"
    )

    for image_name in (
        "drawio-skill-prompt-to-presentation-workflow.png",
        "architecture.png",
        "authenticated-static-site.png",
    ):
        assert f"_images/{image_name}" in page_html
        assert (built_docs / "_images" / image_name).stat().st_size > 1_024
