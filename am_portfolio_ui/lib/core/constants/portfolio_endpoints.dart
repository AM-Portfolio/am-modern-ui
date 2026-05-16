import 'package:am_common/am_common.dart' as common;

/// Portfolio Module API endpoint constants
class PortfolioEndpoints {
  // Base URL - Loaded from ConfigService
  static String get baseUrl => common.ConfigService.config.api.portfolio.baseUrl;

  // Resources - Loaded from ConfigService
  static String get list => common.ConfigService.config.api.portfolio.listResource;
  static String get holdings => common.ConfigService.config.api.portfolio.holdingsResource;
  static String get summary => common.ConfigService.config.api.portfolio.summaryResource;
  static String get transactions => common.ConfigService.config.api.portfolio.transactionsResource;

  /// Get advanced analytics for a portfolio
  static String advancedAnalytics(String portfolioId) =>
      '/v1/analytics/portfolio/$portfolioId/advanced';

  /// Get user portfolio holdings
  static String userHoldings(String userId) => '$holdings?userId=$userId';

  /// Get user portfolio summary
  static String userSummary(String userId) => '$summary?userId=$userId';
}
