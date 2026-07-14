#!/bin/sh
# Release web build for Docker — host-free so one image works across envs.
# Domain / Google client id come from Helm-mounted /config.json at runtime.
# Local runs still use manage.py + .env.{env} dart-defines.

set -e

cd /app/am_app

# Non-host release flags only — do not set AM_DOMAIN / AM_*_BASE_URL / AM_ENV.
DEFINES="--dart-define=AM_BOOT_TRACE=false --dart-define=AM_BOOT_RUM=true"

echo "[docker_build_web] flutter build web --release --no-wasm-dry-run --no-web-resources-cdn $DEFINES"

# shellcheck disable=SC2086
exec flutter build web --release --no-wasm-dry-run --no-web-resources-cdn $DEFINES
