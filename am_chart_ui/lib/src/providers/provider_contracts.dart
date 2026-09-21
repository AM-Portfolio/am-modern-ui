import 'chart_models.dart';

abstract class MarketDataProvider {
  Future<List<WatchlistSymbol>> search(String query);
  Future<ChartQuote?> getQuote(String symbol);
}

abstract class HistoricalDataProvider {
  Future<List<ChartBar>> getBars({
    required String symbol,
    required String timeframe,
    DateTime? from,
    DateTime? to,
    int? limit,
  });

  /// True when this provider serves synthetic / offline data.
  bool get isMock;
}

abstract class RealTimeDataProvider {
  Stream<ChartBar> ticks(String symbol);
  bool get isMock;
}

abstract class FundamentalDataProvider {
  Future<ChartFundamentals?> getFundamentals(String symbol);
  bool get isMock;
}

abstract class NewsProvider {
  Future<List<ChartNewsItem>> getNews(String symbol);
  bool get isMock;
}

abstract class CorporateActionProvider {
  Future<List<ChartNewsItem>> getActions(String symbol);
  bool get isMock;
}

/// Broker integration — Phase 8. Phase 1 exposes the contract only.
abstract class BrokerProvider {
  String get modeLabel; // SIMULATION | PAPER | LIVE
  Future<bool> isConnected();
}
