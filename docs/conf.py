"""Sphinx configuration for the documentation kit."""

from pathlib import Path
import sys

ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT_DIR / "src"))

project = "Sphinx and draw.io Documentation Kit"
author = "AWS Professional Services"
copyright = "2026, AWS Professional Services"

extensions = [
    "myst_parser",
    "sphinx.ext.autodoc",
    "sphinx.ext.napoleon",
    "sphinxcontrib.mermaid",
]
source_suffix = {
    ".rst": "restructuredtext",
    ".md": "markdown",
}
root_doc = "index"
exclude_patterns = ["_build"]

html_theme = "pydata_sphinx_theme"
html_title = project
html_show_sourcelink = True
templates_path = ["_templates"]
html_static_path = ["_static"]
html_css_files = ["image-fullscreen.css"]
html_js_files = ["image-fullscreen.js"]
# Site navigation lives in the left sidebar on every page instead of the header.
html_sidebars = {"**": ["sidebar-site-nav"]}
html_theme_options = {
    "announcement": (
        "Sample for demonstration and education only. Not for production use "
        "without your own security, operational, and compliance review."
    ),
    "navbar_align": "left",
    "navbar_center": [],
    "show_nav_level": 1,
    "show_toc_level": 2,
}

mermaid_output_format = "raw"
mermaid_version = "11.17.2"
mermaid_use_local = "vendor/mermaid.bundle.mjs"
mermaid_light_theme = "neutral"
mermaid_dark_theme = "neutral"

myst_enable_extensions = ["colon_fence"]
myst_heading_anchors = 3

autodoc_typehints = "description"
napoleon_google_docstring = True
napoleon_numpy_docstring = False
