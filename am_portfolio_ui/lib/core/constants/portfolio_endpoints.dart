/// Portfolio Module API endpoint constants
class PortfolioEndpoints {
  // Base URL
  static const String baseUrl = 'https://am.munish.org/portfolio';
  
  // Resources
  static const String list = '/v1/portfolios/list';
  static const String holdings = '/v1/portfolios/holdings';
  static const String summary = '/v1/portfolios/summary';
  static const String transactions = '/v1/portfolios/transactions';
  
  /// Get advanced analytics for a portfolio
  static String advancedAnalytics(String portfolioId) => 
      '/v1/analytics/portfolio/$portfolioId/advanced';
      
  /// Get user portfolio holdings
  static String userHoldings(String userId) => '$holdings?userId=$userId';
  
  /// Get user portfolio summary
  static String userSummary(String userId) => '$summary?userId=$userId';
}
