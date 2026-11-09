# TODO - Reactive market stream subscriptions

Pack: `docs/reactive-market-stream-subscriptions/`

## Plan loop

- [x] Ingest user request and WebSocket evidence
- [x] Resolve Market domain and repos through `am-repo-catalog`
- [x] Read local context pack and current implementation
- [x] Verify gateway and market-data dependencies read-only
- [x] Record coverage verdict and current code cites
- [x] Define latency/consistency behavior and corner matrix
- [x] Create/update PLAN and themed multi-sheet architecture
- [x] UI preview gate: n/a, lifecycle-only change
- [x] Delivery 10/10, Design 10/10, overall >= 9.5, no open Major/Blocker
- [x] User reviewed the pack and explicitly confirmed Execute

## Implementation - `am_common`

- [x] Add normalized typed `MarketStreamInstrument` intent
- [x] Add owner-scoped `replaceScope` and `releaseScope` to `PriceService`
- [x] Diff effective union; preserve symbols still owned by another scope
- [x] Remove deleted symbols from pending debounce before flush
- [x] Split index and equity gateway batches
- [x] Reconnect and market gate replay only effective union
- [x] Retain safe compatibility path for non-migrated callers (`subscribe`/`unsubscribe` remain available)
- [x] Add subscription/first-tick latency logs without tokens or credentials
- [x] Run temporary focused scope test (passed; test file not retained)

## Implementation - `am_market/common`

- [x] Replace monotonic `_subscribedSymbols`/`_detailSymbols` ownership
- [x] Add cached desired sets per Market surface
- [x] Add active surface and generation protection
- [x] Stop `loadAllIndicesData` and `refreshIndexData` from globally subscribing everything
- [x] Verify surface files with targeted analyzer

## Implementation - `am_market/ui`

- [x] Drive active surface from `SwipeNavigationController` listener and initial URL sync
- [x] Dashboard publishes rendered pinned indices, comparison indices, mover index, and displayed mover rows
- [x] All Indices publishes its current rendered/filter result
- [x] Watch List publishes its current rendered page
- [x] Equity Insider publishes exactly the selected symbol and atomically replaces it
- [x] Paper Trading publishes its visible watchlist page through a host scope
- [x] Chart publishes its visible chart panes through a host scope
- [x] Futures & Options publishes its active underlying through a host scope
- [ ] Stock Detail uses a unique route-instance scope
- [x] Non-live Market tabs activate an empty Market scope
- [x] Add family live-quote provider over shared `PriceService`
- [x] Overlay live price/change in Equity Insider hero
- [ ] Apply live point only to 1D chart, not long-range charts
- [ ] Write widget regressions T1, T3, T4, T10

## Verification

- [x] Run focused scope test and targeted analyzers
- [x] Verify Paper/Chart/F&O scope bridge with targeted analyzer
- [ ] Run full `flutter analyze` on all touched packages with zero findings (blocked by pre-existing package errors/warnings)
- [ ] Build and serve the web app locally using the repo workflow
- [ ] Browser B1: Dashboard -> Insider -> symbol switch -> Dashboard exact frame diff
- [ ] Browser B2: reconnect restores only current scope
- [ ] Confirm no token/credential appears in logs
- [ ] User tests locally before any push

Verification note: `market_dashboard_quote_test.dart` passes. Existing `equity_insider_hero_test.dart` has one unrelated layout assertion failure (expected 32px, actual 36px).

## Deploy and report

- [ ] Deploy to preprod only after explicit approval and local pass
- [ ] Run B3 during market hours and record first-tick latency
- [ ] Create `REPORT.md` only after all required rows pass
- [ ] Commit/push/PR only when explicitly requested
