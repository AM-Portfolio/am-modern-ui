/// Basket Module API endpoint constants
class BasketEndpoints {
  // Base URL - Basket service runs on port 8072
  static const String baseUrl = 'http://localhost:8072';
  
  // Basket endpoints - using full URLs so ApiClient handles them correctly
  static const String opportunities = '$baseUrl/api/v1/basket/opportunities';
  static const String preview = '$baseUrl/api/v1/basket/preview';
  static const String calculateQuantities = '$baseUrl/api/v1/basket/calculate-quantities';
}
