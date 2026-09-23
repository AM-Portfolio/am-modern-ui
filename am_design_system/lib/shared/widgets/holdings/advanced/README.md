# Advanced Holdings (design system)

Shared advanced holdings table/card UI — visual twin of Trade’s advanced holdings layout, **without** depending on `am_trade_ui`.

## When to use

- **AdvancedHoldingsTemplate** — Portfolio Holdings (and any module that needs the advanced table/card chrome).
- **HoldingsDisplayTemplate** / universal holdings — simpler/legacy heatmap-style holdings display.

## How to use

1. Map your domain entity → `AdvancedHoldingRow`.
2. Pass rows into `AdvancedHoldingsTemplate` with your module `accentColor`.
3. Load data from **your** service APIs (e.g. portfolio `GET /v1/portfolios/holdings`). Do not call Trade holdings from Portfolio.

## Trade module

Trade keeps its own `TradeHoldingsAdvancedTemplate`. Do not edit Trade to adopt this template unless a separate migration is planned.
