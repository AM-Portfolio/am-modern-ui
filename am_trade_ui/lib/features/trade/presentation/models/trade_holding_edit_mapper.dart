import '../../internal/domain/entities/trade_controller_entities.dart';
import '../../internal/domain/enums/broker_types.dart';
import '../../internal/domain/enums/derivative_types.dart';
import '../../internal/domain/enums/exchange_types.dart';
import '../../internal/domain/enums/index_types.dart';
import '../../internal/domain/enums/market_segments.dart';
import '../../internal/domain/enums/option_types.dart';
import '../../internal/domain/enums/order_types.dart';
import '../../internal/domain/enums/series_types.dart';
import '../../internal/domain/enums/trade_directions.dart';
import '../../internal/domain/enums/trade_statuses.dart';
import 'trade_holding_view_model.dart';

/// Maps a holdings row into [TradeDetails] for the edit-trade form.
TradeDetails tradeHoldingToEditableDetails(TradeHoldingViewModel holding) {
  T? parseEnum<T extends Enum>(Iterable<T> values, String? str) {
    if (str == null) return null;
    final normalized = str.toLowerCase().replaceAll('_', '');
    for (final v in values) {
      if (v.name.toLowerCase() == normalized) return v;
    }
    return null;
  }

  return TradeDetails(
    tradeId: holding.tradeId,
    portfolioId: holding.portfolioId,
    instrumentInfo: InstrumentInfo(
      symbol: holding.symbol,
      rawSymbol: holding.rawSymbol,
      exchange: parseEnum(ExchangeTypes.values, holding.exchange),
      segment: parseEnum(MarketSegments.values, holding.marketSegment),
      series: parseEnum(SeriesTypes.values, holding.series),
      indexType: parseEnum(IndexTypes.values, holding.indexType),
      derivativeInfo: holding.strikePrice != null
          ? DerivativeInfo(
              strikePrice: holding.strikePrice,
              expiryDate: holding.expiryDate,
              optionType: parseEnum(OptionTypes.values, holding.optionType),
              underlyingSymbol: holding.underlyingSymbol,
              derivativeType:
                  parseEnum(DerivativeTypes.values, holding.derivativeType),
            )
          : null,
      description: holding.description,
      currency: holding.currency,
      lotSize: holding.lotSize,
      isin: holding.isin,
    ),
    status: parseEnum(TradeStatuses.values, holding.status) ?? TradeStatuses.open,
    tradePositionType:
        parseEnum(TradeDirections.values, holding.tradePositionType) ??
            TradeDirections.long,
    entryInfo: EntryExitInfo(
      timestamp: holding.entryTimestamp,
      price: holding.entryPrice,
      quantity: holding.quantity,
      totalValue: holding.entryTotalValue,
      fees: holding.entryFees,
      reason: holding.entryReason,
    ),
    symbol: holding.symbol,
    strategy: holding.strategy,
    exitInfo: (holding.exitTimestamp != null || holding.exitPrice != null)
        ? EntryExitInfo(
            timestamp: holding.exitTimestamp,
            price: holding.exitPrice,
            quantity: holding.quantity,
            totalValue: holding.exitTotalValue,
            fees: holding.exitFees,
            reason: holding.exitReason,
          )
        : null,
    currentPrice: holding.currentPrice,
    metrics: TradeMetrics(
      profitLoss: holding.profitLoss,
      profitLossPercentage: holding.profitLossPercentage,
      returnOnEquity: holding.returnOnEquity,
      riskAmount: holding.riskAmount,
      rewardAmount: holding.rewardAmount,
      riskRewardRatio: holding.riskRewardRatio,
      holdingTimeDays: holding.holdingDays,
      maxAdverseExcursion: holding.maxAdverseExcursion,
      maxFavorableExcursion: holding.maxFavorableExcursion,
    ),
    tradeExecutions: (holding.broker != null || holding.orderType != null)
        ? [
            TradeModel(
              basicInfo: holding.broker != null
                  ? BasicInfo(
                      brokerType:
                          parseEnum(BrokerTypes.values, holding.broker),
                    )
                  : null,
              executionInfo: holding.orderType != null
                  ? ExecutionInfo(
                      orderType:
                          parseEnum(OrderTypes.values, holding.orderType),
                    )
                  : null,
            )
          ]
        : null,
    notes: holding.notes,
    tags: holding.tags,
    userId: holding.userId,
    psychologyData: holding.psychologyData,
  );
}
