# TODO — Paper Trading fast load, streaming, and consistent watchlist UX

| Step | Task | Status |
|------|------|--------|
| 1 | User reviews and approves this plan | **done** |
| 2 | Capture current endpoint waterfall and timings | completed |
| 3 | Make Wallet the only first-render blocker | **done** |
| 4 | Add separate loading states for Orders, Positions, and Preference | **done** |
| 5 | Lazy-load secondary OMS data and gate the mobile analyser | **done** |
| 6 | Preserve symbol-first, price-later watchlist rendering | **done** |
| 7 | Add unit/widget/API regression tests | **done** |
| 8 | Compare before/after locally and in preprod | planned |
| 9 | Optimize measured backend bottlenecks | planned |
| 10 | Connect Paper watchlist and Positions to shared live ticks | planned |
| 11 | Aggregate visible watchlist/position streaming scopes and release them on navigation | planned |
| 12 | Verify/add the gateway's batched market-unsubscribe contract without inventing an API | planned |
| 13 | Fix forced market-open/close boundary refresh and test reconnect/resubscribe | planned |
| 14 | Add live position P&L with zero/out-of-order tick protection | **done** |
| 15 | Add confirmed Buy/Sell/Exit actions to desktop and mobile Positions | **done** |
| 16 | Make Re-order/Retry prefill complete supported order values | **done** |
| 17 | Verify and integrate owner-scoped Paper order events, or retain documented refresh-after-mutation fallback | planned |
| 18 | Replace Paper bookmark with shared unfilled/filled watchlist star behavior | **done** |
| 19 | Bind star states to shared watchlist truth and global/Market theme tokens | **done** |
| 20 | Add accessibility, mutation rollback, cross-page membership, streaming, P&L, and action tests | **done** |
| 21 | Replace the inherited purple Enable Paper Trading CTA style with Market module semantic tokens | **done** |
| 22 | Verify Enable screen foreground, loading, hover, pressed, focus, disabled, error, and light/dark theme states | **done** |
| 23 | Add F&O entry/deep-link/retained-page regression tests proving Option Chain is the initial selected tab | planned |
| 24 | Make authoritative selected-contract metadata the Margin Calculator lot-size source and remove arbitrary quantity fallback behavior | planned |
| 25 | Validate quantity as positive whole-lot multiples and step controls by the resolved lot size | planned |
| 26 | Replace editable Margin Calculator price and `Use LTP` with a read-only selected-contract LTP display | planned |
| 27 | Stream the exact selected contract price while Margin Calculator is visible and release interest when hidden | planned |
| 28 | Remove synthetic/demo/fallback prices from the production margin-calculation path | planned |
| 29 | Clear stale contract values on symbol/contract change and disable calculation until lot size and LTP are confirmed | planned |
| 30 | Add F&O widget/provider tests for missing metadata, zero LTP, contract switching, lot multiples, and live price updates | planned |

No implementation, Postman execution, or deployment is authorized yet.
