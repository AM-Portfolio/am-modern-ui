# PLAN — Dashboard Top Movers → Equity Insider

| Field | Value |
|-------|--------|
| Kind | `feature` |
| Slug | `dashboard-top-movers-equity-insider` |
| Lead repo | `am-modern-ui` |
| Other repos | none |
| Target env | `preprod` after implementation approval; local verification first |
| Branch | `feature/dashboard-top-movers-equity-insider` |
| Delivery rating | 9.0/10 (planning pass) |
| Design rating | 8.9/10 (planning pass) |
| Scorecard overall | 8.8/10 (planning pass) |
| Agent satisfied | `no` — user review gate pending |

Execute gate: **Delivery 10 + Design 10 + overall ≥ 9.5 + all dims ≥ 9.0 + Agent satisfied: yes** + explicit user confirmation.

## Goal

Make every stock row in the active Dashboard Top Movers panel clickable. A click on either a gainer or loser must open the existing Equity Insider surface for that stock and hand off the canonical symbol before the Equity Insider page resolves its data, so the user does not see an unrelated default symbol first.

## Source plan (pointer)

| Field | Value |
|-------|--------|
| Origin | `pasted-chatgpt` / current conversation |
| Pointer | User request with Top Movers screenshot |
| Summary | 1. Gainers and losers are interactive. 2. The clicked stock opens Equity Insider. 3. Use the existing route/state pattern. 4. Keep the shared mover component reusable. 5. Preserve desktop and mobile layouts. 6. Pass only the canonical symbol across the navigation boundary. 7. Do not add an API or database change. |
| Catalog | Domain `am-modern-ui`; packages `am_market/ui`, `am_market/common`, `am_design_system`; existing Equity Insider surface |
| Context files | Root `README.md` (Flutter monorepo and package boundaries); root `AGENTS.md` (read-only production policy and Postman preference); `am_market/ui/pubspec.yaml` (package dependencies); `am_market/ui` dashboard and Equity Insider files below |
| Analysis source | local |
| Coverage | `handles` — existing mover model, shared panel, host navigation, and Equity Insider symbol state were verified |
| AM gaps | Shared tap affordance, host callback wiring, focused tests, and a navigation latency/invalid-symbol matrix are still to implement |

## Images

- `images/` — no preview requested for this change; user-provided screenshot remains conversation context.

## Prerequisites (done / pending / blocked)

| Check | Status | Notes |
|-------|--------|--------|
| MCP needed / connected | done | No external MCP needed for this UI-only slice |
| Downstream APIs exist | done | Equity Insider already owns symbol-driven loading; TopMoverStock already contains `symbol` |
| Postman collection found | n/a | No API contract changes; no Postman row required |
| User approval | pending | Required before implementation by the plan gate |

## World-class feature map

### P0 — this slice

- Click any visible gainer or loser tile on the active Market Dashboard.
- Normalize and hand off the tile’s symbol before selecting the Equity Insider surface.
- Reuse the existing `EquityInsiderPageState.navigateToSymbol` and provider state path.
- Preserve current Top Movers loading, error, live-price update, index selector, responsive layout, hover, and mobile gainers/losers toggle.
- Provide keyboard/focus semantics and a visible interactive affordance without changing the existing visual language.

### P1 — next

- Add a reusable analytics event for mover-to-insider navigation if product analytics needs the source surface.
- Add a route query/deep-link contract for direct Equity Insider symbol URLs if the app later standardizes that behavior.

### P2 — later or never

- Cross-module navigation from every mover-like component automatically; only the active Market Dashboard widget is in scope.
- New quote or fundamentals API endpoints.

## First-run / virtual value UX

N/A. This is read-only market navigation; it does not create money, holdings, orders, or broker linkage.

## Latency & consistency

- The click handler trims and uppercases the symbol, writes `equityInsiderActiveSymbolProvider`, then moves the existing `SwipeNavigationController` to Equity Insider. This ordering prevents the default-symbol resolver from winning the first frame.
- The page keeps its existing Equity Insider request and streaming behavior; no duplicate mover fetch is introduced.
- While Equity Insider data is loading, retain its existing loading state. No new spinner or fake quote is added to the dashboard tile.
- If the host surface is already mounted, call its existing `navigateToSymbol` method after selecting the surface; if it is not yet built, schedule the call with the existing short post-navigation handoff used by Watch List.
- Stale live-price updates remain scoped to the dashboard’s existing mover lists; they must not overwrite the selected Equity Insider symbol.

## Current system (verified)

- `am_market/ui/lib/features/dashboard/presentation/widgets/top_movers_widget_v2.dart` adapts `TopMoverStock` to shared `AmMoverItem` and currently has no tap callback.
- `am_design_system/lib/shared/widgets/movers/am_top_movers_panel.dart` renders desktop side-by-side columns and the mobile segmented view, so the interaction belongs at the shared panel/tile boundary.
- `am_design_system/lib/shared/widgets/movers/am_mover_tile.dart` owns the actual row paint/hover behavior and currently has no activation callback.
- `am_market/ui/lib/features/dashboard/presentation/pages/user_dashboard_page.dart` renders `TopMoversWidgetV2` and already receives canonical `TopMoverStock.symbol` values.
- `am_market/ui/lib/features/dashboard/presentation/pages/dashboard_page.dart` owns the swipe host, `GlobalKey<EquityInsiderPageState>`, and an existing Watch List callback that navigates to Equity Insider and invokes `navigateToSymbol`.
- `am_market/ui/lib/features/equity_insider/presentation/pages/equity_insider_page.dart` exposes `navigateToSymbol`, updates `equityInsiderActiveSymbolProvider`, and updates the Equity Insider market surface symbols.
- `am_dashboard_ui/.../DashboardRankingWidget` is an older dashboard package path and does not match the screenshot’s active `TopMoversWidgetV2` visual path; it is not changed unless a call-graph check proves it is also active.

## Target journeys

1. User opens Market Dashboard, sees Top Movers, clicks a gainer, and lands on Equity Insider for that gainer.
2. User clicks a loser on desktop or after switching the mobile segmented toggle, and lands on Equity Insider for that loser.
3. User clicks a tile while the Equity Insider surface is cold; the host selects the surface, the symbol is preserved, and Equity Insider loads that symbol without default-symbol flash.
4. User encounters an empty or malformed symbol; no navigation occurs and the dashboard remains usable.

## Identity & ownership

- `TopMoverStock.symbol` is the source identifier for this interaction; company name is display-only.
- The design system remains symbol/model agnostic and emits `AmMoverItem` through `ValueChanged<AmMoverItem>`.
- The Market adapter converts the item to a normalized symbol callback.
- `MarketContent` owns surface selection and the `EquityInsiderPageState` key; app-level route constants stay outside `am_market/ui`.
- `EquityInsiderPage` owns active symbol state and the existing symbol history/back behavior.

## State and data flow

`TopMoverStock.symbol` → `AmMoverItem` → `AmTopMoversPanel.onItemTap` → `TopMoversWidgetV2.onSymbolTap` → `UserDashboardPage` callback → `MarketContent` selects Equity Insider → provider symbol handoff → `EquityInsiderPageState.navigateToSymbol` → existing Equity Insider fetch/stream.

## Isolation

- No new backend, database, subscription, or API surface.
- No changes to IPO, Portfolio, Paper, Watch List, or Equity Insider detail presentation.
- Shared design-system additions must remain optional so existing `AmTopMoversPanel` consumers keep their current behavior when no callback is supplied.

## Failure modes

- Blank symbol: ignore the tap, emit a lightweight client diagnostic, and keep the dashboard visible.
- Duplicate tap before navigation completes: de-duplicate identical normalized symbols in the host handoff.
- Equity Insider data/API failure: rely on the existing Equity Insider error/loading UI; do not show a false dashboard success state.
- Surface not yet mounted: use the existing delayed key handoff; if the page is disposed, abort safely.
- Mobile toggle: callback must be passed through both the gainers and losers builders, not only desktop.
- Old dashboard widget: verify inactive by call graph; if active in another shell, record as a follow-up rather than silently changing it.

## Corner-case matrix

| Case | Trigger | Expected | Covered by |
|------|---------|----------|------------|
| Gainer click | Valid gainer symbol | Equity Insider opens for normalized symbol | DS widget test + Market host test |
| Loser click | Valid loser symbol | Same behavior as gainer | DS widget test + Market host test |
| Mobile loser click | Mobile toggle selects losers | Loser tile still invokes callback | DS responsive widget test |
| Blank symbol | Whitespace/empty `symbol` | No route/surface change | Adapter/host unit test |
| Lowercase/whitespace | ` tcs ` | Exactly one `TCS` handoff | Host unit test |
| Cold Equity Insider | Surface not built | Select surface, then invoke existing page key safely | Host integration test |
| Duplicate tap | Same symbol tapped repeatedly | No duplicate navigation/fetch handoff | Host test |
| Data failure after navigation | Equity Insider request fails | Existing Equity Insider failure UI remains | Regression test / manual verification |
| Live update race | Dashboard quote stream updates after tap | Equity Insider symbol is unchanged | State regression test |

## Out of scope

- Changing Equity Insider page layout or data fetching.
- Changing Top Movers ranking, index selection, live quote calculations, or API payloads.
- Adding a new route name or changing global URL semantics.
- Making the legacy `am_dashboard_ui` ranking widget interactive without evidence it is the active screenshot path.

## Open questions

- decided: use the existing MarketContent host callback and Equity Insider key/provider handoff; do not import `am_app` routing into `am_market/ui`.
- decided: no preview artifact is required for this interaction-only request unless the user asks for one.

## Review roles

| Role | When | Looks for |
|------|------|-----------|
| Agent architect | Before implementation | Boundary, state ordering, responsive coverage, failure matrix |
| User / product owner | User review gate | Click behavior, expected landing surface, no visual regressions |
| Optional `/review` | If asked | Design-system and accessibility review |

## UI previews (modern-ui)

- Consent: `not-requested`
- Gate: `n/a`
- Widget/page cites: Top Movers panel and Equity Insider surface
- Previews: `n/a — not requested`

## Services

| Service | Existing or new | Impl notes | Unit tests in this slice |
|---------|-----------------|------------|--------------------------|
| `am_design_system` | existing package | Optional `onItemTap` contract on shared mover tile/panel; theme and layout unchanged | Tap callback, absent callback, semantics/focus |
| `am_market/ui` | existing package | Adapter callback plus `MarketContent` host handoff | Gainer/loser, normalization, cold surface, duplicate tap |
| `am_market/common` | existing package | No code change expected; existing provider is the handoff state | Existing provider behavior regression only |

## Test Plan

Collection: `none — UI-only; no API contract changed`

| Row | Test | Expected | Owner | Result |
|-----|------|----------|-------|--------|
| 1 | `flutter test` design-system mover tests | Tap callback fires for both columns; absent callback is safe | `am_design_system` | not verified |
| 2 | `flutter test` Market Dashboard navigation tests | Valid symbol selects Equity Insider and reaches the keyed page | `am_market/ui` | not verified |
| 3 | Responsive widget test | Mobile segmented gainers/losers tiles remain interactive | `am_design_system` / `am_market/ui` | not verified |
| 4 | `flutter analyze` touched packages | 0 errors, warnings, and lints | `am_design_system`, `am_market/ui` | not verified |
| 5 | Manual local web flow | Click gainer and loser; verify requested symbol loads and no visual regression | `am-modern-ui` | not verified |

## Deploy

Local verification first. Preprod only after implementation, tests, and user approval. No production mutation is authorized by this request.

## Agent scorecard

| Dimension | Score /10 | Evidence or gap |
|-----------|-----------|-----------------|
| Product / features | 9.0 | P0/P1/P2 and responsive journeys defined |
| Architecture / design | 8.7 | Host callback avoids package-layer inversion; draw.io still pending in this planning pass |
| Data / identity / contracts | 9.0 | Symbol ownership and no-API scope are explicit |
| State / money / consistency | 9.0 | Provider-before-navigation and duplicate handoff covered |
| Reliability / failure | 8.8 | Empty, cold, duplicate, and API failure paths mapped |
| Security / authz | 9.0 | Read-only navigation; existing Equity Insider auth/data boundaries retained |
| Observability | 8.0 | Lightweight invalid-symbol diagnostic specified; exact telemetry event remains optional |
| Testability | 8.8 | Matrix maps to widget, host, responsive, and analyzer checks |
| Operability / rollout | 8.8 | No API/schema/deploy change; local then preprod |
| TODO / implementability | 8.7 | Concrete file boundaries identified; implementation pending review |
| **Overall (mean)** | **8.8** | First planning pass; not an execution approval |

## Adversarial review

| Severity | Finding |
|----------|---------|
| Minor | The exact host callback method name and whether provider write is needed before key navigation should be finalized in implementation tests. |
| Minor | Legacy `am_dashboard_ui` needs one call-graph confirmation before being excluded permanently. |

- Blocker/Major count: 0
- Agent satisfied: `no` until architecture artifact and user review are complete

## Rating log

| Pass | Delivery | Design | Overall | Gaps then patched |
|------|----------|--------|---------|-------------------|
| 1 | 9.0 | 8.9 | 8.8 | Added shared-component boundary, host navigation ordering, responsive coverage, invalid-symbol handling, and cold-surface behavior; architecture artifact and tests remain pending |

## User review gate

Please review this plan and confirm the intended behavior before implementation. No runtime code has been changed for this feature yet.

## REPORT gate

Do not write `REPORT.md` until the unit tests, analyzer run, and manual local flow are verified.
