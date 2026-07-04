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
