#!/bin/sh
# Stamp AM_BUILD_ID + flutter_bootstrap.js?v= before flutter build web.
# CI passes BUILD_ID (github.run_id, matches image tag); local builds default to "local".

set -e

BUILD_ID="${BUILD_ID:-local}"
# Numeric run_id from CI — use as-is (matches image tag :${{ github.run_id }})

INDEX="${INDEX_HTML:-/app/am_app/web/index.html}"

if [ ! -f "$INDEX" ]; then
  echo "[inject_build_id] ERROR: missing $INDEX" >&2
  exit 1
fi

sed -i "s/var AM_BUILD_ID = '[^']*'/var AM_BUILD_ID = '${BUILD_ID}'/" "$INDEX"
sed -i "s/flutter_bootstrap.js?v=[^\"']*/flutter_bootstrap.js?v=${BUILD_ID}/" "$INDEX"

echo "[inject_build_id] AM_BUILD_ID=${BUILD_ID}"
