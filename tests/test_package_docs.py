"""Tests for deterministic documentation release packaging."""

import hashlib
from pathlib import Path
import tarfile

import pytest

from scripts.package_docs import create_release, sanitize_version


def create_example_site(root: Path) -> Path:
    """Create a minimal generated-site tree for packaging tests."""
    site_dir = root / "site"
    static_dir = site_dir / "_static"
    static_dir.mkdir(parents=True)
    (site_dir / "index.html").write_text("<h1>Example</h1>\n", encoding="utf-8")
    (static_dir / "site.css").write_text("body {}\n", encoding="utf-8")
    return site_dir


def test_release_archive_is_reproducible(tmp_path: Path) -> None:
    """Verify unchanged inputs produce byte-identical release archives."""
    site_dir = create_example_site(tmp_path)
    dist_dir = tmp_path / "dist"

    archive_path, checksum_path = create_release(site_dir, dist_dir, "test")
    first_archive = archive_path.read_bytes()
    first_checksum = checksum_path.read_text(encoding="utf-8")

    create_release(site_dir, dist_dir, "test")
    second_archive = archive_path.read_bytes()
    second_checksum = checksum_path.read_text(encoding="utf-8")

    assert first_archive == second_archive
    assert first_checksum == second_checksum
    expected_digest = hashlib.sha256(second_archive).hexdigest()
    assert second_checksum == f"{expected_digest}  {archive_path.name}\n"


def test_release_archive_has_normalized_root_and_metadata(tmp_path: Path) -> None:
    """Verify archive paths and metadata are portable and normalized."""
    site_dir = create_example_site(tmp_path)
    archive_path, _ = create_release(site_dir, tmp_path / "dist", "test")

    with tarfile.open(archive_path) as archive:
        members = archive.getmembers()
        names = {member.name for member in members}

    assert "index.html" in names
    assert "_static/site.css" in names
    assert all(not name.startswith(("/", "docs/")) for name in names)
    assert all(member.uid == 0 and member.gid == 0 for member in members)
    assert all(member.mtime == 0 for member in members)


@pytest.mark.parametrize(
    "version",
    ["", "../escape", "contains space", "/absolute", "!invalid"],
)
def test_unsafe_release_versions_are_rejected(version: str) -> None:
    """Verify release names cannot escape or corrupt the output directory."""
    with pytest.raises(ValueError):
        sanitize_version(version)


def test_safe_release_version_is_retained() -> None:
    """Verify a valid release version is returned unchanged."""
    assert sanitize_version("v1.2.3_rc-1") == "v1.2.3_rc-1"
