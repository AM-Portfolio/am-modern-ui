import 'package:freezed_annotation/freezed_annotation.dart';

import 'performance_metrics_dto.dart';

part 'trade_performance_summary_dto.g.dart';

@JsonSerializable()
class TradePerformanceSummaryDto {
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final int breakEvenTrades;
  final double winPercentage;
  final double totalProfitLoss;
  final double averageProfitPerTrade;
  final double averageWinAmount;
  final double averageLossAmount;
  final double averageHoldingTimeWin;
  final double averageHoldingTimeLoss;
  final double maxDrawdown;
  final double profitFactor;
  final double largestWin;
  final double largestLoss;
  final PerformanceMetricsDto metrics;

  TradePerformanceSummaryDto({
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.breakEvenTrades,
    required this.winPercentage,
    required this.totalProfitLoss,
    required this.averageProfitPerTrade,
    required this.averageWinAmount,
    required this.averageLossAmount,
    required this.averageHoldingTimeWin,
    required this.averageHoldingTimeLoss,
    required this.maxDrawdown,
    required this.profitFactor,
    required this.largestWin,
    required this.largestLoss,
    required this.metrics,
  });

  factory TradePerformanceSummaryDto.fromJson(Map<String, dynamic> json) {
    // Handle "Infinity" strings from API
    final patchedJson = Map<String, dynamic>.from(json);
    for (final key in patchedJson.keys) {
      final value = patchedJson[key];
      if (value is String) {
        if (value == 'Infinity' || value == '+Infinity') {
            patchedJson[key] = double.infinity;
        } else if (value == '-Infinity') {
            patchedJson[key] = double.negativeInfinity;
        } else if (value == 'NaN') {
            patchedJson[key] = double.nan;
        }
      }
    }
    return _$TradePerformanceSummaryDtoFromJson(patchedJson);
  }
  Map<String, dynamic> toJson() => _$TradePerformanceSummaryDtoToJson(this);
}
