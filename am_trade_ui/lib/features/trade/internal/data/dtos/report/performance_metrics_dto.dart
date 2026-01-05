import 'package:json_annotation/json_annotation.dart';
import '../../../domain/entities/report/report_performance_metrics.dart';

part 'performance_metrics_dto.g.dart';

@JsonSerializable()
class PerformanceMetricsDto {
  final num? avgHoldTime;
  final num? longestTradeDuration;
  final num? maxTradingWeeksDuration;
  final num? avgTradingWeeksDuration;
  final num? avgGrossTradePnL;
  final num? avgLoss;
  final num? avgMaxTradeLoss;
  final num? avgMaxTradeProfit;
  final num? avgTradeWinLossRatio;
  final num? avgWeeklyGrossPnL;
  final num? avgWeeklyWinLossRatio;
  final num? avgWin;
  final num? grossPnL;
  final num? largestLosingTrade;
  final num? largestProfitableTrade;
  final num? profitFactor;
  final num? avgWeeklyGrossDrawdown;
  final num? avgPlannedRMultiple;
  final num? avgRealizedRMultiple;
  final int? breakevenDays;
  final int? breakevenTrades;
  final int? losingDays;
  final num? maxWeeklyGrossDrawdown;
  final num? avgWeeklyWinPercentage;
  final num? longsWinPercentage;
  final int? maxConsecutiveLosingWeeks;
  final int? maxConsecutiveLosses;
  final int? maxConsecutiveWinningWeeks;
  final int? maxConsecutiveWins;
  final num? shortsWinPercentage;
  final num? winPercentage;
  final int? winningDays;

  PerformanceMetricsDto({
    this.avgHoldTime,
    this.longestTradeDuration,
    this.maxTradingWeeksDuration,
    this.avgTradingWeeksDuration,
    this.avgGrossTradePnL,
    this.avgLoss,
    this.avgMaxTradeLoss,
    this.avgMaxTradeProfit,
    this.avgTradeWinLossRatio,
    this.avgWeeklyGrossPnL,
    this.avgWeeklyWinLossRatio,
    this.avgWin,
    this.grossPnL,
    this.largestLosingTrade,
    this.largestProfitableTrade,
    this.profitFactor,
    this.avgWeeklyGrossDrawdown,
    this.avgPlannedRMultiple,
    this.avgRealizedRMultiple,
    this.breakevenDays,
    this.breakevenTrades,
    this.losingDays,
    this.maxWeeklyGrossDrawdown,
    this.avgWeeklyWinPercentage,
    this.longsWinPercentage,
    this.maxConsecutiveLosingWeeks,
    this.maxConsecutiveLosses,
    this.maxConsecutiveWinningWeeks,
    this.maxConsecutiveWins,
    this.shortsWinPercentage,
    this.winPercentage,
    this.winningDays,
  });

  factory PerformanceMetricsDto.fromJson(Map<String, dynamic> json) {
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
    return _$PerformanceMetricsDtoFromJson(patchedJson);
  }
  Map<String, dynamic> toJson() => _$PerformanceMetricsDtoToJson(this);

  ReportPerformanceMetrics toEntity() => ReportPerformanceMetrics(
    avgHoldTime: avgHoldTime?.toDouble() ?? 0.0,
    longestTradeDuration: longestTradeDuration?.toDouble() ?? 0.0,
    maxTradingWeeksDuration: maxTradingWeeksDuration?.toDouble() ?? 0.0,
    avgTradingWeeksDuration: avgTradingWeeksDuration?.toDouble() ?? 0.0,
    avgGrossTradePnL: avgGrossTradePnL?.toDouble() ?? 0.0,
    avgLoss: avgLoss?.toDouble() ?? 0.0,
    avgMaxTradeLoss: avgMaxTradeLoss?.toDouble() ?? 0.0,
    avgMaxTradeProfit: avgMaxTradeProfit?.toDouble() ?? 0.0,
    avgTradeWinLossRatio: avgTradeWinLossRatio?.toDouble() ?? 0.0,
    avgWeeklyGrossPnL: avgWeeklyGrossPnL?.toDouble() ?? 0.0,
    avgWeeklyWinLossRatio: avgWeeklyWinLossRatio?.toDouble() ?? 0.0,
    avgWin: avgWin?.toDouble() ?? 0.0,
    grossPnL: grossPnL?.toDouble() ?? 0.0,
    largestLosingTrade: largestLosingTrade?.toDouble() ?? 0.0,
    largestProfitableTrade: largestProfitableTrade?.toDouble() ?? 0.0,
    profitFactor: profitFactor?.toDouble() ?? 0.0,
    avgWeeklyGrossDrawdown: avgWeeklyGrossDrawdown?.toDouble() ?? 0.0,
    avgPlannedRMultiple: avgPlannedRMultiple?.toDouble() ?? 0.0,
    avgRealizedRMultiple: avgRealizedRMultiple?.toDouble() ?? 0.0,
    breakevenDays: breakevenDays ?? 0,
    breakevenTrades: breakevenTrades ?? 0,
    losingDays: losingDays ?? 0,
    maxWeeklyGrossDrawdown: maxWeeklyGrossDrawdown?.toDouble() ?? 0.0,
    avgWeeklyWinPercentage: avgWeeklyWinPercentage?.toDouble() ?? 0.0,
    longsWinPercentage: longsWinPercentage?.toDouble() ?? 0.0,
    maxConsecutiveLosingWeeks: maxConsecutiveLosingWeeks ?? 0,
    maxConsecutiveLosses: maxConsecutiveLosses ?? 0,
    maxConsecutiveWinningWeeks: maxConsecutiveWinningWeeks ?? 0,
    maxConsecutiveWins: maxConsecutiveWins ?? 0,
    shortsWinPercentage: shortsWinPercentage?.toDouble() ?? 0.0,
    winPercentage: winPercentage?.toDouble() ?? 0.0,
    winningDays: winningDays ?? 0,
  );
}
