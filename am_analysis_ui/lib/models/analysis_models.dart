class AllocationItem {
  final String name;
  final double percentage;
  final double value;

  AllocationItem({required this.name, required this.percentage, required this.value});
}

class PerformanceDataPoint {
  final DateTime date;
  final double value;

  PerformanceDataPoint({required this.date, required this.value});
}

class MoverItem {
  final String symbol;
  final String name;
  final double price;
  final double changePercentage;
  final double changeAmount;

  MoverItem({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercentage,
    required this.changeAmount,
  });
}

enum AnalysisEntityType {
  PORTFOLIO,
  BASKET,
  ETF,
  MUTUAL_FUND,
  TRADE,
  MARKET_INDEX
}
