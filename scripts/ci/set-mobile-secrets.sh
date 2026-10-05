#!/usr/bin/env bash
# Automated GitHub Secrets configuration script for am-modern-ui & am-pipelines
set -euo pipefail

REPO="${1:-AM-Portfolio/am-modern-ui}"
SECRETS_DIR="${HOME}/.asrax/secrets"
CREDS_DIR="${HOME}/.asrax/credentials.d"

echo "=== Setting GitHub Actions Secrets for ${REPO} ==="

# 1. OAuth & Environment Secrets
echo "Setting OAuth & Environment secrets..."
gh secret set GOOGLE_WEB_CLIENT_ID --body "307768822337-ad7tee4d82cc0b4flgrfs157e5e6rc0g.apps.googleusercontent.com" --repo "$REPO"
gh secret set GOOGLE_IOS_CLIENT_ID --body "307768822337-082220ndhdik3b6utgac7t8hun23dqns.apps.googleusercontent.com" --repo "$REPO"
gh secret set GOOGLE_ANDROID_CLIENT_ID --body "307768822337-ad7tee4d82cc0b4flgrfs157e5e6rc0g.apps.googleusercontent.com" --repo "$REPO"
gh secret set GROWTHBOOK_CLIENT_KEY --body "sdk-Cwr4MxBl0iqnKZJ" --repo "$REPO"

# 2. Apple Developer Secrets
echo "Setting App Store Connect API secrets..."
gh secret set APP_STORE_CONNECT_API_KEY_ID --body "AA5ZK75HAS" --repo "$REPO"
gh secret set APP_STORE_CONNECT_API_ISSUER_ID --body "0aab8fa5-6360-4693-aad6-95a3938c74e1" --repo "$REPO"

if [[ -f "${SECRETS_DIR}/apple/AuthKey_AA5ZK75HAS.p8" ]]; then
  P8_BASE64=$(base64 -i "${SECRETS_DIR}/apple/AuthKey_AA5ZK75HAS.p8" | tr -d '\n')
  gh secret set APP_STORE_CONNECT_API_KEY_BASE64 --body "$P8_BASE64" --repo "$REPO"
  echo "✅ APP_STORE_CONNECT_API_KEY_BASE64 set"
fi

if [[ -f "${SECRETS_DIR}/apple/developer_identity.p12" ]]; then
  P12_BASE64=$(base64 -i "${SECRETS_DIR}/apple/developer_identity.p12" | tr -d '\n')
  gh secret set IOS_CERTIFICATE_BASE64 --body "$P12_BASE64" --repo "$REPO"
  echo "✅ IOS_CERTIFICATE_BASE64 set"
fi

# 3. Android Keystore Secrets
if [[ -f "${SECRETS_DIR}/android/release.jks" ]]; then
  JKS_BASE64=$(base64 -i "${SECRETS_DIR}/android/release.jks" | tr -d '\n')
  gh secret set ANDROID_KEYSTORE_BASE64 --body "$JKS_BASE64" --repo "$REPO"
  echo "✅ ANDROID_KEYSTORE_BASE64 set"
fi

echo "=== GitHub Actions Secrets configuration complete for ${REPO} ==="
