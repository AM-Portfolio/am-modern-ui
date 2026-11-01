# TODO — `ipo-calendar`

Pack: `docs/ipo-calendar/`. User-approved implementation is in progress; deployment remains gated.

## Plan loop

- [x] Ingest pasted source plan and define feature scope.
- [x] Resolve catalog/domain and read local context packs for `am-modern-ui` and `am-market/am-market-data`.
- [x] Verify UI button, nested route, API client, scheduler, Mongo model, Upstox mapping, controllers, and Postman collection.
- [x] Coverage check and source-boundary decision.
- [x] World-class feature map, first-run N/A, latency/consistency, corner matrix, review roles, and UI-preview gate.
- [x] Create themed multi-sheet architecture diagram.
- [x] Complete Delivery 10/10, Design 10/10, scorecard ≥9.5, and adversarial review.
- [x] **Agent satisfied: yes**.
- [x] **User reviewed** PLAN + architecture + TODO and confirmed Execute.

## Execute after approval

### IPO details header — new review gate

- [x] Read and map the approved HTML demo against the current desktop/mobile IPO details screen, DTO, nested navigation, and shared theme components.
- [x] Specify reusable breadcrumb and numeric flame meter contracts, responsive behavior, multiple investor tags, and the missing/invalid/over-range data matrix in PLAN.
- [ ] User reviews the new details-header addendum and approves Flutter implementation. Earlier approval covered the landing-list slice, not this new details design-system slice.
- [x] Add and export a theme-aware `AmNavigationTrail` from `am_design_system/lib/shared/widgets/navigation/am_navigation_trail.dart`, with callback-driven navigation, focus/semantics, and narrow-width ellipsis.
- [x] Add and export a reusable `AmValueMeter` from `am_design_system/lib/shared/widgets/feedback/am_value_meter.dart`, with numeric scaling, token-resolved colors, a contained animated flame, reduced-motion support, truthful overflow, and focused tests/examples.
- [x] Match the approved HTML meter geometry: 5px track, approximately 32px flame thumb, fill ending at the flame center with no low-value gap, 65% flame above/35% below the bar, vertical-only animation, 0×/20×/40×/60×/80×/100× annotations, endpoint clamping, resize recalculation, and no duplicate pointer/connector.
- [x] Add IPO-specific subscription string parsing and investor-category normalization; parser behavior is guarded for zero, blank, malformed, >100, duplicates, and multiple labels.
- [x] Compose the breadcrumb, wrapped investor tags, and meter in the IPO top header across desktop/tablet/mobile; keep detail loading/error escape and the current mobile tabs.
- [x] Remove the bottom `IpoSubscriptionStatusCard` and `IpoEligibleInvestorsCard` placements on desktop and mobile; preserve documents, registrar actions, timeline, browser back, and details ID flow.
- [x] Run focused design-system and IPO tests/analyzers; complete a successful local production web build and HTTP smoke check.
- [ ] Compare the local web build against the approved demo at desktop/tablet/mobile sizes and dark/light/brand themes.

### IPO landing list redesign (current request)

- [x] Extend IPO provider loading to fetch all pages for `open`, `upcoming`, `closed`, and `listed`; deduplicate by provider IPO id and surface incomplete-list errors.
- [x] Add the All-tab ordering: closing today first, then active/upcoming IPOs by ascending bidding close date, then TBA dates, with closed/listed records last.
- [x] Keep existing All/Open/Closing Today/Upcoming/Closed capsules plus Mainboard/SME/Industry/search filtering semantics in both views; preserve server capsule counts separately from loaded result counts.
- [x] Add cards/table toggle immediately after Mainboard and SME on desktop/tablet; cards remain the default on each page load, mobile stays card-only, and both available views expose the same summary fields.
- [x] Show bidding open and close dates on initial list rows/cards; render subscription only when `totalSubscription` is present.
- [x] Route card/table actions through the current IPO details route/popup without changing its behavior.
- [x] Normalize dates with an injectable Asia/Kolkata clock; handle invalid dates, stale nonterminal dates, exact-full pages, repeated pages, maximum-page guards, and malformed ids.
- [x] Define deterministic duplicate precedence (`listed > closed > open > upcoming`) without merging conflicting records.
- [x] Prevent the UI list path from falling through to the current live Upstox provider/sync behavior; return a controlled read-only error when no persisted snapshot is available.
- [x] Add focused unit coverage for pagination semantics, ordering, filters, subscription omission, toggle parity, popup preservation, and read-only fallback.

### am-market-data (existing)

- [x] Add or expose a read-only paginated list path for UI consumption that does not fall through to live Upstox or asynchronous Mongo writes on cache/Mongo miss; preserve the existing admin sync path separately.
- [ ] Create named calendar response/event/month/day DTOs in the existing IPO model layer; document nullable listing fields and `operationId: getIpoListingCalendar` in OpenAPI.
- [ ] Add a repository/query service projection over `upstox_ipos` for the server-computed `Asia/Kolkata` `[current-month, month-after-next)` interval; group/sort exactly two months and defensively dedupe by `_id`.
- [ ] Add `GET /v1/market-data/ipo/calendar` to `UpstoxIpoController`; use existing response/auth/error conventions. No Upstox request or sync trigger on GET.
- [ ] Add bounded calendar-cache read/invalidation after successful existing sync; record query/cache/invalid-date observability. Check preprod query plan before adding the proposed date index.
- [ ] Add unit/controller tests for the backend rows in PLAN.
- [ ] Add/update **Market Data API → IPO Operations → GET IPO Listing Calendar** in live Postman; maintain the existing collection and resolved `Pre-Prod` environment.

### am-modern-ui `am_market/ui` (existing)

- [ ] Add calendar models, API client method, and Riverpod provider bound to `MarketDataSdkService`; no direct HTTP/provider calls and no hardcoded IPO data.
- [ ] Make the landing-page calendar control semantic/clickable and open/close a temporary overlay IPO calendar widget over the existing page; no separate route/page or persistent below-list widget.
- [ ] Build an IPO-specific calendar widget plus month/date/event widgets with theme tokens only; show one month at a time, switch between current/upcoming, and never expose previous/next month navigation.
- [ ] Implement anchored desktop hover/focus/click details and touch/click details with Escape/outside-close; show at most two IPOs at once with wheel/arrow paging, date navigation, TBA values, and navigation to existing details.
- [ ] Implement loading, error/retry, empty-calendar, and last-updated disclosure states.
- [ ] Add Flutter unit/widget/golden coverage for the PLAN matrix.
- [ ] Run `flutter analyze` for `am_market/ui` with 0 errors, warnings, and lints; locally build/serve the web UI for user testing.

## Verify and release after implementation

- [x] Run focused Maven tests and Flutter tests; record results in the implementation handoff.
- [ ] Resolve unrelated pre-existing `am_market/ui` analyzer errors and rerun the full package analyzer; focused IPO analysis is clean.
- [ ] Run Postman Test Plan rows in preprod (read-only except explicit nonprod fixture/sync test).
- [ ] Deploy `am-market-data` to preprod first, validate endpoint, then deploy UI to preprod.
- [ ] Obtain user approval before any production action, push, commit, or PR.
- [ ] Write `REPORT.md` only after all required tests are verified.
