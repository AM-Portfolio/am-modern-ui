import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_metrics.freezed.dart';

@freezed
abstract class PortfolioMetrics with _$PortfolioMetrics {
  const factory PortfolioMetrics({
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
  }) = _PortfolioMetrics;
}
