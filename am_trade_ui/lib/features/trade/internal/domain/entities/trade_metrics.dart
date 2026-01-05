import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_metrics.freezed.dart';

@freezed
abstract class TradeMetrics with _$TradeMetrics {
  const factory TradeMetrics({
    double? profitLoss,
    double? profitLossPercentage,
    double? returnOnEquity,
    double? riskAmount,
    double? rewardAmount,
    double? riskRewardRatio,
    @Default(0) int holdingTimeDays,
    @Default(0) int holdingTimeHours,
    @Default(0) int holdingTimeMinutes,
    double? maxAdverseExcursion,
    double? maxFavorableExcursion,
  }) = _TradeMetrics;
}
