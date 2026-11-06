"""Tests for the local documentation preview server."""

from http.client import HTTPConnection, HTTPResponse
from pathlib import Path
from threading import Thread

import pytest

from scripts.preview_docs import create_server, is_loopback_host, main

ROOT_DIR = Path(__file__).resolve().parent.parent


def test_loopback_host_detection() -> None:
    """Verify only explicit loopback hosts are accepted as local."""
    assert is_loopback_host("127.0.0.1")
    assert is_loopback_host("::1")
    assert is_loopback_host("localhost")
    # The all-interface address is test data that must be rejected.
    assert not is_loopback_host("0.0.0.0")  # nosec B104
    assert not is_loopback_host("example.com")


def test_preview_server_serves_site_and_404(tmp_path: Path) -> None:
    """Verify the preview server returns generated content and missing pages."""
    (tmp_path / "index.html").write_text("preview\n", encoding="utf-8")
    server = create_server("127.0.0.1", 0, tmp_path)
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    port = server.server_address[1]

    connection = HTTPConnection("127.0.0.1", port, timeout=5)
    missing_connection = HTTPConnection("127.0.0.1", port, timeout=5)

    try:
        connection.request("GET", "/")
        response: HTTPResponse = connection.getresponse()
        assert response.status == 200
        assert response.read() == b"preview\n"

        missing_connection.request("GET", "/missing.html")
        missing_response: HTTPResponse = missing_connection.getresponse()
        assert missing_response.status == 404
    finally:
        connection.close()
        missing_connection.close()
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)

    assert not thread.is_alive()


def test_preview_requires_generated_index(tmp_path: Path) -> None:
    """Verify preview startup fails when the generated site is absent."""
    with pytest.raises(FileNotFoundError, match="Run make html first"):
        create_server("127.0.0.1", 0, tmp_path)


def test_cli_rejects_unacknowledged_network_binding() -> None:
    """Verify a network-wide listener requires explicit acknowledgement."""
    # The all-interface address is test input that the CLI must reject before
    # it creates a server.
    with pytest.raises(ValueError, match="--allow-network"):
        main(["--host", "0.0.0.0"])  # nosec B104
