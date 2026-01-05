/// API endpoint constants
/// STUBBED: Hardcoded for Phase 1 testing
class ApiEndpoints {
  // Base URLs
  static String get apiBaseUrl => 'http://localhost:8001';
  
  // Auth base URL
  static String get authBaseUrl => 'http://localhost:8001/api/v1/auth';
  
  // User base URL
  static String get userBaseUrl => 'http://localhost:8002/api/v1/user';
  
  // Authentication endpoints
  static String get login => '$authBaseUrl/login';
  static String get logout => '$authBaseUrl/logout';
  static String get refreshToken => '$authBaseUrl/refresh';
  static String get register => '$userBaseUrl/register';
  
  static String get googleLogin => '$authBaseUrl/google';
  static String get forgotPassword => '$userBaseUrl/forgot-password';
  static String get resetPassword => '$userBaseUrl/reset-password';
  
  // User endpoints
  static String get userProfile => '$userBaseUrl/profile';
  static String get updateProfile => '$userBaseUrl/profile';
  
  /// Get user status endpoint (for activation/status check)
  static String userStatus(String userId) => '$userBaseUrl/$userId/status';
  
  // Portfolio endpoints
  static String get portfolios => '$apiBaseUrl/portfolios';
  static String get portfolioSummary => '$apiBaseUrl/portfolios/summary';
  static String get portfolioHoldings => '$apiBaseUrl/portfolios/holdings';
  
  // Trade endpoints
  static String get trades => '$apiBaseUrl/trades';
  static String get tradeHistory => '$apiBaseUrl/trades/history';
  static String get orders => '$apiBaseUrl/orders';
  static String get positions => '$apiBaseUrl/positions';
  
  // Document endpoints
  static String get documentUpload => '$apiBaseUrl/documents/process';
  static String get documentStatus => '$apiBaseUrl/documents/status';
  
  // Analysis endpoints
  static String get analysis => '$apiBaseUrl/analysis';
  static String get performanceAnalysis => '$apiBaseUrl/analysis/performance';
  static String get riskAnalysis => '$apiBaseUrl/analysis/risk';
  
  /// Get portfolio by ID endpoint
  static String portfolioById(String id) => '$portfolios/$id';
  
  /// Get trade by ID endpoint
  static String tradeById(String id) => '$trades/$id';
  
  /// Get user portfolio holdings
  static String userPortfolioHoldings(String userId) => '$portfolioHoldings?userId=$userId';
  
  /// Get user portfolio summary
  static String userPortfolioSummary(String userId) => '$portfolioSummary?userId=$userId';
}