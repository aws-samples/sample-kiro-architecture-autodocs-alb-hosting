#!/usr/bin/env python3
"""Serve generated documentation on a loopback interface by default."""

from __future__ import annotations

import argparse
from collections.abc import Sequence
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import ipaddress
import logging
from pathlib import Path
from typing import Any

LOGGER = logging.getLogger(__name__)


class LoggingRequestHandler(SimpleHTTPRequestHandler):
    """Serve static files and route request messages through logging."""

    def log_message(self, message_format: str, *args: Any) -> None:
        """Write an HTTP request message through the configured logger.

        Args:
            message_format: Standard library HTTP log format.
            *args: Values for the log format.
        """
        LOGGER.info("%s - %s", self.address_string(), message_format % args)


def is_loopback_host(host: str) -> bool:
    """Return whether a host is explicitly loopback-only.

    Args:
        host: Hostname or IP address.

    Returns:
        True for localhost or a loopback IP address.
    """
    if host.lower() == "localhost":
        return True
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return False


def create_server(
    host: str, port: int, directory: Path
) -> ThreadingHTTPServer:
    """Create a threaded static documentation server.

    Args:
        host: Listener hostname or IP address.
        port: Listener TCP port.
        directory: Generated documentation root.

    Returns:
        Configured HTTP server.

    Raises:
        FileNotFoundError: If the generated site is missing.
    """
    index_path = directory / "index.html"
    if not index_path.is_file():
        raise FileNotFoundError(
            f"Generated site is missing: {index_path}. Run make html first."
        )
    handler = partial(LoggingRequestHandler, directory=str(directory))
    server = ThreadingHTTPServer((host, port), handler)
    server.daemon_threads = True
    return server


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments.

    Args:
        argv: Arguments to parse. Defaults to the process arguments.

    Returns:
        Parsed command-line namespace.
    """
    root_dir = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument(
        "--directory",
        type=Path,
        default=root_dir / "docs" / "_build" / "html",
    )
    parser.add_argument(
        "--allow-network",
        action="store_true",
        help="Acknowledge exposure when binding to a non-loopback host",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    """Run the local documentation server until interrupted.

    Args:
        argv: Arguments to parse. Defaults to the process arguments.

    Returns:
        Process exit status.

    Raises:
        ValueError: If a non-loopback host is requested without
            ``--allow-network``.
    """
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    args = parse_args(argv)
    if not is_loopback_host(args.host) and not args.allow_network:
        raise ValueError(
            "A non-loopback host requires --allow-network to acknowledge exposure."
        )

    directory = args.directory.resolve()
    server = create_server(args.host, args.port, directory)
    LOGGER.info("Serving %s at http://%s:%s", directory, args.host, args.port)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        LOGGER.info("Stopping preview server")
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
