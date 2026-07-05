# Static asset cache strategy — Modern UI

**Scope:** Flutter web shell (`am_app`) served by nginx in Docker/Kubernetes  
**Related:** [FAST_BOOT_PERFORMANCE.md](FAST_BOOT_PERFORMANCE.md) | [PREPROD_DEPLOY_CHECKLIST.md](PREPROD_DEPLOY_CHECKLIST.md) | [RELOAD_AND_TAB_FIXES.md](RELOAD_AND_TAB_FIXES.md)

---

## Overview

Cache policy is **environment-specific**. Dev and preprod disable browser caching because you deploy almost daily and must always see the latest UI on reload and incognito. Prod uses **smart revalidation** (304 when unchanged, fresh 200 after deploy).

API responses are never cached by this nginx config — only static files (`*.js`, `*.wasm`, fonts, etc.).

---

## Environment matrix

| Environment | URL | Helm `environment` | Nginx profile | JS / WASM | Reload (same deploy) | After new deploy | Incognito |
|-------------|-----|----------------------|---------------|-----------|----------------------|------------------|-----------|
| **Local** | `localhost` | — | Flutter dev server | N/A | Hot reload | Hot reload | N/A |
| **Dev cluster** | `am-dev.asrax.in` | `dev` | `nocache` | **no-store** | Always 200 (fresh) | Always fresh | Always fresh |
| **Preprod** | `am.asrax.in` | `preprod` | `nocache` (tiered) | **no-store** app JS; **cache** CanvasKit | Fresh app JS every reload; CanvasKit from disk on 2nd reload | Fresh app JS after deploy | Fresh app JS |
| **Prod** | prod host | `prod` | `revalidate` | **must-revalidate** | **304** (~0.5–1.5s) | **200** (new file) | Fresh (no disk cache) |

---

## Architecture

```
CI (main push)
  → inject_build_id.sh (github.run_id → AM_BUILD_ID in index.html, same as image tag)
  → flutter build web
  → Docker image (both nginx profiles baked in)

Pod startup
  → docker-entrypoint.sh reads ENVIRONMENT from Helm
  → dev / preprod → nginx.profiles/nocache.conf
  → prod           → nginx.profiles/revalidate.conf
```

Files:

| File | Purpose |
|------|---------|
| [`am_app/docker-entrypoint.sh`](../am_app/docker-entrypoint.sh) | Selects profile from `ENVIRONMENT` |
| [`am_app/nginx.profiles/nocache.conf`](../am_app/nginx.profiles/nocache.conf) | Dev + preprod |
| [`am_app/nginx.profiles/revalidate.conf`](../am_app/nginx.profiles/revalidate.conf) | Prod only |
| [`scripts/inject_build_id.sh`](../scripts/inject_build_id.sh) | CI build stamp |
| [`scripts/docker_build_web.sh`](../scripts/docker_build_web.sh) | Docker flutter build (matches manage.py) |

---

## Daily deploy workflow (dev + preprod)

1. Merge to `main` → GitHub Actions builds Docker image
2. Dev deploys automatically
3. **Approve** preprod deploy in GitHub Actions
4. Open `https://am.asrax.in` (normal tab or incognito) → **latest UI**
5. No manual `AM_BUILD_ID` bump — CI injects git SHA on each build
6. No hard refresh needed on preprod/dev

**Expectation:** preprod reload fetches fresh `main.dart.js` every time (~2–7 MB). CanvasKit (~13 MB) served from browser cache on repeat reloads. See [BOOT_RUM.md](BOOT_RUM.md) for timing breakdown.

### Tiered preprod cache (July 2026)

| Path | Cache-Control |
|------|---------------|
| `index.html`, `flutter_bootstrap.js`, `main.dart.js`, `config*.json` | **no-store** |
| `/canvaskit/**` | **public, max-age=604800, must-revalidate** |
| `/assets/**`, fonts, icons | **public, max-age=86400, must-revalidate** |

Testers always see latest UI after deploy because **only app JS is never cached**. CanvasKit changes only when Flutter SDK in Docker image changes.

---

## What is never cached (all environments)

- `/index.html`
- `/flutter_bootstrap.js`
- `/config*.json`
- All backend API calls (separate host/path)

---

## Cloudflare (required for preprod correctness)

Browser `no-store` is not enough if Cloudflare caches at the edge.

| Host | Required rule |
|------|----------------|
| `am-dev.asrax.in` | **Bypass cache** (all paths) |
| `am.asrax.in` | **Bypass cache** (all paths) |
| Prod host | Respect origin `Cache-Control`; enable Brotli + HTTP/3 |

If preprod still shows stale UI after deploy, check Cloudflare first.

---

## How to change behavior later

| Goal | Edit | Redeploy image? |
|------|------|-----------------|
| Dev/preprod cache headers | [`nginx.profiles/nocache.conf`](../am_app/nginx.profiles/nocache.conf) | Yes |
| Prod revalidation policy | [`nginx.profiles/revalidate.conf`](../am_app/nginx.profiles/revalidate.conf) | Yes |
| Move preprod to prod-style cache | [`docker-entrypoint.sh`](../am_app/docker-entrypoint.sh) — add `preprod)` to `prod` case | Yes |
| Which env uses which profile | `docker-entrypoint.sh` `case` statement | Yes |
| Build version in HTML | [`scripts/inject_build_id.sh`](../scripts/inject_build_id.sh) | Yes (CI build) |
| Cloudflare edge | Cloudflare dashboard | No code deploy |
| Local flutter flags | [`scripts/manage.py`](../scripts/manage.py) / `.env.*` | Local only |
| Docker dart-defines | [`.env.preprod`](../.env.preprod) + [`docker_build_web.sh`](../scripts/docker_build_web.sh) | Yes |

### Example: enable caching on preprod when deploys slow down

In `docker-entrypoint.sh`:

```bash
case "${ENVIRONMENT:-preprod}" in
  prod|preprod) PROFILE=revalidate ;;
  *)            PROFILE=nocache ;;
esac
```

---

## Verification

### Dev + preprod

```bash
curl -I https://am-dev.asrax.in/main.dart.js
curl -I https://am.asrax.in/main.dart.js
# Expect: Cache-Control: no-store ...
```

DevTools → Network → reload → `main.dart.js` status **200** (not disk cache).

### Prod

```bash
curl -I https://<prod-host>/main.dart.js
# Expect: Cache-Control: public, max-age=0, must-revalidate

# Second request with ETag:
curl -I -H "If-None-Match: <etag-from-first-response>" https://<prod-host>/main.dart.js
# Expect: 304 Not Modified
```

### After CI deploy

View page source → `AM_BUILD_ID` should match the workflow run id (same as `global.image.tag` in Helm).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Preprod shows old UI after deploy | Cloudflare edge cache | Bypass cache for `am.asrax.in` |
| Prod always re-downloads full JS | `ENVIRONMENT` not `prod` | Add/check [`helm/values.prod.yaml`](../am_app/helm/values.prod.yaml) |
| `AM_BUILD_ID` stays `local` on cluster | CI missing `BUILD_ID` build-arg | Check am-pipelines `central-build-publish.yml` |
| Reload slow on preprod | Expected | no-store policy; boot optimizations still apply |

---

## CI/CD

| Step | Workflow |
|------|----------|
| Build + push | [`modern-ui.yml`](../.github/workflows/modern-ui.yml) → `central-build-publish.yml` |
| Preprod deploy | Approve `preprod-am-modern-ui` environment |
| Prod deploy | After preprod success + approve `prod-am-modern-ui` |

Docker build passes `--build-arg BUILD_ID=${{ github.run_id }}` — matches the deployed image tag.

---

## Future upgrades

- Content-hashed JS filenames + immutable CDN cache (best long-term)
- Deferred imports for smaller cold load ([FAST_BOOT_PERFORMANCE.md](FAST_BOOT_PERFORMANCE.md) Phase 2)
- Custom service worker for prod warm loads
