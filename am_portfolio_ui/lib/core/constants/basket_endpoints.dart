import 'package:am_common/am_common.dart';

/// Basket Module API endpoint constants
class BasketEndpoints {
  // Base URL - Basket service runs on port 8072
  static String get baseUrl => EnvDomains.portfolio;
  
  // Basket endpoints - using full URLs so ApiClient handles them correctly
  static String get opportunities => '$baseUrl/v1/basket/opportunities';
  static String get preview => '$baseUrl/v1/basket/preview';
  static String get calculateQuantities => '$baseUrl/v1/basket/calculate-quantities';
}
