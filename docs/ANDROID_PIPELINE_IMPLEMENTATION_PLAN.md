# Android Pipeline — Detailed Implementation Plan

**Scope:** Android only (iOS later)  
**Rule:** Android Prod runs **only** when code is on `main` (after merge). Otherwise Prod is skipped.  
**Principle:** Do not change the existing web pipeline (`central-build-publish.yml` / `modern-ui.yml` web path).

---

## Goals

1. Build Android in parallel with web (web never blocked by Android).
2. Centralize Android build logic in `am-pipelines`.
3. Trigger from `am-modern-ui` via a thin workflow caller.
4. Develop → test on pipelines `develop` → then merge to `main`.
5. Android Prod only when Modern UI branch is `main`.

---

## Architecture (final)

```
Push / merge in am-modern-ui
        │
        ├── modern-ui.yml
        │     └── am-pipelines/.../central-build-publish.yml@main     → WEB (unchanged)
        │
        └── mobile-android.yml  (NEW)
              └── am-pipelines/.../central-mobile-android.yml@…       → ANDROID
                    @develop while testing
                    @main after pipelines is stable
```

### Job / environment names

| Stage | Web (keep) | Android (new) |
|-------|------------|---------------|
| Dev | Publish UI / Deploy → Dev | Android → Dev |
| Preprod | Publish UI / Deploy → Preprod | Android → Preprod |
| Prod | Publish UI / Deploy → Prod | Android → Prod |

GitHub Environments:

- `dev-am-modern-ui-android`
- `preprod-am-modern-ui-android`
- `prod-am-modern-ui-android` (approval required)

---

## Branch rules (Android)

| Event in am-modern-ui | Android build | Android → Dev | Android → Preprod | Android → Prod |
|-----------------------|---------------|---------------|-------------------|----------------|
| PR / feature branch | Yes (optional light) | Optional artifact | Skip or light | **Skip** |
| Push to `develop` | Yes | Yes (APK artifact) | Yes (Play Internal later) | **Skip** |
| Merge / push to `main` | Yes | Optional | Yes | **Yes** (approval) |

Caller sets:

```yaml
deploy_prod: ${{ github.ref == 'refs/heads/main' }}
```

---

## Phase overview

| Phase | Repo | Branch | Outcome |
|-------|------|--------|---------|
| 0 | Both | — | Prerequisites / decisions |
| 1 | `am-pipelines` | `develop` | Reusable Android workflow (build + artifact) |
| 2 | `am-modern-ui` | feature → `develop` | Thin caller pointing at `@develop` |
| 3 | Both | develop | End-to-end test (parallel with web, Prod skipped) |
| 4 | `am-modern-ui` | app code | Package id, signing wiring, flavors |
| 5 | Both | develop | Play Internal (Preprod) |
| 6 | Both | main path | Android Prod only on `main` + approval |
| 7 | `am-pipelines` | develop → main | Promote pipelines; switch caller to `@main` |
| 8 | — | — | Harden, docs, then iOS later |

---

# Phase 0 — Prerequisites & decisions

**Do before writing CI.**

### 0.1 Decisions (team)

- [ ] Final Android `applicationId` (must replace `com.example.am_app`)
- [ ] Play Console app created (or scheduled)
- [ ] Who approves `prod-am-modern-ui-android`
- [ ] Dev distribution: GitHub artifact first (recommended), Firebase later (optional)

### 0.2 Secrets to prepare (can land in Phase 1–5 gradually)

| Secret | Needed from | Purpose |
|--------|-------------|---------|
| `ANDROID_KEYSTORE_BASE64` | Phase 4+ | Sign release AAB |
| `ANDROID_KEYSTORE_PASSWORD` | Phase 4+ | Keystore password |
| `ANDROID_KEY_ALIAS` | Phase 4+ | Key alias |
| `ANDROID_KEY_PASSWORD` | Phase 4+ | Key password |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Phase 5+ | Upload to Play |

Until secrets exist: CI can still **build debug/unsigned artifacts**.

### 0.3 Exit criteria

- [ ] Package name agreed  
- [ ] Plan accepted by team  
- [ ] Ready to open PR on `am-pipelines` develop  

---

# Phase 1 — `am-pipelines` develop: create Android reusable workflow

**Repo:** `am-pipelines`  
**Branch:** `develop` (or `feature/central-mobile-android` → PR into `develop`)

### 1.1 Create file

`am-pipelines/.github/workflows/central-mobile-android.yml`

### 1.2 Workflow shape (`workflow_call`)

**Inputs (minimum):**

| Input | Type | Default | Meaning |
|-------|------|---------|---------|
| `working_directory` | string | required | e.g. `am_app` |
| `flavor` | string | `preprod` | `dev` / `preprod` / `prod` |
| `build_type` | string | `appbundle` | `apk` or `appbundle` |
| `run_analyze` | boolean | `true` | `flutter analyze` |
| `run_tests` | boolean | `true` | `flutter test` |
| `upload_artifact` | boolean | `true` | Upload AAB/APK to Actions |
| `deploy_dev` | boolean | `false` | Dev distribution job |
| `deploy_preprod` | boolean | `false` | Play Internal (Phase 5) |
| `deploy_prod` | boolean | `false` | Play Production (Phase 6) |
| `package_name` | string | optional | Play package name |

**Jobs (Phase 1 only implement build + artifact):**

1. **Android → Build**
   - `runs-on: ubuntu-latest`
   - Checkout caller repo (default when using `workflow_call`)
   - Setup Java 17
   - Setup Flutter (pin version)
   - `flutter pub get` in monorepo modules as needed (start with `am_app`; expand if build fails)
   - Optional: analyze + test
   - Build:
     - Phase 1: `flutter build apk --debug` or release with debug signing if flavors not ready
     - Later phases: flavor + signed `appbundle`
   - Upload artifact

2. **Android → Dev** — stub or skip in Phase 1 (`if: inputs.deploy_dev`)
3. **Android → Preprod** — stub (`if: inputs.deploy_preprod`) — implement Phase 5
4. **Android → Prod** — stub (`if: inputs.deploy_prod`) — implement Phase 6

### 1.3 Do NOT touch

- `central-build-publish.yml`
- Helm / universal-chart
- Existing web deploy jobs

### 1.4 Optional smoke trigger inside pipelines

Add `workflow_dispatch` on the same file **or** a tiny test caller so you can run the workflow manually from `am-pipelines` develop before Modern UI is wired.

### 1.5 PR & merge

1. Open PR: `feature/central-mobile-android` → `am-pipelines` **`develop`**
2. Review
3. Merge to **`develop`**
4. Confirm workflow appears under Actions on develop

### 1.6 Exit criteria

- [ ] `central-mobile-android.yml` exists on `am-pipelines` **develop**
- [ ] Manual or test run can complete **Build** + artifact
- [ ] Web workflows unchanged  
- [ ] Prod/Preprod jobs either skipped or stubs that no-op safely  

---

# Phase 2 — `am-modern-ui`: thin caller → pipelines `@develop`

**Repo:** `am-modern-ui`  
**Branch:** `feature/mobile-android-workflow` → PR into `develop`

### 2.1 Create file

`am-modern-ui/.github/workflows/mobile-android.yml`

### 2.2 Trigger (align with web, can tighten later)

```yaml
on:
  push:
    branches: ["main", "develop", "feature/**", "hotfix/**", "fix/**"]
  pull_request:
    branches: ["main", "develop"]
  workflow_dispatch:
```

(Adjust `paths-ignore` like web if desired.)

### 2.3 Call pipelines develop

```yaml
jobs:
  android:
    name: Publish Android
    uses: AM-Portfolio/am-pipelines/.github/workflows/central-mobile-android.yml@develop
    with:
      working_directory: "am_app"
      deploy_dev: ${{ github.ref == 'refs/heads/develop' }}
      deploy_preprod: ${{ github.ref == 'refs/heads/develop' || github.ref == 'refs/heads/main' }}
      deploy_prod: ${{ github.ref == 'refs/heads/main' }}   # ONLY MAIN
    secrets: inherit
```

**This is how Modern UI “triggers” the pipeline:**  
push/merge in Modern UI → this file runs → it calls `am-pipelines` `@develop`.

### 2.4 Leave web alone

Do **not** edit `modern-ui.yml` except if you later want shared triggers; recommended: keep separate files so web and Android fail independently.

### 2.5 PR & merge

1. PR into `am-modern-ui` **`develop`**
2. Merge
3. Push a small commit to `develop` or use `workflow_dispatch`

### 2.6 Exit criteria

- [ ] `mobile-android.yml` exists and calls `@develop`
- [ ] Push to Modern UI `develop` starts **Android** workflow
- [ ] Web `modern-ui.yml` still runs independently
- [ ] On `develop`, Android Prod job is **skipped** (`deploy_prod: false`)

---

# Phase 3 — Develop test loop (before Play / Prod)

**Goal:** Prove parallel CI from merge/push on develop.

### 3.1 Test matrix

| Test | Action | Expected |
|------|--------|----------|
| T1 | Push to `am-modern-ui` develop | Web pipeline runs; Android pipeline runs |
| T2 | Android build fails (optional force) | Web Deploy Dev/Preprod still can succeed |
| T3 | Web fails | Android still can succeed |
| T4 | Branch is `develop` | Android → Prod **skipped** |
| T5 | Download artifact | APK/AAB installs or is valid file |
| T6 | PR (not main) | Prod skipped |

### 3.2 How engineers check Dev app (while CI exists)

1. Prefer local: `flutter run` on emulator/phone against Dev APIs  
2. Or download **Android → Dev** / build artifact from Actions and install APK  

### 3.3 Exit criteria

- [ ] Parallel behavior confirmed  
- [ ] Prod skip on non-main confirmed  
- [ ] Team comfortable with logs/artifacts  
- [ ] Ready for app readiness (Phase 4)  

---

# Phase 4 — App readiness in `am-modern-ui`

**Repo:** `am-modern-ui`  
**Branch:** feature → `develop`  
**Can overlap late Phase 1–3, but required before Play upload.**

### 4.1 Replace example identity

Current state:

- `applicationId = "com.example.am_app"`
- Release uses **debug** signing

Tasks:

- [ ] Set real `applicationId` / namespace  
- [ ] Update Kotlin package / `MainActivity` path if needed  
- [ ] App name / icons as needed  

### 4.2 Signing for CI

- [ ] Create upload keystore (keep offline backup)
- [ ] Add GitHub org/repo secrets (see Phase 0)
- [ ] Wire `key.properties` generation in CI (never commit keystore)
- [ ] `build.gradle.kts` release `signingConfig` → release keystore

### 4.3 Flavors / env config (recommended)

| Flavor | APIs | Used by |
|--------|------|---------|
| `dev` | Dev backend | Engineer builds |
| `preprod` | Preprod backend | Play Internal |
| `prod` | Prod backend | Play Production |

Mobile cannot use web Helm `config.json` the same way — bake env via flavor or `--dart-define`.

### 4.4 Versioning

- [x] `versionName` from `pubspec.yaml` (`--build-name`)
- [x] `versionCode` from `pubspec +N` + `github.run_number` (+ optional `version_code_offset`) in CI (`--build-number`)

### 4.5 Exit criteria

- [ ] Local `flutter build appbundle --flavor preprod` (or equivalent) works  
- [ ] CI can produce **signed** AAB  
- [ ] No secrets in git  

---

# Phase 5 — Preprod = Play Internal

**Repos:** `am-pipelines` develop + `am-modern-ui` develop

### 5.1 Play Console setup

- [ ] App created with matching package name  
- [ ] Internal testing track enabled  
- [ ] Testers email list / Google group  
- [ ] Service account with Play Developer API access  
- [ ] Secret `PLAY_STORE_SERVICE_ACCOUNT_JSON` added  

### 5.2 Implement **Android → Preprod** job

In `central-mobile-android.yml`:

- Build signed AAB (`preprod` flavor)
- Upload to Play track: **`internal`**
- Gate with GitHub Environment: `preprod-am-modern-ui-android` (optional approval)

### 5.3 Caller flags

- `develop` → `deploy_preprod: true`
- `main` → `deploy_preprod: true` (keep Internal updated from main too, optional)

### 5.4 Test from develop merge

1. Merge app + workflow changes to Modern UI `develop`  
2. Wait for Android workflow  
3. Confirm build on Play Internal  
4. Install via Play Internal link on a test device  
5. Confirm app hits **preprod** APIs  

### 5.5 Exit criteria

- [ ] Develop merge → AAB on Play Internal  
- [ ] QA can install without sideload  
- [ ] Still: **Android Prod skipped** on develop  

---

# Phase 6 — Prod only on `main` merge

### 6.1 Implement **Android → Prod** job

- Build signed AAB (`prod` flavor)
- Upload to Play **production** (or upload then manual promote — choose one)
- GitHub Environment: `prod-am-modern-ui-android` **with required reviewers**
- `if: inputs.deploy_prod == true`

### 6.2 Caller rule (must keep)

```yaml
deploy_prod: ${{ github.ref == 'refs/heads/main' }}
```

### 6.3 Test procedure

| Step | Action | Expected |
|------|--------|----------|
| 1 | Push only to `develop` | Prod job skipped |
| 2 | Open PR develop → main | Prod still skipped on PR (unless you intentionally enable; recommend skip on PR) |
| 3 | Merge PR into `main` | Android Prod job appears / waits for approval |
| 4 | Approve `prod-am-modern-ui-android` | Upload/promote to Play Production |
| 5 | Reject / don’t approve | Web can still proceed independently; Android Prod not published |

### 6.4 Exit criteria

- [ ] Non-main → Prod skipped always  
- [ ] Main merge → Prod gated by approval  
- [ ] Production package uses **prod** APIs  

---

# Phase 7 — Promote pipelines develop → main; switch Modern UI ref

When Android workflow on pipelines `develop` is stable:

### 7.1 am-pipelines

1. PR: `develop` → `main` (include `central-mobile-android.yml`)  
2. Merge after review  
3. Confirm workflow exists on `main`  

### 7.2 am-modern-ui

Change caller from:

```yaml
uses: .../central-mobile-android.yml@develop
```

to:

```yaml
uses: .../central-mobile-android.yml@main
```

PR → merge to Modern UI `develop`, then to `main` as usual.

### 7.3 Exit criteria

- [ ] Production callers use `@main`  
- [ ] `@develop` only used for future pipeline experiments  
- [ ] Web still on its existing `@main` path  

---

# Phase 8 — Hardening (after first successful main → Play)

- [ ] Cache Flutter / Gradle in CI for speed  
- [ ] Fail PR on `flutter analyze` / tests  
- [ ] Staged rollout % on Play Production  
- [ ] Crash reporting (e.g. Sentry) + mapping files  
- [ ] Document engineer Dev install steps  
- [ ] Only then start **iOS** plan (same pattern → TestFlight)

---

## Suggested timeline (flexible)

| Week | Focus |
|------|--------|
| 1 | Phase 0–1 (pipelines develop workflow + artifact) |
| 1–2 | Phase 2–3 (Modern UI caller `@develop` + parallel tests) |
| 2–3 | Phase 4 (package id, signing, flavors) |
| 3–4 | Phase 5 (Play Internal) |
| 4 | Phase 6–7 (main-only Prod + promote pipelines to main) |

---

## File checklist (end state)

### am-pipelines

- [ ] `.github/workflows/central-mobile-android.yml` (on develop, then main)
- [ ] No breaking changes to `central-build-publish.yml`

### am-modern-ui

- [ ] `.github/workflows/mobile-android.yml` (caller)
- [ ] `.github/workflows/modern-ui.yml` unchanged (web)
- [ ] Android app: real applicationId, signing, flavors
- [ ] This plan doc (optional living doc)

### GitHub

- [ ] Environments: `*-am-modern-ui-android`
- [ ] Secrets for keystore + Play service account  

---

## Definition of Done (project)

1. Push to Modern UI runs **web** and **Android** in parallel.  
2. Web Dev/Preprod/Prod behavior unchanged.  
3. Develop merge → Android build (+ Preprod Internal); **Prod skipped**.  
4. Main merge → Android Prod job runs only after approval.  
5. Android logic centralized in `am-pipelines`; Modern UI only triggers via thin workflow.  
6. Pipelines Android workflow merged to `main` and Modern UI calls `@main`.

---

## Next action (start Phase 1)

1. Branch from `am-pipelines` **`develop`**.  
2. Add `central-mobile-android.yml` (build + artifact only).  
3. PR → merge to `develop`.  
4. Then Phase 2: add `mobile-android.yml` in Modern UI calling `@develop`.
