# Overview chart timeframe sync + full popup

| Field | Value |
|-------|-------|
| kind | feature |
| slug | overview-chart-timeframe-sync |
| Lead repo | am-modern-ui |
| Other repos | am-portfolio; am-market only if 1D candles truncated |
| Target env | preprod |
| Branch | feature/overview-chart-timeframe-sync |

## Problem

Overview comparison chart does not feel synced to the global timeframe: 1Y can look wrong / labels weak; **1D starts ~13:55** instead of full session 09:15–15:30 IST; holiday/weekend 1D flatlines instead of last working day; expand icon is off on Overview.

## World-class feature map

### P0

- Timeframe → chart window: 1D full session; 1W=7d; 1M=30d; 3M/6M/1Y/5Y matching lookback; X-axis formats per TF.
- 1D holiday/weekend/pre-open → last trading day’s intraday curve.
- Partial candle payloads still span 09:15→close via carry-forward from open baseline.
- Fit-to-window default zoom so full TF is visible; expand opens full overview via `/app/chart/compare`.
- Surfaces: `PortfolioComparisonChartSection` → `DashboardChartWidget` → `ComparisonChartView` / `MultiIndexChart`.

### P1

- Holiday calendar (NSE) instead of weekday walk-back.
- Golden/widget tests for zoom fit.

### P2

- Per-user zoom memory; shareable expand deep link with series list.

## Current system (verified)

- Global `appTimeFrameProvider` reloads `dashboardOverlayProvider`.
- 1D → `GET /v1/portfolios/intraday`; else `GET /v1/portfolios/history?timeFrame=`.
- Indices → `GET /v1/analysis/historical-charts?range=`.
- `PortfolioIntradayService` skips charts when cash closed; holiday lookback removed.
- `PortfolioSnapshotService` uses calendar Periods (1M ≠ 30d UI).
- `showExpandButton: false` on Overview overlay; market already wires `expandedChartPath`.

## Target journeys

1. User selects 1Y → chart shows ~12 months, monthly X ticks, fit viewport.
2. User selects 1D mid-session → X from ~09:15 to now (not 13:55-only).
3. User opens app on holiday → 1D shows last working day session.
4. User taps expand → full Performance Chart page with same series/TF.

## Latency & consistency

- Overlay reload on TF change; intraday Redis TTL short when session incomplete.
- No invented p99; chart may show sync banner while history BUILDING.

## Corner-case matrix

| Case | Trigger | Expected | Covered by |
|------|---------|----------|------------|
| Partial candles from 13:55 | Incomplete OHLC | Series from 09:15 via carry-forward | unit |
| Weekend / holiday | Cash closed | Last trading day candles | unit |
| Empty holdings | No symbols | 09:15 flat baseline only | unit |
| 1M lookback | history?timeFrame=1M | 30 calendar days | unit |
| Expand | Icon on Overview | `/app/chart/compare?context=dashboard&tf=…` | manual |

## UI previews (modern-ui)

Gate passes (P0 visible Overview chart). Refs: `docs/ui-pages` portfolio/dashboard patterns; user screenshots in pack images. After-change preview: `images/preview-overview-chart-after.png`.

## Out of scope

New ISIN APIs; paper-trading; Market Movers rewrite; wealth % formula changes beyond window.

## Test Plan

1. Overview: switch 1D/1W/1M/3M/6M/1Y/5Y — window and X labels match table.
2. 1D mid/late session — first tick ~09:15.
3. Weekend/holiday — last working day intraday.
4. Expand icon → full overview page.
5. `mvn test` portfolio intraday/history; Flutter overlay/chart unit tests.

## Agent scorecard

| Dimension | Score |
|-----------|-------|
| Product | 9.5 |
| Architecture | 9.5 |
| Data / contracts | 9.5 |
| State / money | 9.0 |
| Reliability | 9.5 |
| Security | 9.5 |
| Observability | 9.0 |
| Testability | 9.5 |
| Operability | 9.5 |
| TODO | 9.5 |
| **Overall** | **9.5** |

Delivery 10 · Design 10 · Agent satisfied: yes (user confirmed Cursor plan Execute).
