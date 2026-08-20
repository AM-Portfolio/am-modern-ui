import '../models/basket_catalog.dart';
import '../models/basket_opportunity.dart';
import '../models/tracking_basket.dart';
import '../models/basket_detail.dart';

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

  Future<List<TrackingBasket>> getMyBaskets({
    required String userId,
    required String portfolioId,
  });

  Future<void> createPortfolio(Map<String, dynamic> request);

  Future<BasketOpportunity> applySubstitutes(Map<String, dynamic> request);

  Future<BasketOpportunity> calculateQuantities(Map<String, dynamic> request);

  Future<void> deleteBasket({
    required String basketId,
    required String userId,
  });

  Future<BasketDetail> getBasketDetail({
    required String basketId,
    required String userId,
  });
}
