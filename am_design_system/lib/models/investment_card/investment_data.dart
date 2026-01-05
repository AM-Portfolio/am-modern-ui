/// Core investment data model
class InvestmentData {
  const InvestmentData({
    required this.symbol,
    required this.name,
    required this.currentValue,
    required this.investedAmount,
    required this.avgPrice,
    required this.quantity,
    required this.currentPrice,
    required this.changeValue,
    required this.changePercent,
    required this.isPositive,
    this.additionalInfo,
  });
  final String symbol;
  final String name;
  final double currentValue;
  final double investedAmount;
  final double avgPrice;
  final int quantity;
  final double currentPrice;
  final double changeValue;
  final double changePercent;
  final bool isPositive;
  final String? additionalInfo;

  /// Create a copy with modified values
  InvestmentData copyWith({
    String? symbol,
    String? name,
    double? currentValue,
    double? investedAmount,
    double? avgPrice,
    int? quantity,
    double? currentPrice,
    double? changeValue,
    double? changePercent,
    bool? isPositive,
    String? additionalInfo,
  }) => InvestmentData(
    symbol: symbol ?? this.symbol,
    name: name ?? this.name,
    currentValue: currentValue ?? this.currentValue,
    investedAmount: investedAmount ?? this.investedAmount,
    avgPrice: avgPrice ?? this.avgPrice,
    quantity: quantity ?? this.quantity,
    currentPrice: currentPrice ?? this.currentPrice,
    changeValue: changeValue ?? this.changeValue,
    changePercent: changePercent ?? this.changePercent,
    isPositive: isPositive ?? this.isPositive,
    additionalInfo: additionalInfo ?? this.additionalInfo,
  );

  @override
  String toString() =>
      'InvestmentData(symbol: $symbol, name: $name, currentValue: $currentValue)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvestmentData &&
        other.symbol == symbol &&
        other.name == name &&
        other.currentValue == currentValue &&
        other.investedAmount == investedAmount &&
        other.avgPrice == avgPrice &&
        other.quantity == quantity &&
        other.currentPrice == currentPrice &&
        other.changeValue == changeValue &&
        other.changePercent == changePercent &&
        other.isPositive == isPositive &&
        other.additionalInfo == additionalInfo;
  }

  @override
  int get hashCode => Object.hash(
    symbol,
    name,
    currentValue,
    investedAmount,
    avgPrice,
    quantity,
    currentPrice,
    changeValue,
    changePercent,
    isPositive,
    additionalInfo,
  );
}
