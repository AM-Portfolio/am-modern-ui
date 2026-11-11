# Market and Paper Trading Plan

Status: **implementation in progress; F&O contract-resolution fix awaiting approval**
Scope: `am-modern-ui` Market UI, Market common, the centralized `am_design_system`, and the existing `am-market` instrument-search backend contract/provider path, including Paper Trading, Market F&O, and Market Analytics.
Out of scope: Portfolio, Trade, unrelated backend services, new services, and unrelated modules.

## Implementation TODO

- [x] Make F&O contract metadata and selected-contract LTP load independently and asynchronously.
- [~] Add Margin loading/error/empty states. (Present in code, but the desktop layout defect can prevent the body from painting.)
- [~] Fix the desktop Margin layout failure. (Invalid stretch removed; browser-only layout regression still awaits Chrome runner.)
- [~] Fix the tab-switch freeze. (Outgoing heavy tab removed from the transition; browser interaction timing remains to verify.)
- [~] Prevent duplicate/restarted requests during F&O tab switching and retained-page navigation. (Active-tab mounting is fixed; request-cache coverage remains.)
- [x] Avoid eager work from inactive F&O tabs where the existing tab architecture permits.
- [x] Curate F&O landing shortcuts to HDFC Bank, Reliance, Wipro, Infosys, NIFTY, and BANKNIFTY.
- [~] Add or update focused regression tests for async loading, failure states, tab switching, and landing shortcuts. (Existing F&O regression tests pass; new provider-state coverage remains.)
- [~] Run formatting and focused tests. (15 VM tests pass; the added web-only desktop test is skipped on VM because the Chrome test runner did not complete. Browser and rapid-switch verification remain.)

## Goal

Make Paper Trading and F&O open quickly, show only confirmed data, stream only visible symbols, and keep the UI consistent with the global Market theme.

## Mandatory implementation and design-system rule

Before changing or adding code:

1. Search the complete codebase for an existing implementation of the required behavior.
2. Reuse the existing provider, controller, widget, theme token, stream lifecycle, API client, animation, or test whenever it already satisfies the requirement.
3. If existing logic is incomplete, fine-tune or extend it instead of creating a parallel implementation.
4. Introduce new logic only after confirming that no suitable reusable implementation exists.
5. Do not implement the same endpoint call, state, subscription handling, validation, animation, or theme behavior twice.
6. Use the centralized design system and existing Market components before creating a new widget or style.
7. Every changed widget must actively listen to global theme and Market theme changes through the approved design-system tokens; no raw colors, duplicate theme constants, or module-local visual replacements.
8. Restrict code changes to the market-data instrument-search DTO/provider plus `am_market` and `am_design_system`; do not touch Portfolio, Trade, or unrelated modules.
9. Document the reuse decision or the reason new logic was necessary before implementation.

## Verified root cause: NIFTY lot-size/quantity mismatch

The live development request was reproduced with the exact body used by the UI:

`POST https://am-dev.asrax.in/market/v1/instruments/search`

Request filters were `queries=["NIFTY"]`, exchanges `NSE/NSE_FO`, segments `NSE_FO/NFO`, and instrument types `FUT/FUTIDX/FUTSTK`. The response was `200 OK`, about `1.19s`, `9.3 KB`, and `18` contracts. The first result was `FINNIFTY FUT 23 NOV 26` with `lot_size=60`; NIFTY contracts appeared later with `lot_size=65`.

The backend is returning valid records, but its `queries` field is intentionally broad text matching. `UpstoxInstrumentService` matches `NIFTY` against `name`, `asset_symbol`, `trading_symbol`, `underlying_key`, and `underlying_symbol`, so related underlyings are included. The controller returns that ordered list unchanged.

The frontend then compounds the ambiguity:

- `futuresContractsMetadataProvider` sends only the broad text query and returns the raw ordered list.
- `MarginCalculatorView` uses `selectedContract ?? contracts.first`, so it can initialize from FINNIFTY and set quantity to 60.
- `FuturesView._ensureDefaultSelection` also chooses the first non-expired raw result before applying the visible table's underlying filter.
- The header/details cards resolve the lot size from `selectedContract`, but before selection arrives they fall back to the NIFTY static mapping of 65. When the cross-underlying contract arrives, the display changes to 60.

This is why the screenshots show NIFTY 50 in the page header, FINNIFTY in the margin contract, lot size 65 in one widget, and quantity 60 in another. It is a contract identity race/mismatch, not an exchange lot-size change.

## Backend + frontend permanent fix plan

### Backend: narrow the existing search contract

1. Extend the existing `InstrumentSearchCriteria` with an optional structured `underlyingSymbols` list. Do not add a second endpoint or alter the meaning of the existing broad `queries` search.
2. In the existing Upstox provider query, when `underlyingSymbols` is present, add an exact `underlying_symbol`/`asset_symbol` match alongside the existing exchange, segment, and instrument-type filters. Preserve current behavior when the list is absent.
3. Apply the same optional filter semantics to the existing Zerodha provider using the fields available in its instrument model; if that provider lacks normalized underlying metadata, keep its existing behavior and document the limitation rather than guessing from arbitrary text.
4. Update the generated/OpenAPI-backed SDK request model and the existing Postman request documentation if the public request schema is generated from this DTO. Keep the field optional for backward compatibility.
5. Add backend tests proving: broad `queries=[NIFTY]` remains backward compatible; `underlyingSymbols=[NIFTY]` excludes FINNIFTY/BANKNIFTY/NIFTYNXT50; NIFTY futures retain their response `lot_size=65`; empty/unknown filters do not widen results unexpectedly.

### Frontend: one authoritative contract identity

1. Reuse the existing `matchesFutureUnderlying` alias logic and extract/share it rather than creating a second symbol-matching implementation.
2. Send the canonical active underlying through the new structured backend filter. Keep client-side exact filtering as defense-in-depth for stale or mixed backend data.
3. Add one pure resolver/provider for the active futures contract: accept the selected contract only when it belongs to the current underlying; otherwise choose the nearest non-expired contract from the filtered metadata deterministically.
4. Make the header/details cards, Futures table default selection, chart/depth cards, and Margin Calculator consume that same resolved contract. Remove their separate `selectedContract ?? firstContract` and static lot-size paths where confirmed metadata exists.
5. Initialize and update quantity from the resolved contract's authoritative `lot_size`; reset it only when the contract identity changes, and preserve intentional user edits without allowing a cross-underlying contract to remain.
6. Keep static lot-size mappings only as a loading/unavailable fallback; never show them over confirmed contract metadata. Do not display a FINNIFTY contract while the active symbol is NIFTY.
7. Keep quote enrichment asynchronous: metadata filtering/selection must not wait for every contract quote. Fetch the selected contract quote independently and leave calculation disabled until the selected contract and valid LTP are confirmed.

### Regression and verification

- Curl/API regression: broad NIFTY search and structured NIFTY underlying search; record status, latency, result count, first contract, and lot-size fields.
- Flutter provider tests: NIFTY response containing FINNIFTY first resolves to NIFTY; NIFTY lot size is 65; BANKNIFTY and FINNIFTY resolve to their own lot sizes.
- Widget tests: header lot size, selected contract, margin contract, and quantity always agree before and after asynchronous metadata/quote arrival and after repeated tab switches.
- Edge cases: no matching contract, expired-only results, stale selected contract after symbol change, missing/zero lot size, missing LTP, user-edited quantity, duplicate response rows, and backend filter unavailable/older deployment.
- Verify the response contract remains compatible for existing equity/security-search callers.

### No-duplicate-logic decision

The fix extends the existing `/v1/instruments/search` endpoint, `InstrumentSearchCriteria`, `matchesFutureUnderlying`, `FoLotSizeConfig`, `selectedFutureContractProvider`, and existing metadata/quote providers. No new endpoint, API client, independent cache, or parallel lot-size resolver is planned.

## Problems and solutions

| Problem | Solution |
|---|---|
| Paper page waits for Wallet, Orders, Positions, Preferences, and prices | Block only on `GET /v1/wallets?kind=PAPER`; lazy-load the rest independently. |
| Loading is shown as an empty list | Track `idle/loading/data/empty/error` separately and show the correct state. |
| Watchlist prices arrive slowly or trigger many calls | Load visible symbols first, batch LTP, and use Quotes only for fallback/depth. Never invent prices. |
| Hidden Overview/analyser work runs early | Load analyser/fundamental/chart data only when Overview opens. |
| Paper symbols keep streaming after navigation | Subscribe only to the visible watchlist/position symbol union; unsubscribe when leaving, paginating, or changing tabs. |
| Paper P&L is not live | Consume valid WebSocket ticks for visible positions and recalculate row and total P&L without mutating OMS data. |
| Position/order actions are incomplete or unsafe | Add confirmed Buy/Sell/Exit ticket flows, revalidate OMS quantity before submit, and refresh after success. Preserve Cancel, Re-order, and Retry with complete order values. |
| Paper uses a bookmark instead of the shared star | Reuse the shared Market watchlist membership and star behavior, including confirmed add/remove, rollback, accessibility, and pending state. |
| Paper Watchlist header contains a redundant Add to Watchlist action | Remove only the header-level Add to Watchlist button on desktop and mobile. Keep the shared row-level star and existing source/dropdown flows available. |
| Refresh button may return cached values or refresh more than necessary | Reuse `WatchlistController.refreshVisibleQuotes()` and `PaperMarketClient.enrichQuotes()`, but add an explicit user-refresh path that sends `refresh=true` to the existing LTP/Quotes calls. Refresh only the current visible page, preserve source/page/selection/depth state, and keep the request generation guard. |
| Refresh causes list jitter or duplicate requests | Keep one in-flight refresh per visible page, disable/relabel the control while active, merge valid responses into existing rows, and avoid rebuilding the Paper desk or OMS state. |
| Hovering between Paper Watchlist stocks shifts the row layout | Reuse the current hover/action state, but reserve a stable action-toolbar width and animate opacity/visibility instead of conditionally inserting/removing the toolbar. The price column must not move when hover changes. |
| Hover transitions feel abrupt when moving between stocks | Animate the outgoing/incoming action state with a short `AnimatedSwitcher`/`AnimatedOpacity` transition while keeping row height and width fixed. Do not use a full-list animation or rebuild the entire watchlist. |
| Paper controls use hardcoded or inherited colors | Use global theme tokens, `context.colors`, `context.marketTheme`, and `ModuleColors.market` for every state. |
| Enable Paper Trading button appears purple | Apply the Market CTA theme for normal, hover, pressed, focus, disabled, and loading states. |
| F&O can reopen on Margin/Futures | Reset the retained F&O tab to Option Chain on every new entry, symbol change, search, and deep link. |
| Margin Calculator waits for unrelated data | Remove its dependency on the full Option Chain. Load only the selected futures contract metadata and LTP. |
| Margin selects an illiquid first contract | Prefer the nearest valid contract with a positive actual LTP; otherwise show LTP unavailable and disable calculation. |
| Margin loads quotes for every futures contract | Fetch metadata first, then quote only the selected contract. Cache results by symbol/contract. |
| Margin quantity/price can be wrong or blank | Quantity comes from authoritative NSE contract lot size; price is the selected contract's read-only actual LTP. No universal `50`, fake price, or synthetic carry price. |
| Margin is intermittently blank or slow | The current `futuresContractsProvider` waits for instrument search and then waits for one quote request containing every returned contract. `MarginCalculatorView` converts loading/error into an empty list, so a slow or failed request looks like a blank calculator. The provider is also `autoDispose` while all `TabBarView` children are constructed, so switching tabs can restart the same request. Split the existing path into cached metadata and selected-contract quote loading, expose loading/error/unavailable states, and let Margin render the confirmed lot size as soon as metadata arrives. Fetch the selected contract LTP independently, deduplicate in-flight requests, and never block Margin on Option Chain or the full Futures table. |
| F&O page freezes while opening or switching tabs | `TabBarView` constructs Option Chain, Futures, and Margin content together. Their providers and widgets can therefore start option-chain loading, full futures instrument search, all-contract quote enrichment, charts, and margin binding at the same time. The first visible header may already have its data, but the body still waits on the slowest full-list request. Keep the tab shell light, activate each tab's data path only when that tab is selected, and schedule non-visible work asynchronously after first paint. Avoid provider writes and expensive selection/enrichment during build. |

| F&O landing recommendations show too many stocks and omit key indices | `dynamicFoRecommendationsProvider` currently returns the first security-search recommendations, so stock results can replace the intended index shortcuts. Reuse the existing recommendation provider/service but normalize and curate the landing list to keep `HDFC Bank`, `Reliance`, `Wipro`, and `Infosys`, and add `NIFTY` and `BANKNIFTY`. Preserve the existing fallback and click-to-select flow; do not add a new endpoint. |

### Latest F&O audit: Margin blank, tab latency, and default-tab regression

Confirmed from the current widget/provider graph:

- `FoPage._buildTabDetailView` watches Option Chain data for the mobile expiry picker and constructs all three `TabBarView` children together.
- `FoHeaderCard` independently watches market status, Option Chain, and the full enriched Futures provider. This means the header can display correctly while the body is still waiting on unrelated work.
- `MarginCalculatorView` watches metadata, then creates a selected-contract quote provider during its build. It currently collapses metadata loading/error to an empty list and has no dedicated visible loading/error state, so a slow or failed search appears blank.
- The Futures provider still performs full-list quote enrichment for the Futures tab. If that provider is retained or rebuilt during tab changes, it can compete with the selected-contract Margin request.
- The retained `FoPage` owns the `TabController`; parent reset calls can occur before the retained F&O child is mounted on direct-route/deep-link entry. That explains why the initial tab can remain Margin even though `initialIndex` is zero.

Fix sequence:

1. Add an explicit active-tab state boundary. Ensure only the selected body mounts its data-heavy widget, while preserving tab state through a keyed cache only after first activation. Do not let inactive tabs start providers.
2. Move expiry data needed by the mobile picker behind the Option Chain tab’s active state; the header must use a lightweight cached summary or show an unavailable state instead of forcing the full chain.
3. Make `FoHeaderCard` consume the smallest existing cached quote/summary path. It must not trigger full Futures enrichment just to render the header.
4. In Margin, render metadata-loading, metadata-error, no-contract, quote-loading, quote-error, and valid-price states explicitly. Keep the selected-contract quote request independent and deduplicated.
5. Move all default-contract selection and controller synchronization out of the build method into provider/listener or post-frame state transitions guarded by symbol/contract identity. This prevents rebuild feedback and UI stalls.
6. Reset the F&O tab from a route-entry token delivered after the retained `FoPage` is mounted, rather than relying only on a parent `GlobalKey` call during navigation.
7. Add timeline tests and widget tests for: cold direct route, retained route return, tab switches, delayed metadata, delayed quote, failed quote, and inactive-tab request counts. Verify the header paints first and that one tab cannot block another.

### Follow-up runtime investigation from the blank Margin screenshot

Latest finding: `_buildWebDashboard` puts a `Row(crossAxisAlignment: CrossAxisAlignment.stretch)` inside a vertical `SingleChildScrollView`. This gives the row unbounded height and can fail during desktop layout after metadata arrives. Existing Margin tests use the default narrow viewport and miss this branch. Capture the Flutter exception in a desktop-width widget test before changing it. The header uses a separate data path, so its values can appear even while the Margin body fails.

Screen freeze: the repeated layout failure is a plausible source of dropped frames. The current `AnimatedSwitcher` also retains an outgoing heavy tab in a full-size `Stack` during the 180 ms transition; it can continue layout and hit testing while the next tab is selected. Confirm the exact contribution of each with Flutter errors, frame timing, and rapid-click tests before attributing the remaining delay to API latency.

Prioritized fix: reproduce the desktop layout failure; correct the stretch constraint with bounded or natural panel heights; assert the Margin panels and actual values paint; then test rapid Option Chain → Futures → Margin → Option Chain switching with delayed providers, ensuring the outgoing child cannot intercept clicks or keep failing layout. Verify all loading/error/unavailable states and the direct-entry Option Chain default afterward.

The screenshot confirms that the tab label changes to Margin, but it does not prove that the Margin widget produced a valid frame. The current code still has several observable points that must be instrumented before another fix:

- `AnimatedSwitcher` is now the body host. Its custom `StackFit.expand` layout must be verified with a frame marker for the active tab; otherwise a transition can report the new tab while the visible child is still an old or zero-content subtree.
- `MarginCalculatorView` watches metadata and conditionally watches the selected-contract quote provider. The provider state, request key, and first frame must be logged/tested separately. A blank screen is not an acceptable loading representation.
- The metadata request can remain pending indefinitely because the SDK call has no UI-level timeout or cancellation state. Add a bounded timeout around the existing request path and show a retryable error while preserving stale cached metadata.
- `FoPage` still watches Option Chain data for the mobile expiry picker even when Margin or Futures is active. Move that watch behind the active Option Chain state so a non-Option tab cannot rebuild from chain updates.
- Default-tab reset must be tested after the retained child is mounted, not only when the parent navigation callback fires. Use a route-entry/reset token or an explicit visibility callback and assert the controller index after the frame settles.

Required next fix pass:

1. Add structured diagnostics for tab index, active child key, metadata state, quote state, request start/end, and provider disposal. Reproduce the blank screenshot and identify the first missing state transition.
2. Replace the custom `AnimatedSwitcher` body host with a constrained active-tab transition that has one authoritative child and a guaranteed loading/error fallback. Do not keep previous heavy tab subtrees in the layout during the transition.
3. Gate the mobile expiry-provider watch to Option Chain only and remove any remaining full Futures provider watch from the header path.
4. Add timeout, cancellation/deduplication, and retry behavior to the existing metadata/selected-quote path. Keep endpoint calls asynchronous and independent.
5. Add a widget test that switches Option Chain → Futures → Margin → Option Chain with delayed providers and asserts every tab is clickable and paints a non-empty state within the expected frame budget.

### Margin Calculator intermittent-load fix plan

1. Reproduce with DevTools Network and logs for a cold load, tab switch, symbol change, and return to F&O. Record instrument-search time, quote time, provider state, and whether the widget is disposed/recreated.
2. Reuse the existing `futuresContractsProvider`, `selectedFutureContractProvider`, and SDK client, but separate their responsibilities: metadata list first, selected-contract quote second. Do not add a second API client or duplicate endpoint wrapper.
3. Add a stable cached/in-flight request layer keyed by normalized symbol and contract identifier. A tab switch must reuse an active request instead of restarting it.
4. Make Margin observe the full `AsyncValue` rather than `.maybeWhen(... orElse: [])`, so loading, backend error, no-contract, missing-LTP, and valid-data states are distinct and visible.
5. Select the nearest valid contract with a positive confirmed LTP. If metadata exists but LTP is unavailable, show the contract and an explicit unavailable-price state; disable calculation rather than leaving blank fields.
6. Keep the existing authoritative lot-size resolver and read-only LTP binding. Update controllers only when symbol/contract identity or confirmed response data changes, avoiding provider writes during build.
7. Ensure the F&O page does not eagerly force the Margin/Futures request when the user only opens Option Chain; preserve the existing default Option Chain behavior and load each tab’s data when its content becomes active where the current navigator permits.
8. Add regression tests for slow metadata, quote failure, empty contracts, repeated tab switches, cached return, dynamic lot size, and read-only actual LTP. Verify no request multiplication and no blank-without-state UI.
9. Profile the F&O first frame and tab-switch frame. Confirm the header can paint independently, then confirm Option Chain, Futures, and Margin requests do not block one another or run duplicate full-list enrichment in the background.
10. Curate the landing shortcuts using the existing search response: retain HDFC Bank, Reliance, Wipro, and Infosys, add NIFTY and BANKNIFTY, and verify each selection resolves to the correct F&O symbol and contract search.

### Market Analytics: Historical Monthly Performance

| Problem | Solution |
|---|---|
| Compact monthly cards display `NIFTY` even when the ranking contains `NIFTY METAL`, `NIFTY IT`, or another actual index | First compare `topPerformer.symbol` with `allIndices[0].symbol` in the existing `/v1/analysis/indices/historical-performance` response. Reuse the existing `allIndices` data for the compact card if it contains the correct ranked name. Change the backend only if the response itself is inconsistent after cache/API verification. |
| Monthly cells are too narrow because available width is divided by all 12 months | Keep all 12 months in the horizontal scroll, but use a uniform desktop cell width instead of dividing the viewport by 12. |
| Wide layout shows October and sidebar-open layout shows August before the names are readable | Derive the visible window from the actual `LayoutBuilder` width: target approximately January–September on the wide layout and January–July when the secondary sidebar is open. Do not remove later months; keep them reachable by scrolling. |
| Long index names are clipped or visually reduced to `NIFTY` | Give every month column the same minimum width and render the full index name on one line. Keep the month header, card, and every year row aligned to that width. |
| Hover scaling changes the apparent card size | Preserve uniform card dimensions and use border/shadow emphasis instead of changing layout size on hover. |
| Desktop and compact month scrollers can use different sizing rules | Reuse the existing horizontal scroll and responsive `LayoutBuilder` logic; update both `HistoricalPerformanceSection` and `CylinderMonthScroller` only where their current sizing rules differ. |

Affected files:

- `am_market/ui/lib/features/market_analysis/presentation/widgets/historical_performance_section.dart`
- `am_market/ui/lib/features/market_analysis/presentation/widgets/monthly_performance_card.dart`
- `am_market/ui/lib/features/market_analysis/presentation/widgets/cylinder_month_scroller.dart`
- `am_market/common/lib/models/indices_performance_model.dart` only if response normalization is required

No new endpoint or backend change is part of this plan. The existing historical-performance endpoint, `allIndices` payload, ranking dialog, horizontal scroll controller, and responsive layout logic must be reused first. If the backend response is inconsistent, record it separately rather than changing the backend in this scope.

## Endpoint behavior

- Wallet is the only blocking Paper request.
- Orders, Positions, Preferences, Watchlists, Index batch, LTP, and Quotes load independently.
- Explicit Watchlist refresh uses the existing live-LTP batch and Quotes fallback with `refresh=true`; ordinary background loads may continue using the normal cache policy.
- Historical/fundamental endpoints do not block Paper or Margin Calculator.
- F&O uses `/v1/instruments/search` for contract metadata and `/v1/market-data/quotes` only for the selected contract where possible.
- `/v1/market-data/option-chain` is used by Option Chain, not as a prerequisite for Margin Calculator.
- F&O endpoints must be asynchronous and independently rendered: header quote, option-chain data, futures metadata, selected-contract LTP, and margin calculation must not wait on one another unless the displayed calculation actually requires that response.
- The F&O landing shortcuts reuse the existing security-search response; no new recommendations endpoint is required.

## Implementation order

1. Capture baseline Network timings and browser Console errors.
2. Fix Paper first paint and independent loading states.
3. Add visible-symbol WebSocket subscribe/unsubscribe lifecycle.
4. Add live position P&L and safe Buy/Sell/Exit actions.
5. Remove the redundant Watchlist header Add action, make current-page refresh force fresh quotes, and smooth row hover transitions.
6. Replace Paper bookmark and Enable CTA with shared Market theme/star behavior.
7. Fix F&O tab reset and decouple Margin Calculator from Option Chain.
8. Fix futures contract selection, authoritative lot size, and read-only actual LTP.
9. Fix Market Analytics index-name selection and responsive monthly-card sizing.
10. Add regression tests and compare before/after waterfalls locally and in preprod.

## Acceptance criteria

- Paper desk renders after Wallet only; slow secondary endpoints do not block it.
- Loading, empty, error, and unavailable-price states are explicit; no fake values are shown.
- Only visible Paper watchlist and position symbols are subscribed; subscriptions are removed on navigation and restored on return.
- Watchlist header has no redundant Add button; row-level shared star behavior remains available.
- Watchlist Refresh updates only the visible page with fresh market values, preserves UI state, and does not rebuild the Paper desk.
- Moving hover between stocks does not shift the price column or change row dimensions; the action transition is smooth.
- Position P&L updates from valid in-order ticks.
- Buy/Sell/Exit actions require confirmation and latest OMS validation.
- Paper watchlist uses the same shared filled/unfilled star and membership truth as Market Watchlist.
- All Paper controls follow light/dark global and Market themes.
- New F&O journeys always open on Option Chain.
- Margin uses the selected contract's authoritative lot size and actual read-only LTP.
- Illiquid contracts show an explicit unavailable state rather than blank or synthetic values.
- Historical monthly cards display the actual ranked index name, not a generic `NIFTY` label.
- All monthly cells have uniform dimensions; wide layout initially shows about September and sidebar-open layout about July.
- October–December remain available through horizontal scrolling.
- Only the market-data instrument-search DTO/provider, `am_market`, and `am_design_system` are changed; no Portfolio, Trade, or unrelated module is changed.

## Implementation status

The lot-size/contract-resolution fix is implemented locally and verified with focused UI and backend regression tests. Deployment, commit, and push are not included in this implementation step.
