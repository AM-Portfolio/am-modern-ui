/// Model for top mover stock data
class TopMoverStock {
  final String symbol;
  final String companyName;
  final double lastPrice;
  final double change;
  final double changePercent;
  final int volume;
  final bool changeUnavailable;

  TopMoverStock({
    required this.symbol,
    required this.companyName,
    required this.lastPrice,
    required this.change,
    required this.changePercent,
    required this.volume,
    this.changeUnavailable = false,
  });

  TopMoverStock copyWith({
    double? lastPrice,
    double? change,
    double? changePercent,
    bool? changeUnavailable,
  }) {
    return TopMoverStock(
      symbol: symbol,
      companyName: companyName,
      lastPrice: lastPrice ?? this.lastPrice,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      volume: volume,
      changeUnavailable: changeUnavailable ?? this.changeUnavailable,
    );
  }

  factory TopMoverStock.fromJson(Map<String, dynamic> json) {
    final pctRaw = json['changePercent'] ??
        json['changePercentage'] ??
        json['percentChange'] ??
        json['pChange'] ??
        json['pchange'] ??
        json['pctChange'] ??
        json['change_percent'];
    final changePercent = double.tryParse(pctRaw?.toString() ?? '');
    return TopMoverStock(
      symbol: json['symbol'] as String? ?? '',
      companyName:
          json['companyName'] as String? ?? json['symbol'] as String? ?? '',
      lastPrice: double.tryParse(json['lastPrice']?.toString() ?? '') ?? 0.0,
      change: double.tryParse(json['change']?.toString() ?? '') ?? 0.0,
      changePercent: changePercent ?? 0.0,
      volume: int.tryParse(json['volume']?.toString() ?? '') ?? 0,
      changeUnavailable: changePercent == null,
    );
  }
}
