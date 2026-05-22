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

  factory StockIndicesMarketData.fromJson(Map<String, dynamic> json) {
    // Handle differences in API response vs expected
    // market.html checks 'data' or 'stocks'
    var list = json['data'] as List? ?? json['stocks'] as List? ?? [];
    List<StockData> stocksList = list.map((i) => StockData.fromJson(i)).toList();

    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : null;

    double parseLastPrice() {
      // 1. Direct last price check (top level or metadata)
      final directLast = json['lastPrice'] ?? json['last_price'] ?? json['last'] ?? 
                         metadata?['lastPrice'] ?? metadata?['last_price'] ?? metadata?['last'] ?? metadata?['close'] ?? json['close'];
      if (directLast != null && directLast != 0 && directLast != 0.0) {
        return (directLast as num).toDouble();
      }
      
      // 2. Fallback to prevClose + change (top level or metadata)
      final prevClose = json['previousClose'] ?? json['previous_close'] ?? json['prevClose'] ?? json['prev_close'] ??
                        metadata?['previousClose'] ?? metadata?['previous_close'] ?? metadata?['prevClose'] ?? metadata?['prev_close'] ?? 0;
                        
      final change = json['change'] ?? metadata?['change'] ?? 0;
      
      final double prevCloseDouble = (prevClose as num).toDouble();
      final double changeDouble = (change as num).toDouble();
      
      if (prevCloseDouble != 0 && prevCloseDouble != 0.0) {
        return prevCloseDouble + changeDouble;
      }
      
      return 0.0;
    }

    return StockIndicesMarketData(
      indexSymbol: json['indexSymbol'] ?? 'Unknown',
      lastPrice: parseLastPrice(),
      change: (json['change'] ?? metadata?['change'] ?? 0).toDouble(),
      pChange: (json['pChange'] ?? json['percentChange'] ?? metadata?['percChange'] ?? 0).toDouble(),
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


