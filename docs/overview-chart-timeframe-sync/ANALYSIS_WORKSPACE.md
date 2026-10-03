# Chart analysis workspace (addendum)

Overview expand (`/app/chart/compare?context=dashboard`) opens a **Chart Analysis Workspace**:

- Layouts: 1 / 2-stack / 2×2 (max 4 cards)
- Defaults: Compare **Overall + NIFTY 50** (+ preferred portfolio when present); Candle **NIFTY 50** + SMA(20)
- Per-card timeframe, symbol search, Compare vs Candle mode
- Indicators (candle): SMA 20/50, EMA 20, RSI 14, MACD
- Optional Sync TF across cards

Overview embed still applies window fixes: re-baseline to 0%, pad daily TF to today, denser 6M ticks, hide 0.0/last-value guides when `showEndValuePills: false`.
