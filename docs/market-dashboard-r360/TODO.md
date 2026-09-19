# TODO — `market-dashboard-r360`

## Gate

- [ ] User reviewed PLAN (free vs premium cut, P0 layout)
- [ ] Open decisions answered (viewport, TF set, FII chip)
- [ ] User: go / approved / implement
- [ ] (After approve) Stitch / preview images in `images/`
- [ ] Agent satisfied → Execute

## P0 (after approve)

- [ ] Presentation layout: strip → chart → movers hub → sector → heatmap
- [ ] Wire `OverviewSectionPort` (and TF) to new widgets — no old template
- [ ] Movers hub: Gainers | Losers + TF chips; keep index picker
- [ ] Sector row from `fetchSectorPerformance`
- [ ] Heatmap from existing provider
- [ ] FII/DII today chip → Activity route (use kept port)
- [ ] Empty / error states per PLAN matrix
- [ ] Widget + unit tests for hub + TF mapping
- [ ] :9000 smoke

## P1

- [ ] Advance/Decline source
- [ ] Most Active + 52W APIs or client ranking
- [ ] News / corporate actions slot

## P2 / never

- [ ] Recovery, Only Buyers, Ace, IPO — backlog
- [ ] Never: Advisory / Alpha / Basket / IAP / Reports
