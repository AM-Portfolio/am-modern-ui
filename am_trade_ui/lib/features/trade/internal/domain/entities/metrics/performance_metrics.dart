class PerformanceMetrics {
  final double totalProfitLoss;
  final double totalProfitLossPercentage;
  final double winRate;
  final double profitFactor;
  final double expectancy;
  final double annualizedReturn;
  final double averageWinningTrade;
  final double averageLosingTrade;
  final double largestWinningTrade;
  final double largestLosingTrade;
  final double winLossRatio;
  final double maxDrawdown;
  final int longestWinningStreak;
  final int longestLosingStreak;
  final double returnOnCapital;
  final double tradesPerDay;

  PerformanceMetrics({
    required this.totalProfitLoss,
    required this.totalProfitLossPercentage,
    required this.winRate,
    required this.profitFactor,
    required this.expectancy,
    required this.annualizedReturn,
    required this.averageWinningTrade,
    required this.averageLosingTrade,
    required this.largestWinningTrade,
    required this.largestLosingTrade,
    required this.winLossRatio,
    required this.maxDrawdown,
    required this.longestWinningStreak,
    required this.longestLosingStreak,
    required this.returnOnCapital,
    required this.tradesPerDay,
  });
}
