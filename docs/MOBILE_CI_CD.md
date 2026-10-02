# Mobile CI/CD — secrets, branch policy, and setup

Caller workflows live in this repo; reusable jobs live in **am-pipelines**.

| Workflow | Role |
|----------|------|
| [`.github/workflows/web-ci.yml`](../.github/workflows/web-ci.yml) | Web Contabo only (no Android/iOS) |
| [`.github/workflows/mobile-ci.yml`](../.github/workflows/mobile-ci.yml) | Android + iOS in parallel |

Pipelines refs (while iterating): `AM-Portfolio/am-pipelines@feature/mobile-android-ios-ci`.

Package / bundle id: `com.asrax.aminvestment`.

---

## Branch policy

| Branch | Build | Store deploy |
|--------|-------|--------------|
| `feature/**`, `develop`, `hotfix/**` | Yes (AAB + IPA/app artifacts) | **No** |
| `main` | Yes | **Internal first** (Play Internal + TestFlight), then **full** (Play Production + App Store) via GitHub Environments |

Environments (create in GitHub → Settings → Environments):

- `android-internal` / `ios-internal` — light or auto approval
- `android-prod` / `ios-prod` — required reviewers for full release

Manual dispatch on `mobile-ci` can force deploy (`force_deploy`); prefer `main` for real store uploads.

Retired: `deploy-mobile.yml`, `unified-ci.yml` (replaced by `web-ci` + `mobile-ci`).

---

## Secrets checklist (repo `AM-Portfolio/am-modern-ui`)

Never commit real client IDs, keys, keystores, or `.p8` / `.p12` / profiles. Empty placeholders only in git (`am_app/web/config.*.json`, helm `appConfig.*` client fields).

### Shared (web Contabo inject + mobile dart-defines)

| Secret | Used by |
|--------|---------|
| `GOOGLE_WEB_CLIENT_ID` | Web ConfigMap helm param + mobile `AM_GOOGLE_CLIENT_ID` |
| `GOOGLE_IOS_CLIENT_ID` | Web ConfigMap + iOS Info.plist / dart-define |
| `GOOGLE_ANDROID_CLIENT_ID` | Web ConfigMap + Android dart-define |
| `GROWTHBOOK_CLIENT_KEY` | Web helm param + mobile `AM_GROWTHBOOK_CLIENT_KEY` (use per-env secrets if keys differ) |

Local laptop sources (examples): OAuth clients from Google Cloud (`admin@asrax.in`); GrowthBook SDK connection client key. Prefer Vault SoT → GitHub secrets when MCP/`gh` auth works.

### Android deploy

| Secret | Purpose |
|--------|---------|
| `ANDROID_KEYSTORE_BASE64` | Upload keystore `.jks` (base64) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias (e.g. `upload`) |
| `ANDROID_KEY_PASSWORD` | Key password |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Raw Play API service account JSON (not base64) |

### iOS deploy

| Secret | Purpose |
|--------|---------|
| `APP_STORE_CONNECT_API_KEY_ID` | ASC API Key ID (e.g. from `APPLE_KEY_ID` in `~/.asrax/credentials.d/apple-developer.env`) |
| `APP_STORE_CONNECT_API_ISSUER_ID` | ASC Issuer ID (`APPLE_ISSUER_ID`) |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64 of `AuthKey_*.p8` (e.g. `~/.asrax/secrets/AuthKey_AA5ZK75HAS.p8`) |
| `IOS_CERTIFICATE_BASE64` | Apple Distribution `.p12` (base64) — **Mac export** |
| `IOS_CERTIFICATE_PASSWORD` | `.p12` export password |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store `.mobileprovision` (base64) |
| `IOS_KEYCHAIN_PASSWORD` | Ephemeral CI keychain password (any strong random string) |

SSH deploy keys are **not** used for Play/TestFlight.

---

## How to obtain missing files

### Android upload keystore

If the app is already on Play with Play App Signing, recover the **upload** keystore used at enrollment (or request an upload-key reset). Search backups for `*.jks` / `am_investment_keystore` before creating a new key.

New keystore (only if you still control signing / new app):

```bash
keytool -genkeypair -v \
  -keystore am_investment_upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storepass '<STORE_PASSWORD>' \
  -keypass '<KEY_PASSWORD>' \
  -dname "CN=Asrax, OU=Mobile, O=Asrax, L=City, ST=State, C=IN"
```

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("am_investment_upload.jks")) | Set-Clipboard
# ANDROID_KEYSTORE_BASE64 = clipboard; set password/alias secrets
```

Keep `.jks` under `~/.asrax/secrets/` only.

### Play Console service account

1. GCP → Service Account → JSON key.
2. Enable **Google Play Android Developer API**.
3. Play Console → Users and permissions → invite SA email with release-to-testing/production for `com.asrax.aminvestment`.
4. Paste raw JSON into `PLAY_STORE_SERVICE_ACCOUNT_JSON`.

Do not reuse an unrelated GCP SA (e.g. a personal test SA) unless it is invited in Play.

### iOS Distribution `.p12` (Mac required)

1. [Certificates](https://developer.apple.com/account/resources/certificates/list) → Apple Distribution → CSR → download `.cer` → import Keychain.
2. Keychain → My Certificates → Export `.p12` → password.
3. `base64 -i Dist.p12 | pbcopy` → `IOS_CERTIFICATE_BASE64` + `IOS_CERTIFICATE_PASSWORD`.

### iOS App Store provisioning profile

1. Identifiers → App ID `com.asrax.aminvestment`.
2. Profiles → App Store → select Distribution cert → download `.mobileprovision`.
3. `base64 -i ….mobileprovision | pbcopy` → `IOS_PROVISIONING_PROFILE_BASE64`.

### ASC API `.p8` (often already on laptop)

`~/.asrax/secrets/AuthKey_*.p8` + `apple-developer.env` (`APPLE_KEY_ID`, `APPLE_ISSUER_ID`). Map to `APP_STORE_CONNECT_*` secrets. Fix `APPLE_PRIVATE_KEY_PATH` to the machine path you use (Windows vs Mac).

---

## Operator steps (end-to-end)

1. Create GitHub Environments: `android-internal`, `android-prod`, `ios-internal`, `ios-prod`.
2. Set all secrets above on `am-modern-ui` (env-scope Contabo/web clients on `dev`/`preprod`/`prod` if keys differ).
3. Ensure am-pipelines branch with `central-mobile-android.yml` / `central-mobile-ios.yml` is pushed; `mobile-ci` / `web-ci` `uses:` point at that ref until merged to `main`.
4. Push a `feature/*` branch → confirm artifacts, **no** Play/TestFlight jobs.
5. Merge to `main` → Internal uploads → approve `*-prod` Environments → full store release.
6. Grep repo: no live `sdk-*` GrowthBook keys / Google client IDs in tracked config/helm (examples only).

---

## Related

- Pipelines operator notes: `am-pipelines` → `docs/MOBILE_CI_CD.md`
- Older Android phase plan: [ANDROID_PIPELINE_IMPLEMENTATION_PLAN.md](./ANDROID_PIPELINE_IMPLEMENTATION_PLAN.md)
