# Mobile CI/CD — secrets, branch policy, and setup

Caller workflows live in this repo; reusable jobs live in **am-pipelines@main**.

| Workflow | Role |
|----------|------|
| [`.github/workflows/web-ci.yml`](../.github/workflows/web-ci.yml) | Web Contabo only |
| [`.github/workflows/mobile-ci.yml`](../.github/workflows/mobile-ci.yml) | **Primary** — build + Internal → Production store ladder |
| [`.github/workflows/codemagic-fallback.yml`](../.github/workflows/codemagic-fallback.yml) | Approval-gated Codemagic Internal-only backup |
| [`.github/workflows/deploy-store-artifacts.yml`](../.github/workflows/deploy-store-artifacts.yml) | Re-upload existing AAB/IPA (CM reuse needs `codemagic-fallback`) |

Pipelines ref: `AM-Portfolio/am-pipelines@main`.

Package / bundle id: `com.asrax.aminvestment`.

---

## Store ladder (Internal → Production)

Same GitHub Mobile CI binary promotes Internal → final stores.

| Stage | Android | iOS | When | Environment |
|-------|---------|-----|------|-------------|
| Build | AAB | IPA + `ios-keep-<sha>` | when platform enabled | — |
| Internal | Play **internal** (upload AAB) | **TestFlight** | feature dispatch; always on `main` | `android-internal` / `ios-internal` |
| Production | Play **production** (**promote** same `versionCode`; do not re-upload AAB) | **App Store** | **`main` only** (or `force_deploy`) after Internal succeeds | `android-prod` / `ios-prod` (required reviewers) |

**Android:** Internal uploads the AAB once; Production assigns that `versionCode` to the production track via Play API promote. Re-uploading the same AAB fails with “Version code N has already been used.”

**Operator:** confirm Internal on device / TestFlight before approving `*-prod`.

### Feature / dispatch
Actions → **Mobile CI** → set `deploy_internal` and/or `deploy_testflight` → Internal only (Production skipped).

### Main
Push to `main` → Internal jobs → approve `android-prod` / `ios-prod` → Play Production + App Store submit.

---

## Codemagic (manual fallback only)

**No auto triggers on any branch.** GitHub owns the store ladder.

| Workflow id | When | Track |
|-------------|------|-------|
| `android-ci-build` / `ios-ci-build` | Manual Start build only | artifacts / email |
| `android-play-internal` / `ios-testflight` | Manual or **Codemagic fallback** workflow | Internal only |

### Approval path
1. Actions → **Codemagic fallback** → choose workflow + branch.
2. Approve GitHub Environment **`codemagic-fallback`** (required reviewers).
3. Job starts Codemagic via API (`CODEMAGIC_API_TOKEN` + `CODEMAGIC_APP_ID`).
4. Verify Play Internal / TestFlight — **not** Production from CM.

Checklist (also in workflow YAML): GH outage/signing gap → branch/version floors → approve → verify store.

---

## Branch policy

| Trigger | Build | Internal | Production |
|---------|-------|----------|------------|
| feature push | Yes | No (unless dispatch) | No |
| dispatch `deploy_internal` / `deploy_testflight` | Yes | Yes | No |
| `main` push | Yes | Yes | Yes (after `*-prod` approve) |
| Codemagic fallback | CM build | Yes | No |

Environments (Settings → Environments):

- `android-internal` / `ios-internal` — light approval
- `android-prod` / `ios-prod` — required reviewers for final stores
- `codemagic-fallback` — required reviewers for CM start / CM artifact reuse

---

## Secrets checklist (repo `AM-Portfolio/am-modern-ui`)

### Shared
| Secret | Used by |
|--------|---------|
| `GOOGLE_WEB_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID` / `GOOGLE_ANDROID_CLIENT_ID` | dart-defines / web |
| `GROWTHBOOK_CLIENT_KEY` | mobile + web |

### Android (GitHub Play)
| Secret | Purpose |
|--------|---------|
| `ANDROID_KEYSTORE_*` | Upload signing |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Play API |

### iOS (GitHub TestFlight / App Store)
| Secret | Purpose |
|--------|---------|
| `APP_STORE_CONNECT_API_KEY_*` | ASC upload |
| `IOS_CERTIFICATE_*` / `IOS_PROVISIONING_PROFILE_BASE64` / `IOS_KEYCHAIN_PASSWORD` | Signing |

### Codemagic fallback
| Secret | Purpose |
|--------|---------|
| `CODEMAGIC_API_TOKEN` | Start builds / fetch artifacts |
| `CODEMAGIC_APP_ID` | App id (`6ac22a8f93e6cd231a7ad1d6`) |

---

## Operator steps

1. Ensure Environments above exist with reviewers on `*-prod` and `codemagic-fallback`.
2. Feature: Mobile CI + `deploy_internal` / `deploy_testflight` → verify Internal.
3. Merge to `main` → approve Internal envs if needed → approve `android-prod` / `ios-prod` → Production stores.
4. Only if GH cannot ship: **Codemagic fallback** (Internal only).

---

## Related

- Pipelines: `am-pipelines` → `docs/MOBILE_CI_CD.md`
- [ANDROID_PIPELINE_IMPLEMENTATION_PLAN.md](./ANDROID_PIPELINE_IMPLEMENTATION_PLAN.md)
