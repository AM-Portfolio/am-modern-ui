class TradeDistributionMetrics {
  final Map<String, int> tradesByDay;
  final Map<String, double> profitByDay;
  final Map<String, double> winRateByDay;
  final Map<String, int> tradesByHour;
  final Map<String, double> profitByHour;
  final Map<String, double> winRateByHour;
  final Map<String, int> tradesByMonth;
  final Map<String, double> profitByMonth;
  final Map<String, double> winRateByMonth;
  final Map<String, int> tradeCountByAssetClass;
  final Map<String, int> tradeCountByStrategy;

  TradeDistributionMetrics({
    required this.tradesByDay,
    required this.profitByDay,
    this.winRateByDay = const {},
    required this.tradesByHour,
    required this.profitByHour,
    this.winRateByHour = const {},
    this.tradesByMonth = const {},
    this.profitByMonth = const {},
    this.winRateByMonth = const {},
    required this.tradeCountByAssetClass,
    required this.tradeCountByStrategy,
  });
}
