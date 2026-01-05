import 'package:freezed_annotation/freezed_annotation.dart';

import 'report_performance_metrics.dart';

part 'trade_performance_summary.freezed.dart';

@freezed
abstract class TradePerformanceSummary with _$TradePerformanceSummary {
  const factory TradePerformanceSummary({
    required int totalTrades,
    required int winningTrades,
    required int losingTrades,
    required int breakEvenTrades,
    required double winPercentage,
    required double totalProfitLoss,
    required double averageProfitPerTrade,
    required double averageWinAmount,
    required double averageLossAmount,
    required double averageHoldingTimeWin,
    required double averageHoldingTimeLoss,
    required double maxDrawdown,
    required double profitFactor,
    required double largestWin,
    required double largestLoss,
    required ReportPerformanceMetrics metrics,
  }) = _TradePerformanceSummary;
}
