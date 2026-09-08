import 'package:dio/dio.dart';
import 'package:am_common/am_common.dart' hide ApiClient;
import 'models/watchlist_model.dart';
import 'package:get_it/get_it.dart';

class WatchlistApiClient {
  final Dio _dio;

  WatchlistApiClient({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: EnvDomains.market)) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          if (GetIt.I.isRegistered<SecureStorageService>()) {
            final token = await GetIt.I<SecureStorageService>().getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
        } catch (_) {}
        return handler.next(options);
      },
    ));
  }

  Future<List<Watchlist>> getWatchlists() async {
    final response = await _dio.get('/v1/watchlists');
    final data = response.data as List;
    return data.map((json) => Watchlist.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Watchlist> createWatchlist(String name) async {
    final response = await _dio.post('/v1/watchlists', data: {'name': name});
    return Watchlist.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Watchlist> updateWatchlist(String id, String name) async {
    final response = await _dio.put('/v1/watchlists/$id', data: {'name': name});
    return Watchlist.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteWatchlist(String id) async {
    await _dio.delete('/v1/watchlists/$id');
  }

  Future<List<WatchlistItem>> getWatchlistItems(String id) async {
    final response = await _dio.get('/v1/watchlists/$id/items');
    final data = response.data as List;
    return data.map((json) => WatchlistItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<WatchlistItem> addStock(String id, String symbol) async {
    final response = await _dio.post('/v1/watchlists/$id/items', data: {'symbol': symbol});
    return WatchlistItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeStock(String id, String symbol) async {
    await _dio.delete('/v1/watchlists/$id/items/$symbol');
  }

  Future<List<WatchlistCheckStatus>> checkStockInWatchlists(String symbol) async {
    final response = await _dio.get('/v1/watchlists/check/$symbol');
    final data = response.data as List;
    return data.map((json) => WatchlistCheckStatus.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Map<String, Map<String, dynamic>>> getLiveLTP(List<String> symbols) async {
    if (symbols.isEmpty) return {};
    try {
      final response = await _dio.get(
        '/v1/market-data/live-ltp',
        queryParameters: {
          'symbols': symbols.join(','),
          'isIndexSymbol': 'false',
          'timeframe': '1D',
          'refresh': 'false',
        },
      );
      if (response.data is Map && response.data['data'] is Map) {
        final dataMap = response.data['data'] as Map;
        return dataMap.map((key, val) => MapEntry(key.toString().toUpperCase(), (val as Map).cast<String, dynamic>()));
      }
    } catch (e) {
      // ignore
    }
    return {};
  }

  Future<Map<String, String>> getInstrumentNames(List<String> symbols) async {
    if (symbols.isEmpty) return {};
    try {
      final response = await _dio.post(
        '/v1/instruments/search',
        data: {'tradingSymbols': symbols},
      );
      if (response.data is List) {
        final res = <String, String>{};
        for (final item in response.data as List) {
          if (item is Map) {
            final sym = item['trading_symbol'] ?? item['tradingSymbol'] ?? item['symbol'];
            final name = item['name'] ?? item['company_name'] ?? item['companyName'];
            if (sym != null && name != null) {
              res[sym.toString().toUpperCase()] = name.toString();
            }
          }
        }
        return res;
      }
    } catch (_) {}
    return {};
  }
}

