#!/usr/bin/env bash
# Automated GitHub Secrets configuration script for am-modern-ui
# Never prints secret values. Skips missing local files with a warning.
set -euo pipefail

REPO="${1:-AM-Portfolio/am-modern-ui}"
SECRETS_DIR="${HOME}/.asrax/secrets"
APPLE_DIR="${SECRETS_DIR}/apple"
CREDS_DIR="${HOME}/.asrax/credentials.d"

echo "=== Setting GitHub Actions Secrets for ${REPO} ==="

# 1. OAuth & Environment Secrets
echo "Setting OAuth & Environment secrets..."
gh secret set GOOGLE_WEB_CLIENT_ID --body "307768822337-ad7tee4d82cc0b4flgrfs157e5e6rc0g.apps.googleusercontent.com" --repo "$REPO"
gh secret set GOOGLE_IOS_CLIENT_ID --body "307768822337-082220ndhdik3b6utgac7t8hun23dqns.apps.googleusercontent.com" --repo "$REPO"
gh secret set GOOGLE_ANDROID_CLIENT_ID --body "307768822337-ad7tee4d82cc0b4flgrfs157e5e6rc0g.apps.googleusercontent.com" --repo "$REPO"
gh secret set GROWTHBOOK_CLIENT_KEY --body "sdk-Cwr4MxBl0iqnKZJ" --repo "$REPO"

# 2. Apple Developer / App Store Connect
echo "Setting App Store Connect API secrets..."
gh secret set APP_STORE_CONNECT_API_KEY_ID --body "AA5ZK75HAS" --repo "$REPO"
gh secret set APP_STORE_CONNECT_API_ISSUER_ID --body "0aab8fa5-6360-4693-aad6-95a3938c74e1" --repo "$REPO"

P8=""
for cand in \
  "${APPLE_DIR}/AuthKey_AA5ZK75HAS.p8" \
  "${SECRETS_DIR}/AuthKey_AA5ZK75HAS.p8"; do
  if [[ -f "$cand" ]]; then P8="$cand"; break; fi
done
if [[ -n "$P8" ]]; then
  P8_BASE64=$(base64 -i "$P8" 2>/dev/null | tr -d '\n' || base64 "$P8" | tr -d '\n')
  gh secret set APP_STORE_CONNECT_API_KEY_BASE64 --body "$P8_BASE64" --repo "$REPO"
  echo "OK: APP_STORE_CONNECT_API_KEY_BASE64 set from ${P8}"
else
  echo "WARN: AuthKey_AA5ZK75HAS.p8 not found — ASC fetch / altool need APP_STORE_CONNECT_API_KEY_BASE64"
fi

# Distribution cert (.p12) — optional if ASC fetch-signing-files is used in CI
P12=""
for cand in \
  "${APPLE_DIR}/developer_identity.p12" \
  "${HOME}/.asrax/developer_certificate.p12" \
  "${SECRETS_DIR}/developer_certificate.p12"; do
  if [[ -f "$cand" ]]; then P12="$cand"; break; fi
done
if [[ -n "$P12" ]]; then
  P12_BASE64=$(base64 -i "$P12" 2>/dev/null | tr -d '\n' || base64 "$P12" | tr -d '\n')
  gh secret set IOS_CERTIFICATE_BASE64 --body "$P12_BASE64" --repo "$REPO"
  echo "OK: IOS_CERTIFICATE_BASE64 set from ${P12}"
else
  echo "WARN: no .p12 found — CI will use ASC fetch-signing-files when ASC keys are set"
fi

# Cert password: ~/.asrax/secrets/apple/ios_certificate_password.txt or apple-developer.env IOS_CERTIFICATE_PASSWORD
CERT_PASS=""
if [[ -f "${APPLE_DIR}/ios_certificate_password.txt" ]]; then
  CERT_PASS="$(tr -d '\r\n' < "${APPLE_DIR}/ios_certificate_password.txt")"
elif [[ -f "${CREDS_DIR}/apple-developer.env" ]]; then
  # shellcheck disable=SC1090
  set -a
  # Only pull the one key if present (file may have other vars)
  CERT_PASS="$(grep -E '^[[:space:]]*IOS_CERTIFICATE_PASSWORD=' "${CREDS_DIR}/apple-developer.env" | head -1 | cut -d= -f2- | tr -d '\r' | sed 's/^["'\'']//;s/["'\'']$//')"
  set +a
fi
if [[ -n "${CERT_PASS}" ]]; then
  gh secret set IOS_CERTIFICATE_PASSWORD --body "$CERT_PASS" --repo "$REPO"
  echo "OK: IOS_CERTIFICATE_PASSWORD set"
else
  echo "WARN: IOS_CERTIFICATE_PASSWORD not found (needed only for p12 path)"
fi

# Distribution private key PEM (Codemagic CERTIFICATE_PRIVATE_KEY) — ASC fetch when cert already exists in Apple portal
CERT_PEM=""
for cand in \
  "${APPLE_DIR}/ios_distribution_private_key" \
  "${APPLE_DIR}/ios_distribution_private_key.pem" \
  "${SECRETS_DIR}/ios_distribution_private_key" \
  "${SECRETS_DIR}/ios_distribution_private_key.pem"; do
  if [[ -f "$cand" ]]; then CERT_PEM="$cand"; break; fi
done
if [[ -n "$CERT_PEM" ]]; then
  gh secret set CERTIFICATE_PRIVATE_KEY < "$CERT_PEM" --repo "$REPO"
  echo "OK: CERTIFICATE_PRIVATE_KEY set from ${CERT_PEM}"
elif [[ -n "$P12" ]] && command -v openssl >/dev/null 2>&1; then
  TMP_PEM="$(mktemp)"
  if openssl pkcs12 -in "$P12" -nodes -nocerts -passin "pass:${CERT_PASS:-}" -out "$TMP_PEM" 2>/dev/null \
    || openssl pkcs12 -in "$P12" -nodes -nocerts -passin "pass:${CERT_PASS:-}" -legacy -out "$TMP_PEM" 2>/dev/null; then
    if grep -q "PRIVATE KEY" "$TMP_PEM" 2>/dev/null; then
      gh secret set CERTIFICATE_PRIVATE_KEY < "$TMP_PEM" --repo "$REPO"
      echo "OK: CERTIFICATE_PRIVATE_KEY extracted from ${P12}"
    else
      echo "WARN: openssl ran but no PRIVATE KEY block — set ${APPLE_DIR}/ios_distribution_private_key manually"
    fi
  else
    echo "WARN: could not extract key from p12 (password?) — ASC fetch needs CERTIFICATE_PRIVATE_KEY PEM"
  fi
  rm -f "$TMP_PEM"
else
  echo "WARN: no ios_distribution_private_key PEM — ASC fetch may fail if Apple already has a Distribution cert"
fi

# Provisioning profile
PROFILE=""
for cand in \
  "${APPLE_DIR}/AppStore_com.asrax.aminvestment.mobileprovision" \
  "${APPLE_DIR}/"*.mobileprovision; do
  # Expand glob carefully
  if [[ -f "$cand" ]]; then PROFILE="$cand"; break; fi
done
# shellcheck disable=SC2086
if [[ -z "$PROFILE" ]]; then
  shopt -s nullglob
  for cand in "${APPLE_DIR}"/*.mobileprovision; do
    PROFILE="$cand"
    break
  done
  shopt -u nullglob
fi
if [[ -n "$PROFILE" && -f "$PROFILE" ]]; then
  PROF_BASE64=$(base64 -i "$PROFILE" 2>/dev/null | tr -d '\n' || base64 "$PROFILE" | tr -d '\n')
  gh secret set IOS_PROVISIONING_PROFILE_BASE64 --body "$PROF_BASE64" --repo "$REPO"
  echo "OK: IOS_PROVISIONING_PROFILE_BASE64 set from ${PROFILE}"
else
  echo "WARN: no .mobileprovision under ${APPLE_DIR} — CI ASC fetch will create/download one"
fi

# Optional keychain password for CI import
if [[ -f "${APPLE_DIR}/ios_keychain_password.txt" ]]; then
  KC_PASS="$(tr -d '\r\n' < "${APPLE_DIR}/ios_keychain_password.txt")"
  gh secret set IOS_KEYCHAIN_PASSWORD --body "$KC_PASS" --repo "$REPO"
  echo "OK: IOS_KEYCHAIN_PASSWORD set"
fi

# 3. Android Keystore Secrets
if [[ -f "${SECRETS_DIR}/android/release.jks" ]]; then
  JKS_BASE64=$(base64 -i "${SECRETS_DIR}/android/release.jks" 2>/dev/null | tr -d '\n' || base64 "${SECRETS_DIR}/android/release.jks" | tr -d '\n')
  gh secret set ANDROID_KEYSTORE_BASE64 --body "$JKS_BASE64" --repo "$REPO"
  echo "OK: ANDROID_KEYSTORE_BASE64 set"
elif [[ -f "${SECRETS_DIR}/keystore_base64.txt" ]]; then
  JKS_BASE64="$(tr -d '\r\n[:space:]' < "${SECRETS_DIR}/keystore_base64.txt")"
  gh secret set ANDROID_KEYSTORE_BASE64 --body "$JKS_BASE64" --repo "$REPO"
  echo "OK: ANDROID_KEYSTORE_BASE64 set from keystore_base64.txt"
fi

echo "=== GitHub Actions Secrets configuration complete for ${REPO} ==="
echo "Note: TestFlight needs either (p12+profile+password) OR APP_STORE_CONNECT_API_KEY_* for ASC fetch in central-mobile-ios."
