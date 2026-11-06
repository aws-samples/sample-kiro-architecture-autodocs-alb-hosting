"""Tests for editable draw.io sources and rendered PNGs."""

from pathlib import Path
import struct
from typing import Any

from defusedxml import ElementTree

import pytest

ROOT_DIR = Path(__file__).resolve().parent.parent
DRAWIO_ROOTS = (ROOT_DIR / "docs",)
# Discover sources so forks can replace the site diagrams.
DRAWIO_SOURCES = sorted(
    path
    for drawio_root in DRAWIO_ROOTS
    for path in drawio_root.rglob("*.drawio")
    if "_build" not in path.parts
)


def _style_coordinates(style: str, prefix: str) -> tuple[float, float] | None:
    values = dict(
        part.split("=", maxsplit=1)
        for part in style.split(";")
        if "=" in part
    )
    x_value = values.get(f"{prefix}X")
    y_value = values.get(f"{prefix}Y")
    if x_value is None or y_value is None:
        return None
    return float(x_value), float(y_value)


def _absolute_origin(
    cell_id: str,
    cells_by_id: dict[str, Any],
) -> tuple[float, float]:
    x_position = 0.0
    y_position = 0.0
    current_id: str | None = cell_id
    visited: set[str] = set()

    while current_id is not None and current_id in cells_by_id:
        if current_id in visited:
            raise AssertionError(f"Cyclic draw.io parent chain at cell {cell_id}")
        visited.add(current_id)

        cell = cells_by_id[current_id]
        geometry = cell.find("mxGeometry")
        if geometry is not None:
            x_position += float(geometry.attrib.get("x", 0))
            y_position += float(geometry.attrib.get("y", 0))
        current_id = cell.attrib.get("parent")

    return x_position, y_position


def _port_position(
    cell: Any,
    coordinates: tuple[float, float],
    edge_parent_id: str,
    cells_by_id: dict[str, Any],
) -> tuple[float, float]:
    geometry = cell.find("mxGeometry")
    assert geometry is not None

    cell_x, cell_y = _absolute_origin(cell.attrib["id"], cells_by_id)
    parent_x, parent_y = _absolute_origin(edge_parent_id, cells_by_id)
    width = float(geometry.attrib["width"])
    height = float(geometry.attrib["height"])
    x_ratio, y_ratio = coordinates
    return (
        cell_x - parent_x + width * x_ratio,
        cell_y - parent_y + height * y_ratio,
    )


def _meets_perpendicularly(
    port: tuple[float, float],
    waypoint: tuple[float, float],
    coordinates: tuple[float, float],
) -> bool:
    x_ratio, y_ratio = coordinates
    tolerance = 0.5

    if x_ratio in {0.0, 1.0} and 0.0 < y_ratio < 1.0:
        return abs(port[1] - waypoint[1]) <= tolerance
    if y_ratio in {0.0, 1.0} and 0.0 < x_ratio < 1.0:
        return abs(port[0] - waypoint[0]) <= tolerance
    return True


def test_docs_contain_at_least_one_diagram() -> None:
    """Verify the diagram checks below are not silently skipped."""
    assert DRAWIO_SOURCES


@pytest.mark.parametrize("source", DRAWIO_SOURCES, ids=lambda path: path.stem)
def test_drawio_sources_are_valid_and_fully_labeled(source: Path) -> None:
    """Verify draw.io XML structure, numeric IDs, and one label per edge."""
    root = ElementTree.parse(source).getroot()
    cells = root.findall(".//mxCell")

    cell_ids = [cell.attrib["id"] for cell in cells]
    assert len(cell_ids) == len(set(cell_ids))
    assert all(cell_id.isdigit() for cell_id in cell_ids)

    edges = [cell for cell in cells if cell.attrib.get("edge") == "1"]
    labels = [
        cell
        for cell in cells
        if "edgeLabel" in cell.attrib.get("style", "")
    ]
    assert edges
    assert all(label.attrib.get("value", "").strip() for label in labels)

    labels_by_edge = {
        edge.attrib["id"]: [
            label
            for label in labels
            if label.attrib.get("parent") == edge.attrib["id"]
        ]
        for edge in edges
    }
    assert all(len(edge_labels) == 1 for edge_labels in labels_by_edge.values())


@pytest.mark.parametrize("source", DRAWIO_SOURCES, ids=lambda path: path.stem)
def test_waypointed_edges_meet_icons_perpendicularly(source: Path) -> None:
    """Verify routed edges do not run along icon boundaries before turning."""
    root = ElementTree.parse(source).getroot()
    cells = root.findall(".//mxCell")
    cells_by_id = {cell.attrib["id"]: cell for cell in cells}
    labels_by_edge = {
        cell.attrib["parent"]: cell.attrib.get("value", "")
        for cell in cells
        if "edgeLabel" in cell.attrib.get("style", "")
    }
    violations: list[str] = []

    for edge in (cell for cell in cells if cell.attrib.get("edge") == "1"):
        points = edge.findall("./mxGeometry/Array[@as='points']/mxPoint")
        if not points:
            continue

        edge_parent_id = edge.attrib.get("parent", "1")
        endpoint_checks = (
            ("exit", edge.attrib.get("source"), points[0]),
            ("entry", edge.attrib.get("target"), points[-1]),
        )
        for prefix, endpoint_id, waypoint_element in endpoint_checks:
            if endpoint_id is None or endpoint_id not in cells_by_id:
                continue
            coordinates = _style_coordinates(
                edge.attrib.get("style", ""),
                prefix,
            )
            if coordinates is None:
                continue

            port = _port_position(
                cells_by_id[endpoint_id],
                coordinates,
                edge_parent_id,
                cells_by_id,
            )
            waypoint = (
                float(waypoint_element.attrib["x"]),
                float(waypoint_element.attrib["y"]),
            )
            if not _meets_perpendicularly(port, waypoint, coordinates):
                label = labels_by_edge.get(edge.attrib["id"], edge.attrib["id"])
                violations.append(f"{label}: {prefix} segment")

    assert not violations, "Non-perpendicular routed edges: " + ", ".join(
        violations
    )


def _style_property(style: str, name: str) -> str | None:
    values = dict(
        part.split("=", maxsplit=1)
        for part in style.split(";")
        if "=" in part
    )
    return values.get(name)


@pytest.mark.parametrize("source", DRAWIO_SOURCES, ids=lambda path: path.stem)
def test_parallel_edge_tracks_do_not_cross_node_labels(source: Path) -> None:
    """Verify distinct top or bottom edge tracks do not cross one label."""
    root = ElementTree.parse(source).getroot()
    cells = root.findall(".//mxCell")
    cells_by_id = {cell.attrib["id"]: cell for cell in cells}
    labels_by_edge = {
        cell.attrib["parent"]: cell.attrib.get("value", "")
        for cell in cells
        if "edgeLabel" in cell.attrib.get("style", "")
    }
    tracks_by_label_side: dict[
        tuple[str, str],
        dict[float, list[str]],
    ] = {}

    for edge in (cell for cell in cells if cell.attrib.get("edge") == "1"):
        endpoint_checks = (
            ("exit", edge.attrib.get("source")),
            ("entry", edge.attrib.get("target")),
        )
        for prefix, endpoint_id in endpoint_checks:
            if endpoint_id is None or endpoint_id not in cells_by_id:
                continue
            coordinates = _style_coordinates(
                edge.attrib.get("style", ""),
                prefix,
            )
            if coordinates is None:
                continue

            x_ratio, y_ratio = coordinates
            if y_ratio not in {0.0, 1.0} or not 0.0 < x_ratio < 1.0:
                continue

            node = cells_by_id[endpoint_id]
            label_side = _style_property(
                node.attrib.get("style", ""),
                "verticalLabelPosition",
            )
            port_side = "top" if y_ratio == 0.0 else "bottom"
            if label_side != port_side:
                continue

            edge_label = labels_by_edge.get(
                edge.attrib["id"],
                edge.attrib["id"],
            )
            tracks = tracks_by_label_side.setdefault(
                (endpoint_id, port_side),
                {},
            )
            tracks.setdefault(round(x_ratio, 3), []).append(edge_label)

    violations: list[str] = []
    for (node_id, label_side), tracks in tracks_by_label_side.items():
        if len(tracks) < 2:
            continue
        node_label = cells_by_id[node_id].attrib.get("value", node_id).replace(
            "\n", " "
        )
        edge_labels = sorted(
            {
                edge_label
                for labels_at_position in tracks.values()
                for edge_label in labels_at_position
            }
        )
        violations.append(
            f"{node_label}: {len(tracks)} {label_side} tracks from "
            + ", ".join(edge_labels)
        )

    assert not violations, "Parallel edge tracks cross node labels: " + ", ".join(
        violations
    )


@pytest.mark.parametrize("source", DRAWIO_SOURCES, ids=lambda path: path.stem)
def test_rendered_png_exists_and_has_dimensions(source: Path) -> None:
    """Verify every editable source has a non-empty, valid PNG rendering."""
    png_path = source.with_suffix(".png")
    data = png_path.read_bytes()

    assert data.startswith(b"\x89PNG\r\n\x1a\n")
    assert len(data) > 1_024
    width, height = struct.unpack(">II", data[16:24])
    assert width > 100
    assert height > 100
