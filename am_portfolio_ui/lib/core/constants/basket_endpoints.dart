/// Basket Module API endpoint constants
class BasketEndpoints {
  // Base URL - Basket service runs on port 8072
  static const String baseUrl = 'https://am.asrax.in/portfolio';

  // Basket endpoints - using full URLs so ApiClient handles them correctly
  static const String opportunities = '$baseUrl/v1/basket/opportunities';
  static const String preview = '$baseUrl/v1/basket/preview';
  static const String calculateQuantities =
      '$baseUrl/v1/basket/calculate-quantities';
}
