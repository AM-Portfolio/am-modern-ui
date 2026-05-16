class MoverItem {
  final String symbol;
  final String name;
  final double price;
  final double changePercentage;
  final double changeAmount;
  final bool isGainer;

  MoverItem({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercentage,
    required this.changeAmount,
    this.isGainer = true,
  });
}
