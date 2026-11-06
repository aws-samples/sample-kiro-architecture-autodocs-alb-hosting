#!/usr/bin/env python3
"""Create a deterministic documentation release archive and checksum."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import logging
from pathlib import Path
import re
import tarfile
from typing import BinaryIO

LOGGER = logging.getLogger(__name__)
VERSION_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


def sanitize_version(version: str) -> str:
    """Validate a release version for use in file names.

    Args:
        version: Candidate release version.

    Returns:
        The validated version.

    Raises:
        ValueError: If the version is empty or contains unsafe characters.
    """
    if not VERSION_PATTERN.fullmatch(version):
        raise ValueError(
            "Version must start with an alphanumeric character and contain "
            "only alphanumerics, dots, underscores, or hyphens."
        )
    return version


def normalized_tarinfo(
    archive: tarfile.TarFile, path: Path, archive_name: str
) -> tarfile.TarInfo:
    """Create normalized tar metadata for a path.

    Args:
        archive: Open tar archive used to inspect the path.
        path: Source file or directory.
        archive_name: Relative name inside the archive.

    Returns:
        Tar metadata with stable ownership, time, and permissions.
    """
    info = archive.gettarinfo(str(path), arcname=archive_name)
    info.uid = 0
    info.gid = 0
    info.uname = ""
    info.gname = ""
    info.mtime = 0
    info.mode = 0o755 if info.isdir() else 0o644
    return info


def add_site_tree(archive: tarfile.TarFile, site_dir: Path) -> None:
    """Add generated site content to an archive in stable order.

    Args:
        archive: Open tar archive.
        site_dir: Generated HTML root.
    """
    paths = sorted(site_dir.rglob("*"), key=lambda path: path.as_posix())
    for path in paths:
        archive_name = path.relative_to(site_dir).as_posix()
        info = normalized_tarinfo(archive, path, archive_name)
        if info.isfile():
            with path.open("rb") as source:
                archive.addfile(info, source)
        elif info.isdir():
            archive.addfile(info)
        else:
            raise ValueError(f"Unsupported generated-site entry: {path}")


def sha256_file(path: Path) -> str:
    """Calculate the SHA-256 digest of a file.

    Args:
        path: File to hash.

    Returns:
        Lowercase hexadecimal digest.
    """
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def create_release(
    site_dir: Path, dist_dir: Path, version: str
) -> tuple[Path, Path]:
    """Create a deterministic site archive and checksum file.

    Args:
        site_dir: Generated HTML root.
        dist_dir: Release output directory.
        version: Validated release version.

    Returns:
        Archive path and checksum path.

    Raises:
        FileNotFoundError: If the generated site is missing.
    """
    index_path = site_dir / "index.html"
    if not index_path.is_file():
        raise FileNotFoundError(f"Generated site is missing: {index_path}")

    dist_dir.mkdir(parents=True, exist_ok=True)
    archive_path = dist_dir / f"documentation-{version}.tar.gz"
    checksum_path = dist_dir / f"documentation-{version}.sha256"

    with archive_path.open("wb") as raw_output:
        with gzip.GzipFile(
            filename="", mode="wb", fileobj=raw_output, mtime=0
        ) as compressed_output:
            with tarfile.open(
                fileobj=compressed_output,
                mode="w",
                format=tarfile.PAX_FORMAT,
            ) as archive:
                add_site_tree(archive, site_dir)

    digest = sha256_file(archive_path)
    checksum_path.write_text(
        f"{digest}  {archive_path.name}\n", encoding="utf-8"
    )
    return archive_path, checksum_path


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments.

    Returns:
        Parsed command-line namespace.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--version",
        default="local",
        help="Release version for output names (default: local)",
    )
    return parser.parse_args()


def main() -> int:
    """Create the release and log its output paths.

    Returns:
        Process exit status.
    """
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    args = parse_args()
    root_dir = Path(__file__).resolve().parent.parent
    version = sanitize_version(args.version)
    archive_path, checksum_path = create_release(
        root_dir / "docs" / "_build" / "html",
        root_dir / "dist",
        version,
    )
    LOGGER.info("Created %s", archive_path)
    LOGGER.info("Created %s", checksum_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
