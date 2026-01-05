import 'package:freezed_annotation/freezed_annotation.dart';
import 'report_performance_metrics.dart';

part 'timing_analysis.freezed.dart';

@freezed
abstract class TimingAnalysis with _$TimingAnalysis {
  const factory TimingAnalysis({
    required List<HourlyPerformance> hourlyPerformance,
    required List<DayOfWeekPerformance> dayOfWeekPerformance,
    required List<MonthlyPerformance> monthlyPerformance,
    required List<YearlyPerformance> yearlyPerformance,
    required List<WeeklyPerformance> weeklyPerformance,
    int? bestTradingHour,
    int? worstTradingHour,
    String? bestTradingDay,
    String? worstTradingDay,
    String? bestTradingMonth,
    String? worstTradingMonth,
  }) = _TimingAnalysis;
}

@freezed
abstract class HourlyPerformance with _$HourlyPerformance {
  const factory HourlyPerformance({
    required int hour,
    required int tradeCount,
    required int winCount,
    required int lossCount,
    required double winRate,
    required double totalProfitLoss,
    required double averageWinAmount,
    required double averageLossAmount,
    required double averageHoldingTime,
    required ReportPerformanceMetrics metrics,
  }) = _HourlyPerformance;
}

@freezed
abstract class DayOfWeekPerformance with _$DayOfWeekPerformance {
  const factory DayOfWeekPerformance({
    required String dayOfWeek,
    required int dayOrder,
    required int tradeCount,
    required int winCount,
    required int lossCount,
    required double winRate,
    required double totalProfitLoss,
    required double averageWinAmount,
    required double averageLossAmount,
    required double averageHoldingTime,
    required ReportPerformanceMetrics metrics,
  }) = _DayOfWeekPerformance;
}

@freezed
abstract class MonthlyPerformance with _$MonthlyPerformance {
  const factory MonthlyPerformance({
    required String month,
    required int monthOrder,
    required int tradeCount,
    required int winCount,
    required int lossCount,
    required double winRate,
    required double totalProfitLoss,
    required double averageWinAmount,
    required double averageLossAmount,
    required double averageHoldingTime,
    required ReportPerformanceMetrics metrics,
  }) = _MonthlyPerformance;
}

@freezed
abstract class YearlyPerformance with _$YearlyPerformance {
  const factory YearlyPerformance({
    required int year,
    required int tradeCount,
    required int winCount,
    required int lossCount,
    required double winRate,
    required double totalProfitLoss,
    required double averageWinAmount,
    required double averageLossAmount,
    required double averageHoldingTime,
    required ReportPerformanceMetrics metrics,
  }) = _YearlyPerformance;
}

@freezed
abstract class WeeklyPerformance with _$WeeklyPerformance {
  const factory WeeklyPerformance({
    required String weekId,
    required int tradeCount,
    required int winCount,
    required int lossCount,
    required double winRate,
    required double totalProfitLoss,
    required ReportPerformanceMetrics metrics,
  }) = _WeeklyPerformance;
}
