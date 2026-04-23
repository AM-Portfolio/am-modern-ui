class AllocationHolding {
  final String symbol;
  final String name;
  final double percentage;
  final double portfolioPercentage;
  final double value;

  AllocationHolding({
    required this.symbol,
    required this.name,
    required this.percentage,
    required this.portfolioPercentage,
    required this.value,
  });
}

class AllocationItem {
  final String name;
  final double percentage;
  final double value;
  final List<AllocationHolding>? holdings;

  AllocationItem({
    required this.name,
    required this.percentage,
    required this.value,
    this.holdings,
  });
}
