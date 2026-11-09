# TODO — Dashboard Top Movers → Equity Insider

Pack: `docs/dashboard-top-movers-equity-insider/`

## Plan loop

- [x] Ingest current user request as source plan
- [x] Lookup `am-repo-catalog` and resolve `am-modern-ui` / market packages
- [x] Read context pack and verify active widget path
- [x] Coverage check: `handles`
- [x] World-class feature map, journeys, latency, and corner matrix
- [x] Decide host callback boundary; keep app-level route ownership out of `am_market/ui`
- [ ] Create/update themed `architecture.drawio`
- [x] User reviewed PLAN + TODO + architecture and confirmed Execute

## Implementation — only after user confirmation

- [x] Add optional item activation callback to `AmMoverTile` with semantics, focus, keyboard activation, and existing hover behavior preserved.
- [x] Thread `AmTopMoversPanel.onItemTap` through desktop and mobile builders.
- [x] Add `TopMoversWidgetV2.onSymbolTap` and map `AmMoverItem.symbol` to the market callback.
- [x] Add `UserDashboardPage.onTopMoverSelected` without importing app routing.
- [x] Add `MarketContent` host method that normalizes the symbol, selects the existing Equity Insider item, seeds provider state, and calls `navigateToSymbol` through `_equityInsiderKey` using the existing safe timing pattern.
- [x] Preserve the existing dashboard/top-mover stream and index selector code paths.
- [x] Preserve mobile segmented gainers/losers behavior through the shared panel callback.
- [x] Add design-system and Market UI interaction tests.
- [x] Run targeted analyzer checks on touched files; full `am_market/ui` analysis remains blocked by pre-existing unrelated package errors.
- [x] Run local web build and verify `http://localhost:9000` responds with HTTP 200.
- [ ] Browser click-through remains pending because the computer-use browser pipe is unavailable in this session.

## Deploy / report

- [ ] No production mutation
- [ ] Preprod only after explicit user approval and verified local tests
- [ ] Write REPORT.md only after tests and manual flow pass
