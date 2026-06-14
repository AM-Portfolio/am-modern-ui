#!/usr/bin/env python3
"""Thin wrapper: resolve modern-ui .env + targets JSON, invoke am-ui-test-agent CLI."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

TESTING_DIR = Path(__file__).resolve().parent
MODERN_UI_ROOT = TESTING_DIR.parent
AGENT_ROOT = MODERN_UI_ROOT.parent / "am-ui-test-agent"
RUN_SCRIPT = AGENT_ROOT / "scripts" / "run_auth_test.py"


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: run_auth.py <local|preprod> [--open-report]", file=sys.stderr)
        return 2

    env_name = sys.argv[1]
    extra = sys.argv[2:]
    target_file = TESTING_DIR / f"targets.{env_name}.json"
    if not target_file.is_file():
        print(f"Missing {target_file}", file=sys.stderr)
        return 1
    if not RUN_SCRIPT.is_file():
        print(f"ui-test-agent not found at {AGENT_ROOT}", file=sys.stderr)
        return 1

    cmd = [
        sys.executable,
        str(RUN_SCRIPT),
        "--target-file",
        str(target_file),
        "--env-file",
        str(MODERN_UI_ROOT / f".env.{env_name}"),
    ]
    cmd.extend(extra)
    print(f"[modern-ui/testing] env={env_name}", flush=True)
    return subprocess.call(cmd, cwd=str(AGENT_ROOT))


if __name__ == "__main__":
    raise SystemExit(main())
