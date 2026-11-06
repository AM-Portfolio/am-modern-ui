# am_chart_ui phases

| Phase | Scope |
|-------|--------|
| 1 | Terminal shell, candlestick engine, watchlist, mock data, route, persist symbol/TF |
| 2 | Indicators + drawings + templates |
| 3 | Alerts + draw-to-trade + entry/SL/target |
| 4 | Fundamentals / news / corporate actions |
| 5 | F&O option chain |
| 6 | Multi-chart + replay + paper on chart |
| 7 | Strategy builder + backtest |
| 8 | Broker adapters + LIVE confirm |
| 9 | AI assistant |

Phase 1 is implemented in this package; later phases add behind the same contracts.

## Strategy catalog (phases 6–7)

Paper / Strategy Lab playbooks (ORB, VWAP, N-layer zones, baskets, etc.) live in:

- [`am_paper_ui/docs/STRATEGY_CATALOG.md`](../../am_paper_ui/docs/STRATEGY_CATALOG.md) — detailed rules + examples
- [`am_paper_ui/assets/config/strategies/`](../../am_paper_ui/assets/config/strategies/) — JSON templates by `strategyId`

Authoritative strategy math for backtest/algo runs is **am-strategy-lab** (am-trade-management), not the chart UI.
