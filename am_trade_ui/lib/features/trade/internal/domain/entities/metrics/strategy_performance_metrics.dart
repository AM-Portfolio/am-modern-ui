class StrategyPerformanceMetrics {
  final String strategyName;
  final double totalProfitLoss;
  final double winRate;
  final double sharpeRatio;

  StrategyPerformanceMetrics({
    required this.strategyName,
    required this.totalProfitLoss,
    required this.winRate,
    required this.sharpeRatio,
  });
}
