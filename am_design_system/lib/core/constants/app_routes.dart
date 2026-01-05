/// App-wide route constants
class AppRoutes {
  static const String portfolio = '/portfolio';
  static const String tradeManagement = '/trades';
  static const String analysis = '/analysis';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String home = '/';
  
  // Portfolio sub-routes
  static const String portfolioHoldings = '/portfolio/holdings';
  static const String portfolioSummary = '/portfolio/summary';
  static const String portfolioDetails = '/portfolio/details';
  
  // Trade management sub-routes
  static const String tradeHistory = '/trades/history';
  static const String tradeOrders = '/trades/orders';
  static const String positions = '/trades/positions';
  static const String tradePortfolios = '/trade/portfolios';
  static const String tradeHoldings = '/trade/holdings';
  static const String tradeCalendar = '/trade/calendar';
  
  // Analysis sub-routes
  static const String performanceAnalysis = '/analysis/performance';
  static const String riskAnalysis = '/analysis/risk';
  static const String portfolioComparison = '/analysis/comparison';
}