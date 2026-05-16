import 'package:am_analysis_core/am_analysis_core.dart';
import 'package:am_design_system/am_design_system.dart' as ds;

import '../../internal/domain/entities/portfolio_holding.dart';

/// Builds top-mover rows from portfolio holdings when analysis API returns 500.
List<MoverItem> moversFromHoldings(
  List<PortfolioHolding> holdings, {
  required ds.TimeFrame timeFrame,
  int limit = 10,
}) {
  final useDaily = timeFrame == ds.TimeFrame.oneDay;

  final movers = holdings.map((h) {
    final pct = useDaily ? h.todayChangePercentage : h.totalGainLossPercentage;
    final amt = useDaily ? h.todayChange : h.totalGainLoss;
    return MoverItem(
      symbol: h.symbol,
      name: h.name.isNotEmpty ? h.name : h.companyName,
      price: h.currentPrice,
      changePercentage: pct,
      changeAmount: amt,
      isGainer: pct >= 0,
    );
  }).toList();

  movers.sort((a, b) => b.changePercentage.abs().compareTo(a.changePercentage.abs()));
  return movers.take(limit * 2).toList();
}