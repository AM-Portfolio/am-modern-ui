import 'package:am_common/am_common.dart' as common;

/// Basket Module API endpoint constants
class BasketEndpoints {
  // Base URL - Dynamic: reads AM_PORTFOLIO_BASE_URL from dart-define via ConfigService
  static String get baseUrl => common.ConfigService.config.api.portfolio.baseUrl;

  // Basket endpoints - using full URLs so ApiClient handles them correctly
  static String get opportunities => '$baseUrl/v1/basket/opportunities';
  static String get preview => '$baseUrl/v1/basket/preview';
  static String get calculateQuantities =>
      '$baseUrl/v1/basket/calculate-quantities';
}
