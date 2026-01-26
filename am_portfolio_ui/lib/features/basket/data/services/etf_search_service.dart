import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart';
import '../../domain/models/etf_search_result.dart';

class EtfSearchService {
  final Dio _dio = Dio();
  // Using the same URL as am_market_ui
  static const String baseUrl = 'https://am.munish.org/api/etf/v1';
  final _storage = GetIt.I<SecureStorageService>();

  EtfSearchService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<Map<String, dynamic>> _getHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<EtfSearchResult>> searchEtfs(String query, {int limit = 20}) async {
    try {
      final headers = await _getHeaders();
      
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'query': query,
          'limit': limit,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data is List) {
          return data.map((e) => EtfSearchResult.fromJson(e)).toList();
        } else if (data is Map) {
          // Handle wrapped response
          final list = data['data'] ?? data['etfs'] ?? data['results'];
          if (list is List) {
            return list.map((e) => EtfSearchResult.fromJson(e)).toList();
          }
        }
        
        AppLogger.warning("Unexpected response structure: $data", tag: "EtfSearchService");
        return [];
      } else {
        AppLogger.error("Failed search: ${response.statusCode}", tag: "EtfSearchService");
        return [];
      }
    } catch (e) {
      AppLogger.error("Error searching ETFs: $e", tag: "EtfSearchService", error: e);
      return [];
    }
  }
}
