#!/bin/sh
set -e

case "${ENVIRONMENT:-preprod}" in
  prod) PROFILE=revalidate ;;
  *)    PROFILE=nocache ;;
esac

mkdir -p /tmp/nginx
cp "/etc/nginx/profiles/${PROFILE}.conf" /tmp/nginx/active.conf

echo "[nginx] ENVIRONMENT=${ENVIRONMENT:-preprod} profile=${PROFILE}"

# Copy runtime config for the environment
CONFIG_FILE="/usr/share/nginx/html/config.${ENVIRONMENT:-preprod}.json"
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" /usr/share/nginx/html/config.json 2>/dev/null || echo "[nginx] Notice: Could not copy config.json (expected if mounted as Read-Only ConfigMap)"
  echo "[nginx] Configured runtime config from $CONFIG_FILE"
else
  echo "[nginx] WARNING: $CONFIG_FILE not found! App will fallback to compiled defaults."
fi

exec nginx -g 'daemon off;' -c /etc/nginx/nginx-docker.conf
