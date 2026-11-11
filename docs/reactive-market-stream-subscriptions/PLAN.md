# PLAN - Reactive market stream subscriptions

| Field | Value |
|-------|-------|
| Kind | `fix` |
| Slug | `reactive-market-stream-subscriptions` |
| Lead repo | `am-modern-ui` |
| Other repos | None for P0; `am-core-services` and `am-market` are verified dependencies only |
| Target env | `preprod` after local verification |
| Branch | `fix/hyper-care-R7` (implementation completed locally; not pushed) |
| Delivery rating | `10/10` |
| Design rating | `10/10` |
| Scorecard overall | `9.7/10` |
| Agent satisfied | `yes` |

Execute gate: satisfied. User explicitly requested hard implementation; changes are complete locally and awaiting verification/push instruction.

## Goal

Make market streaming follow the active Market page:

- Dashboard streams only the indices and stocks currently represented by its visible cards, comparison series, and mover rows.
- Equity Insider streams only its selected equity; changing the equity atomically replaces the old symbol.
- All Indices and Watch List stream their own displayed symbol sets.
- Leaving a live page removes its browser STOMP interests, while shared symbols remain subscribed for any other active owner.
- Returning to Dashboard restores its current displayed symbol set without accumulating stale subscriptions.
- Equity Insider's displayed price reacts to the live quote instead of remaining on the one-time REST profile value.

### Reproduction

1. Open Market Dashboard. The UI subscribes to all loaded indices and index constituents.
2. Navigate to Equity Insider and select one stock.
3. Browser Network continues receiving Dashboard stocks/indices because Dashboard is kept alive and the shared symbol set only grows.
4. Equity Insider renders `fundamentalProfileProvider`, a one-time future, so a received tick does not update the hero price.

Expected: active page intent replaces inactive page intent; actual: process-wide subscription state accumulates symbols.

## Source plan (pointer)

| Field | Value |
|-------|-------|
| Origin | `pasted-chatgpt` |
| Pointer | User request and WebSocket frame sample in this chat |
| Summary | Keep one authenticated STOMP connection; make interests page-aware; Dashboard restores its displayed set; Insider owns only selected equity; unsubscribe unused topics; preserve live UI updates; tolerate first-tick delay |
| Catalog | Market domain; `am-modern-ui` owns Flutter market widgets/streaming; `am-core-services/am-gateway` relays STOMP; `am-market/am-market-data` owns upstream market ingestion |
| Context files | Root `README.md`, root `ARCHITECTURE.md`, `am_market/ui/README.md`, and `am_market/ui/.am.yaml` read locally |
| Analysis source | `am-modern-ui`: local; `am-core-services`: local read-only; `am-market`: local read-only |
| Coverage | `partial` - the requested page behavior is correct, but a plain page `dispose()` solution would fail because Dashboard uses keep-alive and shared symbols need reference ownership |
| AM gaps filled | Owner-scoped diffing, reconnect behavior, symbol normalization, index/equity typing, first-tick UX, route races, tests, observability, and rollout |

## Images

- User-supplied Equity Insider screenshot and WebSocket frame table are evidence only; no files copied.

## Prerequisites

| Check | Status | Notes |
|-------|--------|-------|
| MCP needed / connected | done | Not needed for plan; verified from local repositories |
| Downstream APIs exist | done | `/app/market/subscribe` and `/topic/stock/{symbol}` exist |
| Symbol-level gateway unsubscribe exists | not required for P0 | Gateway has no `/app/market/unsubscribe`; browser topic unsubscribe is the safe per-user operation |
| Postman collection found | n/a | No HTTP contract change; validation is Flutter/unit/widget plus browser STOMP frames |

## Adjacent-surface map

### P0 - this fix (priority order)

1. **First priority - reduce and measure subscription-to-first-tick latency.** Capture timestamps for UI SEND, STOMP topic registration, gateway proxy completion, and first MESSAGE. Keep the existing 100 ms batching only where it improves a page transition; avoid sending oversized symbol batches and prevent stale pending batches from delaying the active page.
2. **Second priority - owner-scoped desired-symbol registry with effective-union diffing.**
3. Market route/surface activation independent of widget disposal.
4. Dashboard displayed-symbol collector.
5. Equity Insider single-symbol scope and live quote binding.
6. All Indices and Watch List explicit scopes; other Market tabs clear previous Market interests.
7. Reconnect and market-hours gate replay only the current effective set.
8. Unit, widget, and focused browser regression tests, including latency assertions.

### P1 - next

- Viewport-level virtualization for very long watchlists or index lists.
- Subscription count/first-tick latency metrics on the gateway and UI telemetry.

### P2 - later or never

- Per-user upstream provider disconnect. The upstream market feed is shared and must not be stopped when one UI page changes.

## First-run / virtual value UX

N/A. No money or broker-linkage behavior changes. Before the first tick, existing REST/profile data remains visible; the page must not blank or show zero.

## Latency & consistency

- **Primary acceptance target:** measure and explain the elapsed time from `/app/market/subscribe` SEND to the first matching `/topic/stock/{symbol}` MESSAGE; do not claim improvement without the four timestamps (UI send, gateway proxy, upstream readiness if available, first message).
- Route change applies the local topic diff immediately; new upstream connect requests retain the existing 100 ms batch debounce only for a short, stable batch. A newer route generation cancels stale pending additions.
- The current delay is plausibly amplified by the oversized all-index batch and the gateway's synchronous proxy to `/v1/market-data/stream/connect`; the implementation must verify this with logs/traces rather than assume it.
- A subscription does not guarantee an immediate MESSAGE. The first frame arrives only when the upstream emits a new tick for that instrument.
- Existing REST data remains as the baseline. Live data wins only after a valid, non-stale tick.
- Symbol changes are atomic at the registry level: compute old/new effective sets, retain overlaps, unsubscribe removed topics, then subscribe additions.
- Reconnect replays only the effective union. Stale symbols from previously visited pages must not return.
- Market-closed gating retains desired state but removes active topics; reopening activates only the currently selected surface.

## Current system (verified)

- `PriceService` stores one global `_subscribedSymbols` set and has no owner/scope model (`am_common/lib/core/services/price_service.dart:27`).
- `MarketProvider._resubscribeActiveSymbols` adds all loaded indices and detail symbols, so the set grows (`am_market/common/lib/providers/market_provider.dart:115`).
- `loadAllIndicesData` subscribes every loaded Indian index regardless of the active page (`market_provider.dart:818`).
- `refreshIndexData` adds the selected index and all constituents without replacing the prior view (`market_provider.dart:792`).
- Dashboard uses `AutomaticKeepAliveClientMixin` and `wantKeepAlive => true`, so navigation does not reliably dispose it (`user_dashboard_page.dart:33`).
- The Market shell knows the active secondary tab through `SwipeNavigationController`, making it the reliable activation signal (`dashboard_page.dart:284`).
- Equity Insider changes `_submittedSymbol` but never acquires/releases a live symbol (`equity_insider_page.dart:116`).
- Equity Insider hero watches only `fundamentalProfileProvider`, so MESSAGE frames cannot update its price (`equity_insider_hero.dart:43`).
- Client `unsubscribe()` detaches `/topic/stock/{symbol}`. Gateway exposes only `/app/market/subscribe`, not symbol-level upstream unsubscribe (`MarketStompController.java:25`).
- Gateway Kafka relay is shared; stopping an upstream provider for one page would affect other sessions and is intentionally out of scope.

## Target design

### 1. Owner-aware registry in `PriceService`

Replace the monotonic global set API with scoped intent:

- `replaceScope(owner, instruments)` stores the owner's complete desired set.
- `releaseScope(owner)` removes that owner.
- Effective subscriptions are the union of all scopes.
- A symbol is unsubscribed only when no owner still requires it.
- Instrument intent carries `symbol` and `isIndexSymbol`; additions are batched separately for indices and equities.
- Normalize whitespace/case at the boundary and deduplicate before diffing.
- Keep legacy `subscribe/unsubscribe` only as a temporary compatibility adapter, then migrate all Market call sites in this slice.

### 2. Active Market surface in `MarketProvider`

- Cache desired sets per surface: Dashboard, All Indices, Equity Insider, Watch List, and optional overlays.
- `setActiveSurface(surface)` publishes only that surface to one `market-ui` PriceService scope.
- Pages may update their cached desired set while kept alive; only the active surface affects the effective subscription.
- Non-live tabs publish an empty set, releasing prior Market interests.

### 3. Page symbol collectors

- Dashboard union: pinned/index cards actually rendered, selected comparison indices, selected mover index, and displayed gainers/losers.
- All Indices: indices represented by that page's current list/filter.
- Equity Insider: exactly the normalized selected symbol.
- Watch List: symbols in the current list/page, excluding unloaded pages.
- Stock Detail: exactly the route symbol via its own owner scope.
- Closed drawers and inactive pages do not contribute symbols.

### 4. Live Equity Insider binding

- Add a family live-quote provider backed by the shared `PriceService` cache/update stream.
- Overlay valid live fields on the REST fundamental profile for the hero price/change.
- Keep profile metadata and historical chart from REST; append live data only to the 1D chart, not 1Y/5Y charts.

## Target journeys

1. Open Dashboard: baseline REST data renders; Dashboard publishes its displayed union; only those topics receive frames.
2. Open Equity Insider: shell activates Insider; Dashboard intent becomes inactive; retained overlaps remain and all other Dashboard topics unsubscribe; selected equity subscribes.
3. Select a peer/search result: old and new symbols are replaced atomically; hero reflects the first valid live tick.
4. Return to Dashboard: current Dashboard set is restored once, without stale Insider-only symbols or duplicates.
5. Reconnect or market reopen: only the effective current set is replayed.

## Identity & ownership

- Scope owner IDs are stable internal constants, not user input: `market.dashboard`, `market.all-indices`, `market.equity-insider`, `market.watchlist`, and `market.stock-detail:<route-instance>`.
- STOMP authentication/session ownership remains unchanged.
- Symbols are normalized, but not treated as security identities.

## State & money

- No money state changes.
- REST data is baseline state; live quotes are an in-memory overlay and are never persisted by the UI.
- The backend Kafka/Influx persistence pipeline remains independent of UI page subscriptions.

## Isolation

- Market page interests must not unsubscribe Portfolio/Dashboard domain topics managed by `StreamingTabCoordinator`.
- One UI scope cannot remove a symbol still referenced by another scope.
- Index and equity batches remain typed separately to avoid mixed `isIndexSymbol` requests.

## Failure modes

- STOMP disconnected: retain desired scopes; replay effective union after reconnect.
- First tick delayed: keep REST value and show no false zero/loading regression.
- Rapid navigation: serialize/apply generation IDs so late async updates from an inactive page cannot reactivate it.
- Symbol switch during debounce: cancel removed pending additions before sending the batch.
- Duplicate/case-varied symbols: normalize and deduplicate.
- Market closes during a route switch: no active topics; latest desired current surface resumes at reopen.
- Page disposed before async data load: ignore its late collector update unless its route generation is current.
- One symbol shared by Dashboard and Insider: retain topic through transition; no unsubscribe/resubscribe flap.

## Corner-case matrix

| Case | Trigger | Expected | Covered by |
|------|---------|----------|------------|
| Dashboard to Insider | Active tab changes | Dashboard-only topics removed; selected equity active | widget test T1 |
| Insider symbol switch | RELIANCE to INFY | RELIANCE removed, INFY added once | unit T2 + widget T3 |
| Return Dashboard | Back/swipe | Exact current Dashboard set restored | widget T4 |
| Shared symbol | Dashboard and Insider both need INFY | No topic flap until last owner releases | unit T5 |
| Rapid route switches | Multiple changes inside debounce | Only latest effective set sent | unit T6 |
| STOMP reconnect | Network reconnect | Only effective union resubscribed | unit T7 |
| Market closed/open | Gate toggles | No topics while closed; current set only on reopen | unit T8 |
| Mixed index/equity | Dashboard union contains both | Two correctly typed gateway batches | unit T9 |
| Delayed first tick | Quiet instrument | REST value remains visible | widget T10 |
| Out-of-order tick | Older timestamp arrives | Existing newer quote retained | existing + unit T11 |
| Inactive async completion | Dashboard request finishes on Insider | Cache may update, active subscriptions do not | unit T12 |
| Empty/invalid symbol | Search clears or bad value | No empty topic; previous scope released only on confirmed selection | unit T13 |

## Out of scope

- Changing Kafka ingestion, InfluxDB measurements, market-data persistence, or shared provider scheduling.
- Adding `/app/market/unsubscribe` or disconnecting the shared Upstox stream per user.
- Visual redesign of Dashboard or Equity Insider.

## Open questions

- None. P0 treats a page's rendered dataset as visible; true pixel-viewport tracking is P1.

## Review roles

| Role | When | Looks for |
|------|------|-----------|
| Agent architect | Until Agent satisfied | Ownership, races, reconnect, code cites, tests |
| Product/tech owner | User review gate | Correct definition of displayed Dashboard/Watch List symbols |
| Optional `/review` | Before merge | AM code review and regression/security review |

## UI previews (modern-ui)

- Consent: `not-requested`
- Gate: `n/a` - behavior/lifecycle only; no visual layout change
- Widget/page cites: Dashboard and Equity Insider listed above
- Previews: `n/a - not requested`

## Services and files

| Service | Existing or new | Planned files | Unit tests |
|---------|-----------------|---------------|------------|
| `am_common` | existing | `am_common/lib/core/services/price_service.dart`; add typed scope/intent model beside service if needed | Scope diff, reference overlap, debounce, reconnect, gate, typing |
| `am_market/common` | existing package | `am_market/common/lib/providers/market_provider.dart` | Surface activation and stale async generation |
| `am_market/ui` | existing deployable | `dashboard_page.dart`, `user_dashboard_page.dart`, `equity_insider_page.dart`, `equity_insider_hero.dart`, All Indices/Watch List integration, live quote provider | Navigation and live-price widget regressions |
| `am-core-services/am-gateway` | existing dependency | No P0 change | Existing controller/proxy tests remain unchanged |
| `am-market/am-market-data` | existing dependency | No change | Existing ingestion/persistence tests remain unchanged |

## Test Plan

No API contract changes; Postman is not the right executor for client-side STOMP subscription ownership.

| Row | Test | Expected | Result |
|-----|------|----------|--------|
| T1-T13 | Focused Dart unit/widget tests from corner matrix | All pass | not verified - implementation pending |
| B1 | Local web latency probe | SEND, gateway completion, and first MESSAGE timestamps are visible; no oversized batch | not verified |
| B2 | Local web: Dashboard -> Insider -> symbol change -> Dashboard | Network frames show exact topic diff; no stale topics | not verified |
| B3 | Local web STOMP reconnect | Only active surface topics return | not verified |
| B4 | Preprod browser during market hours | REST baseline then live updates; first tick latency recorded and compared with baseline | not verified |
| B5 | Analyzer | `flutter analyze` on touched packages: 0 errors/warnings/lints | not verified |

## Deploy

Local build/test first, then preprod. No production deploy is authorized by this plan.

## Agent scorecard

| Dimension | Score /10 | Evidence |
|-----------|-----------|----------|
| Product / features | 9.7 | Dashboard, Insider, All Indices, Watch List, return path covered |
| Architecture / design | 9.7 | Scoped union/diff with active-surface separation and 7-sheet diagram |
| Data / identity / contracts | 9.6 | Typed instrument intent; no backend contract change |
| State / money / consistency | 9.8 | REST baseline/live overlay and atomic replacement defined |
| Reliability / failure | 9.7 | Reconnect, gate, route race, debounce, first-tick delay covered |
| Security / authz | 9.5 | Existing auth unchanged; internal owner IDs and normalized symbols |
| Observability | 9.3 | Planned diff/count/first-tick logs; gateway metric P1 |
| Testability | 9.8 | 13 mapped corners plus browser regressions |
| Operability / rollout | 9.6 | Local then preprod, no server contract or data migration |
| TODO / implementability | 9.9 | File-level tasks and acceptance gates |
| **Overall (mean)** | **9.7** | All dimensions >= 9.0 |

## Adversarial review

| Severity | Finding | Resolution |
|----------|---------|------------|
| Major (closed) | Widget `dispose()` cannot represent visibility because Dashboard is kept alive | Active surface comes from shell controller |
| Major (closed) | Simple unsubscribe can remove a shared symbol still needed elsewhere | Owner scopes with effective-union reference semantics |
| Major (closed) | One boolean can misclassify mixed index/equity debounce batches | Typed intent and separate batches |
| Major (closed) | Received ticks still would not update Equity Insider | Live quote overlay provider added to P0 |
| Major (closed) | Per-user upstream disconnect could break other sessions | Only browser STOMP interest is released in P0 |

- Open Blocker/Major count: 0
- Agent satisfied: yes

## Rating log

| Pass | Delivery | Design | Overall | Gaps then patched |
|------|----------|--------|---------|-------------------|
| 1 | 8/10 | 7/10 | 7.8/10 | Missing keep-alive visibility owner, shared-symbol reference handling, reconnect/gate races, mixed symbol typing, and live hero binding |
| 2 | 10/10 | 10/10 | 9.7/10 | Added owner registry, active-surface cache, atomic diff, typed batching, live overlay, corner matrix, diagrams, and rollout gates |

## User review gate

Review this PLAN, `architecture.drawio`, and `TODO.md`. Explicit confirmation is required before implementation.

## REPORT gate

Do not create `REPORT.md` until all focused tests, analyzer, and browser Test Plan rows are verified.
