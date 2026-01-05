import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_performance_metrics.freezed.dart';

@freezed
abstract class ReportPerformanceMetrics with _$ReportPerformanceMetrics {
  const factory ReportPerformanceMetrics({
    double? avgHoldTime,
    double? longestTradeDuration,
    double? maxTradingWeeksDuration,
    double? avgTradingWeeksDuration,
    double? avgGrossTradePnL,
    double? avgLoss,
    double? avgMaxTradeLoss,
    double? avgMaxTradeProfit,
    double? avgTradeWinLossRatio,
    double? avgWeeklyGrossPnL,
    double? avgWeeklyWinLossRatio,
    double? avgWin,
    double? grossPnL,
    double? largestLosingTrade,
    double? largestProfitableTrade,
    double? profitFactor,
    double? avgWeeklyGrossDrawdown,
    double? avgPlannedRMultiple,
    double? avgRealizedRMultiple,
    int? breakevenDays,
    int? breakevenTrades,
    int? losingDays,
    double? maxWeeklyGrossDrawdown,
    double? avgWeeklyWinPercentage,
    double? longsWinPercentage,
    int? maxConsecutiveLosingWeeks,
    int? maxConsecutiveLosses,
    int? maxConsecutiveWinningWeeks,
    int? maxConsecutiveWins,
    double? shortsWinPercentage,
    double? winPercentage,
    int? winningDays,
  }) = _ReportPerformanceMetrics;
}
