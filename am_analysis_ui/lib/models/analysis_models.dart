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

class AllocationHolding {
  final String symbol;
  final String name;
  final double value;
  final double percentage; // Percentage within the group (e.g., sector)
  final double portfolioPercentage; // Percentage of total portfolio

  const AllocationHolding({
    required this.symbol,
    required this.name,
    required this.value,
    required this.percentage,
    required this.portfolioPercentage,
  });
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
