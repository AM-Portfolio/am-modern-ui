import 'package:am_common/am_common.dart';
import '../../../../core/constants/basket_endpoints.dart';
import '../../domain/models/basket_catalog.dart';
import '../../domain/models/basket_opportunity.dart';

abstract class BasketRemoteDataSource {
  Future<BasketCatalog> getCatalog();

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

class BasketRemoteDataSourceImpl implements BasketRemoteDataSource {
  final ApiClient apiClient;

  BasketRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<BasketCatalog> getCatalog() async {
    final response = await apiClient.get(
      BasketEndpoints.catalog,
      parser: (data) => data,
    );
    return BasketCatalog.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<BasketOpportunity>> getOpportunities({
    required String userId,
    required String portfolioId,
    String? query,
  }) async {
    final response = await apiClient.post(
      BasketEndpoints.opportunities,
      parser: (data) => data,
      body: {
        'userId': userId,
        'portfolioId': portfolioId,
        'etfQuery': query,
      },
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
      parser: (data) => data,
      body: {
        'etfIsin': etfIsin,
        'userId': userId,
        'portfolioId': portfolioId,
      },
    );

    return BasketOpportunity.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<BasketOpportunity> applySubstitutes({
    required String etfIsin,
    required String userId,
    required String portfolioId,
    required List<Map<String, String>> assignments,
    BasketOpportunity? currentOpportunity,
  }) async {
    final response = await apiClient.post(
      BasketEndpoints.applySubstitutes,
      parser: (data) => data,
      body: {
        'etfIsin': etfIsin,
        'userId': userId,
        'portfolioId': portfolioId,
        'assignments': assignments,
        if (currentOpportunity != null) 'currentOpportunity': currentOpportunity.toJson(),
      },
    );
    return BasketOpportunity.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createBasketPortfolio({
    required Map<String, dynamic> body,
  }) async {
    final response = await apiClient.post(
      BasketEndpoints.createPortfolio,
      parser: (data) => data,
      body: body,
    );
    return response as Map<String, dynamic>;
  }
}
