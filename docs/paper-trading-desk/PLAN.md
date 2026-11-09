# PLAN — Paper Trading fast load, live streaming, and consistent watchlist UX

Status: **plan updated; waiting for user review before implementation**
Lead repo: `am-modern-ui`
Target: `preprod`
Code changes: **not started**

## Goal

Show the correct Paper desk as soon as the Paper wallet is known. Load everything else afterward without displaying fake, stale, or falsely empty data. While Market → Paper is visible, stream only the symbols the user can currently see, keep position P&L live, provide safe position/order actions, and use the same themed star-based watchlist interaction as the rest of Market.

## Current problem

The desk currently waits for four sequential OMS calls:

```text
wallet → orders → positions → preference → render desk
```

Only the wallet is required to decide between the Enable page and Paper desk.

After the desk renders, the watchlist separately loads:

```text
index symbols → live LTP → quote fallback
```

On mobile, an offstage analyser may also start hidden fundamental/chart calls after symbol selection.

Verified in:

- `am_paper_ui/lib/presentation/paper_oms_cubit.dart`
- `am_paper_ui/lib/providers/paper_oms_providers.dart`
- `am_paper_ui/lib/presentation/pages/paper_gate_screen.dart`
- `am_paper_ui/lib/presentation/widgets/watchlist/watchlist_controller.dart`
- `am_paper_ui/lib/presentation/pages/paper_desk_screen.dart`

## Endpoint decisions

| Endpoint | Needed for first desk render? | Plan |
|----------|-------------------------------|------|
| `GET /v1/wallets?kind=PAPER` | Yes | Keep blocking |
| `GET /v1/orders?walletId=...` | No | Lazy-load |
| `GET /v1/wallets/{id}/positions` | No | Lazy-load |
| `GET /v1/prefs` | No | Load when ticket opens/background |
| `GET /v1/watchlists` | No | Background |
| `POST /v1/indices/batch` | Only for watchlist rows | Load after desk shell |
| `GET /v1/market-data/live-ltp` | Only for prices | Load after symbol rows |
| `GET /v1/market-data/quotes` | Fallback/depth only | Call only when needed |
| Historical/fundamental endpoints | No | Load only when Overview opens |

## Implementation phases

### 1. Fast first paint

- Call the wallet endpoint.
- If no Paper wallet exists, show Enable Paper Trading.
- If a wallet exists, immediately show the desk and confirmed wallet balance.
- Do not wait for Orders, Positions, or Preferences.

### 2. Safe lazy loading

Track each resource separately:

```text
idle → loading → data / empty / error
```

An unloaded list must never display “No orders” or “No positions.” It must show loading until the server confirms an empty result.

### 3. Progressive watchlist

- Show real symbol rows as soon as index/watchlist data arrives.
- Show `—` or a loader until a real price arrives.
- Batch LTP requests for visible rows.
- Use Quotes only as fallback or when depth is opened.
- Never invent a price; block order submission if no valid positive LTP exists.

### 4. Remove hidden work

- Do not build the mobile analyser until Overview is opened.
- Reuse in-flight requests when a tab is tapped repeatedly.
- Ignore stale responses after rapid symbol changes.
- Fetch Quote and LTP concurrently when the order ticket opens.

### 5. Backend measurement and optimization

- Measure cold/warm latency and payload size for Wallet, Orders, Positions, Index, LTP, and Quotes.
- Keep Wallet and Index responses lean and cached safely.
- Confirm LTP is a real batch operation.
- Consider `includeDepth=false` for lightweight watchlist quote fallback only after measurement.
- Verify the actual `am-oms` source before changing its backend; it is not present in this workspace.

### 6. Market → Paper streaming lifecycle

- Keep REST LTP as the truthful initial snapshot; WebSocket ticks progressively replace it only when valid and newer.
- Connect incoming `PriceService` ticks to Paper watchlist rows and open-position LTP/P&L. Publishing symbols without consuming ticks is incomplete.
- Maintain separate Paper sub-scopes for visible watchlist symbols and visible position symbols, then publish their deduplicated union. One pane must not overwrite the other pane's interest.
- On pagination, watchlist/index change, or position-book change, subscribe additions and unsubscribe removals.
- On Paper → another Market tab, release Paper interest. On leaving Market entirely, release the `market-ui` scope. Keep the authenticated STOMP connection open; remove only unnecessary symbol interest.
- On return, fetch/retain the safe REST snapshot and replay the currently visible Paper scope.
- During market close, retain desired symbols locally but remove frontend topics and send the gateway's supported backend unsubscribe command. At market open, force-refresh status and replay active scopes.
- Validate the gateway contract before implementation: `/app/market/subscribe` exists in the UI; a matching batched market-unsubscribe destination was not found locally and must not be invented silently.
- Fix market-session boundary refresh so the one-hour status cache cannot suppress the opening/closing transition.
- Preserve the existing fail-open policy for a transient status failure, but use the last valid session/calendar boundary where available.

### 7. Live Positions and safe trade actions

- Subscribe to open-position symbols only while Positions is visible (or simultaneously visible beside Watchlist on desktop).
- Recalculate per-row unrealized P&L and total P&L on every valid, in-order tick without refreshing Orders/Positions REST data.
- Add themed `Buy`, `Sell`, and `Exit` actions to desktop rows and mobile cards.
- `Exit` opens the existing Paper order ticket for confirmation; it never submits immediately.
- For a positive quantity, prefill `SELL` and the full available quantity. If short Paper positions are supported, a negative quantity prefills `BUY` and the absolute quantity.
- Revalidate the latest OMS position and quantity at submission; prevent oversell unless short selling is explicitly supported by the Paper OMS contract.
- Refresh wallet, orders, and positions after a successful order without blocking the ticket success state.

### 8. Orders correctness and live status

- Preserve working-order Cancel, filled-order Re-order, and rejected-order Details/Retry.
- Re-order and Retry must prefill the complete safe order intent: symbol, side, quantity, order type, and applicable limit/target/stop values. The current flow copies only symbol and side and defaults quantity to `1`.
- A filled BUY order's `Re-order` remains another BUY; selling a holding is done through the Position `Sell`/`Exit` action.
- Verify whether OMS/gateway exposes an owner-scoped Paper order-event topic. If it exists, subscribe only while Paper is active and merge events idempotently. If it does not exist, keep explicit refresh-after-mutation behavior and document any proposed backend contract separately.
- Unsubscribe Paper order events on leaving Paper/Market and on logout.

### 9. Consistent watchlist star and global theme

- Replace the Paper bookmark affordance with the exact shared Market watchlist star interaction.
- Unfilled star means the symbol is not in the selected/global watchlist; filled star means membership is confirmed.
- Clicking the star uses the existing watchlist source of truth and mutation flow. Do not create a Paper-only membership flag or optimistic state that can disagree with the Watchlist page.
- Show a pending/disabled state during mutation, roll back on failure, and prevent duplicate add/remove submissions.
- Reflect membership changes made elsewhere in Market without requiring a Paper page reload.
- Reuse the shared watchlist star widget/icon semantics where practical so tooltip, accessibility label, hit target, and behavior remain uniform.
- The control must react to the global light/dark theme and Market module theme. Use `context.colors.*`, `context.marketTheme.*`, and `ModuleColors.market`; no raw `Colors.*`, hex values, or Paper-specific hardcoded icon colors.
- Preserve keyboard focus, screen-reader labels (`Add to watchlist` / `Remove from watchlist`), and an accessible tap target on desktop and mobile.

### 10. Enable Paper Trading screen theme correction

- `PaperEnablePage` currently uses an unstyled `FilledButton`, so it inherits the app-wide primary CTA theme and appears purple. The page has no raw purple literal, but the inherited result is incorrect for Market → Paper.
- Style `Enable paper trading` from the Market module theme, following existing Market CTA patterns: Market accent background, theme-derived foreground, and theme-derived hover, pressed, focus, disabled, and loading states.
- Use `ModuleColors.market` or the equivalent shared Market semantic token for the accent, and `context.colors.actionPrimaryFg`/the approved design-system foreground token for contrast. Do not introduce a raw hex value or `Colors.*` workaround.
- Keep title, explanatory copy, error text, loading indicator, focus ring, and surrounding background bound to `Theme.of(context)`, `context.colors.*`, and Market semantic tokens.
- The CTA must update immediately when the global light/dark theme changes and must visually align with the active Market navigation accent.
- Prefer a reusable Market CTA style/component when one already exists; do not create a Paper-only color constant.

### 11. Market F&O — Option Chain default and margin-data correctness

This is an adjacent Market-module execution slice, not Paper OMS behavior. Keep changes inside `am_market/ui` and its existing Market SDK/providers; do not modify Portfolio, Trade, Dashboard, or unrelated modules.

#### Verified current behavior

- `FoPage` creates its three-tab controller with index `0`, where index `0` is `Option Chain`.
- Entering Futures & Options through the Market navigator calls `resetToOptionChain()`, and selecting another F&O symbol also calls it. The user's Option Chain-first expectation is therefore already represented in the current local source.
- The margin calculator does not currently hardcode quantity `50` for every symbol. `FoLotSizeConfig.resolveLotSize()` prioritizes selected-contract metadata, then Option Chain metadata, then a local index fallback table, then `1`.
- The local fallback table is still hardcoded exchange metadata and can become stale. It must not silently override or substitute for authoritative contract metadata when calculating real margin.
- The margin price is an editable `TextField`. Once edited, `_userEditedPrice` prevents later LTP rebinding. This does not meet the requirement for a read-only actual selected-contract price.
- Futures enrichment contains synthetic/fallback contract pricing derived from spot and other hardcoded fallback values in adjacent widgets. Synthetic prices must never feed a production margin calculation presented as actual.

#### Required correction

- Preserve Option Chain as the initial tab whenever F&O opens for a selected stock/index, including sidebar entry, swipe entry, deep link, global search, retained-page return, and `initialSymbol` changes.
- Add a regression test proving a previously selected Futures Contracts or Margin Calculator tab resets to Option Chain on a new F&O entry/symbol journey.
- Make the selected contract's authoritative `lot_size`/`lotSize`/minimum-lot metadata the quantity basis. Option Chain contract metadata may be used when it identifies the same selected contract/underlier.
- Treat NSE/BSE lot sizes as dynamic contract metadata owned by the backend/instrument master. Do not introduce a universal `50`, and do not silently calculate using a stale local table when authoritative metadata is unavailable.
- Until authoritative lot metadata arrives, show quantity/lot size as unavailable or loading and disable margin calculation. Never substitute an arbitrary quantity.
- Keep quantity user-adjustable only in valid whole-lot multiples. `+` and `−` move exactly one resolved lot; typed values must be positive multiples of that lot or show validation.
- Replace the editable Price `TextField` and `Use LTP` action with a read-only themed price display bound to the selected contract's actual LTP.
- Update the read-only price from the existing Market price stream while the Margin Calculator is visible, using the selected contract/instrument key rather than only the underlier symbol.
- If no valid positive selected-contract LTP exists, show `—`/unavailable and disable calculation. Do not use spot-derived carry estimates, demo values, `2203.50`, or another contract's price.
- On contract or symbol change, clear the previous contract's quantity, price, and computed margin immediately; show loading until metadata and LTP for the new contract are confirmed.
- Derived notional and margin values must recompute from the confirmed lot-multiple quantity and latest valid selected-contract LTP only.
- Use global and Market theme tokens for read-only, loading, unavailable, validation, hover, focus, and disabled states; no raw colors or static visual data.

## Correctness rules

- Wallet response controls Enable vs Desk.
- Loading is not treated as empty.
- Missing price remains unavailable, not zero.
- Remote preference failure may use the confirmed local/default `MARKET` preference.
- JWT ownership and PAPER-only isolation stay unchanged.
- Existing order idempotency and submit guards stay unchanged.
- A WebSocket tick may update displayed market value but may not mutate OMS quantity, fills, wallet balance, or order status.
- Watchlist membership is confirmed by the shared Market watchlist state/API, not by icon-local state.
- Position Exit always requires ticket confirmation and a fresh OMS quantity validation.
- Theme and module colors come only from shared design-system tokens.
- Generic app-primary button styling must not override the Market semantic accent on the Enable Paper Trading screen.
- No new service, database, or response contract unless separately approved.

## Required tests

| Case | Expected |
|------|----------|
| Wallet succeeds while Orders/Positions are slow | Desk renders immediately |
| No Paper wallet | Enable page renders |
| Orders/Positions still loading | Loader, not false empty state |
| Index loads before prices | Symbols render; prices show unavailable |
| LTP and Quotes fail | No fake price; order cannot submit |
| Overview remains closed | No analyser API calls |
| Repeated tab taps | One in-flight request |
| Rapid symbol changes | Only latest symbol updates UI |
| OMS/Redis/provider failure | Explicit error/fallback; no corrupted data |
| Valid tick for visible watchlist symbol | Only that row updates from the real tick |
| Valid tick for open position | LTP, row P&L, and total P&L update consistently |
| Out-of-order/zero tick | Existing valid value is preserved |
| Change watchlist page/index | Removed symbols unsubscribe; new visible symbols subscribe once |
| Watchlist and Positions visible together | Deduplicated union is streamed; neither scope overwrites the other |
| Leave Paper/Market and return | Interest is released, then current visible scope is replayed |
| Market opens/closes near cached status boundary | Forced status refresh applies the correct subscription transition |
| Exit long position | SELL ticket opens with current symbol and available quantity; no immediate submit |
| Oversell/racing position update | Submission is rejected or corrected from latest OMS truth |
| Re-order/Retry | Complete supported order values are prefilled for user confirmation |
| Paper order event duplicated/out of order | Idempotent merge leaves one correct order state |
| Symbol not in watchlist | Unfilled themed star with Add semantics |
| Add/remove watchlist succeeds | Star changes only to the confirmed membership state |
| Add/remove watchlist fails/double-clicked | State rolls back; no duplicate mutation |
| Global theme changes | Star, hover, focus, disabled, and selected states update from theme tokens |
| Enable screen in light and dark themes | CTA uses the Market accent with accessible themed foreground and surface colors |
| Enable CTA hover/press/focus/disabled/loading | Every state is theme-token driven; no purple app-primary fallback or raw color |
| Open F&O after previously leaving it on Margin/Futures | Option Chain is selected for the new entry journey |
| Open F&O with `initialSymbol` or search/deep-link symbol | Symbol is selected and Option Chain is the visible tab |
| Selected contract metadata arrives | Quantity initializes to that contract's authoritative lot size, never universal `50` |
| Lot metadata is missing/stale | Quantity remains unavailable and calculation is disabled; no arbitrary fallback |
| User changes quantity | Only positive whole-lot multiples are accepted; controls step by one lot |
| Selected contract LTP arrives/ticks | Read-only price and derived margins update from that exact contract |
| Contract/symbol changes | Previous quantity, price, and margin clear before new data is shown |
| Contract LTP is missing/zero | Price shows unavailable and calculation is disabled; no synthetic price |
| User attempts to edit price | Price is not editable and has no `Use LTP` override action |

## Acceptance criteria

- First desk render depends only on Wallet latency.
- Orders, Positions, Preferences, prices, and analyser data no longer block the desk shell.
- No arbitrary or silently stale values are shown.
- No hidden analyser calls occur before Overview opens.
- No duplicate request storm occurs.
- Visible Paper watchlist and position values consume live ticks during market hours.
- Paper symbol interest is removed when no longer visible and restored on return.
- Position P&L changes from valid ticks without repeated OMS or REST quote polling.
- Position Sell/Buy/Exit and complete Re-order/Retry flows open a correctly prefilled confirmation ticket.
- Paper uses the same unfilled/filled watchlist star behavior and shared membership truth as the Market Watchlist page.
- No hardcoded icon, state, or theme colors are introduced.
- The Enable Paper Trading CTA follows the Market module theme in every interaction state instead of inheriting the purple app-primary CTA.
- F&O always opens a selected symbol on Option Chain, and Margin Calculator uses only authoritative lot metadata and read-only actual selected-contract LTP.
- Before/after request waterfalls are captured in preprod.

## Delivery order

1. Capture baseline.
2. Implement wallet-only gate and resource loading states.
3. Add lazy loading and analyser gating.
4. Add tests.
5. Measure again locally/preprod.
6. Optimize backend endpoints only where measurements justify it.

## Review gate

UI previews: not requested.
Architecture: `architecture.drawio`.
Implementation, Postman execution, deployment, and production changes remain blocked until the user explicitly approves this plan.
