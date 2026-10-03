import 'package:am_design_system/am_design_system.dart';

import '../../../internal/domain/entities/portfolio_holding.dart';

/// Maps portfolio domain holdings → design-system [AdvancedHoldingRow].
List<AdvancedHoldingRow> mapPortfolioHoldingsToAdvancedRows(
  Iterable<PortfolioHolding> holdings,
) {
  return holdings
      .map(
        (h) => AdvancedHoldingRow(
          id: h.id,
          symbol: h.symbol,
          companyName: h.companyName.isNotEmpty ? h.companyName : h.name,
          sector: h.sector.isEmpty ? null : h.sector,
          industry: h.industry.isEmpty ? null : h.industry,
          brokerLabel: h.primaryBroker?.brokerName,
          assetClass: h.assetClass.isEmpty ? null : h.assetClass,
          quantity: h.quantity,
          avgPrice: h.avgPrice,
          currentPrice: h.currentPrice,
          investedAmount: h.investedAmount,
          currentValue: h.currentValue,
          totalGainLoss: h.totalGainLoss,
          totalGainLossPercentage: h.totalGainLossPercentage,
          todayChange: h.todayChange,
          todayChangePercentage: h.todayChangePercentage,
          portfolioWeight: h.portfolioWeight,
        ),
      )
      .toList();
}
