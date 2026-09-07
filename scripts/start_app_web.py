#!/usr/bin/env python3
"""Build (if needed) and serve am_app web — stable for multiple browser tabs/sessions."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

workspace_root = Path(__file__).resolve().parent.parent
build_web = workspace_root / "am_app" / "build" / "web"
serve_script = workspace_root / "scripts" / "serve_web.py"
manage_script = workspace_root / "scripts" / "manage.py"


def main() -> None:
    parser = argparse.ArgumentParser(description="Serve am_app web with SPA fallback")
    parser.add_argument("--env", default="prod", choices=["local", "dev", "preprod", "prod"])
    parser.add_argument("--port", type=int, default=9000)
    parser.add_argument(
        "--build",
        action="store_true",
        help="Force flutter build web before serving",
    )
    args = parser.parse_args()

    if args.build or not (build_web / "index.html").is_file():
        print(f"[start_app_web] Building am_app for env={args.env} ...")
        env = os.environ.copy()
        env["PYTHONIOENCODING"] = "utf-8"
        result = subprocess.run(
            [sys.executable, str(manage_script), "build", "app", args.env],
            cwd=workspace_root,
            env=env,
        )
        if result.returncode != 0 and not (build_web / "index.html").is_file():
            raise SystemExit(f"flutter build web failed (exit {result.returncode})")

    if not (build_web / "index.html").is_file():
        raise SystemExit(f"Build output missing: {build_web / 'index.html'}")

    print(f"[start_app_web] Serving release build at http://localhost:{args.port}/")
    subprocess.run(
        [sys.executable, str(serve_script), "--port", str(args.port), "--directory", str(build_web)],
        cwd=workspace_root,
        check=True,
    )


if __name__ == "__main__":
    main()
