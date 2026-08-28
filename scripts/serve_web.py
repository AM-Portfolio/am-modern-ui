#!/usr/bin/env python3
"""Serve Flutter web build with SPA fallback (routes like /login -> index.html)."""

from __future__ import annotations

import argparse
import functools
import http.server
import os
import socketserver
from pathlib import Path


class SPARequestHandler(http.server.SimpleHTTPRequestHandler):
    def send_head(self):
        requested = self.path.split("?", 1)[0]
        file_path = Path(self.translate_path(requested))
        if not file_path.is_file():
            self.path = "/index.html"
        return super().send_head()

    def copyfile(self, source, outputfile):
        """Ignore client disconnects while streaming large Flutter assets."""
        try:
            super().copyfile(source, outputfile)
        except (ConnectionAbortedError, ConnectionResetError, BrokenPipeError):
            pass

    def log_error(self, format, *args):
        # WinError 10053/10054: browser cancelled an in-flight download (harmless).
        if args and isinstance(args[-1], OSError):
            err = args[-1]
            if getattr(err, "winerror", None) in (10053, 10054):
                return
        if args and args[-1] in ("Broken pipe", "Connection reset by peer"):
            return
        super().log_error(format, *args)


def main() -> None:
    parser = argparse.ArgumentParser(description="Serve Flutter web build with SPA routing")
    parser.add_argument("--port", type=int, default=9000)
    parser.add_argument(
        "--directory",
        default="am_app/build/web",
        help="Path to flutter build/web output",
    )
    args = parser.parse_args()

    web_root = Path(args.directory).resolve()
    if not web_root.is_dir():
        raise SystemExit(f"Directory not found: {web_root}")

    handler = functools.partial(SPARequestHandler, directory=str(web_root))
    with socketserver.TCPServer(("", args.port), handler) as httpd:
        print(f"Serving {web_root} at http://localhost:{args.port}/ (SPA fallback enabled)")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nStopped.")


if __name__ == "__main__":
    main()
