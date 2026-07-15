#!/bin/sh
# Release web build for Docker — host-free so one image works across envs.
# Domain / Google client id come from Helm-mounted /config.json at runtime.
# Local runs still use manage.py + .env.{env} dart-defines.

set -e

cd /app/am_app

# Non-host release flags only — do not set AM_DOMAIN / AM_*_BASE_URL / AM_ENV.
DEFINES="--dart-define=AM_BOOT_TRACE=false --dart-define=AM_BOOT_RUM=true"

echo "[docker_build_web] flutter build web --release --no-wasm-dry-run --no-web-resources-cdn --no-tree-shake-icons $DEFINES"

# shellcheck disable=SC2086
# --no-tree-shake-icons: release web subsetting drops glyphs used from deferred
# modules (e.g. Premium / Subscription icons) and leaves empty icon circles.
exec flutter build web --release --no-wasm-dry-run --no-web-resources-cdn --no-tree-shake-icons $DEFINES
