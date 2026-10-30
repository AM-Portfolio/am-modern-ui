# TODO — `ipo-calendar`

Pack: `docs/ipo-calendar/`. Planning is complete; implementation is blocked on user review/confirmation.

## Plan loop

- [x] Ingest pasted source plan and define feature scope.
- [x] Resolve catalog/domain and read local context packs for `am-modern-ui` and `am-market/am-market-data`.
- [x] Verify UI button, nested route, API client, scheduler, Mongo model, Upstox mapping, controllers, and Postman collection.
- [x] Coverage check and source-boundary decision.
- [x] World-class feature map, first-run N/A, latency/consistency, corner matrix, review roles, and UI-preview gate.
- [x] Create themed multi-sheet architecture diagram.
- [x] Complete Delivery 10/10, Design 10/10, scorecard ≥9.5, and adversarial review.
- [x] **Agent satisfied: yes**.
- [ ] **User reviewed** PLAN + architecture + TODO and confirmed Execute.

## Execute after approval

### am-market-data (existing)

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

- [ ] Run focused Maven tests and Flutter tests; record results.
- [ ] Run Postman Test Plan rows in preprod (read-only except explicit nonprod fixture/sync test).
- [ ] Deploy `am-market-data` to preprod first, validate endpoint, then deploy UI to preprod.
- [ ] Obtain user approval before any production action, push, commit, or PR.
- [ ] Write `REPORT.md` only after all required tests are verified.
