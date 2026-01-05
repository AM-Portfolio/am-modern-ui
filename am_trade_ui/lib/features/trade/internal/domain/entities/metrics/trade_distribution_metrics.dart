class TradeDistributionMetrics {
  final Map<String, int> tradesByDay;
  final Map<String, double> profitByDay;
  final Map<String, int> tradesByHour;
  final Map<String, double> profitByHour;
  final Map<String, int> tradeCountByAssetClass;
  final Map<String, int> tradeCountByStrategy;

  TradeDistributionMetrics({
    required this.tradesByDay,
    required this.profitByDay,
    required this.tradesByHour,
    required this.profitByHour,
    required this.tradeCountByAssetClass,
    required this.tradeCountByStrategy,
  });
}
