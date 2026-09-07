# PLAN — `browser-zoom`

| Field | Value |
|-------|--------|
| Kind | `feature` |
| Slug | `browser-zoom` |
| Lead repo | `am-modern-ui` |
| Other repos | n/a |
| Target env | `local` with **prod config** (`AM_ENV=prod`, not preprod Helm, not prod VPS) |
| Branch | `feature/browser-zoom` |
| Delivery rating | **10/10** |
| Design rating | **10/10** |
| Scorecard overall | **9.6** |
| Agent satisfied | **yes** |

Execute gate: Delivery 10 + Design 10 + overall ≥ 9.5 + all dims ≥ 9.0 + Agent satisfied + user confirm. **Agent satisfied ≠ product approved.**

## Goal

Modern-ui web must re-check browser zoom on maximize / minimize / restore / resize, keep desktop chrome from collapsing just because Chrome zoomed the page, and expose Zoom in/out (HUD, Ctrl+/−/0, Ctrl+wheel) that shares one zoom factor with the browser.

## Images

- User attachments: none
- Previews: **n/a — user asked no images**

## Prerequisites (done / pending / blocked)

| Check | Status | Notes |
|-------|--------|--------|
| MCP | n/a | UI-only |
| Downstream APIs | n/a | No API change |
| Postman | n/a | none — UI-only |

## World-class feature map

### P0 — this slice

- Web-only `BrowserZoomHost`: listen `resize`, `visualViewport.resize`, DPR. Debounce ~50ms.
- `MediaQuery.size` = CSS size × chrome zoom so `AppShell` / scaffolds keep desktop chrome; `textScaler` = `appZoom / chromeZoom` so Chrome and in-app zoom do not double.
- HUD **− / percent / + / Reset** (steps 67–200%) on `GlobalSidebar`; compact HUD on mobile web.
- Keyboard Ctrl/Cmd + `+` / `-` / `0`.
- Ctrl+wheel on shell except over charts (`AppZoomScrollGuard`).
- Persist `localStorage` key `am_ui_zoom`.
- Widget tests for math, breakpoint compensation, stub on non-web.

### P1 — next

- Per-monitor zoom; pinch whole-app; Profile zoom.

### P2 — later

- OS magnifier; setting Chrome’s native zoom from JS (not possible).

## First-run / virtual value UX

N/A — no cash, broker, or empty book.

## Latency & consistency

N/A — client-only. Listener miss → zoom `1.0` (today’s CSS-width breakpoints).

## Current system (verified)

- HTML renderer in `am_app/web/flutter_bootstrap.js`.
- `AppShell` desktop cutoff: `constraints.maxWidth > 1100` (hides `GlobalSidebar`).
- `UnifiedSidebarScaffold`: mobile < 1100, compact 1100–1300.
- `AmAdaptiveLayout` / `AmBreakpoints`: 600 / 1100.
- No zoom binding. Charts own Ctrl+wheel (`_ZoomableChartWrapper`, `multi_index_chart`).

## Target journeys

1. Desktop 1920px, Chrome 150%, still see `GlobalSidebar`. Text/icons larger (browser).
2. Maximize then restore while zoomed: chrome and HUD percent stay correct.
3. In-app − / + / Reset and Ctrl+/−/0 match HUD.
4. Ctrl+wheel over a chart zooms the **chart**, not the app.
5. Android/iOS: no HUD, no listeners (stub).

## Identity & ownership

- No user/account ids. Zoom is device-browser local (`am_ui_zoom`).

## State & money

- N/A money.
- State: `chromeZoom` (detected), `appZoom` (HUD, persisted). Shared factor: chrome change syncs `appZoom`; `textScale = appZoom / chromeZoom`.

## Isolation

- Web-only. Non-web stub is zoom `1.0`. Does not touch API/auth.

## Failure modes

- `visualViewport` missing → chrome zoom `1.0`.
- `localStorage` throw → in-memory zoom only.
- Clamp outside 67–200%.
- Chart Ctrl+wheel must not change app zoom.

## Corner-case matrix

| Case | Trigger | Expected | Covered by |
|------|---------|----------|------------|
| Zoom in keeps desktop | 1920 CSS-equivalent at 150% | Sidebar stays; text larger | unit: layout width ≥ 1100 |
| Zoom out keeps layout | 1280 window at 80% | Unzoomed width drives chrome | unit |
| Maximize while zoomed | window maximize | Re-read zoom; no stale mobile chrome | unit + Test Plan |
| Minimize / restore | restore small window | Mobile only if **unzoomed** width is small | unit |
| DPR vs zoom | Windows 125% OS + Chrome 110% | OS scale is not chrome zoom | unit |
| Listener fail | visualViewport missing | zoom=1.0 | unit |
| Chart Ctrl+wheel | wheel over chart | Chart zoom only | widget + Test Plan |
| Clamp | 50% / 250% | Clamp to 67–200 | unit |
| Persist | reload | last percent restored | unit (fake storage) |
| Non-web | Flutter mobile | no-op | unit stub |

## Out of scope

- Changing 1100/1300 breakpoints
- CanvasKit switch
- Backend / Postman / feature flags
- Prod/preprod Helm deploy
- Native HTML “reflow to mobile on zoom” as the product model

## Open questions

- (none) — user: no images; local + prod config; no deploy.

## Review roles

| Role | When | Looks for |
|------|------|-----------|
| Agent architect | Until Agent satisfied | Scorecard, adversarial, code cites |
| You (product / tech owner) | User review gate | P0 vs P1, local prod-config verify |
| Optional `/review` | If asked | am-code-review / reviewer |

## UI previews (modern-ui)

- Gate: fail — **n/a — user asked no images**
- Widget/page cites: `AppShell`, `GlobalSidebar`, `BrowserZoomHost`
- Previews: none

## Services

| Service | Existing or new | Impl notes | Unit tests in this slice |
|---------|-----------------|------------|--------------------------|
| am-modern-ui (`am_design_system` + `am_app`) | existing | Client zoom host + HUD | Math, host rebuild, stub, adaptive width, scroll guard |

## Test Plan (Postman or MCP)

Collection: `none — UI-only`  
Shared Postman env: n/a

Run against `http://localhost:9000` with `AM_ENV=prod` (`npm run run:app:9000:prod`).

| Row | Request or MCP call | Method + path | Expected | Owning service | Result |
|-----|---------------------|---------------|----------|----------------|--------|
| 1 | Chrome 100% wide desktop | n/a | Sidebar, 100% HUD | am-modern-ui | not verified (needs Chrome) |
| 2 | Ctrl+Plus to 125% then 150% | n/a | HUD updates; sidebar remains | am-modern-ui | not verified (needs Chrome) |
| 3 | Maximize / restore | n/a | HUD unchanged; chrome matches unzoomed width | am-modern-ui | not verified (needs Chrome) |
| 4 | Ctrl+0 | n/a | Back to 100% | am-modern-ui | not verified (needs Chrome) |
| 5 | Ctrl+wheel on chart | n/a | Chart zooms; HUD unchanged | am-modern-ui | not verified (needs Chrome) |
| 6 | Reload | n/a | Last zoom restored | am-modern-ui | not verified (needs Chrome) |
| 7 | Mobile viewport | n/a | Compact HUD on web; no HUD on Flutter mobile | am-modern-ui | not verified (needs Chrome) |
| boot | GET http://localhost:9000 AM_ENV=prod | GET / | 200, title AM Investment Platform | am-modern-ui | pass |

## Deploy

**Out of scope.** Local process + prod backend only. Not `am deploy --env prod`.

## Agent scorecard

| Dimension | Score /10 | Evidence or gap |
|-----------|-----------|-----------------|
| Product / features | 10 | P0 map; user skip previews |
| Architecture / design | 10 | 7-sheet draw.io + BusinessFlow |
| Data / identity / contracts | 9.5 | `am_ui_zoom` only |
| State / money / consistency | 9.5 | chrome vs app zoom factor |
| Reliability / failure | 9.5 | fallback 1.0 |
| Security / authz | 9.5 | no secrets; localStorage only |
| Observability | 9.5 | debug log zoom + viewport |
| Testability | 9.5 | matrix mapped |
| Operability / rollout | 9.5 | local + prod config |
| TODO / implementability | 9.5 | junior-ready tasks |
| **Overall (mean)** | **9.6** | |

## Adversarial review

| Severity | Finding |
|----------|---------|
| Minor | Chart Ctrl+wheel exclusion is easy to miss if a new chart is added without `AppZoomScrollGuard` |

- Blocker/Major count: 0
- Agent satisfied = yes

## Rating log (agent architect loop)

| Pass | Delivery | Design | Overall | Gaps then patched |
|------|----------|--------|---------|-------------------|
| 1 | 8 | 8 | 8.4 | preprod + images |
| 2 | 10 | 10 | 9.6 | local prod config; no images |

## User review gate

Confirmed via Cursor plan. Execute: pack (no images) + impl + local prod-config verify. No deploy.

## REPORT gate

Do not write `REPORT.md` until unit tests and Test Plan rows are verified (or user accepts remaining not-verified).
