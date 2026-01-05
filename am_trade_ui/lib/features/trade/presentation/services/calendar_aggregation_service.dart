import 'package:am_common/core/utils/logger.dart';
import '../../internal/domain/entities/trade_controller_entities.dart';
import '../models/calendar_view_models.dart';

/// Service for aggregating trade calendar data into view models
class CalendarAggregationService {
  /// Aggregate trade calendar into yearly view data
  YearlyCalendarData aggregateYearlyData({required Map<String, List<TradeDetails>> calendarData, required int year}) {
    AppLogger.info(
      '[AggregationService] Aggregating yearly data for $year with ${calendarData.length} date entries',
      tag: 'CalendarAggregationService',
    );

    AppLogger.debug(
      '[AggregationService] Date keys: ${calendarData.keys.take(5).join(", ")}${calendarData.length > 5 ? "..." : ""}',
      tag: 'CalendarAggregationService',
    );

    final monthSummaries = <MonthSummary>[];

    var totalTrades = 0;
    var totalPnL = 0.0;
    var totalWinning = 0;
    var totalLosing = 0;

    final monthlyPnLs = <double>[];

    // Process each month (1-12)
    for (var month = 1; month <= 12; month++) {
      final monthData = _getMonthData(calendarData, year, month);

      AppLogger.debug(
        '[AggregationService] Month $month/$year has ${monthData.length} trades',
        tag: 'CalendarAggregationService',
      );

      if (monthData.isNotEmpty) {
        final summary = _createMonthSummary(monthData, year, month);
        monthSummaries.add(summary);

        totalTrades += summary.totalTrades;
        totalPnL += summary.totalPnL;
        totalWinning += summary.winningTrades;
        totalLosing += summary.losingTrades;
        monthlyPnLs.add(summary.totalPnL);
      } else {
        // Add empty month
        monthSummaries.add(
          MonthSummary(
            month: month,
            year: year,
            totalTrades: 0,
            totalPnL: 0.0,
            winningTrades: 0,
            losingTrades: 0,
            tradingDays: 0,
          ),
        );
        monthlyPnLs.add(0.0);
      }
    }

    AppLogger.info(
      '[AggregationService] Year $year summary: $totalTrades trades, totalPnL: $totalPnL',
      tag: 'CalendarAggregationService',
    );

    final avgMonthlyPnL = monthlyPnLs.isNotEmpty ? monthlyPnLs.reduce((a, b) => a + b) / monthlyPnLs.length : 0.0;

    // Find best and worst months
    var bestMonth = 1;
    var worstMonth = 1;
    var maxPnL = monthlyPnLs[0];
    var minPnL = monthlyPnLs[0];

    for (var i = 0; i < monthlyPnLs.length; i++) {
      if (monthlyPnLs[i] > maxPnL) {
        maxPnL = monthlyPnLs[i];
        bestMonth = i + 1;
      }
      if (monthlyPnLs[i] < minPnL) {
        minPnL = monthlyPnLs[i];
        worstMonth = i + 1;
      }
    }

    return YearlyCalendarData(
      year: year,
      months: monthSummaries,
      totalTrades: totalTrades,
      totalPnL: totalPnL,
      winningTrades: totalWinning,
      losingTrades: totalLosing,
      avgMonthlyPnL: avgMonthlyPnL,
      bestMonth: bestMonth,
      worstMonth: worstMonth,
    );
  }

  /// Aggregate trade calendar into monthly view data
  MonthlyCalendarData aggregateMonthlyData({
    required Map<String, List<TradeDetails>> calendarData,
    required int year,
    required int month,
  }) {
    final daySummaries = <DaySummary>[];

    var totalTrades = 0;
    var totalPnL = 0.0;
    var totalWinning = 0;
    var totalLosing = 0;
    var tradingDays = 0;

    final dailyPnLs = <double>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Process each day in the month
    for (var day = 1; day <= daysInMonth; day++) {
      final dateKey = _formatDateKey(year, month, day);
      final dayTrades = calendarData[dateKey] ?? [];

      if (dayTrades.isNotEmpty) {
        final summary = _createDaySummary(dayTrades, year, month, day);
        daySummaries.add(summary);

        totalTrades += summary.totalTrades;
        totalPnL += summary.totalPnL;
        totalWinning += summary.winningTrades;
        totalLosing += summary.losingTrades;
        tradingDays++;
        dailyPnLs.add(summary.totalPnL);
      } else {
        // Add empty day
        daySummaries.add(
          DaySummary(
            day: day,
            month: month,
            year: year,
            totalTrades: 0,
            totalPnL: 0.0,
            winningTrades: 0,
            losingTrades: 0,
          ),
        );
        dailyPnLs.add(0.0);
      }
    }

    final avgDailyPnL = tradingDays > 0 ? totalPnL / tradingDays : 0.0;

    // Find best and worst days
    var bestDay = 1;
    var worstDay = 1;
    if (dailyPnLs.isNotEmpty) {
      var maxPnL = dailyPnLs[0];
      var minPnL = dailyPnLs[0];

      for (var i = 0; i < dailyPnLs.length; i++) {
        if (dailyPnLs[i] > maxPnL) {
          maxPnL = dailyPnLs[i];
          bestDay = i + 1;
        }
        if (dailyPnLs[i] < minPnL) {
          minPnL = dailyPnLs[i];
          worstDay = i + 1;
        }
      }
    }

    return MonthlyCalendarData(
      year: year,
      month: month,
      days: daySummaries,
      totalTrades: totalTrades,
      totalPnL: totalPnL,
      winningTrades: totalWinning,
      losingTrades: totalLosing,
      avgDailyPnL: avgDailyPnL,
      bestDay: bestDay,
      worstDay: worstDay,
      tradingDays: tradingDays,
    );
  }

  /// Aggregate trade calendar into daily view data
  DailyCalendarData aggregateDailyData({
    required Map<String, List<TradeDetails>> calendarData,
    required DateTime date,
  }) {
    final dateKey = _formatDateKey(date.year, date.month, date.day);
    final trades = calendarData[dateKey] ?? [];

    final totalTrades = trades.length;
    var totalPnL = 0.0;
    var totalVolume = 0.0;
    var winningTrades = 0;
    var losingTrades = 0;
    final symbolDistribution = <String, int>{};
    final holdingTimes = <Duration>[];

    for (final trade in trades) {
      totalPnL += (trade.metrics?.profitLoss ?? 0.0);
      totalVolume += (trade.entryInfo.totalValue ?? 0.0);

      if ((trade.metrics?.profitLoss ?? 0.0) > 0) {
        winningTrades++;
      } else if ((trade.metrics?.profitLoss ?? 0.0) < 0) {
        losingTrades++;
      }

      // Track symbol distribution
      final symbol = trade.instrumentInfo.symbol;
      symbolDistribution[symbol ?? "UNKNOWN"] = (symbolDistribution[symbol ?? "UNKNOWN"] ?? 0) + 1;

      // Track holding time
      final holdingTime = Duration(
        days: (trade.metrics?.holdingTimeDays ?? 0),
        hours: (trade.metrics?.holdingTimeHours ?? 0),
        minutes: (trade.metrics?.holdingTimeMinutes ?? 0),
      );
      holdingTimes.add(holdingTime);
    }

    final avgHoldingTime = holdingTimes.isNotEmpty
        ? Duration(
            microseconds: holdingTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) ~/ holdingTimes.length,
          )
        : Duration.zero;

    return DailyCalendarData(
      date: date,
      trades: trades,
      totalTrades: totalTrades,
      totalPnL: totalPnL,
      winningTrades: winningTrades,
      losingTrades: losingTrades,
      totalVolume: totalVolume,
      avgHoldingTime: avgHoldingTime,
      symbolDistribution: symbolDistribution,
    );
  }

  // Helper methods

  List<TradeDetails> _getMonthData(Map<String, List<TradeDetails>> calendarData, int year, int month) {
    final allTrades = <TradeDetails>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (var day = 1; day <= daysInMonth; day++) {
      final dateKey = _formatDateKey(year, month, day);
      final dayTrades = calendarData[dateKey] ?? [];
      allTrades.addAll(dayTrades);
    }

    return allTrades;
  }

  MonthSummary _createMonthSummary(List<TradeDetails> trades, int year, int month) {
    final totalTrades = trades.length;
    var totalPnL = 0.0;
    var winningTrades = 0;
    var losingTrades = 0;
    final tradingDaysSet = <int>{};

    for (final trade in trades) {
      totalPnL += (trade.metrics?.profitLoss ?? 0.0);

      if ((trade.metrics?.profitLoss ?? 0.0) > 0) {
        winningTrades++;
      } else if ((trade.metrics?.profitLoss ?? 0.0) < 0) {
        losingTrades++;
      }

      tradingDaysSet.add((trade.entryInfo.timestamp?.day ?? 0));
    }

    return MonthSummary(
      month: month,
      year: year,
      totalTrades: totalTrades,
      totalPnL: totalPnL,
      winningTrades: winningTrades,
      losingTrades: losingTrades,
      tradingDays: tradingDaysSet.length,
    );
  }

  DaySummary _createDaySummary(List<TradeDetails> trades, int year, int month, int day) {
    final totalTrades = trades.length;
    var totalPnL = 0.0;
    var winningTrades = 0;
    var losingTrades = 0;

    for (final trade in trades) {
      totalPnL += (trade.metrics?.profitLoss ?? 0.0);

      if ((trade.metrics?.profitLoss ?? 0.0) > 0) {
        winningTrades++;
      } else if ((trade.metrics?.profitLoss ?? 0.0) < 0) {
        losingTrades++;
      }
    }

    return DaySummary(
      day: day,
      month: month,
      year: year,
      totalTrades: totalTrades,
      totalPnL: totalPnL,
      winningTrades: winningTrades,
      losingTrades: losingTrades,
    );
  }

  String _formatDateKey(int year, int month, int day) =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
