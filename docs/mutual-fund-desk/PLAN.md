# Mutual Fund Desk (am_mutual_fund_ui)

## Ship A (landed)

First-class shell module at `/app/mutual-funds` talking to Asrax MF BFF.

- Package: `am_mutual_fund_ui`
- Dig base: `services.mutualFund` → `https://am-dev.asrax.in/router/am/mf`
- Flows: Explore → scheme detail → onboarding (KYC/UCC/FATCA/bank) → invest/pay/order detail → mandate + SIP/XSIP
- Auth: Bearer via `AuthProviders.attachAuthInterceptor`; `Idempotency-Key` on purchase
- Feature flag: `mutual-funds-enabled` (default ON when GB missing)

## Ship B (landed)

Holdings list, redeem, switch; mandate status refresh; seed client meta removed (fail-closed).

## Ship C / D / E (landed in code)

- Dig `mf_catalog`: ~15k schemes / 7k ISINs / NAV + enrichment categories pushed
- Order/SIP history + STP/SWP routes in shell nav
- Payment-link surface when `purchase_payment` returns non-trusted member
- Ops verify: `mf_service/scripts/verify_ship_c_*.py`; dig checklists notes 22–23
- Remaining ops: NSE trusted-member reply → funded UAT pay; live BFF search smoke with JWT

## Peer chrome (landed)

- `MfShell` uses `UnifiedSidebarScaffold` + `SecondarySidebarSection` (Browse: Explore/Holdings; Account: Onboarding/Systematic) — same pattern as portfolio/trade
- Shared kit: `MfPageHeader`, `MfEmptyState` / `MfErrorBanner` / `MfLoadingBlock` / `MfQuietNote`, `GlassCard`-based `MfFundCard`
- `AppColors.mutualFundAccent` synced via `ModuleColors.applyBrandSync`
- Nested routes highlight parent dest (scheme/invest/orders → Explore; redeem/switch → Holdings)

## Dig catalog (live browse)

Explore fullness depends on **am-market-data** JDBC + populated catalog tables — not the Flutter package.

- Helm: `AM_MARKET_MF_JDBC_URL` + vault `AM_MARKET_MF_JDBC_USER`/`PASSWORD` in `am-market/am-market-data/helm/`
- Dig note: `dig_vault_seed` cannot `CREATE DATABASE mf_catalog` yet → host in `user_platform_dev` schema `mf_catalog` (same grant pattern as Mongo `mutual_funds_dev`)
- Push: `am-mutual-fund/catalog/push_to_postgres.py` (or `_push_core.py` for scheme+NAV only)
- Invest/SIP still gated to SchemeIdMapper UAT ISINs (`INF579M01AV5`, `INF579M01AW3`)

## UI gap-fill (landed)

Wired thin desk gaps against existing BFF — no invented BFF fields.

- Scheme detail: `getNav` (~1Y) sparkline + `getPerformance` trailing returns strip (`—` when null)
- Holdings: show `avgNav`; client-side `currentValue ≈ units * latestNav` via cached performance/scheme providers; metric strip total value
- Onboarding: `POST /v1/mf/kyc/ekyc/start` step after KYC (skip allowed; dig UAT business fail is expected)
- History: Orders | SIPs | Mandates (`GET /v1/mf/mandates`); tap mandate → `getMandate` status refresh
- Still out of scope: dig CronJob ops, STP/SWP list persistence, BFF `current_value` field

## Desk gap-fill (1A + 2A, 2026-11-22)

- Systematic hydrates mandate/SIP refs from `GET /mandates` + `GET /sips`
- Order pay: payment mode chips + payment-link / non-trusted copy (GET_LINK in `failure_message`)
- History SIP rows: pause / resume / cancel
- Explore Buyable → BFF `purchaseAllowed`; filters use `AmToggleChip`
- BFF `POST /v1/mf/sips/resume` — stub ACTIVE roundtrip; NSE `RESUME_UNSUPPORTED`
- Ops note: [`DESK-UAT-READINESS.md`](DESK-UAT-READINESS.md); stub smoke: `mf_service/scripts/verify_desk_journey_stub.py`

## Verify (dig)

1. Sidebar **Mutual Funds** → secondary Browse/Account sections; Explore shows schemes when market-data catalog is live
2. Scheme detail: returns strip + NAV chart when history exists; nulls show `—`
3. Holdings: avg NAV + current value when catalog NAV resolves; empty CTA → Explore
4. Onboarding: eKYC step callable; UAT business fail visible; UCC must `ok:true` before FATCA/Bank
5. History: mandates list + tap-to-refresh; SIP pause/cancel/resume; Purchase → pay may business-fail on UAT (expected) with link when present
6. Mandate local `id` then SIP with that id → `distributor_sip_ref`; Systematic reopen hydrates from lists
