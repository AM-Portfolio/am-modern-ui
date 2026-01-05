import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/trade_statuses.dart';
import 'trade_controller_entities.dart';

part 'trade_calendar.freezed.dart';

/// Trade calendar entity representing calendar data from the domain perspective
@freezed
abstract class TradeCalendar with _$TradeCalendar {
  const factory TradeCalendar({required Map<String, List<TradeDetails>> portfolioTrades}) = _TradeCalendar;

  /// Factory for creating empty trade calendar
  factory TradeCalendar.empty(String userId, String portfolioId) => const TradeCalendar(portfolioTrades: {});

  const TradeCalendar._();

  /// Get all trades from all portfolios as a flat list
  List<TradeDetails> get allTrades {
    final trades = <TradeDetails>[];
    for (final portfolioTradeList in portfolioTrades.values) {
      trades.addAll(portfolioTradeList);
    }
    return trades;
  }

  /// Get trades for a specific portfolio
  List<TradeDetails> getTradesForPortfolio(String portfolioId) => portfolioTrades[portfolioId] ?? [];

  /// Get trades by date range
  List<TradeDetails> getTradesByDateRange(DateTime startDate, DateTime endDate) => allTrades.where((trade) {
    final tradeDate = trade.entryInfo.timestamp;
    return tradeDate != null &&
        tradeDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        tradeDate.isBefore(endDate.add(const Duration(days: 1)));
  }).toList();

  /// Get trades by status
  List<TradeDetails> getTradesByStatus(TradeStatuses status) =>
      allTrades.where((trade) => trade.status == status).toList();

  /// Get trades by symbol
  List<TradeDetails> getTradesBySymbol(String symbol) =>
      allTrades.where((trade) => trade.instrumentInfo.symbol?.toUpperCase() == symbol.toUpperCase()).toList();

  /// Get total number of trades
  int get totalTradesCount => allTrades.length;

  /// Get total profit/loss across all trades
  double get totalProfitLoss => allTrades.fold(0.0, (sum, trade) => sum + (trade.metrics?.profitLoss ?? 0.0));

  /// Get winning trades count
  int get winningTradesCount => allTrades.where((trade) => (trade.metrics?.profitLoss ?? 0.0) > 0).length;

  /// Get losing trades count
  int get losingTradesCount => allTrades.where((trade) => (trade.metrics?.profitLoss ?? 0.0) < 0).length;

  /// Get break-even trades count
  int get breakEvenTradesCount => allTrades.where((trade) => (trade.metrics?.profitLoss ?? 0.0) == 0).length;

  /// Calculate win rate percentage
  double get winRate {
    if (totalTradesCount == 0) return 0.0;
    return (winningTradesCount / totalTradesCount) * 100;
  }

  /// Get unique symbols traded
  Set<String> get uniqueSymbols =>
      allTrades.map((trade) => trade.instrumentInfo.symbol ?? '').where((s) => s.isNotEmpty).toSet();

  /// Get unique portfolios
  Set<String> get portfolioIds => portfolioTrades.keys.toSet();
}

/// Trade calendar event entity for individual trade events
@freezed
abstract class TradeCalendarEvent with _$TradeCalendarEvent {
  const factory TradeCalendarEvent({
    required String id,
    required DateTime date,
    required String type,
    String? symbol,
    String? status,
    double? amount,
    double? profitLoss,
    double? profitLossPercentage,
    String? description,
    Map<String, dynamic>? metadata,
  }) = _TradeCalendarEvent;

  const TradeCalendarEvent._();

  /// Create event from TradeDetails
  factory TradeCalendarEvent.fromTradeDetails(TradeDetails trade) => TradeCalendarEvent(
    id: trade.tradeId,
    date: trade.entryInfo.timestamp ?? DateTime.now(),
    type: trade.status.name.toUpperCase(),
    symbol: trade.instrumentInfo.symbol,
    status: trade.status.name,
    amount: trade.entryInfo.totalValue,
    profitLoss: trade.metrics?.profitLoss,
    profitLossPercentage: trade.metrics?.profitLossPercentage,
    description: trade.instrumentInfo.description,
    metadata: {
      'portfolioId': trade.portfolioId,
      'tradePositionType': trade.tradePositionType.name,
      'strategy': trade.strategy,
    },
  );

  /// Create event from TradeModel (execution)
  factory TradeCalendarEvent.fromTradeModel(TradeModel execution, String portfolioId) => TradeCalendarEvent(
    id: execution.basicInfo?.tradeId ?? '',
    date: execution.basicInfo?.tradeDate ?? DateTime.now(),
    type: execution.basicInfo?.tradeType?.name.toUpperCase() ?? 'UNKNOWN',
    symbol: execution.instrumentInfo?.symbol,
    status: execution.basicInfo?.tradeType?.name,
    amount: (execution.executionInfo?.quantity ?? 0) * (execution.executionInfo?.price ?? 0),
    description: execution.instrumentInfo?.description,
    metadata: {
      'portfolioId': portfolioId,
      'orderId': execution.basicInfo?.orderId,
      'brokerType': execution.basicInfo?.brokerType?.name,
      'quantity': execution.executionInfo?.quantity,
      'price': execution.executionInfo?.price,
    },
  );
}
