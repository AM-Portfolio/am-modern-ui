import 'package:am_common/am_common.dart';
import '../../../../core/constants/basket_endpoints.dart';
import '../../domain/models/basket_opportunity.dart';

abstract class BasketRemoteDataSource {
  Future<List<BasketOpportunity>> getOpportunities({
    required String userId,
    required String portfolioId,
    String? query,
  });

  Future<BasketOpportunity> getPreview({
    required String etfIsin,
    required String userId,
    required String portfolioId,
  });
}

class BasketRemoteDataSourceImpl implements BasketRemoteDataSource {
  final ApiClient apiClient;

  BasketRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<BasketOpportunity>> getOpportunities({
    required String userId,
    required String portfolioId,
    String? query,
  }) async {
    final response = await apiClient.post(
      BasketEndpoints.opportunities,
      parser: (data) => data,
      body: {'userId': userId, 'portfolioId': portfolioId, 'etfQuery': query},
    );

    return (response as List)
        .map((e) => BasketOpportunity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BasketOpportunity> getPreview({
    required String etfIsin,
    required String userId,
    required String portfolioId,
  }) async {
    final response = await apiClient.post(
      BasketEndpoints.preview,
      parser: (data) => data, // Pass-through as we need raw map for fromJson
      body: {'etfIsin': etfIsin, 'userId': userId, 'portfolioId': portfolioId},
    );

    return BasketOpportunity.fromJson(response as Map<String, dynamic>);
  }
}
