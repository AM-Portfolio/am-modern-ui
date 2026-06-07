class StockIndicesMarketData {
  final String indexSymbol;
  final double lastPrice;
  final double change;
  final double pChange;
  final List<StockData> stocks;

  StockIndicesMarketData({
    required this.indexSymbol,
    required this.lastPrice,
    required this.change,
    required this.pChange,
    required this.stocks,
  });

  static double _number(dynamic value) => value is num ? value.toDouble() : 0.0;

  static double _resolveLastPrice(
    Map<String, dynamic> json,
    Map<String, dynamic> metadata,
  ) {
    final direct = _number(json['lastPrice'] ?? json['last'] ?? metadata['last']);
    if (direct > 0) return direct;

    final previousClose = _number(json['previousClose'] ?? metadata['previousClose']);
    final change = _number(json['change'] ?? metadata['change']);
    if (previousClose > 0 && change != 0) return previousClose + change;

    final pChange = _number(json['pChange'] ?? json['percentChange'] ?? metadata['percChange'] ?? metadata['percentChange']);
    if (previousClose > 0 && pChange != 0) {
      return previousClose * (1 + (pChange / 100));
    }

    return 0.0;
  }

  factory StockIndicesMarketData.fromJson(Map<String, dynamic> json) {
    // Handle differences in API response vs expected
    // market.html checks 'data' or 'stocks'
    var list = json['data'] as List? ?? json['stocks'] as List? ?? [];
    List<StockData> stocksList = list.map((i) => StockData.fromJson(i)).toList();
    final metadata = json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return StockIndicesMarketData(
      indexSymbol: json['indexSymbol'] ?? 'Unknown',
      lastPrice: _resolveLastPrice(json, metadata),
      change: _number(json['change'] ?? metadata['change']),
      pChange: _number(json['pChange'] ?? json['percentChange'] ?? metadata['percChange'] ?? metadata['percentChange']),
      stocks: stocksList,
    );
  }

  StockIndicesMarketData copyWith({
    String? indexSymbol,
    double? lastPrice,
    double? change,
    double? pChange,
    List<StockData>? stocks,
  }) {
    return StockIndicesMarketData(
      indexSymbol: indexSymbol ?? this.indexSymbol,
      lastPrice: lastPrice ?? this.lastPrice,
      change: change ?? this.change,
      pChange: pChange ?? this.pChange,
      stocks: stocks ?? this.stocks,
    );
  }
}

class StockData {
  final String symbol;
  final double lastPrice;
  final double change;
  final double pChange;
  final double open;
  final double dayHigh;
  final double dayLow;

  StockData({
    required this.symbol,
    required this.lastPrice,
    required this.change,
    required this.pChange,
    required this.open,
    required this.dayHigh,
    required this.dayLow,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    return StockData(
      symbol: json['symbol'] ?? '',
      lastPrice: (json['lastPrice'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      pChange: (json['pChange'] ?? 0).toDouble(),
      open: (json['open'] ?? 0).toDouble(),
      dayHigh: (json['dayHigh'] ?? 0).toDouble(),
      dayLow: (json['dayLow'] ?? 0).toDouble(),
    );
  }
}

class MarketData {
  final List<StockIndicesMarketData> indices;
  final List<StockIndicesMarketData> globalIndices;

  MarketData({required this.indices, required this.globalIndices});
}
