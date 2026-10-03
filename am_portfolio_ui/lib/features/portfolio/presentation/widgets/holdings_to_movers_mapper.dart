import 'package:am_analysis_core/am_analysis_core.dart';
import 'package:am_design_system/am_design_system.dart' as ds;

import '../../internal/domain/entities/portfolio_holding.dart';

/// Builds top-mover rows from portfolio holdings when analysis API returns 500.
/// Equity-only; near-zero day moves omitted so UI stays honest.
List<MoverItem> moversFromHoldings(
  List<PortfolioHolding> holdings, {
  required ds.TimeFrame timeFrame,
  int limit = 10,
}) {
  final useDaily = timeFrame == ds.TimeFrame.oneDay;

  final movers = holdings
      .where((h) {
        final cls = h.assetClass.trim().toUpperCase();
        return cls.isEmpty || cls == 'EQUITY';
      })
      .map((h) {
        final pct = useDaily ? h.todayChangePercentage : h.totalGainLossPercentage;
        final amt = useDaily ? h.todayChange : h.totalGainLoss;
        return MoverItem(
          symbol: h.symbol,
          name: h.companyName.isNotEmpty ? h.companyName : h.symbol,
          price: h.currentPrice,
          changePercentage: pct,
          changeAmount: amt,
        );
      })
      .where((m) => m.changePercentage.abs() > 0.005)
      .toList();

  movers.sort(
    (a, b) => b.changePercentage.abs().compareTo(a.changePercentage.abs()),
  );
  return movers.take(limit * 2).toList();
}
