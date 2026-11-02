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
  return TradeDetails(
    tradeId: holding.tradeId,
    portfolioId: holding.portfolioId,
    instrumentInfo: InstrumentInfo(
      symbol: holding.symbol,
      rawSymbol: holding.rawSymbol,
      exchange: parseExchange(holding.exchange),
      segment: parseMarketSegment(holding.marketSegment),
      series: parseFlexibleEnum(SeriesTypes.values, holding.series),
      indexType: parseFlexibleEnum(IndexTypes.values, holding.indexType),
      derivativeInfo: (holding.strikePrice != null ||
              holding.expiryDate != null ||
              holding.derivativeType != null ||
              holding.optionType != null)
          ? DerivativeInfo(
              strikePrice: holding.strikePrice,
              expiryDate: holding.expiryDate,
              optionType:
                  parseFlexibleEnum(OptionTypes.values, holding.optionType),
              underlyingSymbol: holding.underlyingSymbol,
              derivativeType: parseFlexibleEnum(
                  DerivativeTypes.values, holding.derivativeType),
            )
          : null,
      description: holding.description,
      currency: holding.currency,
      lotSize: holding.lotSize,
      isin: holding.isin,
    ),
    status: parseFlexibleEnum(TradeStatuses.values, holding.status) ??
        TradeStatuses.open,
    tradePositionType:
        parseFlexibleEnum(TradeDirections.values, holding.tradePositionType) ??
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
                      brokerType: parseFlexibleEnum(
                          BrokerTypes.values, holding.broker),
                    )
                  : null,
              executionInfo: holding.orderType != null
                  ? ExecutionInfo(
                      orderType: parseFlexibleEnum(
                          OrderTypes.values, holding.orderType),
                    )
                  : null,
            )
          ]
        : null,
    notes: holding.notes,
    tags: holding.tags,
    userId: holding.userId,
    psychologyData: holding.psychologyData,
    entryReasoning: holding.entryReasoning,
    exitReasoning: holding.exitReasoning,
    attachments: holding.attachments,
  );
}

/// Prefer API / cubit [TradeDetails], then holdings row, then optional hints
/// (e.g. portfolio name → broker).
TradeDetails resolveTradeForEdit({
  required TradeHoldingViewModel holding,
  List<TradeDetails>? knownTrades,
  TradeDetails? fetchedTrade,
  String? portfolioNameHint,
}) {
  final fromHolding = tradeHoldingToEditableDetails(holding);
  TradeDetails base = fetchedTrade ?? fromHolding;
  if (fetchedTrade == null && knownTrades != null) {
    for (final t in knownTrades) {
      if (t.tradeId == holding.tradeId) {
        base = t;
        break;
      }
    }
  }

  final instrument = base.instrumentInfo;
  final resolvedSegment = () {
    final s = instrument.segment;
    if (s != null && s != MarketSegments.unknown) return s;
    final h = fromHolding.instrumentInfo.segment;
    if (h != null && h != MarketSegments.unknown) return h;
    // Cash equity symbols almost always trade as Equity when segment was omitted.
    return MarketSegments.equity;
  }();
  final mergedInstrument = instrument.copyWith(
    exchange: instrument.exchange ?? fromHolding.instrumentInfo.exchange,
    segment: resolvedSegment,
    series: instrument.series ?? fromHolding.instrumentInfo.series,
    indexType: instrument.indexType ?? fromHolding.instrumentInfo.indexType,
    isin: instrument.isin ?? fromHolding.instrumentInfo.isin,
    description:
        instrument.description ?? fromHolding.instrumentInfo.description,
    derivativeInfo:
        instrument.derivativeInfo ?? fromHolding.instrumentInfo.derivativeInfo,
  );

  BrokerTypes? broker;
  OrderTypes? orderType;
  for (final e in [
    ...?base.tradeExecutions,
    ...?fromHolding.tradeExecutions,
  ]) {
    broker ??= e.basicInfo?.brokerType;
    orderType ??= e.executionInfo?.orderType;
  }
  broker ??= parseFlexibleEnum(BrokerTypes.values, portfolioNameHint) ??
      parseFlexibleEnum(BrokerTypes.values, holding.broker);
  orderType ??=
      parseFlexibleEnum(OrderTypes.values, holding.orderType);

  final List<TradeModel>? executions =
      (broker != null || orderType != null)
          ? [
              TradeModel(
                basicInfo:
                    broker != null ? BasicInfo(brokerType: broker) : null,
                executionInfo: orderType != null
                    ? ExecutionInfo(orderType: orderType)
                    : null,
              ),
            ]
          : base.tradeExecutions ?? fromHolding.tradeExecutions;

  // Prefer a real entry price; fall back to execution / holding / current.
  final entry = base.entryInfo;
  double? execPrice;
  for (final e in base.tradeExecutions ?? const <TradeModel>[]) {
    final p = e.executionInfo?.price;
    if (p != null && p > 0) {
      execPrice = p;
      break;
    }
  }
  final holdingPrice =
      holding.entryPrice ?? holding.avgPrice ?? holding.currentPrice;
  final resolvedPrice = (entry.price != null && entry.price! > 0)
      ? entry.price
      : (execPrice ??
          ((holdingPrice != null && holdingPrice > 0)
              ? holdingPrice
              : entry.price));

  return base.copyWith(
    instrumentInfo: mergedInstrument,
    entryInfo: entry.copyWith(price: resolvedPrice),
    currentPrice: base.currentPrice ?? holding.currentPrice,
    strategy: base.strategy ?? fromHolding.strategy,
    notes: base.notes ?? fromHolding.notes,
    tradeExecutions: executions,
    psychologyData: base.psychologyData ?? fromHolding.psychologyData,
    entryReasoning: base.entryReasoning ?? fromHolding.entryReasoning,
    exitReasoning: base.exitReasoning ?? fromHolding.exitReasoning,
    attachments: base.attachments ?? fromHolding.attachments,
  );
}

ExchangeTypes? parseExchange(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final n = _norm(raw);
  for (final v in ExchangeTypes.values) {
    if (_norm(v.name) == n || _norm(v.displayName) == n) return v;
  }
  return null;
}

MarketSegments? parseMarketSegment(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  // Prefer the dedicated converter (handles EQ, INDEX, etc.).
  final fromConverter = const MarketSegmentsConverter().fromJson(raw);
  if (fromConverter != null && fromConverter != MarketSegments.unknown) {
    return fromConverter;
  }
  return parseFlexibleEnum(MarketSegments.values, raw);
}

T? parseFlexibleEnum<T extends Enum>(Iterable<T> values, String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final n = _norm(raw);
  for (final v in values) {
    if (_norm(v.name) == n) return v;
    // Prefer displayName when the enum exposes one (BrokerTypes, etc.).
    try {
      final display = (v as dynamic).displayName as String?;
      if (display != null && _norm(display) == n) return v;
    } catch (_) {}
  }
  // Match SCREAMING_SNAKE / display-ish forms against enum name.
  for (final v in values) {
    if (_norm(v.name.replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => '_${m[0]}',
        )) ==
        n) {
      return v;
    }
  }
  return null;
}

String _norm(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
