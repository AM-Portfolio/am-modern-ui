class WatchlistStock {
  const WatchlistStock({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.ltp,
    required this.change,
    required this.changePercent,
    this.holdingQty,
    this.avgPrice,
  });

  final String symbol;
  final String name;
  final String exchange;
  final double ltp;
  final double change;
  final double changePercent;
  final int? holdingQty;
  final double? avgPrice;

  bool get isPositive => change > 0;
  bool get isNegative => change < 0;

  WatchlistStock copyWith({
    String? symbol,
    String? name,
    String? exchange,
    double? ltp,
    double? change,
    double? changePercent,
    int? holdingQty,
    double? avgPrice,
  }) {
    return WatchlistStock(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      exchange: exchange ?? this.exchange,
      ltp: ltp ?? this.ltp,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      holdingQty: holdingQty ?? this.holdingQty,
      avgPrice: avgPrice ?? this.avgPrice,
    );
  }
}
