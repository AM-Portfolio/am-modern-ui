import '../models/basket_catalog.dart';
import '../models/basket_opportunity.dart';

abstract class BasketRepository {
  Future<BasketCatalog> getCatalog();

  Future<List<BasketOpportunity>> getOpportunities({
    required String userId,
    required String portfolioId,
    String? query,
  });

  Future<BasketOpportunity> getBasketPreview({
    required String etfIsin,
    required String userId,
    required String portfolioId,
  });

  Future<BasketOpportunity> applySubstitutes({
    required String etfIsin,
    required String userId,
    required String portfolioId,
    required List<Map<String, String>> assignments,
  });

  Future<Map<String, dynamic>> createBasketPortfolio({
    required Map<String, dynamic> body,
  });
}
