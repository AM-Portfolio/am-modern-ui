#!/usr/bin/env python3
"""Local CORS-aware reverse proxy for dig Mutual Fund BFF.

Flutter web on localhost:9000 cannot call https://{AM_DOMAIN}/router/am/mf
with Authorization (CORS preflight via api-gateway). This proxy:

  UI  →  http://127.0.0.1:9011/router/am/mf/v1/...
      →  https://{AM_DOMAIN}/router/am/mf/v1/...

Reflects Origin on every response / OPTIONS so the browser accepts JWT GETs.

Usage:
  python scripts/dev_mf_proxy.py
  AM_DOMAIN=am-dev.asrax.in MF_PROXY_PORT=9011 python scripts/dev_mf_proxy.py
"""

from __future__ import annotations

import os
import socket
import sys
from http.client import HTTPSConnection
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

DEFAULT_PORT = int(os.environ.get("MF_PROXY_PORT", "9011"))
AM_DOMAIN = os.environ.get("AM_DOMAIN", "am-dev.asrax.in").strip() or "am-dev.asrax.in"
UPSTREAM_PREFIX = "/router/am/mf"
HOP_BY_HOP = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
    "host",
    "content-length",
}


def port_open(host: str, port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(0.35)
        return s.connect_ex((host, port)) == 0


class MfProxyHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write(f"[mf-proxy] {self.address_string()} - {fmt % args}\n")

    def _cors_headers(self) -> dict[str, str]:
        origin = self.headers.get("Origin") or "*"
        req_headers = self.headers.get("Access-Control-Request-Headers")
        allow_headers = (
            req_headers
            if req_headers
            else "Authorization, Content-Type, Idempotency-Key, Accept, X-Requested-With"
        )
        return {
            "Access-Control-Allow-Origin": origin,
            "Access-Control-Allow-Credentials": "true",
            "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": allow_headers,
            "Access-Control-Max-Age": "86400",
            "Vary": "Origin",
        }

    def do_OPTIONS(self) -> None:  # noqa: N802
        self.send_response(204)
        for k, v in self._cors_headers().items():
            self.send_header(k, v)
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        self._proxy()

    def do_POST(self) -> None:  # noqa: N802
        self._proxy()

    def do_PUT(self) -> None:  # noqa: N802
        self._proxy()

    def do_PATCH(self) -> None:  # noqa: N802
        self._proxy()

    def do_DELETE(self) -> None:  # noqa: N802
        self._proxy()

    def _proxy(self) -> None:
        parsed = urlsplit(self.path)
        path = parsed.path or "/"
        # Accept both /router/am/mf/... and /v1/... (prepend prefix).
        if path == UPSTREAM_PREFIX or path.startswith(UPSTREAM_PREFIX + "/"):
            upstream_path = path
        else:
            upstream_path = UPSTREAM_PREFIX + (path if path.startswith("/") else f"/{path}")
        if parsed.query:
            upstream_path = f"{upstream_path}?{parsed.query}"

        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length > 0 else None

        headers = {}
        for key, value in self.headers.items():
            if key.lower() in HOP_BY_HOP:
                continue
            headers[key] = value
        headers["Host"] = AM_DOMAIN

        try:
            conn = HTTPSConnection(AM_DOMAIN, timeout=60)
            conn.request(self.command, upstream_path, body=body, headers=headers)
            upstream = conn.getresponse()
            payload = upstream.read()
        except Exception as exc:  # noqa: BLE001
            msg = f'{{"error":"mf_proxy_upstream","message":"{exc}"}}'.encode()
            self.send_response(502)
            for k, v in self._cors_headers().items():
                self.send_header(k, v)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(msg)))
            self.end_headers()
            self.wfile.write(msg)
            return

        self.send_response(upstream.status)
        for k, v in self._cors_headers().items():
            self.send_header(k, v)
        for key, value in upstream.getheaders():
            if key.lower() in HOP_BY_HOP:
                continue
            if key.lower().startswith("access-control-"):
                continue
            self.send_header(key, value)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(payload)
        conn.close()


def main() -> int:
    host = "127.0.0.1"
    port = DEFAULT_PORT
    if port_open(host, port):
        print(f"[mf-proxy] Already listening on http://{host}:{port} — reusing")
        return 0

    server = ThreadingHTTPServer((host, port), MfProxyHandler)
    print(
        f"[mf-proxy] http://{host}:{port}{UPSTREAM_PREFIX} → "
        f"https://{AM_DOMAIN}{UPSTREAM_PREFIX}"
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[mf-proxy] stopped")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
