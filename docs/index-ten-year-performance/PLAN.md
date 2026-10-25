# Selected-index ten-year performance

## Delivery

- **Kind:** feature (combined dashboard correction and mobile F&O interactions)
- **Lead repository / package:** `am-modern-ui` / `am_market/ui`
- **Target environment:** preprod after local verification
- **Source plan:** user report and supplied desktop/mobile screenshots. The dashboard labels its historical widget with the selected index but currently renders aggregate monthly index rankings. Desired outcome: each index selection renders that index's own monthly return history for the latest ten-year range and its overall return.
- **Catalog resolution:** `am-modern-ui` is the Market-domain Flutter monorepo; `am_market/ui` is its deployable market surface. Analysis source: local.

## Current system (verified)

- The shell is `am_app`; market presentation code is in `am_market/ui`, shared market state/API code in `am_market/common`, and design tokens in `am_design_system` (`README.md`, `ARCHITECTURE.md`).
- `UserDashboardPage` owns `selectedIndexForMovers`, changes it in `_onDashboardIndexSelected`, and passes it only as a title (`focusSymbol`) to `HistoricalPerformanceSection` (`am_market/ui/lib/features/dashboard/presentation/pages/user_dashboard_page.dart`).
- `HistoricalPerformanceSection` calls `MarketAnalysisService.getIndicesHistoricalPerformance(years: 10)` with no symbol. That request is `/v1/analysis/indices/historical-performance`, whose DTO has top/worst/all indices per month (`historical_performance_section.dart`, `market_analysis_service.dart`, `indices_performance_model.dart`). This explains the mixed-index cells in the reported screen.
- The correct existing route is `ApiService.fetchHistoricalPerformance(symbol, years: 10)`: `/v1/analysis/performance/monthly?symbol=<selected>&years=10&detailed=false`. Its `HistoricalPerformanceResponse` contains `startYear`, `endYear`, `overallReturn`, and one selected index's year/month returns (`api_service.dart`, `historical_performance_model.dart`).
- `HeatmapExplorerView` already renders that per-symbol response in the supplied "Overall Return" matrix, but it is embedded in the Market Analysis view and contains legacy raw-color styling that must not be copied into new work.

## Coverage check

**Handles, with a correction:** the user correctly identifies a wrong widget/data binding. The precise fault is not that the index selection fails; it is that the dashboard widget ignores it for the request and uses an aggregate DTO. No API or database change is needed.

## World-class feature map

| Priority | User-visible outcome |
|---|---|
| P0 | Selected index's own ten-year return matrix with NIFTY 50 initial load, mobile Option Chain Calls/Puts focus shortcuts, and compact Option Chain only expiry control using a reusable design-system submarine reveal. |
| P1 | Remember a user's last Calls/Puts horizontal focus when returning to the Option Chain during the same session. Defer until usability feedback. |
| P2 | Saved per-user F&O display preferences across devices. Outside this delivery. |

First-run: the Market dashboard starts with NIFTY 50; the F&O expiry button appears after the option chain's available expiries load. If none are available, it remains disabled with a clear unavailable label. No broker linkage or money movement is involved.

Latency and consistency: tab motion is local and must feel immediate. Selecting an expiry uses the existing cached `optionChainProvider`; while that request settles, show its existing loading/empty/error state and keep the chosen expiry label consistent with provider state. A stale symbol/expiry response must not relabel the compact control for the newer selection.

## P0 journey and acceptance criteria

1. User opens Market Dashboard: NIFTY 50 is the explicit default request target and displays a ten-year monthly return matrix for NIFTY 50, with an `Overall Return (startYear-endYear)` header.
2. User taps any available Indian index in the grid/drawer/bottom sheet: the widget immediately requests that newly selected symbol, then replaces all cells, years, header range, annual totals, and overall return with that exact index's values.
3. Fast A -> B -> C changes: only C may update the visible matrix; late A/B replies are discarded.
4. A partial current year displays unavailable future months as neutral `-` cells; an empty successful response shows an informative empty state; a failed response shows a local retry action without breaking movers, chart, or heatmap.
5. Desktop/tablet: visible 12-column monthly matrix, pinned year labels, annual-return column, keyboard/mouse horizontal access where needed.
6. Android/mobile: no clipped labels or compressed cells. A compact title/overall header plus pinned year column and horizontally scrollable month rows retains a minimum touch-friendly cell width; horizontal gesture stays inside the matrix and does not interfere with page scroll.

## Implementation design

1. Replace the dashboard use of aggregate `HistoricalPerformanceSection` with a dedicated selected-index performance widget. Do not repurpose `IndicesHistoricalPerformanceResponse` or `MonthlyPerformanceCard`; those are semantically aggregate/ranking UI.
2. The widget receives the dashboard's `selectedIndexForMovers`, whose established initial value is `NIFTY 50`, and creates a symbol-scoped request through existing `ApiService.fetchHistoricalPerformance(symbol, years: 10)`. It requests NIFTY 50 on its first mount and refreshes in `didUpdateWidget` for every later selection, uses a monotonically increasing request generation plus `mounted` checks, and never renders a response whose symbol/generation no longer matches the requested selection.
3. Render the existing `HistoricalPerformanceResponse` directly: descending years, Jan-Dec monthly values, yearly total, and positive/negative/neutral states. Use only design-system color/theme tokens (`context.colors`, `context.marketTheme`, spacing and typography); no raw colors or mock data.
4. Keep the widget self-contained so the dashboard does not add a second global MarketProvider loading channel or disturb its movers/chart/heatmap state. Reuse parsing/formatting helpers only where their data contract matches.
5. Preserve the desktop screenshot's information hierarchy: selected-index title, color-coded overall return, month header, matrix, annual return. On mobile, apply a horizontal scroll controller with semantics and a visible affordance; do not use the aggregate view's index-ranking cards or open-ranking interaction.

## Contracts, state, and non-goals

| Area | Decision |
|---|---|
| API | Reuse GET `/v1/analysis/performance/monthly`; no new endpoint, model field, migration, or auth behavior. |
| Identity | The canonical `StockIndicesMarketData.indexSymbol` selected by the dashboard is passed unchanged as `symbol`. |
| Freshness | One request per symbol transition; in-flight stale results are ignored. Existing backend response/caching behavior remains authoritative. |
| Non-goals | Altering Market Analysis, global aggregate rankings, heatmap data, top movers, chart comparison, or index selection mechanics. |

## Failure and corner-case matrix

| Case | Trigger | Expected | Covered by |
|---|---|---|
| Initial loading | Dashboard opens | Per-index loading placeholder, no fake values | widget test |
| Index switch | Tap NIFTY BANK after NIFTY 50 | Title and all values belong to NIFTY BANK | widget test |
| Stale reply | A response returns after B was selected | A is discarded | unit/widget test |
| API failure | Non-200/network failure | Local error + retry, surrounding dashboard usable | widget test |
| No history | Empty `yearlyPerformance` | Local empty state | widget test |
| Current-year gaps | Future months are absent | Neutral `-`, no fabricated zero | widget test |
| Negative/positive/zero | Monthly and overall return values | Theme-token negative/positive/neutral colors and accessible labels | widget test |
| Narrow Android | 360px-wide viewport | Pinned year/readable columns; horizontal scroll; no overflow | widget golden/layout test |

## Test plan

1. Add deterministic widget/unit coverage for response mapping, formatting, error/empty/retry, symbol update, and stale-result suppression.
2. Run formatter and `flutter analyze` for `am_market/ui` with zero diagnostics.
3. Run the touched package tests.
4. Start the local market web app and inspect desktop and 360/390px mobile emulation, then Android if an emulator/device is available: select at least NIFTY 50, NIFTY BANK, and a long-name index; verify title, overall return, all cells, scroll, and no overflow.
5. Before preprod, use the configured Postman workspace to verify the existing per-symbol endpoint returns distinct payloads for two indices; no collection mutation is required.

## Rollout and observability

- Local first; preprod only after user approval. No production deployment is in scope.
- Preserve/extend lightweight client timing/error telemetry around the new widget request if the surrounding dashboard convention supports it; do not log tokens or payloads.
- Rollback is a single UI revert; backend remains unchanged.

## P0 addendum — mobile Option Chain Calls/Puts focus

The supplied F&O screenshots identify a second, mobile-only usability improvement. This is unrelated to the index-performance endpoint and will remain isolated to the Option Chain presentation layer.

### Current system (verified)

- `OptionChainView` in `am_market/ui/lib/features/f_o/presentation/pages/option_chain_view.dart` owns `_horizontalScrollController` for the entire table. On small screens its min width is 920px and it initially jumps to the center, so Calls and Puts are both partly off screen.
- Its compact toolbar already renders equal-width `CALLS | Bid | Val | Grk | PUTS` controls, but Calls/Puts are display-only `sideBadge`s. The controller is not exposed to them.
- The controller is bound to the `SingleChildScrollView` containing the header and every option-row, so moving it shifts the entire option chain consistently without a new API request or data transformation.

### Required interaction

1. On mobile/Android only, initial table positioning remains centered around STRIKE/spot, as it is today.
2. Tapping **CALLS** animates the same horizontal table controller to its leading edge (`0`), revealing the Call-side columns as in the second screenshot.
3. Tapping **PUTS** animates the controller to its trailing edge (`maxScrollExtent`), revealing the Put-side columns; no inverse/reordered data is used.
4. A user may still swipe horizontally to any intermediate position; CALLS/PUTS are shortcuts, not a modal/filter and must not alter selected expiry, quote data, active optional column groups, or vertical/spot scrolling.
5. The controls have semantic button labels (for example, “Show call columns”) and a selected/focus treatment that reflects the last shortcut tapped. Desktop/tablet behavior stays unchanged.

### Implementation design

1. Add a small private mobile-only side-focus state (`calls`, `puts`, or none) to `OptionChainView`.
2. Convert the existing mobile Calls/Puts badges to accessible token-styled tap targets. Preserve their current green/red token semantics and touch target sizing.
3. Add a guarded `_focusOptionSide` helper: schedule after layout, check `_horizontalScrollController.hasClients`, then `animateTo(0)` for Calls or `animateTo(position.maxScrollExtent)` for Puts with a short ease-out curve. It must tolerate zero extent/data reload without throwing.
4. Keep the current center-on-new-chain behavior as initial positioning. Reset the shortcut focus when the symbol/expiry/column set changes so a stale selection state is not announced; do not fight an active user drag.
5. Add widget coverage at a 360px width for Calls -> leading edge, Puts -> trailing edge, no overflow, semantic labels, and manual-scroll compatibility. Verify on Android/emulator alongside the existing horizontal swipe hint.

### Addendum failure/corner matrix

| Case | Trigger | Expected | Covered by |
|---|---|---|---|
| Calls tap before layout | first frame/controller unattached | Safe no-op or queued post-frame focus; no exception | widget test |
| No horizontal overflow | wide/non-mobile viewport | No focus action or mobile behavior change | widget test |
| Calls tap | controller has extent | Smooth scroll to leading call columns | widget test |
| Puts tap | controller has extent | Smooth scroll to trailing put columns | widget test |
| Chain refresh | symbol/expiry changes | Existing center-on-load behavior applies; stale focus state resets | widget test |
| Manual swipe | user drags after shortcut | Scroll remains directly manipulable; no data/filter change | widget/manual test |

## P0 addendum — mobile expiry control in F&O tabs

### Screenshot intent and current code

The latest mobile screenshot shows a full-width expiry/calendar row beneath `Option Chain | Futures Contracts | Margin Calculator`. The user wants the expiry control at the right end of that tab row, directly beside Margin Calculator. The freed height should bring the Calls/Bid/Val/Grk/Puts controls and table upward.

`FoPage._buildTabDetailView` owns the three-tab `TabBar` and `TabBarView` (`am_market/ui/lib/features/f_o/presentation/pages/fo_page.dart`). `OptionChainView._buildToolbar` currently creates the full-width mobile expiry control using the `optionChainProvider` response (`expiries`, `expiry`) and `foSelectedExpiryProvider` (`option_chain_view.dart`, `fo_provider.dart`). Selecting an expiry already reloads the option chain through that provider. The F&O chart embed has no three-tab row and should retain access to its expiry control.

### Target behavior

1. On full-page mobile/Android F&O, render a compact, touch-friendly calendar/expiry button immediately to the right of Margin Calculator in the same navigation row. Show the active expiry in short form when space permits; its accessible label gives the full date. Tapping opens the existing list of available expiries, with the current expiry selected.
2. Remove the duplicate full-width expiry row from the full-page mobile Option Chain toolbar. The Calls/Puts and optional-column controls sit immediately under the tabs, so the table gains the recovered height.
3. Show the calendar control only while Option Chain is selected. Tapping or swiping to Futures Contracts or Margin Calculator makes it dive downward behind the tab-row baseline and fade/scale out; returning to Option Chain makes it rise above that line with a small settling motion. A subtle surface ripple evokes the submarine crossing the waterline. The tab row stays fixed so labels do not jump.
4. The calendar's action remains unavailable and absent from semantics after it dives out. Honor reduced-motion settings by removing or minimizing travel while still updating visibility. Rapid tab changes settle on the currently selected tab without a stranded overlay.
5. The relocation and submarine motion apply only at the existing mobile breakpoint (`AmBreakpoints.mobile`, under 600 logical pixels) on mobile web and Android. Desktop/tablet keep their current expiry placement and have no dive/rise effect. The chart-terminal embedded Option Chain keeps its own expiry selector because it has no F&O tab bar.

### Design-system motion template and color contract

- Add a public reusable `AmSubmarineReveal` in `am_design_system/lib/shared/widgets/feedback/am_submarine_reveal.dart`, export it through `am_design_system.dart`, and document a minimal usage example. It accepts `visible`, `child`, an optional theme-derived `accentColor`, and a fixed-slot/reserve-space mode for tab rows. It has no F&O or calendar dependency; other modules may wrap their own controls.
- Motion specification: **dive** (about `AppAnimations.fast` to `AppAnimations.medium`) translates the control downward through a `ClipRect` at the baseline, scales it slightly smaller, fades it, and plays one restrained surface ripple. **Surface** (about `AppAnimations.medium`) reverses the path, crests a few logical pixels above its resting position, then settles. The motion must be continuous under rapid `visible` changes, without jumping or leaving a ghost button.
- Use existing `AppAnimations` timing/curve conventions and `AppSpacing` for travel/line geometry. The ripple receives the caller's `accentColor`, defaulting to `Theme.of(context).colorScheme.primary`; it derives transparency from that color. The animation component declares **no hex colors, raw `Colors.*`, or new palette token**.
- In `am_market/ui`, the expiry button, tabs, border, text, and focus states use only `context.colors`, `context.marketTheme`, `ModuleColors.market`, and existing design-system spacing/typography. The module adds no local color constants or palette values. Positive/negative option-chain styling continues to use `context.marketTheme.positive/negative`.
- When hidden, the wrapped control is excluded from hit testing, focus traversal, and semantics. `MediaQuery` reduced-motion preference yields an immediate or near-immediate visibility change without travel/ripple. Maintain the reserved slot to prevent the tab row reflowing.

### Implementation approach

1. Extract the expiry picker from `OptionChainView` into a small reusable F&O widget, backed by the existing `optionChainProvider` and `foSelectedExpiryProvider`. Keep expiry formatting in one place. For the compact mobile variant, show a concise date/icon and open a menu or bottom sheet of API-provided expiries; never fabricate dates.
2. Implement and export the design-system `AmSubmarineReveal` template, then give the full-page F&O host a stable tab controller and compose the mobile navigation row as flexible tabs plus a fixed-width trailing expiry slot. Wrap the compact expiry button with `AmSubmarineReveal(visible: selectedTab == optionChain, accentColor: ModuleColors.market, ...)`. The selected tab index controls visibility, including swipe navigation.
3. Pass a layout mode to `OptionChainView` so it omits its existing expiry row only when the parent hosts the compact control. The embedded view continues to render the existing selector. Ensure the menu closes cleanly if the user leaves Option Chain.
4. At 360 and 390px widths, measure tab text and calendar slot to avoid overlap. If necessary, shorten only the compact visual date, while retaining full accessible text and tappable width. Verify text scaling and landscape width.

### Acceptance and tests

| Case | Expected | Verification |
|---|---|---|
| Open Option Chain on mobile | Calendar beside Margin Calculator; Calls row and chain move up | 360/390px visual/layout test |
| Open calendar | API expiry options; selected expiry highlighted and applied | widget test |
| Tap or swipe to Futures/Margin | Calendar dives/fades out, cannot receive taps, no duplicate expiry row | widget/animation test |
| Return to Option Chain | Calendar rises/fades in with current expiry intact | widget/animation test |
| Change symbol/expiry | Compact label and chain reflect response; no stale option expiry | widget test |
| Chart embed | Own expiry picker still available | widget test |
| Reduced motion, rapid tabs, text scale | Correct final visibility, no layout overflow | widget/accessibility test |
| Reusable motion template | Generic child surfaces/dips smoothly with a caller-provided theme accent, stable slot, hidden semantics, and no local color literal | `am_design_system` widget test and source audit |
| Responsive boundary | At 599px use compact mobile animation; at 600px and above use existing expiry placement without the animation | layout/widget test |

## UI previews (modern-ui)

Consent: `mentioned` — user explicitly requested a demo in the latest ask. P0 surfaces: full mobile F&O tab row and Option Chain (`fo_page.dart`, `option_chain_view.dart`). The preview is an **after-change concept for approval**, not a Flutter runtime screenshot. The [still mockup](images/preview-mobile-option-chain-after.png) shows the compact expiry control beside Margin Calculator and the chain moved upward. The [interactive demo](demo-mobile-fo.html) shows the control diving when another F&O tab is selected and resurfacing on Option Chain; it also demonstrates the CALLS/PUTS table shortcuts. All sample financial values in the demo are illustrative.

## Architect loop / scorecard

First pass: Delivery 8/10, Design 8/10, overall 8.4/10. Evidence established the route/DTO mismatch; remaining work was mobile behavior, stale-response ownership, exact tests, and failure states.

Second pass for the original dashboard correction: Delivery 10/10, Design 10/10; overall 9.6. The later F&O additions require a fresh review before implementation.

Combined feature pass: Delivery 10/10, Design 10/10. Product 9.6, Architecture 9.5, Data/contracts 9.7, State/consistency 9.5, Reliability 9.4, Security 9.4, Observability 9.2, Testability 9.5, Operability 9.4, TODO/implementability 9.7; overall 9.6. Adversarial review: expiry remains owned by the existing provider, the shared animation has no palette, mobile alone opts into the compact control, a compact control still exposes the full date to assistive technology, swiping tabs drives visibility, chart embed keeps an expiry selector, and reduced motion avoids unnecessary travel. Demo data is explicitly illustrative.

**Agent satisfied:** yes. Awaiting user review before implementation.
