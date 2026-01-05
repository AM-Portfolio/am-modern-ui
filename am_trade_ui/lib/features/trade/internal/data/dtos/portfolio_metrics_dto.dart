import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_metrics_dto.freezed.dart';
part 'portfolio_metrics_dto.g.dart';

@freezed
abstract class PortfolioMetricsDto with _$PortfolioMetricsDto {
  const factory PortfolioMetricsDto({
    @Default(0) int totalTrades,
    @Default(0) int winningTrades,
    @Default(0) int losingTrades,
    @Default(0) int breakEvenTrades,
    @Default(0) int openPositions,
    double? winRate,
    double? lossRate,
    double? profitFactor,
    double? expectancy,
    double? totalValue,
    double? totalProfit,
    double? totalLoss,
    double? netProfitLoss,
    double? netProfitLossPercentage,
    double? maxDrawdown,
    double? maxDrawdownPercentage,
    double? sharpeRatio,
    double? sortinoRatio,
    double? monthlyReturns,
    double? weeklyReturns,
  }) = _PortfolioMetricsDto;

  factory PortfolioMetricsDto.fromJson(Map<String, dynamic> json) =>
      _$PortfolioMetricsDtoFromJson(json);
}
