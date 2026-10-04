# Mobile CI/CD — secrets, branch policy, and setup

Caller workflows live in this repo; reusable jobs live in **am-pipelines**.

| Workflow | Role |
|----------|------|
| [`.github/workflows/web-ci.yml`](../.github/workflows/web-ci.yml) | Web Contabo only (no Android/iOS) |
| [`.github/workflows/mobile-ci.yml`](../.github/workflows/mobile-ci.yml) | **Primary** — Android + iOS build; Play Internal via GitHub |
| [`.github/workflows/deploy-store-artifacts.yml`](../.github/workflows/deploy-store-artifacts.yml) | Optional: re-upload an existing AAB/IPA (legacy) |

Pipelines refs (while iterating): `AM-Portfolio/am-pipelines@feature/mobile-android-ios-ci`.

Package / bundle id: `com.asrax.aminvestment`.

---

## Play Internal Testing (GitHub-native — preferred)

No Codemagic required.

1. Actions → **Mobile CI** → Run workflow.
2. Enable **`deploy_internal`**.
3. Approve GitHub Environment **`android-internal`** if prompted.
4. Workflow builds a signed AAB on `ubuntu-latest` and uploads to Play **internal** (`r0adkll/upload-google-play`).
5. `versionCode` = max(pubspec `+N` + `run_number` + offset, **Play API max + 1**).

On push to **`main`**: Play Internal then Play Production (Environments `android-internal` → `android-prod`).

Required secrets: `ANDROID_KEYSTORE_*`, `PLAY_STORE_SERVICE_ACCOUNT_JSON`.

---

## Codemagic (main-only CI + iOS TestFlight backup)

Keep **one** Codemagic application named **AM Flutter · Modern UI**. Settings source = `codemagic.yaml`.

| Workflow id | Display name | When | Store |
|-------------|--------------|------|-------|
| `android-ci-build` | Android CI · AAB | auto **main** only | email only |
| `ios-ci-build` | iOS CI · unsigned | auto **main** only | email only |
| `android-play-internal` | Android · Play Internal | **manual** (backup) | Play `internal` |
| `ios-testflight` | iOS · TestFlight | **manual** (until GH mac runner) | TestFlight |

Feature / develop work does **not** auto-trigger Codemagic — use GitHub Mobile CI.

Local SoT → Codemagic groups (optional backup):

| CM variable | Local source |
|-------------|--------------|
| `ANDROID_KEYSTORE_*` | `~/.asrax/secrets/keystore_base64.txt` + `key.properties` |
| `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | Play SA JSON |
| `APP_STORE_CONNECT_*` | `apple-developer.env` + `AuthKey_*.p8` |

Helper: [`scripts/ci/sync-codemagic-mobile-creds.ps1`](../scripts/ci/sync-codemagic-mobile-creds.ps1).

---

## Branch policy

| Branch / trigger | Build | Android store | iOS store |
|------------------|-------|---------------|-----------|
| `feature/**`, `develop`, `hotfix/**` push | Yes | No | No (artifact only) |
| `workflow_dispatch` + `deploy_internal` | Yes | Play **Internal** | No |
| `main` push | Yes | Internal → Production | No from GH yet |
| Codemagic manual `ios-testflight` | — | — | TestFlight |

Environments (GitHub → Settings → Environments):

- `android-internal` / `ios-internal` — light or auto approval
- `android-prod` / `ios-prod` — required reviewers for full release

**iOS TestFlight from GitHub** is deferred until a dedicated GitHub mac runner is available. Until then use Codemagic **iOS · TestFlight**.

Retired: `deploy-mobile.yml`, `unified-ci.yml`, Codemagic AAB reuse as the primary Internal path.

---

## Secrets checklist (repo `AM-Portfolio/am-modern-ui`)

Never commit real client IDs, keys, keystores, or `.p8` / `.p12` / profiles.

### Shared (web Contabo inject + mobile dart-defines)

| Secret | Used by |
|--------|---------|
| `GOOGLE_WEB_CLIENT_ID` | Web ConfigMap + mobile `AM_GOOGLE_CLIENT_ID` |
| `GOOGLE_IOS_CLIENT_ID` | Web ConfigMap + iOS Info.plist / dart-define |
| `GOOGLE_ANDROID_CLIENT_ID` | Web ConfigMap + Android dart-define |
| `GROWTHBOOK_CLIENT_KEY` | Web helm param + mobile `AM_GROWTHBOOK_CLIENT_KEY` |

### Android deploy (GitHub Play Internal)

| Secret | Purpose |
|--------|---------|
| `ANDROID_KEYSTORE_BASE64` | Upload keystore `.jks` (base64) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Raw Play API service account JSON |

### iOS deploy (Codemagic TestFlight / future GH mac)

| Secret | Purpose |
|--------|---------|
| `APP_STORE_CONNECT_API_KEY_ID` | ASC API Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | ASC Issuer ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64 of `AuthKey_*.p8` |
| `IOS_CERTIFICATE_BASE64` | Apple Distribution `.p12` (base64) |
| `IOS_CERTIFICATE_PASSWORD` | `.p12` export password |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store `.mobileprovision` (base64) |
| `IOS_KEYCHAIN_PASSWORD` | Ephemeral CI keychain password |

`CODEMAGIC_API_TOKEN` is **not** required for Play Internal.

---

## How to obtain missing files

### Android upload keystore

If the app is already on Play with Play App Signing, recover the **upload** keystore used at enrollment (or request an upload-key reset). Search backups for `*.jks` / `am_investment_keystore` before creating a new key.

```bash
keytool -genkeypair -v \
  -keystore am_investment_upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storepass '<STORE_PASSWORD>' \
  -keypass '<KEY_PASSWORD>' \
  -dname "CN=Asrax, OU=Mobile, O=Asrax, L=City, ST=State, C=IN"
```

Keep `.jks` under `~/.asrax/secrets/` only.

### Play Console service account

1. GCP → Service Account → JSON key.
2. Enable **Google Play Android Developer API**.
3. Play Console → Users and permissions → invite SA email with release rights for `com.asrax.aminvestment`.
4. Paste raw JSON into `PLAY_STORE_SERVICE_ACCOUNT_JSON`.

### iOS Distribution / ASC

See prior operator notes: export `.p12` + App Store profile on a Mac; map `AuthKey_*.p8` + `apple-developer.env` into ASC secrets / Codemagic `ios_credentials`.

---

## Operator steps (end-to-end)

1. Create GitHub Environments: `android-internal`, `android-prod`, `ios-internal`, `ios-prod`.
2. Set Android + shared secrets on `am-modern-ui`.
3. Ensure am-pipelines `@feature/mobile-android-ios-ci` has Play max versionCode support; `mobile-ci` `uses:` that ref.
4. Feature branch: Actions → Mobile CI → `deploy_internal=true` → confirm Play Internal.
5. Merge to `main` → Internal + Production (approve `android-prod`).
6. iOS: Codemagic **Start build** → `ios-testflight` until GH mac is ready.

---

## Related

- Pipelines: `am-pipelines` → `docs/MOBILE_CI_CD.md` (if present)
- Older Android phase plan: [ANDROID_PIPELINE_IMPLEMENTATION_PLAN.md](./ANDROID_PIPELINE_IMPLEMENTATION_PLAN.md)
