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

  Future<List<dynamic>> getMyBaskets({
    required String userId,

    required String portfolioId,
  });

  Future<dynamic> createPortfolio(Map<String, dynamic> request);

  Future<dynamic> applySubstitutes(Map<String, dynamic> request);

  Future<dynamic> calculateQuantities(Map<String, dynamic> request);
  Future<dynamic> calculateQuantitiesFinalPreview(Map<String, dynamic> request);

  Future<void> deleteBasket({
    required String basketId,
    required String userId,
  });

  Future<dynamic> getBasketDetail({
    required String basketId,
    required String userId,
  });

  Future<Map<String, dynamic>> listDrafts({
    required String userId,
    String? portfolioId,
  });

  Future<Map<String, dynamic>> getDraft({
    required String draftId,
    required String userId,
  });

  Future<Map<String, dynamic>> upsertDraft(Map<String, dynamic> request);

  Future<void> deleteDraft({
    required String draftId,
    required String userId,
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
  Future<List<dynamic>> getMyBaskets({
    required String userId,
    required String portfolioId,
  }) async {
    final response = await apiClient.get(
      BasketEndpoints.myBaskets,
      queryParams: {
        'userId': userId,
        'portfolioId': portfolioId,
      },
      parser: (data) => data,
    );
    return response as List<dynamic>;
  }

  @override
  Future<dynamic> createPortfolio(Map<String, dynamic> request) async {
    final response = await apiClient.post(
      BasketEndpoints.createPortfolio,
      body: request,
      parser: (data) => data,
    );
    return response;
  }

  @override
  Future<dynamic> calculateQuantities(Map<String, dynamic> request) async {
    final response = await apiClient.post(
      BasketEndpoints.calculateQuantities,
      body: request,
      parser: (data) => data,
    );
    return response;
  }

  @override
  Future<dynamic> calculateQuantitiesFinalPreview(Map<String, dynamic> request) async {
    final response = await apiClient.post(
      BasketEndpoints.calculateQuantitiesFinalPreview,
      body: request,
      parser: (data) => data,
    );
    return response;
  }

  @override
  Future<dynamic> applySubstitutes(Map<String, dynamic> request) async {
    final response = await apiClient.post(
      BasketEndpoints.applySubstitutes,
      body: request,
      parser: (data) => data,
    );
    return response;
  }

  @override
  Future<dynamic> getBasketDetail({
    required String basketId,
    required String userId,
  }) async {
    final response = await apiClient.get(
      BasketEndpoints.getBasketDetail(basketId),
      queryParams: {
        'userId': userId,
      },
      parser: (data) => data,
    );
    return response;
  }

  @override
  Future<void> deleteBasket({
    required String basketId,
    required String userId,
  }) async {
    await apiClient.delete(
      BasketEndpoints.deleteBasket(basketId),
      queryParams: {
        'userId': userId,
      },
      parser: (data) => data,
    );
  }

  @override
  Future<Map<String, dynamic>> listDrafts({
    required String userId,
    String? portfolioId,
  }) async {
    final response = await apiClient.get(
      BasketEndpoints.drafts,
      queryParams: {
        'userId': userId,
        if (portfolioId != null && portfolioId.isNotEmpty)
          'portfolioId': portfolioId,
      },
      parser: (data) => data,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> getDraft({
    required String draftId,
    required String userId,
  }) async {
    final response = await apiClient.get(
      BasketEndpoints.draftById(draftId),
      queryParams: {'userId': userId},
      parser: (data) => data,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> upsertDraft(Map<String, dynamic> request) async {
    // POST is primary (gateway-friendly); PUT remains on the server for compatibility.
    final response = await apiClient.post(
      BasketEndpoints.drafts,
      body: request,
      parser: (data) => data,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<void> deleteDraft({
    required String draftId,
    required String userId,
  }) async {
    await apiClient.delete(
      BasketEndpoints.draftById(draftId),
      queryParams: {'userId': userId},
      parser: (data) => data,
    );
  }
}
