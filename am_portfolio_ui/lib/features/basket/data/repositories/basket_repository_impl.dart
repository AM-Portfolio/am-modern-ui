import '../../domain/models/basket_catalog.dart';
import '../../domain/models/basket_opportunity.dart';
import '../../domain/repositories/basket_repository.dart';
import '../datasources/basket_remote_data_source.dart';

class BasketRepositoryImpl implements BasketRepository {
  final BasketRemoteDataSource remoteDataSource;

  BasketRepositoryImpl({required this.remoteDataSource});

  @override
  Future<BasketCatalog> getCatalog() {
    return remoteDataSource.getCatalog();
  }

  @override
  Future<List<BasketOpportunity>> getOpportunities({
    required String userId,
    required String portfolioId,
    String? query,
  }) async {
    return remoteDataSource.getOpportunities(
      userId: userId,
      portfolioId: portfolioId,
      query: query,
    );
  }

  @override
  Future<BasketOpportunity> getBasketPreview({
    required String etfIsin,
    required String userId,
    required String portfolioId,
  }) async {
    return remoteDataSource.getPreview(
      etfIsin: etfIsin,
      userId: userId,
      portfolioId: portfolioId,
    );
  }

  @override
  Future<BasketOpportunity> applySubstitutes({
    required String etfIsin,
    required String userId,
    required String portfolioId,
    required List<Map<String, String>> assignments,
    BasketOpportunity? currentOpportunity,
  }) async {
    return remoteDataSource.applySubstitutes(
      etfIsin: etfIsin,
      userId: userId,
      portfolioId: portfolioId,
      assignments: assignments,
      currentOpportunity: currentOpportunity,
    );
  }

  @override
  Future<Map<String, dynamic>> createBasketPortfolio({
    required Map<String, dynamic> body,
  }) {
    return remoteDataSource.createBasketPortfolio(body: body);
  }
}
