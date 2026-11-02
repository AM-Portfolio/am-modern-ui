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

## P1 addendum — glass treatment for dashboard monthly performance

### Source and scope

The user-provided Market Dashboard screenshot shows the index heatmap and the selected-index historical monthly performance one after the other, with different visual surface treatments. The request is to make the historical monthly performance widget feel glassmorphic and consistent with the heatmap. This is a presentation-only update to the existing dashboard widget. The ten-year selected-index request, response mapping, cell values, selection behavior, and Market Analysis page are outside this visual change.

### Current system (verified)

- `UserDashboardPage` currently wraps both `DashboardAnalysisHeatmapPanel` and `SelectedIndexPerformanceMatrix` in the same explicit `MarketColors.cardSurface` / `MarketColors.borderDefault` `Container` (`am_market/ui/lib/features/dashboard/presentation/pages/user_dashboard_page.dart`).
- The monthly matrix paints each positive/negative return cell with `context.marketTheme.positive/negative` at alpha 0.55, while the dashboard heatmap uses the lighter semantic `MarketColors.positiveBg/negativeBg` fills and subtle accent borders (`selected_index_performance_matrix.dart`, `index_heatmap_panel.dart`, `market_colors.dart`). This makes the month matrix read as a solid block even though its outer wrapper is similar.
- `am_design_system` exports `GlassCard`; its default variant derives its fill, border, and blur styling from the active theme (`am_design_system/lib/shared/widgets/display/glass_card.dart`). Reuse this existing component instead of introducing a new glass surface or raw palette values.
- The matrix already handles desktop and narrow-screen layouts separately. The visual treatment should work at both sizes and under the active light/dark theme; existing mobile horizontal scrolling remains unchanged.

### Implementation plan

1. Replace only the dashboard's historical-performance flat wrapper with the existing theme-aware `GlassCard`, preserving the current spacing and matrix content. Avoid nesting a second card or changing the heatmap wrapper.
2. Adjust monthly and annual-return cell fills to use the same semantic positive/negative background tokens as `IndexHeatmapTile`, with a theme-token border for definition. Keep neutral/unavailable cells theme-derived. Do not apply per-cell backdrop blur; there can be up to 130 cells, and the glass effect belongs on the section surface while the cells remain readable, efficient tints.
3. Keep the current overall-return header colors, text hierarchy, 10-year data, loading/error/empty states, and scroll behavior intact. Do not add local color constants or hardcoded hex/`Colors.*` values.
4. Compare the heatmap and monthly matrix together in dark and light theme at desktop and 360/390px mobile widths. Check that the card surface reads as glass, cell values remain legible, the annual-return emphasis remains clear, and horizontal scrolling still works.

### Acceptance and verification

| Case | Expected | Verification |
|---|---|---|
| Dashboard dark theme | Monthly widget has a translucent, bordered glass surface that visually belongs with the heatmap | Desktop and mobile visual check |
| Dashboard light theme | Glass surface and return tints derive from light theme tokens with readable text | Theme visual check |
| Positive / negative / neutral / missing cells | Heatmap-consistent semantic tints; no fabricated values or lost labels | Existing matrix widget test plus source review |
| Responsive matrix | Existing year pinning, month scrolling, and 360/390px layout remain intact | Existing narrow-width widget coverage / visual check |
| Data and selection | Selected symbol and all displayed returns are unchanged | Existing selection and response tests |

**Architecture impact:** none. This reuses the existing dashboard widget, theme tokens, and design-system card; no API, data, provider, or navigation flow changes are proposed.

**Plan status:** ready for user review; implementation has not started.

## P1 addendum — filter Futures Contracts by selected underlying

### Current behavior (verified)

- `FoPage` stores the active F&O instrument in `foActiveSymbolProvider` and the header shows that selected symbol (`fo_page.dart`).
- `futuresContractsProvider` sends the active symbol as a free-text `queries` value to `InstrumentSearchCriteria`, then returns the instrument-search results after quote enrichment (`futures_provider.dart`, `am_market/sdk/lib/market/model/instrument_search_criteria.dart`). The SDK documents this endpoint as semantic text search combined with filters, so the query is not an exact-underlying guarantee.
- The visible contract table filters expired rows and the selected expiry month only. Its existing `All` chip means all expiry months; no filter checks `underlying_symbol`, `asset_symbol`, or the contract's exact trading symbol (`futures_contracts_table_widget.dart`). The supplied NIFTY 50 screenshot therefore shows cross-index results because unrelated returned results are not narrowed to the selected underlying.

### Target behavior and implementation plan

1. Add a separate **Underlying** filter to the Futures Contracts list. Its default is the active F&O symbol (for example, NIFTY 50); include an explicit **All underlyings** option for users who intentionally want the broader search results. Keep the existing expiry-month filter as a distinct control so `All expiries` cannot be confused with `All underlyings`.
2. Filter from instrument metadata using a canonical underlying matcher: prefer explicit `underlying_symbol` / `asset_symbol` fields, then use a deliberate exact alias mapping or exact parsed contract root from `trading_symbol` when metadata is absent. Do not use substring matching (`NIFTY` would incorrectly match NIFTY 50, BANKNIFTY, NIFTYNXT50, FINNIFTY, and MIDCPNIFTY). Do not treat a broad search query as proof that a contract matches.
3. Default/reset the underlying selection to the currently active F&O symbol when the user changes the symbol. Preserve the selected expiry filter only if its month/year still exists for the new underlying; otherwise reset expiry to all available expiries.
4. Keep quote enrichment and contract selection intact. Selecting a row still drives the existing selected-contract details, chart, open-interest, depth, and margin views. The optional All-underlyings choice changes only the list scope and must not replace the active F&O symbol or header.
5. On mobile, keep the underlying and expiry controls compact and distinct (for example, a small underlying selector plus the existing horizontally scrollable expiry pills); avoid adding a full-width filter row that pushes the contract list unnecessarily far down. On desktop, keep both filters clearly labeled.
6. If the selected underlying has no matching contracts, show a selected-underlying-specific empty state with a way to switch to All underlyings. If contract metadata is insufficient to safely identify its underlying, exclude it from the selected-only results and keep it available under All underlyings.

### Acceptance and verification

| Case | Expected | Verification |
|---|---|---|
| Open F&O with NIFTY 50 selected | Futures list contains NIFTY 50 futures only; BANKNIFTY, NIFTYNXT50, FINNIFTY, MIDCPNIFTY are absent | Provider/widget regression test |
| Select another index | List updates to that exact underlying and expiry choices match it | Provider/widget test |
| Choose All underlyings | All valid search results return, still sorted and filtered by the expiry selection | Widget test |
| Expiry filter | All/individual month behavior remains independent of underlying scope | Widget test |
| Ambiguous or missing metadata | No unrelated contract leaks into selected-only results; broad mode remains inspectable | Unit test for canonical matching |
| No futures for selected underlying | Clear empty state offers the All underlyings choice without clearing the page's active symbol | Widget test |
| Selected contract and dependent panels | Row selection continues updating existing details and analytics | Regression test |
| Mobile and desktop | Filters remain legible and compact; contract list stays usable at narrow widths | Responsive visual/layout check |

**Architecture impact:** UI/provider filtering over the existing instrument-search response; no new endpoint or backend change is proposed. Confirm the actual populated underlying metadata fields in representative search results before finalizing the alias matcher.

**Plan status:** ready for user review; implementation has not started.

## P1 addendum — keep Spot visible during mobile side focus

### Current behavior and screenshot intent

- The spot-price line is built inside the horizontally scrolling table content (`_buildSpotPriceLine` in `option_chain_view.dart`). Horizontal focus therefore moves the line with the columns instead of keeping it at the viewport's foreground.
- `_focusOptionSide` always scrolls to the corresponding extreme and records the selected side; tapping PUTS repeatedly does not return to the initial landing position.
- The user wants the spot price to remain above the moving columns, like a foreground layer, while a focused view exposes four complete columns. Tapping the currently focused side again (CALLS or PUTS) should restore the normal first-open view. The earlier three-column home-view requirement remains the return target.

### Target behavior and implementation plan

1. Move the spot line/price pill out of the horizontally scrolling content and render it as a foreground overlay spanning the mobile table viewport. Tie its vertical position to the actual spot row and the vertical strike-list scroll, but keep its x-position fixed to the viewport. It must draw above table columns and ignore pointer input so horizontal and vertical swipes still reach the table.
2. On the first CALLS or PUTS focus action, animate the horizontal viewport to a clean side-focused position that shows exactly four complete columns, with no partial neighboring column slivers. Keep the rest of the columns available by manual horizontal swipe. Compute the alignment from laid-out column widths and the active optional groups; do not use a fixed pixel offset. The existing Calls/Puts buttons remain shortcuts, not column filters.
3. Make both side shortcuts symmetric toggles: tapping CALLS or PUTS focuses that side; tapping the currently focused side again clears focus and returns to the same three-column home alignment used on initial mobile load. Tapping the opposite side switches directly to its four-column focus. After a manual swipe, tapping the focused side again still returns home.
4. Recompute and apply the home/side alignment once after a new symbol or expiry response lays out. Do not let asynchronous alignment override a later user drag, optional-column change, or a newer chain response. Keep current vertical spot centering and desktop/tablet behavior unchanged.
5. Respect reduced-motion settings for the horizontal transition, avoid animating to an unattached/zero-extent controller, and clear focus state when the symbol/expiry key changes.

### Acceptance and verification

| Case | Expected | Verification |
|---|---|---|
| Mobile spot overlay | Spot line and pill stay above the columns and span the viewport during horizontal movement | 360/390px visual and scroll test |
| Vertical strike scroll | Overlay tracks the spot row vertically and remains aligned to its strike location | Widget interaction test |
| CALLS / PUTS first tap | Clean four-column focused viewport for the selected side; no adjacent partial columns | Widget/layout test |
| Same-side second tap | Either CALLS or PUTS returns to the initial three-column home alignment | Widget test |
| Opposite-side tap | Switches directly between Calls and Puts focus without an intermediate home snap | Widget test |
| Manual horizontal swipe | Columns move under the spot overlay; swipe remains responsive | Widget interaction test |
| Manual swipe, optional groups, and data refresh | Focus alignment uses current column geometry; same-side return works after a swipe; stale callbacks cannot snap the newer/manual position | Widget regression test |
| Loading / empty / no spot row | No invalid overlay, stale spot pill, or scroll exception | Widget edge-state test |
| Desktop/tablet | Existing spot-line/table layout and behavior remain unchanged | Responsive boundary check |

**Plan status:** ready for user review; implementation has not started.

## P1 addendum — clean three-column initial Option Chain viewport

### Current behavior (verified)

- On mobile, `OptionChainView` renders five default columns: Calls OI, Calls LTP/change, Strike, Puts LTP/change, and Puts OI. The initial minimum width is 520 logical pixels, and the scroll controller centers the whole table (`option_chain_view.dart`).
- Since the centered viewport does not align with the three central columns' boundaries, the screenshot shows partial edges of Calls OI and Puts OI beside the desired quote/strike columns.
- The existing mobile Calls and Puts shortcuts intentionally move to the table's leading and trailing edges. Manual horizontal swiping is also supported.

### Target behavior and implementation plan

1. On first display of a mobile option-chain response, position the horizontal viewport so it shows exactly these three default columns, edge-to-edge: **Calls LTP/change | Strike | Puts LTP/change**. Do not show slivers of either OI column.
2. Calculate the start/end offsets from the actual laid-out column flex widths and row padding in the existing `LayoutBuilder`; do not hardcode pixel offsets. Size the default mobile table width as needed so the 4:2:4 flex span of the three target columns fills the viewport while preserving readable values. If an unusually narrow viewport cannot meet that and minimum readable widths simultaneously, retain the minimum column widths and let the table scroll.
3. Keep Calls OI and Puts OI in the table and accessible by swipe and the existing Calls/Puts focus shortcuts. This is an initial viewport alignment change, not a data-column removal or filter.
4. Apply the same three-column initial alignment on a new symbol/expiry response, once after layout. Do not re-snap after rebuilds, optional-column toggles, or manual scrolling. Preserve the current vertical spot-price centering.
5. Limit the behavior to mobile/Android (`AmBreakpoints.mobile`). Desktop/tablet layout and starting position remain unchanged.

### Acceptance and verification

| Case | Expected | Verification |
|---|---|---|
| Initial mobile load, default columns | Only Calls LTP/change, Strike, and Puts LTP/change are visible; no OI slivers | 360/390px layout + visual check |
| Symbol/expiry changes | View resets once to the same three-column band after the new chain lays out | Widget test |
| Manual swipe / Calls / Puts shortcut | Other columns remain reachable; shortcuts still reach both ends | Existing interaction tests plus regression test |
| Optional columns toggled | No automatic snap or loss of user scroll position | Widget test |
| Desktop/tablet | Existing columns and initial position unchanged | Responsive boundary test |
| Narrow width and text scale | No overflow; readable values with horizontal access if minimums require it | Layout/accessibility check |

**Plan status:** ready for user review; implementation has not started.

## P0 correction — sticky STRIKE column on mobile Option Chain

### Source, scope, and coverage correction

The user's latest mobile screenshots show the intended behavior: in the normal view, STRIKE sits between Calls and Puts; when the user scrolls toward Puts, the **entire STRIKE column** (header and every strike value) stays at the left edge; when scrolling toward Calls, it stays at the right edge. The existing plan covered only the Spot line and capsule. That coverage was **partial**. This is a mobile/Android presentation fix in `am_market/ui`, using the existing chain data and scroll controllers. The earlier plan for a foreground Spot line remains in place, but it does not satisfy this STRIKE requirement by itself.

### Current system (verified)

- `OptionChainView` places its header `Row` and strike-row `ListView.builder` together inside one horizontal `SingleChildScrollView` (`am_market/ui/lib/features/f_o/presentation/pages/option_chain_view.dart`). STRIKE is an `Expanded(flex: 2)` child in both `_buildHeaderColumns` and `_buildRowColumns`, so it leaves the screen with the other columns.
- `_tableViewportKey` and `_horizontalScrollController` already identify the visible width and horizontal offset. The Spot line/capsule is a separate foreground child of the table `Stack`; it does not contain or pin strike values.
- Mobile column geometry already uses the row's horizontal padding, total flex, optional group flex, and a side focus state. The sticky position must derive from those same values; a fixed pixel offset would drift when Bid/Ask, Valuation, or Greeks are enabled.

### Intended interaction

1. Home view: the STRIKE header and values remain in their normal central position between the Call and Put LTP columns. There is no sticky shadow while the natural column is fully visible.
2. Scroll or tap PUTS: as soon as the natural STRIKE column would move beyond the left viewport edge, it remains fully visible at the **left** edge. Put columns move beneath it. The same behavior applies to a manual swipe, not only the PUTS shortcut.
3. Scroll or tap CALLS: as soon as STRIKE would move beyond the right edge, it remains fully visible at the **right** edge. Call columns move beneath it.
4. Reverse direction: STRIKE leaves the edge smoothly and returns to its natural position when that position comes back into view. The Spot line/capsule retains its current vertical spot-row alignment above the table.
5. A side-focused viewport shows STRIKE plus up to three complete columns from that side, with no neighboring sliver. When fewer than three side columns exist, show the available real columns at readable width. A repeated CALLS or PUTS tap still returns to the three-column home view.

### Small implementation design

1. Keep the existing single vertical `ListView.builder` and horizontal `ScrollController`. In the mobile header and each visible row, reserve STRIKE's current two-flex-width slot in the `Row`, then paint its **single** header/cell widget last in that row's `Stack`. This gives it a higher paint order without introducing a second vertical list or duplicating strike semantics.
2. From the already computed flex layout, let `unit = (contentWidth - 2 × rowPaddingH) / totalFlex`, `strikeWidth = 2 × unit`, and `naturalLeft = rowPaddingH + (6 + leftOptionalFlex) × unit - horizontalOffset`. The mobile viewport x-position is `clamp(naturalLeft, 0, viewportWidth - strikeWidth)`. Convert that x-position back to the scrolling row's coordinates for painting. Apply the same result to the header and every visible strike row.
3. Recalculate only when horizontal offset, viewport width, or optional groups change. Give the pinned cell a theme-token surface, subtle border/shadow, and existing market accent so values underneath cannot show through. Keep the normal center state visually aligned with its original slot. The Spot line/capsule stays above the strike layer at the spot divider.
4. Adjust the mobile side-focus offset/width calculation to include the pinned STRIKE width and three available side columns. Keep the desktop/tablet rendering path unchanged.

### Failure and acceptance matrix

| Case | Expected | Verification after approval |
|---|---|---|
| Home at 360/390px | Header and all strike values share the original center x-position; no duplicate cells | Mobile layout inspection |
| Swipe to Puts | STRIKE clamps to left edge before disappearing; values remain aligned with their rows | Scroll interaction check |
| Swipe to Calls | STRIKE clamps to right edge before disappearing | Scroll interaction check |
| Swipe back | STRIKE re-enters the normal slot without a jump or ghost value | Scroll interaction check |
| Bid/Ask, Valuation, Greeks | Clamp and four-column focus use current flex widths; no clipped labels or slivers | Layout check with each group |
| Vertical strike scroll | Pinned values move with the original rows; Spot divider stays at its true strike boundary | Vertical/horizontal interaction check |
| CALLS/PUTS second tap | Returns to the original home viewport with central STRIKE | Interaction check |
| Symbol/expiry reload, empty rows, text scaling | No stale strike overlay, duplicate semantics, overflow, or controller exception | Widget/layout check |
| Desktop/tablet | Existing five-column/default layout and scroll behavior | Responsive boundary check |

**Theme and architecture:** use existing `context.colors`, `context.marketTheme`, and `ModuleColors.market` values; no new colors, endpoint, provider, or design-system primitive. The current data and scroll ownership stay within `OptionChainView`.

**Plan status:** implemented locally. The responsive STRIKE presentation layer derives its position from the live horizontal offset and existing flex geometry; visual verification remains pending on the locally running mobile view.
