import 'dart:convert';

import 'package:am_common/am_common.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'quote_models.dart';
import 'watchlist_models.dart';

/// Market search + live LTP / quotes — same path as Equity Insider.
class PaperMarketClient {
  PaperMarketClient({MarketDataSdkService? sdk})
      : _sdk = sdk ?? MarketDataSdkService();

  final MarketDataSdkService _sdk;
  String? _bearer;

  /// Coalesce identical in-flight live-ltp requests (watchlist + ticket).
  final Map<String, Future<Map<String, Map<String, dynamic>>>> _inflightLtp =
      {};

  /// Re-read access token; skip SecureStorage when already cached unless [force].
  Future<void> _ensureAuth({bool force = false}) async {
    if (!force && _bearer != null && _bearer!.isNotEmpty) {
      _sdk.setAuthentication(_bearer!);
      return;
    }
    try {
      if (GetIt.I.isRegistered<SecureStorageService>()) {
        final token = await GetIt.I<SecureStorageService>().getAccessToken();
        if (token != null && token.isNotEmpty) {
          _bearer = token;
          _sdk.setAuthentication(token);
          return;
        }
      }
    } catch (_) {}
  }

  /// Clear cached bearer (e.g. after 401).
  void clearAuthCache() {
    _bearer = null;
  }

  static bool _isIndexSymbol(String symbol) {
    final s = symbol.trim().toUpperCase();
    return s == 'NIFTY 50' ||
        s == 'NIFTY50' ||
        s.startsWith('NIFTY ') ||
        s == 'BANK NIFTY' ||
        s == 'BANKNIFTY' ||
        s == 'SENSEX';
  }

  /// Nifty 50 constituents via indices batch (same path as Market dashboard).
  Future<List<WatchlistStock>> fetchNifty50Constituents() async {
    await _ensureAuth();
    try {
      final result =
          await _sdk.marketIndexApi.getLatestIndicesData(const ['NIFTY 50']);
      if (result != null && result.data.isNotEmpty) {
        return _mapIndexStocks(result.data);
      }
    } catch (_) {}

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (_bearer != null && _bearer!.isNotEmpty)
          'Authorization': 'Bearer $_bearer',
      };
      final response = await http.post(
        Uri.parse('${EnvDomains.market}/v1/indices/batch?forceRefresh=false'),
        headers: headers,
        body: jsonEncode(const ['NIFTY 50']),
      );
      if (response.statusCode != 200) return const [];
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) return const [];
      final first = decoded.first;
      if (first is! Map) return const [];
      final list = first['data'] as List? ?? first['stocks'] as List? ?? const [];
      final out = <WatchlistStock>[];
      for (final row in list) {
        if (row is! Map) continue;
        final sym = (row['symbol'] ?? '').toString().trim().toUpperCase();
        if (sym.isEmpty) continue;
        final name = (row['companyName'] ?? row['name'] ?? sym).toString().trim();
        out.add(stockFromSymbol(sym, name: name.isEmpty ? sym : name));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  List<WatchlistStock> _mapIndexStocks(List<StockData> data) {
    final out = <WatchlistStock>[];
    for (final s in data) {
      final sym = (s.symbol ?? '').trim().toUpperCase();
      if (sym.isEmpty) continue;
      final name = (s.companyName ?? s.name ?? sym).trim();
      out.add(stockFromSymbol(sym, name: name.isEmpty ? sym : name));
    }
    return out;
  }

  Future<List<SecurityDocument>?> search(
    String query, {
    int limit = 8,
  }) async {
    await _ensureAuth();
    final q = query.trim();
    if (q.isEmpty) return const [];
    return _sdk.securityApi.search(
      q,
      smartRecommendations: true,
      category: 'STOCKS',
      limit: limit,
    );
  }

  /// Builds a session watchlist row from a search hit (quotes filled later).
  WatchlistStock stockFromDocument(SecurityDocument doc) {
    final symbol = (doc.key?.symbol ?? '').trim().toUpperCase();
    final name = (doc.metadata?.companyName ?? symbol).trim();
    return WatchlistStock(
      symbol: symbol,
      name: name.isEmpty ? symbol : name,
      exchange: 'NSE',
      ltp: 0,
      change: 0,
      changePercent: 0,
    );
  }

  WatchlistStock stockFromSymbol(String symbol, {String? name}) {
    final sym = symbol.trim().toUpperCase();
    return WatchlistStock(
      symbol: sym,
      name: (name ?? sym).trim(),
      exchange: 'NSE',
      ltp: 0,
      change: 0,
      changePercent: 0,
    );
  }

  /// Refresh LTP / change for the given symbols via live-ltp.
  Future<List<WatchlistStock>> enrichQuotes(List<WatchlistStock> rows) async {
    if (rows.isEmpty) return rows;
    await _ensureAuth();
    final symbols =
        rows.map((r) => r.symbol).where((s) => s.isNotEmpty).toList();
    if (symbols.isEmpty) return rows;
    // #region agent log
    final _dbgStart = DateTime.now().millisecondsSinceEpoch;
    // #endregion

    final equity = <String>[];
    final indices = <String>[];
    for (final s in symbols) {
      if (_isIndexSymbol(s)) {
        indices.add(s);
      } else {
        equity.add(s);
      }
    }

    final futures = <Future<Map<String, Map<String, dynamic>>>>[];
    if (equity.isNotEmpty) {
      futures.add(_fetchLiveLtpMap(equity, isIndexSymbol: false));
    }
    if (indices.isNotEmpty) {
      futures.add(_fetchLiveLtpMap(indices, isIndexSymbol: true));
    }
    final parts = await Future.wait(futures);
    // #region agent log
    http
        .post(
          Uri.parse(
            'http://127.0.0.1:7626/ingest/0d1c8c7b-9f69-4195-beee-fbf3af51620e',
          ),
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': 'c7037f',
          },
          body: jsonEncode({
            'sessionId': 'c7037f',
            'runId': 'pre-fix',
            'hypothesisId': 'C',
            'location': 'paper_market_client.dart:enrichQuotes',
            'message': 'watchlist enrich done (refresh=false)',
            'data': {
              'equityCount': equity.length,
              'indexCount': indices.length,
              'elapsedMs':
                  DateTime.now().millisecondsSinceEpoch - _dbgStart,
            },
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }),
        )
        .catchError((_) => http.Response('', 599));
    // #endregion
    final dataMap = <String, Map<String, dynamic>>{};
    for (final p in parts) {
      dataMap.addAll(p);
    }
    if (dataMap.isEmpty) return rows;

    return rows.map((row) {
      final item = dataMap[row.symbol.toUpperCase()];
      if (item == null) return row;
      final parsed = _parsePriceFields(item);
      if (parsed.ltp <= 0) return row;
      return row.copyWith(
        ltp: parsed.ltp,
        change: parsed.change,
        changePercent: parsed.changePercent,
      );
    }).toList();
  }

  /// Enrich in chunks so callers can paint progressive LTP.
  Stream<List<WatchlistStock>> enrichQuotesChunked(
    List<WatchlistStock> rows, {
    int chunkSize = 8,
  }) async* {
    if (rows.isEmpty) return;
    await _ensureAuth();
    final size = chunkSize.clamp(1, 50);
    for (var i = 0; i < rows.length; i += size) {
      final end = (i + size).clamp(0, rows.length);
      final chunk = rows.sublist(i, end);
      yield await enrichQuotes(chunk);
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchLiveLtpMap(
    List<String> symbols, {
    required bool isIndexSymbol,
    bool refresh = false,
  }) async {
    if (symbols.isEmpty) return {};
    final normalized = symbols
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();
    if (normalized.isEmpty) return {};
    normalized.sort();
    final cacheKey = '$isIndexSymbol|$refresh|${normalized.join(',')}';
    final inflight = _inflightLtp[cacheKey];
    if (inflight != null) return inflight;

    final future = _fetchLiveLtpMapUncached(
      normalized,
      isIndexSymbol: isIndexSymbol,
      refresh: refresh,
    );
    _inflightLtp[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inflightLtp.remove(cacheKey);
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchLiveLtpMapUncached(
    List<String> symbols, {
    required bool isIndexSymbol,
    required bool refresh,
  }) async {
    final joined = symbols.join(',');

    // One HTTP call only — avoid SDK then HTTP double-hit (same URL twice).
    var parsed = await _fetchLiveLtpHttp(
      joined,
      isIndexSymbol: isIndexSymbol,
      refresh: refresh,
    );

    if (parsed.isEmpty) {
      try {
        final ltpRes = await _sdk.marketDataApi.getLiveLTP(
          joined,
          timeframe: '1D',
          isIndexSymbol: isIndexSymbol,
          refresh: refresh,
        );
        parsed = _parseLiveLtpData(ltpRes);
      } catch (_) {}
    }

    // Remap single-symbol bare quote payloads onto the requested symbol.
    if (parsed.containsKey('_') && symbols.length == 1) {
      parsed[symbols.first.toUpperCase()] = parsed.remove('_')!;
    }
    return parsed;
  }

  /// Single-symbol LTP for Instant Buy — one live-ltp, no quotes round-trip.
  Future<double> fetchLiveLtp(
    String symbol, {
    bool forceRefresh = false,
  }) async {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return 0;
    await _ensureAuth();
    final map = await _fetchLiveLtpMap(
      [sym],
      isIndexSymbol: _isIndexSymbol(sym),
      refresh: forceRefresh,
    );
    final item = map[sym] ?? map['_'];
    if (item == null) return 0;
    return _parsePriceFields(item).ltp;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchLiveLtpHttp(
    String symbols, {
    required bool isIndexSymbol,
    bool refresh = false,
  }) async {
    // #region agent log
    final _dbgStart = DateTime.now().millisecondsSinceEpoch;
    final _symCount = symbols.split(',').where((s) => s.trim().isNotEmpty).length;
    // #endregion
    try {
      final uri = Uri.parse('${EnvDomains.market}/v1/market-data/live-ltp')
          .replace(queryParameters: {
        'symbols': symbols,
        'isIndexSymbol': isIndexSymbol.toString(),
        'timeframe': '1D',
        'refresh': refresh.toString(),
      });
      final headers = <String, String>{
        'Accept': 'application/json',
        if (_bearer != null && _bearer!.isNotEmpty)
          'Authorization': 'Bearer $_bearer',
      };
      final response = await http.get(uri, headers: headers);
      // #region agent log
      final _dbgMs = DateTime.now().millisecondsSinceEpoch - _dbgStart;
      http
          .post(
            Uri.parse(
              'http://127.0.0.1:7626/ingest/0d1c8c7b-9f69-4195-beee-fbf3af51620e',
            ),
            headers: {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': 'c7037f',
            },
            body: jsonEncode({
              'sessionId': 'c7037f',
              'runId': 'pre-fix',
              'hypothesisId': 'A',
              'location': 'paper_market_client.dart:_fetchLiveLtpHttp',
              'message': 'live-ltp http completed',
              'data': {
                'refresh': refresh,
                'isIndexSymbol': isIndexSymbol,
                'symbolCount': _symCount,
                'symbolsPreview': symbols.length > 80
                    ? '${symbols.substring(0, 80)}…'
                    : symbols,
                'status': response.statusCode,
                'elapsedMs': _dbgMs,
              },
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          )
          .catchError((_) => http.Response('', 599));
      // #endregion
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {};
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return {};
      final asObjects = <String, Object>{};
      decoded.forEach((k, v) {
        if (v != null) asObjects[k.toString()] = v as Object;
      });
      return _parseLiveLtpData(asObjects);
    } catch (e) {
      // #region agent log
      http
          .post(
            Uri.parse(
              'http://127.0.0.1:7626/ingest/0d1c8c7b-9f69-4195-beee-fbf3af51620e',
            ),
            headers: {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': 'c7037f',
            },
            body: jsonEncode({
              'sessionId': 'c7037f',
              'runId': 'pre-fix',
              'hypothesisId': 'A',
              'location': 'paper_market_client.dart:_fetchLiveLtpHttp',
              'message': 'live-ltp http error',
              'data': {
                'refresh': refresh,
                'elapsedMs':
                    DateTime.now().millisecondsSinceEpoch - _dbgStart,
                'error': e.toString(),
              },
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          )
          .catchError((_) => http.Response('', 599));
      // #endregion
      return {};
    }
  }

  Map<String, Map<String, dynamic>> _parseLiveLtpData(
    Map<String, Object>? root,
  ) {
    if (root == null) return {};
    Map data = root;
    if (root['data'] is Map) {
      data = root['data'] as Map;
    }
    final out = <String, Map<String, dynamic>>{};
    data.forEach((key, value) {
      if (value is! Map) return;
      final sym = key.toString().trim().toUpperCase();
      if (sym.isEmpty) return;
      out[sym] = Map<String, dynamic>.from(value);
    });
    // Single-symbol payload shaped as the quote itself.
    if (out.isEmpty &&
        (data.containsKey('lastPrice') ||
            data.containsKey('last_price') ||
            data.containsKey('ltp'))) {
      out['_'] = Map<String, dynamic>.from(data);
    }
    return out;
  }

  /// Full quote + optional market depth for one symbol.
  Future<QuoteDetail?> fetchQuoteDetail(
    String symbol, {
    String? name,
    bool forceRefresh = false,
  }) async {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return null;
    await _ensureAuth();
    // #region agent log
    final _dbgStart = DateTime.now().millisecondsSinceEpoch;
    // #endregion

    Map<String, dynamic>? item;
    try {
      final quotes = await _sdk.marketDataApi.getQuotes(
        sym,
        refresh: forceRefresh,
      );
      item = _extractQuoteItem(quotes, sym);
      // #region agent log
      http
          .post(
            Uri.parse(
              'http://127.0.0.1:7626/ingest/0d1c8c7b-9f69-4195-beee-fbf3af51620e',
            ),
            headers: {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': 'c7037f',
            },
            body: jsonEncode({
              'sessionId': 'c7037f',
              'runId': 'pre-fix',
              'hypothesisId': 'D',
              'location': 'paper_market_client.dart:fetchQuoteDetail',
              'message': 'quotes leg done',
              'data': {
                'symbol': sym,
                'forceRefresh': forceRefresh,
                'quotesHit': item != null,
                'elapsedMs':
                    DateTime.now().millisecondsSinceEpoch - _dbgStart,
              },
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          )
          .catchError((_) => http.Response('', 599));
      // #endregion
    } catch (_) {}

    if (item == null) {
      final map = await _fetchLiveLtpMap(
        [sym],
        isIndexSymbol: _isIndexSymbol(sym),
        refresh: forceRefresh,
      );
      item = map[sym] ?? map['_'];
      // #region agent log
      http
          .post(
            Uri.parse(
              'http://127.0.0.1:7626/ingest/0d1c8c7b-9f69-4195-beee-fbf3af51620e',
            ),
            headers: {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': 'c7037f',
            },
            body: jsonEncode({
              'sessionId': 'c7037f',
              'runId': 'pre-fix',
              'hypothesisId': 'D',
              'location': 'paper_market_client.dart:fetchQuoteDetail',
              'message': 'fell back to live-ltp',
              'data': {
                'symbol': sym,
                'forceRefresh': forceRefresh,
                'ltpHit': item != null,
                'elapsedMs':
                    DateTime.now().millisecondsSinceEpoch - _dbgStart,
              },
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          )
          .catchError((_) => http.Response('', 599));
      // #endregion
    }

    if (item == null) {
      return QuoteDetail(symbol: sym, name: name, exchange: 'NSE');
    }

    final prices = _parsePriceFields(item);
    final ohlc = item['ohlc'] is Map ? item['ohlc'] as Map : null;
    final open = _asDouble(item['open'] ??
            item['openPrice'] ??
            ohlc?['open']) ??
        prices.open;
    final high = _asDouble(item['high'] ??
            item['highPrice'] ??
            ohlc?['high']) ??
        prices.high;
    final low = _asDouble(item['low'] ??
            item['lowPrice'] ??
            ohlc?['low']) ??
        prices.low;
    final prev = _asDouble(item['previousClose'] ??
            item['previous_close'] ??
            ohlc?['close']) ??
        prices.previousClose;
    final exchange =
        (item['exchange'] ?? item['segment'] ?? 'NSE').toString().toUpperCase();

    final depth = item['marketDepth'] ?? item['depth'] ?? item['market_depth'];
    final buy = _parseDepthSide(depth, isBuy: true);
    final sell = _parseDepthSide(depth, isBuy: false);

    return QuoteDetail(
      symbol: sym,
      name: name,
      exchange: exchange.isEmpty ? 'NSE' : exchange,
      ltp: prices.ltp,
      change: prices.change,
      changePercent: prices.changePercent,
      open: open,
      high: high,
      low: low,
      previousClose: prev,
      buyDepth: buy.take(5).toList(),
      sellDepth: sell.take(5).toList(),
    );
  }

  Map<String, dynamic>? _extractQuoteItem(
    Map<String, Object>? root,
    String symbol,
  ) {
    if (root == null) return null;
    Map data = root;
    if (root['data'] is Map) {
      data = root['data'] as Map;
    }
    return _findSymbolMap(data, symbol);
  }

  Map<String, dynamic>? _findSymbolMap(Map data, String symbol) {
    final key = data.keys.firstWhere(
      (k) => k.toString().toUpperCase() == symbol.toUpperCase(),
      orElse: () => '',
    );
    if (key == '' || data[key] is! Map) {
      // Sometimes payload is the quote itself (single-symbol).
      if (data.containsKey('lastPrice') ||
          data.containsKey('last_price') ||
          data.containsKey('ltp')) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    }
    return Map<String, dynamic>.from(data[key] as Map);
  }

  _PriceFields _parsePriceFields(Map item) {
    final lp = _asDouble(
          item['lastPrice'] ??
              item['last_price'] ??
              item['ltp'] ??
              item['price'] ??
              item['currentPrice'],
        ) ??
        0;
    final prev = _asDouble(item['previousClose'] ?? item['previous_close']);
    final change = _asDouble(
          item['change'] ??
              item['net_change'] ??
              item['dayChange'] ??
              item['netChange'] ??
              item['chg'],
        ) ??
        (prev != null && prev > 0 && lp > 0 ? lp - prev : 0.0);
    final changePct = _asDouble(
          item['changePercent'] ??
              item['change_percent'] ??
              item['pChange'] ??
              item['dayChangePercent'] ??
              item['percentChange'] ??
              item['pctChange'],
        ) ??
        (prev != null && prev > 0 && lp > 0 ? ((lp - prev) / prev) * 100 : 0.0);
    return _PriceFields(
      ltp: lp,
      change: change,
      changePercent: changePct,
      open: _asDouble(item['open'] ?? item['openPrice']),
      high: _asDouble(item['high'] ?? item['highPrice']),
      low: _asDouble(item['low'] ?? item['lowPrice']),
      previousClose: prev,
    );
  }

  List<DepthLevel> _parseDepthSide(Object? depth, {required bool isBuy}) {
    if (depth is! Map) return const [];
    final sideKeys = isBuy
        ? ['buyOrders', 'buy', 'bids', 'bid']
        : ['sellOrders', 'sell', 'asks', 'ask'];
    List? raw;
    for (final k in sideKeys) {
      if (depth[k] is List) {
        raw = depth[k] as List;
        break;
      }
    }
    if (raw == null) return const [];
    final out = <DepthLevel>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final price = _asDouble(e['price'] ?? e['p']);
      final qty = (_asDouble(e['quantity'] ?? e['qty'] ?? e['q']) ?? 0).round();
      if (price == null || price <= 0) continue;
      out.add(DepthLevel(
        price: price,
        quantity: qty,
        orders: (_asDouble(e['orders'] ?? e['orderCount']))?.round(),
      ));
    }
    return out;
  }

  double? _asDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class _PriceFields {
  const _PriceFields({
    required this.ltp,
    required this.change,
    required this.changePercent,
    this.open,
    this.high,
    this.low,
    this.previousClose,
  });

  final double ltp;
  final double change;
  final double changePercent;
  final double? open;
  final double? high;
  final double? low;
  final double? previousClose;
}
