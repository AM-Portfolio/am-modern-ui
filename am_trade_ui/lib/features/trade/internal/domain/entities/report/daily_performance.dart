import 'package:freezed_annotation/freezed_annotation.dart';
import 'report_performance_metrics.dart';

part 'daily_performance.freezed.dart';

@freezed
abstract class DailyPerformance with _$DailyPerformance {
  const factory DailyPerformance({
    required DateTime date,
    required double totalProfitLoss,
    required int tradeCount,
    required int winCount,
    required int lossCount,
    required double winRate,
    String? bestTradeSymbol,
    double? bestTradePnL,
    required ReportPerformanceMetrics metrics,
  }) = _DailyPerformance;
}
