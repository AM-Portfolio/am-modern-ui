#!/bin/sh
set -e

case "${ENVIRONMENT:-preprod}" in
  prod) PROFILE=revalidate ;;
  *)    PROFILE=nocache ;;
esac

mkdir -p /tmp/nginx
cp "/etc/nginx/profiles/${PROFILE}.conf" /tmp/nginx/active.conf

# Swap the UI config at runtime based on the deployment environment
if [ -f "/usr/share/nginx/html/config.${ENVIRONMENT:-preprod}.json" ]; then
  cp "/usr/share/nginx/html/config.${ENVIRONMENT:-preprod}.json" /usr/share/nginx/html/config.json
  echo "[nginx] Swapped config.json with config.${ENVIRONMENT:-preprod}.json"
else
  echo "[nginx] WARN: config.${ENVIRONMENT:-preprod}.json not found!"
fi

echo "[nginx] ENVIRONMENT=${ENVIRONMENT:-preprod} profile=${PROFILE}"

exec nginx -g 'daemon off;' -c /etc/nginx/nginx-docker.conf
