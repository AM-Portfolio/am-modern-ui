import 'package:am_portfolio_ui/features/basket/domain/models/stock_search_result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';
import 'package:get_it/get_it.dart';

final stockSearchServiceProvider = Provider<StockSearchService>((ref) {
  return StockSearchService(
    dio: Dio(), 
  );
});
class StockSearchService {
  final Dio _dio;
  final _storage = GetIt.I<SecureStorageService>();

  StockSearchService({
    required Dio dio,
  })  : _dio = dio;

  Future<List<StockSearchResult>> searchStocks(String query) async {
    if (query.isEmpty) return [];

    try {
      final token = await _storage.getAccessToken();
      
      final response = await _dio.get(
        '${EnvDomains.market}/v1/securities/search',
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
