#!/bin/sh
# Release web build for Docker — mirrors manage.py build flags + .env dart-defines.

set -e

cd /app/am_app

ENV_FILE="${ENV_FILE:-/app/.env.preprod}"
DEFINES="--dart-define=AM_BOOT_TRACE=false"

if [ -f "$ENV_FILE" ]; then
  echo "[docker_build_web] Loading $ENV_FILE"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|\#*) continue ;;
    esac
    key="${line%%=*}"
    val="${line#*=}"
    case "$key" in
      AM_*)
        if [ "$key" != "AM_BOOT_TRACE" ]; then
          DEFINES="$DEFINES --dart-define=${key}=${val}"
        fi
        ;;
    esac
  done < "$ENV_FILE"
else
  echo "[docker_build_web] WARN: $ENV_FILE not found, using minimal defines"
  DEFINES="$DEFINES --dart-define=AM_ENV=preprod"
fi

echo "[docker_build_web] flutter build web --release --no-wasm-dry-run --no-web-resources-cdn $DEFINES"

# shellcheck disable=SC2086
exec flutter build web --release --no-wasm-dry-run --no-web-resources-cdn $DEFINES
