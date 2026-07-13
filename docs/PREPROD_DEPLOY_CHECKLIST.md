# Preprod Deploy Checklist — Load Time Fixes

Use this before committing and deploying `am-modern-ui` to preprod (`am-preprod.asrax.in`).

**Related docs:**
- [CACHE_STRATEGY.md](../docs/CACHE_STRATEGY.md) — env-wise static cache policy (dev/preprod no-store, prod revalidate)
- [FIRST_URL_TO_AUTH.md](FIRST_URL_TO_AUTH.md) — startup timeline
- [RELOAD_AND_TAB_FIXES.md](RELOAD_AND_TAB_FIXES.md) — reload JS cache + portfolio/trade tab bugs
- [LOAD_TIME_PROBLEM_ANALYSIS.md](LOAD_TIME_PROBLEM_ANALYSIS.md) — problems + fix status
- [FAST_BOOT_PERFORMANCE.md](FAST_BOOT_PERFORMANCE.md) — implementation details
- [DOCKER_README.md](../DOCKER_README.md) — container build

---

## Shipped in this branch (code changes)

| Area | File(s) | Change |
|------|---------|--------|
| Portfolio defer on Dashboard | `global_portfolio_wrapper.dart` | No holdings/summary fetch on Dashboard tab |
| Portfolio dedupe | `portfolio_cubit.dart` | Skip duplicate `loadPortfolioById` |
| HTTP timeouts | `api_client.dart` | 30s default on GET/POST/PUT/DELETE |
| Chart timeout | `dashboard_repository.dart` | 15s on performance API |
| Progressive dashboard | `dashboard_provider.dart` | keepAlive repo, STOMP decouple, parallel kickoff |
| Activity dedupe | `dashboard_recent_activity_widget.dart` | Single REST path |
| UX | `dashboard_web_screen.dart`, `dashboard_mobile_screen.dart` | Chart label, mobile reorder, BootTrace first-widget |
| Lazy Hive | `portfolio_local_data_source.dart`, `portfolio_providers.dart` | Init on first cache access |
| Auth Dio timeout | `injection.dart` | 15s connect / 30s receive on identity calls |
| Cache strategy | `nginx.profiles/`, `docker-entrypoint.sh`, `inject_build_id.sh` | Dev/preprod no-store; prod revalidate; CI build ID |
| Generated | `dashboard_provider.g.dart` | Regenerated — **must be committed** |

---

## Before commit

### 1. Regenerate code (if providers changed)

```bash
cd am-modern-ui/am_dashboard_ui
dart run build_runner build --delete-conflicting-outputs
```

Confirm `dashboard_provider.g.dart` shows `dashboardRepositoryProvider` with `isAutoDispose: false`.

### 2. Static analysis

```bash
cd am-modern-ui/am_dashboard_ui
dart analyze lib/

cd am-modern-ui/am_portfolio_ui
dart analyze lib/features/portfolio/

cd am-modern-ui/am_library
dart analyze lib/core/network/
```

### 3. Release build (matches preprod Docker)

```bash
cd am-modern-ui
npm run build:app:preprod
```

Build must complete without errors. Output: `am_app/build/web/`.

### 4. Optional — trace build for post-deploy debugging

```bash
npm run build:app:preprod:trace
```

Use `?bootTrace=1` in browser after deploy to verify timings.

### 5. Cache headers (after deploy)

See [CACHE_STRATEGY.md](CACHE_STRATEGY.md). Preprod must return `Cache-Control: no-store` on `main.dart.js`:

```bash
curl -I https://am-preprod.asrax.in/main.dart.js
```

Confirm Cloudflare **bypasses cache** for `am-preprod.asrax.in` if stale UI appears after deploy.

---

## Before preprod deploy (verify behavior)

### Smoke test locally with release build

```bash
cd am-modern-ui
npm run build:app:preprod
# Serve build/web on a static server, open /login?bootTrace=1
```

| Check | Expected |
|-------|----------|
| Login appears in **< 5s** (no debug compile) | Pass |
| Log in → Dashboard tab | Pass |
| Network: **no** `portfolios/holdings` or `portfolios/summary` on Dashboard only | Pass |
| Summary / movers / activity fill in **before** chart | Pass |
| Slow performance API → chart error at **~15s**, not 53s+ | Pass |
| BootTrace `dashboard_first_data` at **~1–3s** (healthy backend) | Pass |
| Expired token → refresh fails or completes within **30s** (Dio timeout) | Pass |

### Do NOT use debug run for preprod perf sign-off

`npm run run:app:preprod` includes 60–190s debug compile — not representative of cluster deploy.

---

## Still open (not blocking UI deploy)

| ID | Item | Owner | Notes |
|----|------|-------|-------|
| P15 | Backend API slowness (24–102s) | am-core-services | Root cause for slow chart/portfolio on degraded preprod |
| P14 | Env-specific nginx cache | Platform | `nginx.profiles/` + `docker-entrypoint.sh` — see [CACHE_STRATEGY.md](CACHE_STRATEGY.md) |
| P1 | Debug compile (dev only) | N/A | Use release build for testing |

Deploy UI fixes even if backend is slow — users get progressive dashboard + timeouts instead of infinite spinners.

---

## Post-deploy verification on preprod cluster

1. Open `https://am-preprod.asrax.in` (or preprod UI URL) with `?bootTrace=1`
2. DevTools → Network → filter `am-preprod.asrax.in`
3. Confirm Dashboard landing does not call portfolio holdings/summary
4. Confirm chart timeout ~15s if `/analysis/dashboard/performance` is slow
5. Check browser console for `[BootTrace]` summary

---

## Suggested commit message

```
fix(am-modern-ui): reduce preprod load time — defer portfolio on dashboard, API timeouts, progressive widgets

- Skip portfolio holdings/summary on Dashboard tab; dedupe loadPortfolioById
- 30s ApiClient timeout; 15s performance chart timeout; Dio timeout for auth refresh
- Dashboard STOMP decouple, keepAlive repository, parallel widget kickoff
- Lazy Hive init; BootTrace first-widget-wins; mobile chart reorder
- Docs: FIRST_URL_TO_AUTH, LOAD_TIME_PROBLEM_ANALYSIS, PREPROD_DEPLOY_CHECKLIST
```

---

## Files to include in commit

```
am-modern-ui/am_portfolio_ui/.../global_portfolio_wrapper.dart
am-modern-ui/am_portfolio_ui/.../portfolio_cubit.dart
am-modern-ui/am_portfolio_ui/.../portfolio_local_data_source.dart
am-modern-ui/am_portfolio_ui/.../portfolio_providers.dart
am-modern-ui/am_library/.../api_client.dart
am-modern-ui/am_dashboard_ui/.../dashboard_provider.dart
am-modern-ui/am_dashboard_ui/.../dashboard_provider.g.dart
am-modern-ui/am_dashboard_ui/.../dashboard_repository.dart
am-modern-ui/am_dashboard_ui/.../dashboard_web_screen.dart
am-modern-ui/am_dashboard_ui/.../dashboard_mobile_screen.dart
am-modern-ui/am_dashboard_ui/.../dashboard_recent_activity_widget.dart
am-modern-ui/am_app/lib/core/di/injection.dart
am-modern-ui/docs/FIRST_URL_TO_AUTH.md
am-modern-ui/docs/LOAD_TIME_PROBLEM_ANALYSIS.md
am-modern-ui/docs/PREPROD_DEPLOY_CHECKLIST.md
am-modern-ui/docs/FAST_BOOT_PERFORMANCE.md
am-modern-ui/am_app/README.md
```
