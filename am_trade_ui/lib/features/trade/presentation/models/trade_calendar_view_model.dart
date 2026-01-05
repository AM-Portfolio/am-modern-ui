import 'package:am_common/core/utils/logger.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../internal/domain/entities/trade_calendar.dart';
import '../../internal/domain/entities/trade_controller_entities.dart';
import '../converters/trade_calendar_converter.dart';

/// View model for trade calendar data optimized for UI consumption
class TradeCalendarViewModel {
  const TradeCalendarViewModel({
    required this.portfolioId,
    required this.calendarData,
    this.tradeDetailsData,
    this.dateFilter,
    this.selectedDate,
    this.lastUpdated,
  });

  /// Factory method to create TradeCalendarViewModel from TradeCalendar entity
  factory TradeCalendarViewModel.fromEntity(TradeCalendar entity) {
    AppLogger.info(
      '[ViewModel] Creating from entity with ${entity.portfolioTrades.length} portfolios',
      tag: 'TradeCalendarViewModel',
    );

    // Get the portfolio ID from the first available portfolio
    final portfolioId = entity.portfolioTrades.keys.isNotEmpty ? entity.portfolioTrades.keys.first : '';

    AppLogger.info('[ViewModel] Selected portfolioId: $portfolioId', tag: 'TradeCalendarViewModel');

    // Convert entity to calendar data using the converter
    final calendarData = TradeCalendarConverter.convertEntityToCalendarData(entity: entity);

    // Organize trade details by date
    final tradeDetailsMap = <String, List<TradeDetails>>{};
    if (entity.portfolioTrades.isNotEmpty) {
      final trades = entity.portfolioTrades[portfolioId] ?? [];
      AppLogger.info(
        '[ViewModel] Processing ${trades.length} trades for portfolio $portfolioId',
        tag: 'TradeCalendarViewModel',
      );

      for (final trade in trades) {
        final tradeDate = trade.entryInfo.timestamp;
        if (tradeDate != null) {
          final dateKey = tradeDate.toIso8601String().substring(0, 10);
          if (!tradeDetailsMap.containsKey(dateKey)) {
            tradeDetailsMap[dateKey] = [];
          }
          tradeDetailsMap[dateKey]!.add(trade);
        }
      }

      AppLogger.info(
        '[ViewModel] Organized trades into ${tradeDetailsMap.length} dates',
        tag: 'TradeCalendarViewModel',
      );
      for (final entry in tradeDetailsMap.entries) {
        AppLogger.debug('[ViewModel] Date ${entry.key}: ${entry.value.length} trades', tag: 'TradeCalendarViewModel');
      }
    }

    return TradeCalendarViewModel(
      portfolioId: portfolioId,
      calendarData: calendarData,
      tradeDetailsData: tradeDetailsMap,
      lastUpdated: DateTime.now(),
    );
  }

  /// Portfolio ID this calendar represents
  final String portfolioId;

  /// Calendar data organized by date (for universal calendar widget)
  final Map<String, List<CardData>> calendarData;

  /// Trade details organized by date (for hierarchical calendar)
  final Map<String, List<TradeDetails>>? tradeDetailsData;

  /// Applied date filter
  final DateSelection? dateFilter;

  /// Currently selected date
  final DateTime? selectedDate;

  /// When this data was last updated
  final DateTime? lastUpdated;

  /// Get all available dates from calendar data
  List<DateTime> get availableDates => calendarData.keys.map(DateTime.parse).toList()..sort();

  /// Get all events (deprecated, use calendarData instead)
  @deprecated
  List<Map<String, dynamic>> get events =>
      calendarData.entries.map((entry) => {'date': entry.key, 'cards': entry.value}).toList();

  /// Get date range from available data
  DateSelection? get dateRange {
    if (calendarData.isEmpty) return null;

    final dates = availableDates;
    if (dates.isEmpty) return null;

    return DateSelection(
      startDate: dates.first,
      endDate: dates.last,
      description: 'Trade Calendar Range',
      filterType: DateFilterMode.custom,
    );
  }

  /// Get total number of trade days
  int get totalTradeDays => calendarData.length;

  /// Get total P&L across all dates
  double get totalPnL {
    var total = 0.0;
    for (final cards in calendarData.values) {
      for (final card in cards) {
        if (card is TradeCardData) {
          total += card.pnl;
        }
      }
    }
    return total;
  }

  /// Get total trade count across all dates
  int get totalTradeCount {
    var total = 0;
    for (final cards in calendarData.values) {
      for (final card in cards) {
        if (card is TradeCardData) {
          total += card.tradeCount;
        }
      }
    }
    return total;
  }

  /// Get overall win rate
  double get overallWinRate {
    var totalWins = 0;
    var totalTrades = 0;

    for (final cards in calendarData.values) {
      for (final card in cards) {
        if (card is TradeCardData) {
          totalWins += card.winCount;
          totalTrades += card.tradeCount;
        }
      }
    }

    return totalTrades > 0 ? totalWins / totalTrades : 0.0;
  }

  /// Copy with new parameters
  TradeCalendarViewModel copyWith({
    String? portfolioId,
    Map<String, List<CardData>>? calendarData,
    Map<String, List<TradeDetails>>? tradeDetailsData,
    DateSelection? dateFilter,
    DateTime? selectedDate,
    DateTime? lastUpdated,
  }) => TradeCalendarViewModel(
    portfolioId: portfolioId ?? this.portfolioId,
    calendarData: calendarData ?? this.calendarData,
    tradeDetailsData: tradeDetailsData ?? this.tradeDetailsData,
    dateFilter: dateFilter ?? this.dateFilter,
    selectedDate: selectedDate ?? this.selectedDate,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}
