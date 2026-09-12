/// Bid/ask level for market depth.
class DepthLevel {
  const DepthLevel({
    required this.price,
    required this.quantity,
    this.orders,
  });

  final double price;
  final int quantity;
  final int? orders;
}

/// Full quote used by order header + watchlist depth expand.
class QuoteDetail {
  const QuoteDetail({
    required this.symbol,
    this.name,
    this.exchange = 'NSE',
    this.ltp = 0,
    this.change = 0,
    this.changePercent = 0,
    this.open,
    this.high,
    this.low,
    this.previousClose,
    this.volume,
    this.buyDepth = const [],
    this.sellDepth = const [],
  });

  final String symbol;
  final String? name;
  final String exchange;
  final double ltp;
  final double change;
  final double changePercent;
  final double? open;
  final double? high;
  final double? low;
  final double? previousClose;

  /// Total quantity traded so far (session volume).
  final int? volume;
  final List<DepthLevel> buyDepth;
  final List<DepthLevel> sellDepth;

  bool get isPositive => change > 0;
  bool get isNegative => change < 0;
  bool get hasDepth => buyDepth.isNotEmpty || sellDepth.isNotEmpty;

  int get totalBuyQty =>
      buyDepth.fold<int>(0, (sum, e) => sum + e.quantity);
  int get totalSellQty =>
      sellDepth.fold<int>(0, (sum, e) => sum + e.quantity);
  int get totalBuyOrders => buyDepth.fold<int>(
        0,
        (sum, e) => sum + (e.orders ?? 0),
      );
  int get totalSellOrders => sellDepth.fold<int>(
        0,
        (sum, e) => sum + (e.orders ?? 0),
      );
}
