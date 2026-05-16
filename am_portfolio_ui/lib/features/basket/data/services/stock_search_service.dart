import 'package:am_portfolio_ui/core/services/secure_storage_service.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/stock_search_result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart' as common;

final stockSearchServiceProvider = Provider<StockSearchService>((ref) {
  return StockSearchService(
    dio: Dio(),
    storage: ref.read(secureStorageServiceProvider),
  );
});

class StockSearchService {
  final Dio _dio;
  final SecureStorageService _storage;
  
  // Using ConfigService for dynamic URL
  static String get _baseUrl => common.ConfigService.config.api.marketData?.baseUrl ?? 'https://am.munish.org';

  StockSearchService({required Dio dio, required SecureStorageService storage})
    : _dio = dio,
      _storage = storage;

  Future<List<StockSearchResult>> searchStocks(String query) async {
    if (query.isEmpty) return [];

    try {
      final token = await _storage.getToken();

      final response = await _dio.get(
        '$_baseUrl/api/market/v1/securities/search',
        queryParameters: {'query': query},
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((e) => StockSearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      // Log error or handle significantly
      print('Error searching stocks: $e');
      return [];
    }
  }
}
