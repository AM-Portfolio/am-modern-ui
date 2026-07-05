# Page Reload & Tab Navigation Fixes

**Date:** July 2026  
**Related:** [FIRST_URL_TO_AUTH.md](FIRST_URL_TO_AUTH.md) | [PREPROD_DEPLOY_CHECKLIST.md](PREPROD_DEPLOY_CHECKLIST.md)

---

## Issue 1 — Static asset caching (dev + preprod)

### Policy (July 2026)
Daily deploys to **dev** and **preprod** require **always-fresh** UI on reload and incognito.

**Full reference:** [CACHE_STRATEGY.md](CACHE_STRATEGY.md)

### Current behavior
[`docker-entrypoint.sh`](../am_app/docker-entrypoint.sh) selects nginx profile from Helm `ENVIRONMENT`:
- **dev / preprod** → [`nginx.profiles/nocache.conf`](../am_app/nginx.profiles/nocache.conf) — **no-store** on all static assets
- **prod** → [`nginx.profiles/revalidate.conf`](../am_app/nginx.profiles/revalidate.conf) — **must-revalidate** (304 / 200)

Reload / incognito on preprod → always fetches latest bundle (~4–8s release build).
### Debug vs release
`npm run run:app:preprod` (debug) loads many small library chunks — **not** the same as preprod cluster release build.

---

## Issue 2 — Portfolio tab: no API calls

### Symptom
Navigate Dashboard → Portfolio (or open Portfolio tab): no `portfolios/list`, `holdings`, or `summary` in Network tab.

### Root cause (bug in Phase 2 defer fix)
[`global_portfolio_wrapper.dart`](../am_portfolio_ui/lib/features/portfolio/presentation/widgets/global_portfolio_wrapper.dart) used `context.read<PortfolioCubit>()` from the **wrapper's** context, which is **outside** `BlocProvider`. Tab-switch sync (`didUpdateWidget`) silently failed — cubit was never found.

Also: when portfolio list loaded with `_selectedPortfolioId` already set (from Dashboard remember), listener skipped `loadPortfolioById`.

### Fix (shipped)
1. Use `_portfolioBlocContext` (inside BlocProvider) for cubit access
2. `_syncPortfolioStreaming()` runs on tab change **and** post-frame after cubit create
3. On `PortfolioListLoaded`, if ID already selected and Portfolio/Trade tab → call `_selectPortfolio` / `loadPortfolioById`

### Verify
1. Open Dashboard → Network: **no** portfolio holdings/summary
2. Click Portfolio → Network: `portfolios/list`, then `holdings` + `summary` **once**
3. Reload on `/app/portfolio/{id}/overview` → same APIs fire

---

## Issue 3 — Trade UI 400 errors

### Symptom
Trade tab returns HTTP 400 from trade APIs.

### Root cause
Trade providers called APIs with **empty** `portfolioId` when global portfolio never loaded (same bug as Issue 2). Backend rejects invalid/missing portfolio ID.

### Fix (shipped)
Guard in trade stream providers — skip API if `portfolioId.isEmpty`:
- `tradeHoldingsStreamProvider`
- `tradeSummaryStreamProvider`
- `tradeCalendarStreamProvider`
- `watchTradesByPortfolioProvider`
- `tradeControllerCubitForPortfolioProvider`

After Issue 2 fix, Trade tab gets valid portfolio ID and APIs should return 200.

### Verify
1. Dashboard → Trade (with portfolio selected) → trade APIs use valid UUID in URL
2. Trade discovery (no portfolio) → **no** 400 spam; show portfolio selection UI instead

---

## Quick test checklist

```
[ ] Reload preprod — main.dart.js Cache-Control no-store; always 200 (fresh after deploy)
[ ] Dashboard — no portfolio detail APIs
[ ] Portfolio tab — list + holdings + summary fire
[ ] Trade tab — no 400 when portfolio selected
[ ] Trade discovery — no API calls with empty portfolioId
```

---

## Issue 4 — Reload shows login flash before dashboard

### Symptom
Reload on `/app/dashboard` (or any `/app/*`) shows bootstrap spinner → login form → dashboard.

### Root cause
1. **AppShell** duplicated auth redirect to `/login` while router already handled session restore
2. **Auth refresh network failure** (530) emitted `Unauthenticated` instead of recoverable state
3. Double bootstrap spinners (HTML + Flutter)

### Fix (shipped)
- Removed AppShell login redirect — **GoRouter only**
- Added `AuthRestoreFailed` for transient refresh failures; session-restore overlay on `/app/*`
- Login page spinner when `?redirect=/app/*` during restore
- Context-aware copy: “Restoring your session…” on `/app/*` reload
- See [BOOT_RUM.md](BOOT_RUM.md) for automatic timing on every visit (no query param)

### Verify
```
[ ] Reload /app/dashboard — no login form at any point
[ ] Reload /app/portfolio/{id}/overview — URL preserved
[ ] Visit https://am.asrax.in — window.__AM_BOOT_TRACE__.rum populated after ~6s
```

---

## Issue 5 — CanvasKit re-downloaded every reload

### Symptom
Every reload downloads ~15 MB including CanvasKit WASM (~13 MB).

### Fix (shipped)
Tiered nginx in [`nginx.profiles/nocache.conf`](../am_app/nginx.profiles/nocache.conf):
- **no-store:** `main.dart.js`, bootstrap, index.html, config
- **cache:** `/canvaskit/**` (7 days, must-revalidate)

### Verify
```
[ ] curl -I main.dart.js → Cache-Control: no-store
[ ] curl -I canvaskit/canvaskit.wasm → public, max-age=604800
[ ] 2nd reload DevTools → canvaskit from disk cache
[ ] After deploy → main.dart.js 200, UI changes visible
```
