import '../../domain/models/basket_opportunity.dart';
import '../../domain/repositories/basket_repository.dart';
import '../datasources/basket_remote_data_source.dart';

class BasketRepositoryImpl implements BasketRepository {
  final BasketRemoteDataSource remoteDataSource;

  BasketRepositoryImpl({required this.remoteDataSource});

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
}
