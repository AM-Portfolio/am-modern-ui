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
| am-market-data | existing | Add a calendar projection DTO/service/repository query/cache invalidation/controller/OpenAPI beside existing Upstox IPO API. Do not create a scheduler or vendor client. | range/year rollover, grouping/sorting, nulls/malformed dates, dedupe, stale snapshot/cache behavior, controller schema/status |
| am-modern-ui `am_market/ui` | existing | Add IPO route, response models/client/provider, two-month screen and accessible date detail surface using theme tokens. | two-month invariant, loading/error/empty, hover/focus/tap, TBA, multiple events, route/back, responsive layout |

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

## Deploy

Default **preprod**. Release backend first, verify the endpoint with the existing Postman collection, then deploy UI. The UI remains backward-compatible until its endpoint call is live; on a backend failure it shows retryable error. No production deployment or push is authorized by this plan.

## Agent scorecard

| Dimension | Score /10 | Evidence |
|---|---:|---|
| Product / features | 9.8 | P0 journeys, explicit scope and truthful TBA semantics |
| Architecture / design | 9.7 | Verified repos, multi-sheet diagram, reuse of existing boundary |
| Data / identity / contracts | 9.8 | Stable ID, named schemas, field/null/sort/range rules |
| State / money / consistency | 9.5 | No money state; snapshot/freshness/upsert invariants stated |
| Reliability / failure | 9.7 | Scheduler/cache/read separation and user outcomes |
| Security / authz | 9.3 | Read-only existing API policy; no secrets/privileged sync exposure added |
| Observability | 9.4 | Scheduler/query invalid-date/cache/freshness logging and metrics tasks |
| Testability | 9.8 | Corner matrix maps to API and UI tests |
| Operability / rollout | 9.6 | Preprod-first, compatible order, existing Postman collection |
| TODO / implementability | 9.8 | File-level execution sequence and gates |
| **Overall (mean)** | **9.7** | all dimensions ≥ 9.0 |

## Adversarial review

| Severity | Finding |
|---|---|
| Resolved | Do not use the separate `/v1/ipo` NSE feed; UI already depends on Upstox-backed `/v1/market-data/ipo`. |
| Resolved | Do not make page loads call Upstox or trigger sync; it would be slow, rate-limited, and nondeterministic. |
| Resolved | Do not infer listing price from price band or exchange from a UI default. |
| Resolved | “Hover only” excludes touch and keyboard users; focus/tap uses the same details surface. |
| Resolved | Generic calendar component enables broad navigation; IPO feature owns a constrained two-month grid. |

- Blocker/Major count: 0

## Rating log (agent architect loop)

| Pass | Delivery | Design | Overall | Gaps then patched |
|---|---:|---:|---:|---|
| 1 | 7.0 | 6.8 | 8.1 | Verified UI/backend, scheduler data fields, source boundary, and Postman collection; added exact event semantics and contract. |
| 2 | 9.1 | 9.2 | 9.3 | Added range/time-zone, cache/freshness, null behavior, accessibility, test matrix, and rollout. |
| 3 | 10.0 | 10.0 | 9.7 | Added diagram, scorecard, adversarial review; no unresolved design question remains. |

## User review gate

After **Agent satisfied: yes**, review PLAN + architecture + TODO + UI previews (if any). Explicit confirmation is required before Execute.

## REPORT gate

Do not write `REPORT.md` until unit tests and Test Plan rows are verified.
