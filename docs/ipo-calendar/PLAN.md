 # PLAN — `ipo-calendar`

| Field | Value |
|---|---|
| Kind | feature |
| Slug | ipo-calendar |
| Lead repo | am-modern-ui |
| Other repos | am-market (`am-market-data`) |
| Target env | preprod |
| Branch | `feature/ipo-calendar` |
| Delivery rating | 10/10 |
| Design rating | 10/10 |
| Scorecard overall | 9.7/10 |
| Agent satisfied | yes |

Execute gate: **Delivery 10 + Design 10 + overall ≥ 9.5 + all dims ≥ 9.0 + Agent satisfied: yes** + user confirm.

## Goal

Make the currently inert **IPO Calendar** button on the IPO landing screen open a temporary overlay widget over the existing IPO page, matching the existing index-comparison overlay pattern. The widget presents exactly one Indian-market-calendar month at a time, with a two-button switch between the current month and the next month; it never exposes a previous-month view. Clicking Back, close, outside the panel, or the toolbar button again dismisses it. Each listing date reveals a compact, bounded details surface showing at most two IPOs at a time, with paging/scroll controls for more IPOs and previous/next date controls. It supports hover, keyboard focus, click, and touch. Each item includes the provider-supplied listing price when known and listing exchange. An IPO announced now for next month is visible after the scheduled Upstox sync persists it.

## Scope expansion — IPO details header (approved HTML, planning only)

Source pointer: the user-approved [IPO details demo](./demo/ipo-details-inline-subscription.html) and the subsequent request to move its generic meter and breadcrumb into `am_design_system`. This addendum supersedes the earlier *unchanged details presentation* constraint for this screen; it retains the existing IPO ID, detail fetch, navigation stack, timeline, documents, and registrar actions. The current request authorizes a plan, not Flutter implementation. Coverage of the existing pack was partial: the landing redesign was covered, but the details-header composition, shared contracts, theme response, and multiple investor categories were not.

### Current system, verified

- Catalog: `am-modern-ui` is the existing Flutter monorepo in the Market domain. `am_market/ui` is the deployable UI package; `am_design_system` is the shared package in the same git root. Sources: root `README.md`, `ARCHITECTURE.md`, `am_market/ui/.am.yaml`, and the catalog's `domains.md`/`repos.md`. No new service, API, or schema is needed.
- `IpoDetailsScreen` in `am_market/ui/lib/features/ipo/screens/ipo_details_screen.dart` fetches `ipoDetailsProvider(ipoId)`, then renders a standalone desktop back icon, `IpoOverviewHeaderCard`, `IpoTimelineStepper`, documents, registrar, and two lower subscription/investor cards. Mobile repeats both lower cards in the Overview tab, with identity/back controls outside its metrics card.
- `IpoOverviewHeaderCard` in `am_market/ui/lib/features/ipo/widgets/ipo_overview_header_card.dart` owns desktop identity, symbol/board/industry tags, open countdown, and eight facts. Its mobile `metricsOnly` and `lotSizeOnly` paths are separate; no subscription meter or breadcrumb exists there today.
- `AsraxIpoDetailsDto` in `am_market/ui/lib/features/ipo/models/ipo_models.dart` already supplies nullable `totalSubscription` and `List<AsraxInvestorCategoryDto>? eligibleInvestors` (`category`, `subscription`). The details API client and provider already supply the DTO; the feature must not infer unknown investor categories.
- `am_design_system` exports `AmBackButton`, `AmStatCard`, `AppColorsTheme`, `ThemeColorExtensions`, and `ModuleColors`. `AmStatCard` supports a basic progress fraction but does not provide the compact flame meter, 0×/100× scale, overflow semantics, or the required token-only styling. No shared breadcrumb was found. Both proposed primitives therefore belong in `am_design_system`, then are exported from `am_design_system.dart`.
- Theme source: `context.colors` resolves the active `AppColorsTheme` extension, including surface, border, text, and divider tokens. `ModuleColors.market` is the market accent and is brand-synced by global theme selection; the market-only `context.marketTheme` extension also exists. The shared package must not import the market UI package. `IpoCenterHost` has a nested Navigator; the current card/table helper pushes `IpoDetailsScreen` on that nearest Navigator, so `Navigator.of(context).pop()` returns to the IPO list in the normal flow.

### Approved demo translated to production

| Demo element | Flutter owner and binding | Behavior |
|---|---|---|
| `IPOs › {company}` inside top card | Shared `AmNavigationTrail` hosted by `IpoOverviewHeaderCard` | `IPOs` calls the supplied list-navigation callback; current label comes from the fetched detail DTO; narrow widths ellipsize the current label and keep the parent action reachable. |
| Initials, name, legal name, symbol, SME/Mainboard, industry | Existing IPO header and `IpoBoardBadge` | Retain provider values and existing theme treatment; avoid inventing a legal company name when the API has none. |
| One or many category tags after industry | IPO header adapter over `eligibleInvestors` | Trim blank categories, dedupe case-insensitively while preserving first-seen order, then `Wrap` tags after industry. Show only category names (e.g. `HNI`, `Retail`, `QIB`); no “Eligible investors” heading or empty-list assertion. |
| Overall subscription panel with animated flame, 0×/100× scale | Shared numeric `AmValueMeter` hosted in the top card | IPO adapter parses `totalSubscription`, supplies label, suffix `×`, max 100, current market accent, and semantic value. Keep bar and flame contained within panel; the flame animation moves subtly without changing the data value. |
| Status/countdown and eight key facts | Existing IPO header, fact grid | Retain data-driven status/countdown and facts; ensure width and wrapping accommodate the meter. |
| Important Dates, Documents, Registrar Details | Existing `IpoTimelineStepper`, `IpoDocumentsCard`, `IpoRegistrarCard` | Keep their data bindings and real document/contact actions. The HTML uses sample data only; it is not a runtime fixture. |
| Bottom subscription and investor cards | `IpoDetailsScreen` composition | Remove their placements on desktop and mobile after the header exposes the information. Retain shared source data; do not delete potentially reusable classes as part of the layout change. |

### Reusable design-system contracts

- `AmNavigationTrail` in `am_design_system/lib/shared/widgets/navigation/am_navigation_trail.dart`: a list of `AmNavigationTrailItem(label, onTap?)` or equivalent typed items; the final item is current/noninteractive. It supplies separator, keyboard focus, tooltips, accessible labels, and ellipsis from shared theme tokens. Routing is owned by each caller's callback; the shared widget does not assume a root route or call `Navigator.pop()` itself. Embed it in the parent content surface with no extra card/margin. This is the standard breadcrumb navigation pattern with a clearer public component name.
- `AmValueMeter` in `am_design_system/lib/shared/widgets/feedback/am_value_meter.dart`: required finite numeric `value`, positive finite `maxValue`, label, optional suffix/formatter, optional `accentColor`, `showFlame` or marker variant, and semantic value label. Default accent is `Theme.of(context).colorScheme.primary`; IPO passes `ModuleColors.market` during build. Background, border, text, track, and flame contrast derive from `context.colors`/`ThemeData` on every build. The market package passes its module accent; other modules can pass their own accent and data without copying IPO layout or parsing code. No raw hex, `Colors.*`, cached theme color, or brand-specific constant in the component.
- Meter truth: progress is `clamp(value / maxValue, 0, 1)`, with `maxValue=100` for the IPO presentation. The readout shows the uncapped finite value and `×`. A value above 100 fills the track and retains the real number (plus an accessible beyond-scale description); it must not report `100×` as the actual reading. A small visual minimum for the flame hit area may keep `0.87×` visible, but the fill, spoken value, and scale remain mathematically accurate. Zero remains zero; negative, NaN, and infinity are rejected by the feature adapter. Label is `Overall subscription`, scale is `0×` and `100×` as approved.
- Flame: a single vector flame shape inside the track, filled from the active accent plus a contrast token. Animate a restrained sway/pulse only; position is derived from value and clamped so it cannot clip at 0 or 100. Honor `MediaQuery.disableAnimations`/accessible navigation and platform reduce-motion settings; animation must stop while offstage or when disabled. Expose one semantic meter value, hide decorative flame from screen readers.
- IPO parsing is outside the shared widget: accept provider strings such as `0.87`, `0.87x`, or `0.87×` after trimming; reject empty, malformed, negative, NaN, and infinity. Omit the meter for unknown data instead of showing an invented `0×`. Keep explicit `0` visible. Do not derive the overall rate by summing category subscriptions.

### Approved HTML meter visual contract

The implementation must reproduce the current reference file [`demo/ipo-details-inline-subscription.html`](./demo/ipo-details-inline-subscription.html):

- Use one compact rounded panel with `Overall subscription` on the left and the live value with the `×` suffix on the right. Do not add a second subscription card, duplicate flame, separate pointer, connector, or eligibility heading inside this meter.
- Use a thin 5px horizontal rounded track. The active fill must end at the flame's center so low values such as `0.87×` never show a gap between the fill and flame.
- The flame is the slider thumb. Its horizontal center is the clamped value position, and the track remains behind it. The marker is approximately 32px square and vertically offset so about 65% sits above the bar and about 35% overlaps below it.
- Animate only a restrained vertical breathing/flicker. No sideways rotation, lateral blinking, detached pin, or extra pointer. Reduced-motion mode keeps the same marker static.
- Annotate the scale below the track at `0×`, `20×`, `40×`, `60×`, `80×`, and `100×` with evenly spaced ticks. Values above `100×` clamp visually but retain their true numeric readout and accessible overflow description.
- Any low-value visibility minimum affects only the marker/fill endpoint; it must not change the numeric value, scale labels, or semantic progress. Explicit `0×` remains visible at the left boundary.
- Recalculate marker and fill positions when the panel/header resizes. Keep the meter usable beside long IPO names and multiple investor tags.
- Resolve panel, text, track, fill, glow, contrast, and border colors from active global/module theme tokens on every build. No hardcoded cyan, raw hex, cached theme color, or IPO-specific color is permitted in the reusable component.

### Responsive journeys and state

- Desktop: nested breadcrumb at the top edge of the header; identity left, meter toward the right, status/countdown at the far right; facts remain below the divider. Documents and registrar remain the only lower information cards. The small vertical gap above the header follows the demo.
- Tablet/narrow width: header wraps its meter onto a second line aligned to the right, then facts wrap using their existing layout logic. No horizontal overflow or overlap with a long company name or many category tags.
- Mobile: place breadcrumb, identity/status, investor tags, and meter in a compact top header visible before tab content. Preserve the current three functional tabs (`Overview`, `Lot Size`, `Documents`) and their scroll positions. The Overview retains facts/timeline/registrar but no lower subscription or investor cards. This preserves mobile task navigation while applying the demo's top-of-page hierarchy.
- Breadcrumb's `IPOs` action pops the nearest IPO details route when possible; direct/deep entry without a previous route navigates to the IPO list route through an IPO-owned callback. Existing browser back and mobile back gestures should resolve to the same list. While details load or fail, an `IPOs` escape remains available.
- The widget reads `Theme.of(context)` and `context.colors` inside `build`, so dark/light/brand changes update surfaces, text, fill, flame, and tags immediately; no stateful caching of colors and no static cyan. Verify the app shell and standalone market host because `MarketThemeExtension` is registered separately in standalone Market UI.

### World-class feature map

| Priority | Outcome |
|---|---|
| P0 | Approved header placement, breadcrumb to list, reusable shared components, exact detail data, multiple category tags, compact responsive layout, removal of both bottom cards. |
| P1 | Accessible keyboard/screen-reader navigation and meter semantics; reduced-motion behavior; theme-switch and >100× truth tests. |
| P2 | Cross-module adoption examples in component documentation; no new endpoint or live subscription streaming in this slice. |

### Failure and corner matrix

| Case | Trigger | Expected | Verification |
|---|---|---|---|
| No detail payload / request error | detail fetch fails | Existing retry state plus working list breadcrumb | details widget test |
| Missing subscription | null/blank/malformed string | Meter omitted; other header content stays aligned | parser + widget tests |
| Explicit zero | `0` or `0x` | `0×` is visible with zero progress and contained flame | parser + meter test |
| Over-range subscription | `100.01` or `136x` | Full track, true readout, overflow semantic, no marker clipping | meter test |
| Invalid numeric | negative/NaN/infinity | No fake rate or crash | parser test |
| Investor categories absent | null/empty/blank categories | No category tags and no generic eligibility claim | header test |
| Many categories | duplicates/long strings | Stable dedupe, wrapped tags, no horizontal overflow | narrow widget test |
| Nested/direct navigation | normal list push or direct details entry | `IPOs` returns to list in both routes; keyboard activation works | navigation test |
| Theme changes | dark/light/brand swap while open | Accent, track, background, contrast, text update in place | design-system widget test |
| Motion preference | animations disabled / offstage | Static visible flame, no ticker leak | meter lifecycle test |
| Very narrow viewport / large text | 320px, text scale | Breadcrumb and tags remain readable; no overflow | responsive widget test |

### Delivery sequence and test plan

1. Add shared breadcrumb and value meter with public exports, component examples, numeric/scale semantics, theme tokens, animation lifecycle, and focused design-system tests. Reuse existing typography, spacing, radius, and `AppColorsTheme` accessors.
2. Add the IPO-only string parser and category normalizer. Feed numeric rate and current `ModuleColors.market` to the shared meter; feed category labels to the existing tag treatment. No API change.
3. Compose the header across desktop/tablet/mobile, keep nested breadcrumb navigation and loading/error escape, and remove lower subscription/investor card placements. Keep timeline, documents, registrar, and mobile tabs functional.
4. Verify focused design-system tests, IPO parser/widget/navigation tests, targeted analyzers, and a local web run at desktop/tablet/mobile widths. Compare against the approved HTML in dark and light/brand themes; verify long names, multiple investors, missing data, and browser back. Resolve unrelated package analyzer baseline separately if still present.

First-run/broker semantics: not applicable to this read-only IPO details view; absent market data is explicitly omitted. Latency/consistency: the header uses the existing single details request and renders no invented interim value; stale provider values follow existing detail fetch behavior. Security: the breadcrumb only invokes existing local navigation and does not add an endpoint or access to restricted data. Observability: retain the existing details request/error path; no new backend telemetry required. UI preview consent: the user supplied and approved the HTML demo; no new bitmap preview is requested. Review gate: present this addendum and its architecture update for approval before Flutter implementation.

### Details addendum review and rating

| Pass | Delivery | Design | Overall | Finding |
|---|---:|---:|---:|---|
| 1 | 8/10 | 7/10 | 8.2/10 | Initial demo pointer exposed missing shared APIs, numeric scale truth, theme switching, and the mobile tab distinction. |
| 2 | 10/10 | 10/10 | 9.7/10 | Verified repository contracts and navigation, specified reusable APIs and edge matrix, and added the `DetailsFlow` architecture sheet. |

Scorecard for this addendum: Product 9.8, Architecture 9.7, Data/contracts 9.8, State/consistency 9.6, Reliability 9.7, Security 9.5, Observability 9.4, Testability 9.8, Operability 9.6, TODO/implementability 9.9; mean **9.7/10**. Agent satisfied: **yes**, subject to user review of this new slice before implementation.

Adversarial check: a 100× scale makes a 0.87× fill nearly invisible, so the flame marker receives a visible clamped hit area while numeric progress and semantics stay exact. `AmStatCard` would bring unrelated visual behavior and hardcoded colors; the new meter reads active tokens. Multiple category tags wrap and dedupe without inventing categories. A navigation trail cannot assume a root Navigator because IPO Center embeds one. A brand switch must rebuild with the synced module accent. The initial static HTML is a visual reference, not a source for hardcoded production values. No remaining blocker or major design gap was found.

## Scope expansion — IPO landing list redesign (current request)

This addendum extends the existing `ipo-calendar` pack to cover the redesigned landing list while preserving the existing IPO details interaction. The HTML review prototype is [`demo/index.html`](./demo/index.html).

### Source pointer and coverage

| Field | Value |
|---|---|
| Origin | current user request in this conversation, 1 Nov 2026 IST |
| Request | Keep the card view as default; add a table/card toggle after Mainboard and SME; show subscription only when supplied; keep all existing status/board/industry filters; order **All** as closing-today first, then dated active/upcoming IPOs ascending by bidding close date, TBA active IPOs, and closed/listed IPOs last; do not change the existing IPO detail popup or its navigation behavior. |
| Coverage | partial before this addendum — calendar behavior was planned, but list pagination, listed-status inclusion, subscription visibility, view state, and All ordering were not. |
| Decision | Reuse the existing `/v1/market-data/ipo` contract and its `pageNumber`/`records` parameters, but harden the UI list path so cache/Mongo misses do not trigger a live vendor sync or database write. No new deployable service or database write is required by the UI itself. |

### P0 — landing list

- Cards remain the initial view on every landing-page load. The table/card control is placed immediately after the Mainboard and SME controls, matching the updated demo; view state is local to the page and is not persisted.
- On mobile widths, the table/card control is omitted and the landing list is forced to the card view; the desktop/tablet selection remains local and responsive.
- The existing status capsules remain the same: All, Open, Closing Today, Upcoming, and Closed. Board and Industry filters keep their current semantics and operate in either view.
- The client loads every required page for `open`, `upcoming`, `closed`, and `listed`, deduplicates by provider IPO id, and never treats the count endpoint as the list itself. The Closed capsule includes both `closed` and `listed`, matching the current KPI label.
- Only the All result applies the new ordering: (1) open IPOs whose bidding end date is today in `Asia/Kolkata`; (2) remaining non-closed IPOs with a valid bidding end date ascending; (3) non-closed IPOs with no bidding end date; (4) `closed` and `listed` IPOs last. Name/id is the deterministic tie-breaker.
- Card and table rows expose the same summary fields: company/symbol, board, status, price band, issue size, bidding open date, bidding close date, and subscription when available. A missing subscription is omitted, not rendered as `TBA`, `0x`, or an inferred value.
- Clicking a card or table-row action continues through the current IPO details route and popup behavior unchanged. This slice does not redesign, replace, or alter the existing details popup.

### P1 — resilience and polish

- Show a loading state while all status pages are being collected, and a retryable list error if the aggregate request cannot produce a trustworthy result. Do not silently present an incomplete All list as complete.
- Show a compact result count based on the loaded deduplicated list, separate from the server KPI counts; expose no fabricated total when a status page failed.
- Keep the table horizontally scrollable on narrow screens and keep the card view single-column on mobile.

### P2 — later or never

- Persisting the user's preferred view across sessions, changing the existing details popup, changing the server's count definition, live subscription streaming, and a new combined all-status endpoint are outside this slice unless performance evidence requires a follow-up.

### Current system evidence for the new scope

- [`ipo_providers.dart`](../../am_market/ui/lib/features/ipo/providers/ipo_providers.dart) currently loads only `open`, `upcoming`, and `closed`; each request is caught independently and `listed` is not requested.
- [`ipo_api_client.dart`](../../am_market/ui/lib/features/ipo/data/ipo_api_client.dart) currently sends only `status`, even though the backend accepts `pageNumber` and `records`.
- [`ipo_kpi_stats_bar.dart`](../../am_market/ui/lib/features/ipo/widgets/ipo_kpi_stats_bar.dart) displays `counts.closed + counts.listed` under the single Closed label.
- [`ipo_landing_screen.dart`](../../am_market/ui/lib/features/ipo/screens/ipo_landing_screen.dart) currently renders a 20-item client-side page, which cannot expose server pages that were never fetched.
- [`ipo_summary_card.dart`](../../am_market/ui/lib/features/ipo/widgets/ipo_summary_card.dart) owns the existing card-to-details navigation and must remain the behavioral source for the detail flow.
- [`UpstoxIpoController.java`](../../../am-market/am-market-data/market-data-api/src/main/java/com/am/marketdata/api/controller/UpstoxIpoController.java) accepts `pageNumber` and `records` (default 30); [`UpstoxIpoService.java`](../../../am-market/am-market-data/market-data-service/src/main/java/com/am/marketdata/service/ipo/UpstoxIpoService.java) caps a requested page at 100 but currently falls through from Mongo/Redis to a live provider and async persistence on a miss.
- `UpstoxIpoService.getIpos` currently falls through to a live Upstox provider and asynchronously persists summaries when cache/Mongo has no content; the landing-list read path must not inherit that vendor-call/write behavior for four concurrent status streams.
- `ipoMatchesFilter` currently derives `Closing Today` from the process-local `DateTime.now()` and a string prefix; the new comparator/filter must normalize dates against an injectable `Asia/Kolkata` clock.
- The existing filter state also includes search text, so the redesign must preserve search semantics even though the visible request emphasizes capsules, board, and industry.

### Implementation handoff — landing-list slice

- Reused the existing market-themed `AppSegmentedControl` for the Cards/Table toggle and extended the shared `AdaptiveDataTable` with theme tokens plus horizontal scrolling for this use case; no feature-local replacement of an existing design-system primitive was introduced.
- Implemented the cards/table landing list, complete paginated status aggregation, deterministic All-tab ordering, IST date normalization, optional subscription rendering, and the existing details-route navigation.
- Added the backend `cacheOnly` read path so UI list reads do not fall through to Upstox or asynchronous persistence on a cache/Mongo miss; the existing live/sync path remains available to its current callers.
- Focused IPO analysis and tests pass. The full `am_market/ui` analyzer still reports unrelated pre-existing workspace errors outside this feature and is not represented as clean.

### Landing-list state and data contract

- `viewMode`: `cards | table`, initial value `cards`, UI-only.
- `statusFilter`: existing values; `All` invokes the special ordering, other capsules retain current filtering behavior.
- `subscription`: use the provider's existing `totalSubscription` summary field; null/blank means the field is not rendered.
- `biddingEndDate`: parse as an ISO date for ordering; invalid/blank values sort after dated active IPOs and before closed/listed only when the IPO is not closed/listed.
- `status`: `closed` and `listed` are both terminal for All ordering and the Closed capsule; no status is inferred from dates in the client.
- `ipoId`: provider-stable id remains the dedupe and details-navigation identity; company name and symbol are not identities.

### Landing-list latency and consistency

- Fetch pages per status with the existing bounded `records <= 100` contract. Stop a status stream when a page is shorter than the requested page size; never loop indefinitely.
- Fetch independent status streams concurrently, then dedupe and sort once. The UI shows skeletons until the aggregate is ready so users do not mistake the first page for the complete list.
- Redis/Mongo remain the intended backend read path and the scheduled Upstox sync remains the ingestion path. Because the current service has a live-provider fallback on cache/Mongo miss, implementation must add/use a read-only list path for the UI (or make the existing path explicitly cache/Mongo-only); a normal page load must not call Upstox or mutate the database.
- Fetching all terminal pages is deliberately traded for a complete All result: the first render may wait longer than the current first-page-only screen. Requests run concurrently by status, sequentially by page within a status, with skeletons and cancellation of obsolete refreshes; the UI never labels a partial result as complete.
- If one required status stream fails, the UI reports an incomplete-list error with Retry rather than silently dropping that status and showing a misleading All result.

### Adversarial review pass 2 — trade-offs and resolved gaps

- **Pagination termination:** request pages with `records=100`; a short page ends a status stream. If a page is exactly full, request one more page. Apply a configured maximum-page guard and a repeated-page/id-fingerprint guard; reaching either guard produces an incomplete-list error instead of an infinite loop or silently truncated All list.
- **Conflicting duplicate records:** deduplicate by stable `ipoId`. When the same id appears in multiple status streams, choose the terminal status in this order: `listed`, `closed`, `open`, `upcoming`; within the same status prefer the record with the greatest field completeness, then the first stable page result. Do not merge values from different records or deduplicate by name/symbol.
- **Date/time correctness:** normalize ISO timestamps/dates to an `Asia/Kolkata` calendar date before filtering or sorting. The ordering is: open-and-closing-today; all other nonterminal records with valid dates ascending (including stale past-dated records, which remain provider-status-driven); nonterminal missing/invalid dates; `closed`/`listed` last. Use an injectable clock for tests around midnight IST and UTC-offset inputs.
- **Unknown status and malformed identity:** preserve unknown status for display but place it in the nonterminal ordering buckets; skip blank/malformed ids with telemetry, and treat an all-invalid page as a failed/incomplete result rather than creating synthetic identities.
- **Filter/count drift:** apply status, board, industry, and existing search filtering before All sorting. Capsule counts remain server snapshot counts; the result count is the loaded, deduplicated, filtered count. The UI must not imply these values are guaranteed equal when snapshots change or duplicate statuses are collapsed.
- **Subscription semantics:** trim whitespace; an explicit numeric value such as `0` is real data and remains visible, while null/blank/missing values are omitted. The table SUB header is shown only when the current filtered result has at least one supplied value; individual missing cells remain blank and are not replaced with `TBA` or `0x`.
- **View/pagination state:** changing Cards/Table preserves the active filters and current logical page; changing filters or refreshed data resets/clamps the page so the user never sees an empty out-of-range page. Cards and table use the same `ipoId` action and the existing `IpoSummaryCard` details route behavior.
- **Table sorting trade-off:** this slice implements the product-defined All ordering only; column-header sorting is intentionally not added because it would override the requested lifecycle order. It is a later product decision, not an implicit behavior.
- **Overlay coexistence:** the cards/table control must not close, replace, or alter the existing calendar overlay or IPO details route. If a view change occurs while an overlay is open, the overlay keeps its own state and the existing details action remains unchanged.

### Landing-list corner matrix

| Case | Trigger | Expected | Covered by |
|---|---|---|---|
| More than one server page | Closed/listed count exceeds 30 | all pages load; UI list can exceed 30; client page size remains 20 | provider unit; UI Test 8 |
| Listed records | API returns `listed` separately from `closed` | Closed capsule and All include listed records exactly once | provider unit; UI Test 9 |
| Closing today | open IPO `biddingEndDate` equals today's IST date | appears before other active IPOs only on All | ordering unit; UI Test 10 |
| Active date order | multiple active/upcoming end dates | ascending bidding-close date; TBA after dated active entries | ordering unit; UI Test 10 |
| Terminal records | status `closed` or `listed` | always last on All; preserved in Closed filter | ordering/filter unit; UI Test 9 |
| Missing subscription | summary has null/blank `totalSubscription` | no subscription metric/cell/placeholder for that IPO | widget test; UI Test 11 |
| View toggle | user selects Table then Cards | same filtered set and detail action; Cards is default on reload | widget/integration test; UI Test 12 |
| Existing detail flow | card/table action clicked | current IPO details popup/route opens unchanged | integration test; UI Test 13 |
| Partial status failure | one paginated status request fails | retryable incomplete-list state; no false complete All result | provider/widget test; UI Test 14 |
| Narrow viewport | mobile/tablet width | cards collapse; table scrolls without clipped content | golden/integration test; UI Test 15 |
| Exact-full terminal page | a status page returns exactly 100 records | one bounded follow-up page is requested; no terminal records are omitted | pagination unit; UI Test 16 |
| Repeated/over-limit page | API repeats a page or exceeds configured page guard | stop safely and show incomplete-list Retry state | pagination unit; UI Test 17 |
| Duplicate status record | same `ipoId` appears in closed and listed/open responses | one row; terminal precedence is deterministic | dedupe unit; UI Test 18 |
| Invalid identity | blank/missing `id` in a response item | skip and record telemetry; all-invalid result is not shown as complete | parsing/provider test; UI Test 19 |
| IST boundary | UTC timestamp crosses midnight in Asia/Kolkata | Closing Today and All ordering use the IST date, not browser local date | date utility test; UI Test 20 |
| Stale active date | nonterminal IPO has a bidding close date before today | remains provider-status-driven and follows the documented nonterminal date order | ordering unit; UI Test 21 |
| Existing live fallback | cache/Mongo miss would trigger vendor fallback | UI list path stays read-only or returns controlled Retry; no UI-triggered sync | backend service test; UI Test 22 |
| Counts/list mismatch | server KPI snapshot changes during list fetch | capsules retain server counts; loaded result count stays truthful and separately labelled | integration test; UI Test 23 |
| Mixed subscription data | some filtered rows have subscription and others do not | header appears when applicable; missing rows have no fabricated cell value | widget test; UI Test 24 |
| Toggle during overlay | calendar/details surface is open while view changes | existing overlay/details behavior remains unchanged | integration test; UI Test 25 |

## Source plan (pointer)

| Field | Value |
|---|---|
| Origin | pasted-chatgpt |
| Pointer | user request in this conversation, 27 Oct 2026 IST |
| Summary | Wire the existing button; show only current + next month; show IPOs by date; desktop hover details; include listing price and exchange where available; use the existing Upstox scheduler; avoid duplicates; introduce a dedicated calendar read endpoint only if it improves the UI contract. |
| Catalog | Market domain: `am-modern-ui` Flutter web owns `am_market/ui`; `am-market/am-market-data` owns the existing market-data API, Upstox integration, scheduler, Mongo, and Redis. |
| Context files | `am-modern-ui/README.md`, `am-modern-ui/ARCHITECTURE.md`, `am-modern-ui/am_market/ui/README.md`, `.am.yaml`; `am-market/README.md`, `am-market/am-market-data/README.md`, `.am.yaml`. The UI uses Riverpod and `MarketDataSdkService`; `am-market-data` is Spring Boot with modular API/service/scheduler layers and Mongo/Redis. |
| Analysis source | am-modern-ui: local; am-market/am-market-data: local |
| Coverage | partial — the desired UX and dedicated read endpoint are valid, but the scheduler already stores the required source fields and must be reused, not duplicated. |
| AM gaps filled | explicit event semantics, immutable two-month window, mobile/keyboard behavior, cache/freshness, no-data/error states, contract precision, dedupe invariant, rollout and tests. |

## Images

- `images/` — user supplied IPO-page reference screenshots remain in this conversation; no generated preview requested.

## Prerequisites (done / pending / blocked)

| Check | Status | Notes |
|---|---|---|
| Existing scheduler/data source | done | `UpstoxIpoSyncScheduler` calls `UpstoxIpoService.syncUpstoxIpos`; persisted details include `timeline.listingDate`, `listingPrice`, and `listingExchange`. |
| Stable dedupe key | done | Mongo `upstox_ipos` uses Upstox IPO `id` as `_id`; Spring `save` is an upsert. |
| Existing API test collection | done | Postman **Market Data API** → **IPO Operations** already has list/detail/sync/counts. Add one Calendar request there; do not create another collection. |
| Shared test environment | done | `Pre-Prod` is the resolved preprod environment. |
| Index decision | pending implementation verification | Prefer a compound Mongo index on `timeline.listingDate` + `id` only after checking the collection/query plan in preprod; it is a performance optimization, not a new source of truth. |

## World-class feature map

### P0 — this slice

- A clickable, semantic IPO Calendar control opens/closes a temporary overlay widget over the existing IPO page; no separate page or route is required.
- The widget derives exactly two selectable months in `Asia/Kolkata`: current and next. It renders one month at a time with labelled Current/Upcoming month buttons. No previous/next/year controls.
- A date cell has an event marker and event count only when an IPO has a valid scheduled **listing date**. Hover/focus/click opens a compact, non-clipping detail surface; touch/click opens the same detail on mobile. Each item links to the existing IPO detail page.
- The detail surface shows a maximum of two IPOs per view. Arrow buttons and wheel/scroll paging move through the remaining IPOs; date navigation buttons move to the previous/next date that has listings.
- A dedicated, read-only `GET /v1/market-data/ipo/calendar` response shaped for the two-month calendar, served from persisted Upstox documents only. It carries `windowStart`, `windowEndExclusive`, `asOf`, `lastSyncedAt`, and grouped month/date events.
- Listing details are truthful: `listingPrice` is shown only when supplied; otherwise **Listing price: TBA**. `listingExchange` is shown as supplied, otherwise **Exchange: TBA**. The UI must never infer a listing price from the issue price band.
- Upstox scheduler reuse: normal calendar loads do not call Upstox. Existing nightly distributed lock and stable-ID upsert remain the only ingestion path; refresh shows cached/persisted data and its freshness.

### P1 — next

- A compact “last updated” disclosure and a retry action after an API failure.
- Pre-warm/invalidate a bounded Redis calendar read cache immediately after a successful IPO sync, with a short TTL and the two-month window key.
- Deep link to a particular IPO calendar date when the app’s router supports URL state.

### P2 — later or never

- Historical months, arbitrary month navigation, a separate calendar route/page or persistent below-list widget, reminders/watchlists, calendar export, or a live price feed. These conflict with the two-month-only scope or require a separate product decision.

## First-run / virtual value UX

N/A. IPO calendar is public market-information UI; it has no broker linking, money, trading, or seeded value.

## Latency & consistency

- The response reads Mongo (with optional bounded Redis read cache), never invokes Upstox on user navigation. The UI loads one response, displays a skeleton for both panels, and offers Retry on transport/server failure.
- Freshness is scheduler-bound: startup sync handles `open` and `upcoming`; the locked nightly sync handles `all`. A newly announced next-month IPO appears after the next successful relevant sync, not as a speculative client-side record. `lastSyncedAt` makes that lag visible.
- If Mongo is unavailable or the calendar cache is cold and cannot be populated, return a controlled 5xx and show a retryable error; do not silently call the vendor from a UI request. An empty successful response is a valid “No IPO listings announced for these two months” state.
- The two-month range is computed once on the server in `Asia/Kolkata`, returned in the body, and consumed as-is by the client; this prevents client clock/time-zone boundary disagreement.

## Current system (verified)

- [`ipo_landing_screen.dart`](../../am_market/ui/lib/features/ipo/screens/ipo_landing_screen.dart) renders the existing visual calendar control as a `Container` with no tap handler.
- [`ipo_center_host.dart`](../../am_market/ui/lib/features/ipo/screens/ipo_center_host.dart) owns the embedded IPO navigator and currently routes only list and details.
- [`ipo_api_client.dart`](../../am_market/ui/lib/features/ipo/data/ipo_api_client.dart) already uses `MarketDataSdkService` for `/v1/market-data/ipo`; the new client call belongs beside it, with a Riverpod provider beside existing IPO providers.
- [`UpstoxIpoSyncScheduler.java`](../../../am-market/am-market-data/market-data-scheduler/src/main/java/com/am/marketdata/scheduler/UpstoxIpoSyncScheduler.java) starts open/upcoming sync and runs `all` nightly under a tracked distributed lock.
- [`UpstoxIpoService.java`](../../../am-market/am-market-data/market-data-service/src/main/java/com/am/marketdata/service/ipo/UpstoxIpoService.java) persists full detail by stable `id`, including timeline, listing price, and listing exchange; [`UpstoxIpoDocument.java`](../../../am-market/am-market-data/market-data-service/src/main/java/com/am/marketdata/service/model/UpstoxIpoDocument.java) maps to `upstox_ipos`.
- [`UpstoxIpoController.java`](../../../am-market/am-market-data/market-data-api/src/main/java/com/am/marketdata/api/controller/UpstoxIpoController.java) already owns the `/v1/market-data/ipo` endpoint family. The unrelated `/v1/ipo` NSE feed must not be mixed into this calendar.

## Target journeys

1. User opens IPOs and presses **IPO Calendar**. A temporary overlay panel opens over the current page and shows the current IST month; a toggle switches to the next month.
2. User hovers/focuses/clicks a marked date on desktop, or taps it on touch. A compact anchored details surface shows two IPOs at a time with name/symbol, board/status, listing price or TBA, exchange or TBA, and a View details action.
3. User uses the popover paging controls or mouse wheel to browse more than two IPOs, and date controls to move between dates with listings without closing the widget.
4. On 27 October, an IPO whose valid `listingDate` is in November is returned in the Upcoming month view after a successful sync—even if its current status is `upcoming`. Missing/invalid listing dates produce no calendar event.
5. Empty, stale, loading, and failed states remain understandable without fabricating an IPO or an inferred price.

## Identity & ownership

- This is anonymous/read-only market data under the existing market API access policy; no user-owned resource is created.
- `ipoId` is the provider-stable Mongo `_id` and the only event identity. Do not deduplicate by mutable company name, symbol, or listing date.
- The server owns `asOf`, the current/next-month computation, and `lastSyncedAt`; the client formats them but does not alter the range.

## State & money

- No user money, allocation, application, or trade state changes.
- Each calendar event is one projected persisted IPO; it contains scheduled listing metadata, not an assertion that a listing price already exists. `null` price/exchange are first-class states.

## Isolation

- Dedicated calendar projection reads only `upstox_ipos`, retaining the Upstox source boundary used by the existing UI.
- No data is written by the endpoint, Flutter route, hover/focus/tap actions, or Postman regression request.

## API contract

`GET /v1/market-data/ipo/calendar` — no date-range query parameters; server pins exactly the current and next `Asia/Kolkata` months.

```json
{
  "windowStart": "2026-10-01",
  "windowEndExclusive": "2026-12-01",
  "asOf": "2026-10-27",
  "lastSyncedAt": "2026-10-27T00:00:00Z",
  "months": [
    {
      "month": "2026-10",
      "days": [
        {
          "date": "2026-10-29",
          "events": [{
            "ipoId": "provider-stable-id",
            "companyName": "Example IPO",
            "symbol": "EXAMPLE",
            "issueType": "regular",
            "status": "upcoming",
            "listingPrice": null,
            "listingExchange": "NSE,BSE"
          }]
        }
      ]
    }
  ]
}
```

- Named OpenAPI schemas: `IpoCalendarResponse`, `IpoCalendarMonth`, `IpoCalendarDay`, `IpoCalendarEvent`; `operationId: getIpoListingCalendar`.
- `months` always contains two objects in chronological order, including empty months; days and events are sorted ascending. `listingPrice` and `listingExchange` are nullable. `date`/`month` use ISO calendar values.
- Repository query bounds use ISO `YYYY-MM-DD` lexical ordering, reject malformed dates at mapping/query time, and defensively remove duplicate `ipoId` values before response construction.

## Failure modes

- A vendor outage affects the scheduler, not the on-demand calendar read; retained persisted data remains visible with its timestamp.
- A scheduler failure retains its prior data, records the error via existing scheduler/service logs, and leaves the freshness timestamp unchanged.
- Unknown date, no IPOs, missing price/exchange, API timeout, and overlapping popovers each have explicit expected UI behavior in the matrix below.

## Corner-case matrix

| Case | Trigger | Expected | Covered by |
|---|---|---|---|
| Month boundary | 31 Dec / 1 Jan or client clock differs | server returns current + next IST month, including year rollover; UI renders exactly returned months | service unit; API Test 1; Flutter unit |
| Future announced IPO | `upcoming` record has next-month `timeline.listingDate` | appears once in next-month day; no price is invented | service unit; API Test 2; Flutter widget |
| Missing listing date | provider omits/null/malformed timeline listing date | excluded from calendar, logged/metric counted; no crash | service unit; API Test 3 |
| Multiple IPOs on date | day has 2+ distinct IDs | count marker and one scroll-safe popover list; each item opens correct details | service unit; Flutter widget |
| Unknown listing details | `listingPrice`/`listingExchange` null | show TBA fields, not a price band/default exchange | mapper unit; Flutter widget; API Test 4 |
| Duplicate sync/input | same provider ID appears in repeated sync/result | one Mongo document and one calendar event | sync/service unit; API Test 5 |
| Scheduler/vendor miss | sync fails after prior success | calendar serves persisted snapshot with unchanged freshness; no vendor call on GET | service/scheduler unit; API Test 6 |
| API/read failure | 5xx/network error | two-panel skeleton then error with retry, no stale fake data | Flutter widget |
| Touch/keyboard | no hover device or keyboard focus | tap/click/focus opens accessible details; Escape/tap outside closes it | Flutter widget/integration |
| Narrow viewport | mobile width | exactly two labelled pages/tabs, no third/previous month and no clipped popover | Flutter golden/widget |

## Out of scope

- Application/bidding/allotment/refund calendar events, historical month browsing, user reminders, trades, and price streaming.
- Changing the upstream Upstox sync cadence or adding a second provider/scheduler.
- Rewriting the general-purpose design-system calendar.

## Open questions

- Decided: a calendar event means **scheduled exchange listing date**, not every IPO lifecycle milestone. This aligns with the requested listing price/exchange information and next-month listing example.
- Decided: display is read-only and anonymous; existing detail navigation provides deeper context.
- Decided: use `Asia/Kolkata` as market time zone and no month selection controls.

## Review roles

| Role | When | Looks for |
|---|---|---|
| Agent architect | complete | Repo evidence, contract, two-month invariant, failure/corner coverage |
| You (product / tech owner) | review gate | Listing-date semantics, popover density, P0/P1 scope, TBA wording |
| Optional `/review` | later | Code and contract review before merge |

## UI previews (modern-ui)

- Consent: `not-requested`
- Gate: pass — feature, visible IPO surface, modern-ui in scope.
- Widget/page cites: `IpoLandingScreen`, proposed `IpoCalendarScreen`.
- Previews: `n/a — not requested`.

## Services

| Service | Existing or new | Impl notes | Unit tests in this slice |
|---|---|---|---|
| am-market-data | existing | Add the calendar projection beside the existing Upstox IPO API and expose/harden a read-only paginated list path for UI consumption. Do not create a scheduler or vendor client; keep admin/vendor sync separate. | range/year rollover, grouping/sorting, nulls/malformed dates, dedupe, stale snapshot/cache behavior, read-only miss behavior, controller schema/status |
| am-modern-ui `am_market/ui` | existing | Preserve the current IPO details route/popup. Add paginated status loading, All ordering, subscription-aware summary fields, cards/table view state, and the calendar surface using theme tokens. | list pagination/dedupe, All ordering, filters, missing subscription, cards/table parity, default cards, unchanged detail action, loading/error/empty, responsive layout |

## Test Plan (Postman or MCP)

Collection: **Market Data API** (`33502037-fe53d633-c028-4d76-9029-0b85eafb13dc`) → existing **IPO Operations** folder; add **GET IPO Listing Calendar**.  
Shared Postman env: preprod → **Pre-Prod** (resolved); production is not in scope.

| Row | Request or MCP call | Method + path | Expected | Owning service | Result |
|---|---|---|---|---|---|
| 1 | Current two-month window | `GET /v1/market-data/ipo/calendar` | 200; two chronological months; exact IST bounds; named body fields | am-market-data | not verified |
| 2 | Upcoming next-month IPO fixture | same | one event at its `listingDate` even with `status=upcoming` | am-market-data | not verified |
| 3 | Missing/invalid date fixture | same | 200; record absent; response shape remains valid | am-market-data | not verified |
| 4 | Null price/exchange fixture | same | nullable values retained—not substituted with issue price/BSE | am-market-data | not verified |
| 5 | Repeated sync / stable ID fixture | sync then GET (nonprod only) | one event per `ipoId` | am-market-data | not verified |
| 6 | Retained snapshot after vendor/sync failure | GET after controlled failure fixture | persisted response/freshness behavior matches contract; no UI-triggered vendor call | am-market-data | not verified |
| 7 | Browser UI flow | IPO list → Calendar → date details → IPO details → Back | correct route and two-month/mobile/accessibility behavior | am-modern-ui | not verified |
| 8 | Paginated All list | `GET /v1/market-data/ipo?status={open,upcoming,closed,listed}&pageNumber=...&records=100` | every page is collected; loaded result count is separate from KPI count | am-modern-ui | not verified |
| 9 | Listed/closed terminal records | same list calls | Closed includes `closed` + `listed`; each stable IPO id appears once | am-modern-ui | not verified |
| 10 | All ordering | Browser UI flow with closing-today, dated, TBA, and terminal fixtures | closing today first; remaining active dates ascending; TBA next; closed/listed last | am-modern-ui | not verified |
| 11 | Subscription visibility | Browser UI flow with present and missing `totalSubscription` | subscription renders only when supplied; no fabricated placeholder/value | am-modern-ui | not verified |
| 12 | Cards/table toggle | Browser UI flow → toggle after Mainboard/SME | cards are default; both views preserve filters, fields, and result set | am-modern-ui | not verified |
| 13 | Existing IPO details behavior | Browser UI flow → card/table action → close/back | current details popup/route and behavior remain unchanged | am-modern-ui | not verified |
| 14 | Partial status-page failure | Browser UI with one required status request failed | retryable incomplete-list state; no misleading complete All list | am-modern-ui | not verified |
| 15 | Narrow viewport | Browser UI at mobile/tablet widths | cards collapse; table scrolls; no clipped required fields | am-modern-ui | not verified |
| 16 | Exact-full page boundary | paginated list fixture with 100 records on page 1 | page 2 is requested; all records remain available | am-modern-ui | not verified |
| 17 | Pagination guard | repeated page or configured maximum-page fixture | bounded stop with incomplete-list Retry state | am-modern-ui | not verified |
| 18 | Conflicting duplicate status | same id returned by multiple status streams | listed > closed > open > upcoming precedence; one row | am-modern-ui | not verified |
| 19 | Invalid identity payload | item has blank/missing id | malformed item is skipped; all-invalid result fails safely | am-modern-ui | not verified |
| 20 | IST date boundary | UTC timestamp around midnight IST | Closing Today and ordering use Asia/Kolkata date | am-modern-ui | not verified |
| 21 | Stale active date | open/upcoming item has an end date before today | provider status is preserved; deterministic nonterminal ordering applies | am-modern-ui | not verified |
| 22 | Read-only list fallback | cache/Mongo miss fixture | no UI-triggered Upstox call or write; controlled Retry when no snapshot | am-market-data | not verified |
| 23 | KPI/list snapshot drift | counts and list are read from changing snapshots | server capsule counts and loaded result count remain separately truthful | am-modern-ui | not verified |
| 24 | Mixed subscription rows | filtered result contains present, zero, blank, and null subscription values | explicit zero is shown; blank/null is omitted; table header behavior is correct | am-modern-ui | not verified |
| 25 | Overlay coexistence | toggle while calendar/details surface is open | existing overlay and details route behavior is unchanged | am-modern-ui | not verified |

## Deploy

Default **preprod**. Release backend first, verify the endpoint with the existing Postman collection, then deploy UI. The UI remains backward-compatible until its endpoint call is live; on a backend failure it shows retryable error. No production deployment or push is authorized by this plan.

## Agent scorecard

| Dimension | Score /10 | Evidence |
|---|---:|---|
| Product / features | 9.8 | P0 journeys, explicit scope and truthful TBA semantics |
| Architecture / design | 9.7 | Verified repos, multi-sheet diagram, reuse of existing boundary |
| Data / identity / contracts | 9.8 | Stable ID, named schemas, field/null/sort/range rules |
| State / money / consistency | 9.5 | No money state; snapshot/freshness/upsert invariants stated |
| Reliability / failure | 9.8 | Read-only fallback decision, bounded pagination, cancellation, and user outcomes |
| Security / authz | 9.3 | Read-only existing API policy; no secrets/privileged sync exposure added |
| Observability | 9.4 | Scheduler/query invalid-date/cache/freshness logging and metrics tasks |
| Testability | 9.9 | Expanded matrix maps date, pagination, identity, count-drift, overlay, and UI tests |
| Operability / rollout | 9.6 | Preprod-first, compatible order, existing Postman collection |
| TODO / implementability | 9.9 | File-level execution sequence, read-only backend gate, and explicit guards |
| **Overall (mean)** | **9.7** | all dimensions ≥ 9.0; implementation and execution tests remain pending |

## Adversarial review

| Severity | Finding |
|---|---|
| Resolved | Do not use the separate `/v1/ipo` NSE feed; UI already depends on Upstox-backed `/v1/market-data/ipo`. |
| Resolved | Do not make page loads call Upstox or trigger sync; it would be slow, rate-limited, and nondeterministic. |
| Resolved | Do not infer listing price from price band or exchange from a UI default. |
| Resolved | “Hover only” excludes touch and keyboard users; focus/tap uses the same details surface. |
| Resolved | Generic calendar component enables broad navigation; IPO feature owns a constrained two-month grid. |
| Resolved | Existing `getIpos` can fall through to live Upstox and an async Mongo write; the plan now requires a read-only UI list path or controlled error on snapshot miss. |
| Resolved | Full-page pagination could loop or truncate on exact-full/repeated responses; the plan now requires a page cap, fingerprint guard, and follow-up page after an exact-full page. |
| Resolved | Browser-local date logic could disagree with market date; the plan now requires an injectable Asia/Kolkata clock and offset-aware normalization. |
| Resolved | Duplicate IDs across status streams could produce nondeterministic fields; the plan now defines terminal-status precedence and no cross-record field merge. |
| Resolved | Table sorting could conflict with lifecycle ordering; column sorting is explicitly out of scope for this slice. |

- Blocker/Major count: 0

## Rating log (agent architect loop)

| Pass | Delivery | Design | Overall | Gaps then patched |
|---|---:|---:|---:|---|
| 1 | 7.0 | 6.8 | 8.1 | Verified UI/backend, scheduler data fields, source boundary, and Postman collection; added exact event semantics and contract. |
| 2 | 9.1 | 9.2 | 9.3 | Added range/time-zone, cache/freshness, null behavior, accessibility, test matrix, and rollout. |
| 3 | 10.0 | 10.0 | 9.7 | Added diagram, scorecard, adversarial review; no unresolved design question remains. |
| 4 | 10.0 | 10.0 | 9.7 | Adversarial pass added read-only fallback, pagination guards, duplicate precedence, IST normalization, count drift, stale dates, overlay coexistence, and mapped tests. |

## User review gate

After **Agent satisfied: yes**, review PLAN + architecture + TODO + UI previews (if any). Explicit confirmation is required before Execute.

## REPORT gate

Do not write `REPORT.md` until unit tests and Test Plan rows are verified.
