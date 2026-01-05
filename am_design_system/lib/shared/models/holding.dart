class Holding {
  final String symbol;
  final String sector;
  final double quantity;
  final double currentValue;
  final double totalGainLoss;
  final double totalGainLossPercentage;
  final double todayChange;
  final double todayChangePercentage;
  final double portfolioWeight;
  final double investedAmount;
  final double avgPrice;
  final double currentPrice;
  final String companyName;

  const Holding({
    required this.symbol,
    required this.sector,
    required this.quantity,
    required this.currentValue,
    required this.totalGainLoss,
    required this.totalGainLossPercentage,
    required this.todayChange,
    required this.todayChangePercentage,
    required this.portfolioWeight,
    required this.investedAmount,
    required this.avgPrice,
    required this.currentPrice,
    required this.companyName,
  });
}

enum HoldingsSortBy {
  symbol('Symbol'),
  currentValue('Current Value'),
  gainLoss('Gain/Loss'),
  gainLossPercent('Gain/Loss %'),
  todayChange('Today Change'),
  quantity('Quantity'),
  portfolioWeight('Weight');

  const HoldingsSortBy(this.displayName);
  final String displayName;
}

enum HoldingsDisplayFormat {
  value('Value'),
  percentage('Percentage'),
  both('Both');

  const HoldingsDisplayFormat(this.displayName);
  final String displayName;
}

enum HoldingsChangeType {
  daily('Daily'),
  total('Total');

  const HoldingsChangeType(this.displayName);
  final String displayName;
}
