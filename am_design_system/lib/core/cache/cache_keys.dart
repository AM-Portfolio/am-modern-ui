/// Centralized cache keys for Portfolio module
class PortfolioCacheKeys {
  /// Portfolio summary cache key
  static String summary(String userId, String portfolioId) =>
      'portfolio_summary_${userId}_$portfolioId';

  /// Portfolio holdings cache key
  static String holdings(String userId, String portfolioId) =>
      'portfolio_holdings_${userId}_$portfolioId';

  /// Portfolio heatmap cache key
  static String heatmap(String userId, String portfolioId) =>
      'portfolio_heatmap_${userId}_$portfolioId';

  /// Portfolio analytics cache key
  static String analytics(String userId, String portfolioId) =>
      'portfolio_analytics_${userId}_$portfolioId';
}

/// Centralized cache keys for Trade module
class TradeCacheKeys {
  /// Trade portfolios list cache key
  static String portfolios(String userId) => 'trade_portfolios_$userId';

  /// Trades for a specific portfolio
  static String trades(String userId, String portfolioId) =>
      'trade_trades_${userId}_$portfolioId';

  /// Trade metrics for a portfolio
  static String metrics(String userId, String portfolioId) =>
      'trade_metrics_${userId}_$portfolioId';

  /// Trade calendar data
  static String calendar(String userId, String portfolioId) =>
      'trade_calendar_${userId}_$portfolioId';
}

/// Centralized cache keys for Market module
class MarketCacheKeys {
  /// Market overview cache key
  static String overview(String userId) => 'market_overview_$userId';

  /// ETF list cache key
  static String etfList(String userId) => 'market_etf_list_$userId';

  /// Stock details cache key
  static String stockDetails(String symbol) => 'market_stock_$symbol';

  /// Market sectors cache key
  static String sectors(String userId) => 'market_sectors_$userId';
}

/// Default TTL durations for different data types
class CacheTTL {
  /// Short-lived data (5 minutes) - realtime market data
  static const short = Duration(minutes: 5);

  /// Medium-lived data (15 minutes) - portfolio summaries
  static const medium = Duration(minutes: 15);

  /// Long-lived data (1 hour) - historical trade data
  static const long = Duration(hours: 1);

  /// Very long-lived data (24 hours) - static reference data
  static const veryLong = Duration(hours: 24);
}
