import 'package:am_design_system/am_design_system.dart';

import '../../models/trade_holding_view_model.dart';

/// Maps trade holdings → design-system [AdvancedHoldingRow] for DS template.
List<AdvancedHoldingRow> mapTradeHoldingsToAdvancedRows(
  Iterable<TradeHoldingViewModel> holdings,
) {
  return holdings
      .map(
        (h) => AdvancedHoldingRow(
          id: h.tradeId,
          symbol: h.symbol,
          companyName: h.companyName,
          sector: h.sector,
          industry: h.industry,
          exchange: h.exchange,
          brokerLabel: h.broker,
          quantity: (h.quantity ?? 0).toDouble(),
          avgPrice: h.avgPrice ?? h.entryPrice ?? 0,
          currentPrice: h.currentPrice ?? 0,
          investedAmount: h.entryTotalValue ??
              ((h.quantity ?? 0) * (h.avgPrice ?? h.entryPrice ?? 0)),
          currentValue: h.currentValue ?? 0,
          totalGainLoss: h.profitLoss ?? 0,
          totalGainLossPercentage: h.profitLossPercentage ?? 0,
        ),
      )
      .toList();
}
