import 'package:am_common/am_common.dart';

/// Portfolio Module API endpoint constants
class PortfolioEndpoints {
  // Base URL
  static String get baseUrl => ConfigService.config.api.portfolio.baseUrl;
  
  // Resources
  static const String list = '/v1/portfolios/list';
  static const String holdings = '/v1/portfolio-summary';
  static const String summary = '/v1/portfolio-summary';
  static const String transactions = '/v1/trades/portfolio-details';
  
  /// Get advanced analytics for a portfolio
  static String advancedAnalytics(String portfolioId) => 
      '/v1/analytics/portfolio/$portfolioId/advanced';
      
  /// Get user portfolio holdings
  static String userHoldings(String userId) => '$holdings?userId=$userId';
  
  /// Get user portfolio summary
  static String userSummary(String userId) => '$summary?userId=$userId';
}
