/// Calendar data provider interface and implementations
library;

import 'dart:async';
import 'package:am_design_system/core/utils/common_logger.dart';


import 'card_types.dart';


/// Abstract data provider for calendar cards
abstract class CalendarDataProvider {
  /// Get card data for a specific date range
  Future<Map<String, List<CardData>>> getCardData({
    required DateTime startDate,
    required DateTime endDate,
    required List<CalendarCardType> cardTypes,
    Map<String, dynamic>? filters,
  });

  /// Get available card types for this provider
  List<CalendarCardType> getSupportedCardTypes();

  /// Get default card configurations
  List<CalendarCardConfig> getDefaultCardConfigs();

  /// Stream for real-time data updates
  Stream<Map<String, List<CardData>>>? get dataStream => null;
}

/// Trading data provider
class TradeCalendarDataProvider extends CalendarDataProvider {
  TradeCalendarDataProvider({this.portfolioId, this.mockData});

  final String? portfolioId;
  final Map<String, dynamic>? mockData;

  @override
  Future<Map<String, List<CardData>>> getCardData({
    required DateTime startDate,
    required DateTime endDate,
    required List<CalendarCardType> cardTypes,
    Map<String, dynamic>? filters,
  }) async {
    CommonLogger.methodEntry('getCardData', tag: 'TradeCalendarDataProvider');
    CommonLogger.info('Fetching calendar data from $startDate to $endDate', tag: 'TradeCalendarDataProvider');
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 300));

    final result = <String, List<CardData>>{};

    // Process mock data or make API call
    final tradeData = mockData ?? await _fetchTradeData(startDate, endDate);
    CommonLogger.debug('Trade data received: ${tradeData.length} entries', tag: 'TradeCalendarDataProvider');


    // Group trades by date
    final tradesByDate = _groupTradesByDate(tradeData);

    // Generate card data for each date
    for (final entry in tradesByDate.entries) {
      final dateKey = entry.key;
      final trades = entry.value;
      final cardDataList = <CardData>[];

      for (final cardType in cardTypes) {
        final cardData = _generateTradeCardData(dateKey, trades, cardType);
        if (cardData != null) {
          cardDataList.add(cardData);
        }
      }

      if (cardDataList.isNotEmpty) {
        result[dateKey] = cardDataList;
      }
    }

    return result;
  }

  @override
  List<CalendarCardType> getSupportedCardTypes() => [
    CalendarCardType.pnlSummary,
    CalendarCardType.tradeMetrics,
    CalendarCardType.winLossRatio,
    CalendarCardType.riskReward,
    CalendarCardType.tradeVolume,
    CalendarCardType.summary,
  ];

  @override
  List<CalendarCardConfig> getDefaultCardConfigs() => [
    const CalendarCardConfig(
      type: CalendarCardType.pnlSummary,
      title: 'P&L Summary',
    ),
    const CalendarCardConfig(
      type: CalendarCardType.tradeMetrics,
      title: 'Trade Metrics',
      size: CardSizeType.large,
      layout: CardLayoutStyle.grid,
      theme: CardTheme.info,
    ),
    const CalendarCardConfig(
      type: CalendarCardType.winLossRatio,
      title: 'Win/Loss Ratio',
      size: CardSizeType.small,
      layout: CardLayoutStyle.chart,
    ),
  ];

  Future<Map<String, dynamic>> _fetchTradeData(
    DateTime start,
    DateTime end,
  ) async {
    CommonLogger.warning(
      '🚨 _fetchTradeData is currently returning EMPTY data. '
      'This needs to be implemented with a real API call or linked to a repository.',
      tag: 'TradeCalendarDataProvider',
    );
    // In real implementation, this would make an API call
    // For now, return empty data
    return {};
  }


  Map<String, List<Map<String, dynamic>>> _groupTradesByDate(
    Map<String, dynamic> data,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    // Extract trades from mock data structure
    if (data.isNotEmpty) {
      for (final portfolioEntry in data.values) {
        if (portfolioEntry is List) {
          for (final trade in portfolioEntry) {
            if (trade is Map<String, dynamic> &&
                trade.containsKey('tradeDate')) {
              final dateKey = trade['tradeDate'] as String;
              grouped.putIfAbsent(dateKey, () => []).add(trade);
            }
          }
        }
      }
    }

    return grouped;
  }

  CardData? _generateTradeCardData(
    String dateKey,
    List<Map<String, dynamic>> trades,
    CalendarCardType cardType,
  ) {
    if (trades.isEmpty) return null;

    switch (cardType) {
      case CalendarCardType.pnlSummary:
        return _generatePnLCardData(dateKey, trades);
      case CalendarCardType.tradeMetrics:
        return _generateTradeMetricsCardData(dateKey, trades);
      case CalendarCardType.winLossRatio:
        return _generateWinLossCardData(dateKey, trades);
      default:
        return null;
    }
  }

  TradeCardData _generatePnLCardData(
    String dateKey,
    List<Map<String, dynamic>> trades,
  ) {
    double totalPnL = 0;
    var winCount = 0;
    var lossCount = 0;

    for (final trade in trades) {
      final status = trade['status'] as String?;
      final metrics = trade['metrics'] as Map<String, dynamic>?;

      if (metrics != null && metrics.containsKey('totalPnL')) {
        totalPnL += (metrics['totalPnL'] as num).toDouble();
      }

      if (status == 'WIN') {
        winCount++;
      } else if (status == 'LOSS') {
        lossCount++;
      }
    }

    return TradeCardData(
      dateKey: dateKey,
      pnl: totalPnL,
      tradeCount: trades.length,
      winCount: winCount,
      lossCount: lossCount,
      trades: trades,
    );
  }

  TradeCardData _generateTradeMetricsCardData(
    String dateKey,
    List<Map<String, dynamic>> trades,
  ) {
    final cardData = _generatePnLCardData(dateKey, trades);

    // Calculate additional metrics
    double totalVolume = 0;
    for (final trade in trades) {
      final entryInfo = trade['entryInfo'] as Map<String, dynamic>?;
      if (entryInfo != null) {
        final quantity = (entryInfo['quantity'] as num?)?.toDouble() ?? 0;
        final price = (entryInfo['price'] as num?)?.toDouble() ?? 0;
        totalVolume += quantity * price;
      }
    }

    return cardData.copyWith(
      totalVolume: totalVolume,
      winRate: cardData.calculatedWinRate,
    );
  }

  TradeCardData _generateWinLossCardData(
    String dateKey,
    List<Map<String, dynamic>> trades,
  ) => _generatePnLCardData(dateKey, trades);
}

/// Portfolio data provider
class PortfolioCalendarDataProvider extends CalendarDataProvider {
  PortfolioCalendarDataProvider({this.portfolioId});

  final String? portfolioId;

  @override
  Future<Map<String, List<CardData>>> getCardData({
    required DateTime startDate,
    required DateTime endDate,
    required List<CalendarCardType> cardTypes,
    Map<String, dynamic>? filters,
  }) async {
    // Simulate portfolio data fetching
    await Future.delayed(const Duration(milliseconds: 200));

    final result = <String, List<CardData>>{};

    // Generate mock portfolio data for the date range
    final currentDate = startDate;
    while (!currentDate.isAfter(endDate)) {
      final dateKey = _formatDate(currentDate);
      final cardDataList = <CardData>[];

      for (final cardType in cardTypes) {
        final cardData = _generatePortfolioCardData(dateKey, cardType);
        if (cardData != null) {
          cardDataList.add(cardData);
        }
      }

      if (cardDataList.isNotEmpty) {
        result[dateKey] = cardDataList;
      }

      currentDate.add(const Duration(days: 1));
    }

    return result;
  }

  @override
  List<CalendarCardType> getSupportedCardTypes() => [
    CalendarCardType.portfolioValue,
    CalendarCardType.assetAllocation,
    CalendarCardType.portfolioPerformance,
    CalendarCardType.diversification,
  ];

  @override
  List<CalendarCardConfig> getDefaultCardConfigs() => [
    const CalendarCardConfig(
      type: CalendarCardType.portfolioValue,
      title: 'Portfolio Value',
      theme: CardTheme.info,
    ),
    const CalendarCardConfig(
      type: CalendarCardType.assetAllocation,
      title: 'Asset Allocation',
      size: CardSizeType.large,
      layout: CardLayoutStyle.chart,
    ),
  ];

  CardData? _generatePortfolioCardData(
    String dateKey,
    CalendarCardType cardType,
  ) {
    switch (cardType) {
      case CalendarCardType.portfolioValue:
        return PortfolioCardData(
          dateKey: dateKey,
          totalValue: 100000 + (DateTime.now().millisecondsSinceEpoch % 50000),
          dailyChange: (DateTime.now().millisecondsSinceEpoch % 10000) - 5000,
          dailyChangePercent:
              ((DateTime.now().millisecondsSinceEpoch % 1000) - 500) / 100,
        );
      default:
        return null;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Data provider factory
class CalendarDataProviderFactory {
  static CalendarDataProvider createProvider({
    required String context,
    Map<String, dynamic>? config,
  }) {
    switch (context.toLowerCase()) {
      case 'trade':
      case 'trading':
        return TradeCalendarDataProvider(
          portfolioId: config?['portfolioId'] as String?,
          mockData: config?['mockData'] as Map<String, dynamic>?,
        );
      case 'portfolio':
        return PortfolioCalendarDataProvider(
          portfolioId: config?['portfolioId'] as String?,
        );
      default:
        return TradeCalendarDataProvider(); // Default fallback
    }
  }
}

/// Extension for TradeCardData
extension TradeCardDataExtension on TradeCardData {
  TradeCardData copyWith({
    String? dateKey,
    double? pnl,
    int? tradeCount,
    int? winCount,
    int? lossCount,
    double? totalVolume,
    Duration? avgHoldingTime,
    double? maxDrawdown,
    double? winRate,
    List<Map<String, dynamic>>? trades,
    Map<String, dynamic>? metadata,
  }) => TradeCardData(
    dateKey: dateKey ?? this.dateKey,
    pnl: pnl ?? this.pnl,
    tradeCount: tradeCount ?? this.tradeCount,
    winCount: winCount ?? this.winCount,
    lossCount: lossCount ?? this.lossCount,
    totalVolume: totalVolume ?? this.totalVolume,
    avgHoldingTime: avgHoldingTime ?? this.avgHoldingTime,
    maxDrawdown: maxDrawdown ?? this.maxDrawdown,
    winRate: winRate ?? this.winRate,
    trades: trades ?? this.trades,
    metadata: metadata ?? this.metadata,
  );
}
