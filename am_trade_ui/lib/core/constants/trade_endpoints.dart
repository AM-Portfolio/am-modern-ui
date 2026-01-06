/// Trade Module API endpoint constants
class TradeEndpoints {
  // Base URLs
  static const String tradeBaseUrl = 'https://am.munish.org/api/trade';
  
  // Trade Details
  static const String details = '/v1/trades/details';
  static const String detailsByPortfolio = '$details/portfolio';
  static const String detailsBatch = '$details/batch';
  static const String detailsByIds = '$details/by-ids';
  static const String detailsFilter = '$details/filter';
  
  // General Trade Endpoints
  static const String filter = '/v1/trades/filter';
  static const String search = '/v1/trades/search';
  
  // Calendar Endpoints
  static const String calendarBase = '/v1/trades/calendar';
  static const String calendarMonth = '$calendarBase/month';
  static const String calendarDay = '$calendarBase/day';
  static const String calendarQuarter = '$calendarBase/quarter';
  static const String calendarFinancialYear = '$calendarBase/financial-year';
  
  // Metrics
  static const String metrics = '/v1/metrics';
  static const String metricsTypes = '$metrics/types';
}
