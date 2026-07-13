#!/bin/sh
set -e

case "${ENVIRONMENT:-preprod}" in
  prod) PROFILE=revalidate ;;
  *)    PROFILE=nocache ;;
esac

mkdir -p /tmp/nginx
cp "/etc/nginx/profiles/${PROFILE}.conf" /tmp/nginx/active.conf

echo "[nginx] ENVIRONMENT=${ENVIRONMENT:-preprod} profile=${PROFILE}"

cat <<EOF > /usr/share/nginx/html/config.json
{
  "env": "${ENVIRONMENT:-preprod}"
}
EOF
echo "[nginx] Generated config.json with env: ${ENVIRONMENT:-preprod}"

exec nginx -g 'daemon off;' -c /etc/nginx/nginx-docker.conf
