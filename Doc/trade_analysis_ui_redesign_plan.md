# Trade Analysis UI Redesign Plan

> This doc was created per `AGENTS.md` — all plans live in `Doc/`.

See the full plan in the IDE artifact. Summary of phases:

## Execution Order

1. **Phase 5 → `trade_analysis_page.dart`**: Tighten header — title row, then sub-row with portfolio/date/apply/refresh/download.
2. **Phase 2 → `timing_insights_banner.dart`**: Redesign as a single-row info bar with icon+bold+sub-label facts, purple links, dismiss button.
3. **Phase 1 → `timing_kpi_row.dart`**: KPI cards — large value left, sparkline/donut right, remove left icons.
4. **Phase 3 → `timing_avg_pnl_chart.dart`**: Taller charts (200px), Y-axis labels, rounded bar corners, Weakest/Best pill badges.
5. **Phase 4a → `timing_analysis_tab.dart`**: `_RankControls` — cleaner pill chips, stack icon before row count.
6. **Phase 4b → `timing_rank_table.dart`**: Flat table (no outer border), R:R colored fill bar, colored P&L/Win Rate cells.

## Files Changed

- `am_trade_ui/lib/features/trade/presentation/analysis/trade_analysis_page.dart`
- `am_trade_ui/lib/features/trade/presentation/analysis/widgets/timing_insights_banner.dart`
- `am_trade_ui/lib/features/trade/presentation/analysis/widgets/timing_kpi_row.dart`
- `am_trade_ui/lib/features/trade/presentation/analysis/widgets/timing_avg_pnl_chart.dart`
- `am_trade_ui/lib/features/trade/presentation/analysis/tabs/timing_analysis_tab.dart`
- `am_trade_ui/lib/features/trade/presentation/analysis/widgets/timing_rank_table.dart`
