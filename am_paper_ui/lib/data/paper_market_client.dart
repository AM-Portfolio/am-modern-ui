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
    final s = _bareSymbol(symbol);
    return s == 'NIFTY 50' ||
        s == 'NIFTY50' ||
        s.startsWith('NIFTY ') ||
        s == 'BANK NIFTY' ||
        s == 'BANKNIFTY' ||
        s == 'SENSEX';
  }

  static String _normalizeExchange(String? exchange) {
    final ex = (exchange ?? 'NSE').trim().toUpperCase();
    if (ex.isEmpty) return 'NSE';
    if (ex == 'NSE_EQ') return 'NSE';
    if (ex == 'BSE_EQ') return 'BSE';
    return ex;
  }

  /// Strip exchange/segment prefix (`NSE:TRENT` → `TRENT`).
  static String _bareSymbol(String symbol) {
    final s = symbol.trim().toUpperCase();
    if (s.contains('|')) {
      return s.substring(s.indexOf('|') + 1).trim();
    }
    if (s.contains(':')) {
      return s.substring(s.indexOf(':') + 1).trim();
    }
    return s;
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
    final sym = _bareSymbol(symbol);
    return WatchlistStock(
      symbol: sym,
      name: (name ?? sym).trim(),
      exchange: 'NSE',
      ltp: 0,
      change: 0,
      changePercent: 0,
    );
  }

  /// Refresh LTP / change via live-ltp, falling back to quotes when empty/miss.
  Future<List<WatchlistStock>> enrichQuotes(List<WatchlistStock> rows) async {
    if (rows.isEmpty) return rows;
    await _ensureAuth();

    final byExchange = <String, List<WatchlistStock>>{};
    for (final row in rows) {
      if (row.symbol.trim().isEmpty) continue;
      final ex = _normalizeExchange(row.exchange);
      byExchange.putIfAbsent(ex, () => []).add(row);
    }
    if (byExchange.isEmpty) return rows;

    final dataMap = <String, Map<String, dynamic>>{};
    for (final entry in byExchange.entries) {
      final exchange = entry.key;
      final group = entry.value;
      final equity = <String>[];
      final indices = <String>[];
      for (final r in group) {
        final bare = _bareSymbol(r.symbol);
        if (_isIndexSymbol(bare)) {
          indices.add(bare);
        } else {
          equity.add(bare);
        }
      }
      final futures = <Future<Map<String, Map<String, dynamic>>>>[];
      if (equity.isNotEmpty) {
        futures.add(_fetchLiveLtpMap(
          equity,
          isIndexSymbol: false,
          exchange: exchange,
        ));
      }
      if (indices.isNotEmpty) {
        futures.add(_fetchLiveLtpMap(
          indices,
          isIndexSymbol: true,
          exchange: exchange,
        ));
      }
      for (final part in await Future.wait(futures)) {
        dataMap.addAll(part);
      }
    }

    // Quotes fallback for symbols still missing LTP (live-ltp often empty off-hours).
    final stillMissing = <String, List<String>>{};
    for (final entry in byExchange.entries) {
      for (final row in entry.value) {
        final item = _lookupInParsedMap(
          dataMap,
          row.symbol,
          exchange: entry.key,
        );
        final ltp = item == null ? 0.0 : _parsePriceFields(item).ltp;
        if (ltp <= 0) {
          stillMissing
              .putIfAbsent(entry.key, () => [])
              .add(_bareSymbol(row.symbol));
        }
      }
    }
    for (final entry in stillMissing.entries) {
      final symbols = entry.value.where((s) => s.isNotEmpty).toSet().toList();
      if (symbols.isEmpty) continue;
      final fromQuotes = await _fetchQuotesPriceMap(
        symbols,
        exchange: entry.key,
      );
      dataMap.addAll(fromQuotes);
    }

    if (dataMap.isEmpty) return rows;

    return rows.map((row) {
      final item = _lookupInParsedMap(
        dataMap,
        row.symbol,
        exchange: row.exchange,
      );
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

  /// Batch quotes → symbol-keyed price maps (same shape as live-ltp parse).
  Future<Map<String, Map<String, dynamic>>> _fetchQuotesPriceMap(
    List<String> symbols, {
    required String exchange,
  }) async {
    if (symbols.isEmpty) return {};
    final ex = _normalizeExchange(exchange);
    final joined = symbols.map(_bareSymbol).where((s) => s.isNotEmpty).join(',');
    if (joined.isEmpty) return {};
    final root = await _fetchQuotesHttp(
      joined,
      exchange: ex,
      forceRefresh: false,
    );
    if (root == null) return {};

    Map data = root;
    if (root['quotes'] is Map) {
      data = root['quotes'] as Map;
    } else if (root['data'] is Map) {
      data = root['data'] as Map;
    }

    final out = <String, Map<String, dynamic>>{};
    data.forEach((key, value) {
      if (value is! Map) return;
      final raw = key.toString().trim().toUpperCase();
      if (raw.isEmpty) return;
      final map = Map<String, dynamic>.from(value);
      final bare = _bareSymbol(raw);
      out[raw] = map;
      if (bare.isNotEmpty && bare != raw) {
        out.putIfAbsent(bare, () => map);
      }
      out.putIfAbsent('$ex:$bare', () => map);
    });
    return out;
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
    String exchange = 'NSE',
  }) async {
    if (symbols.isEmpty) return {};
    final ex = _normalizeExchange(exchange);
    final normalized = symbols
        .map(_bareSymbol)
        .where((s) => s.isNotEmpty)
        .toList();
    if (normalized.isEmpty) return {};
    normalized.sort();
    final cacheKey = '$ex|$isIndexSymbol|$refresh|${normalized.join(',')}';
    final inflight = _inflightLtp[cacheKey];
    if (inflight != null) return inflight;

    final future = _fetchLiveLtpMapUncached(
      normalized,
      isIndexSymbol: isIndexSymbol,
      refresh: refresh,
      exchange: ex,
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
    required String exchange,
  }) async {
    final joined = symbols.join(',');

    var parsed = await _fetchLiveLtpHttp(
      joined,
      isIndexSymbol: isIndexSymbol,
      refresh: refresh,
      exchange: exchange,
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

    if (parsed.containsKey('_') && symbols.length == 1) {
      final bare = symbols.first;
      parsed[bare] = parsed.remove('_')!;
      parsed['$exchange:$bare'] = parsed[bare]!;
    }
    return parsed;
  }

  /// Single-symbol LTP for Instant Buy — one live-ltp, no quotes round-trip.
  Future<double> fetchLiveLtp(
    String symbol, {
    bool forceRefresh = false,
    String exchange = 'NSE',
  }) async {
    final sym = _bareSymbol(symbol);
    if (sym.isEmpty) return 0;
    await _ensureAuth();
    final map = await _fetchLiveLtpMap(
      [sym],
      isIndexSymbol: _isIndexSymbol(sym),
      refresh: forceRefresh,
      exchange: exchange,
    );
    final item = _lookupInParsedMap(map, sym, exchange: exchange);
    if (item == null) return 0;
    return _parsePriceFields(item).ltp;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchLiveLtpHttp(
    String symbols, {
    required bool isIndexSymbol,
    bool refresh = false,
    String exchange = 'NSE',
  }) async {
    try {
      final uri = Uri.parse('${EnvDomains.market}/v1/market-data/live-ltp')
          .replace(queryParameters: {
        'symbols': symbols,
        'exchange': _normalizeExchange(exchange),
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
    } catch (_) {
      return {};
    }
  }

  /// Quotes GET with exchange (SDK has no exchange param yet).
  Future<Map<String, Object>?> _fetchQuotesHttp(
    String symbol, {
    required String exchange,
    bool forceRefresh = false,
  }) async {
    try {
      final uri = Uri.parse('${EnvDomains.market}/v1/market-data/quotes')
          .replace(queryParameters: {
        'symbols': symbol,
        'exchange': _normalizeExchange(exchange),
        'refresh': forceRefresh.toString(),
      });
      final headers = <String, String>{
        'Accept': 'application/json',
        if (_bearer != null && _bearer!.isNotEmpty)
          'Authorization': 'Bearer $_bearer',
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final asObjects = <String, Object>{};
      decoded.forEach((k, v) {
        if (v != null) asObjects[k.toString()] = v as Object;
      });
      return asObjects;
    } catch (_) {
      return null;
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
      final raw = key.toString().trim().toUpperCase();
      if (raw.isEmpty) return;
      final map = Map<String, dynamic>.from(value);
      out[raw] = map;
      final bare = _bareSymbol(raw);
      if (bare.isNotEmpty && bare != raw) {
        out.putIfAbsent(bare, () => map);
      }
      // Prefer exchange from payload when indexing qualified key.
      final ex = _normalizeExchange(
        (map['exchange'] ?? map['segment'] ?? '').toString(),
      );
      if (ex.isNotEmpty && bare.isNotEmpty) {
        out.putIfAbsent('$ex:$bare', () => map);
      }
    });
    if (out.isEmpty &&
        (data.containsKey('lastPrice') ||
            data.containsKey('last_price') ||
            data.containsKey('ltp'))) {
      out['_'] = Map<String, dynamic>.from(data);
    }
    return out;
  }

  Map<String, dynamic>? _lookupInParsedMap(
    Map<String, Map<String, dynamic>> data,
    String symbol, {
    String? exchange,
  }) {
    final bare = _bareSymbol(symbol);
    final ex = _normalizeExchange(exchange);
    return data['$ex:$bare'] ??
        data[bare] ??
        data[symbol.trim().toUpperCase()] ??
        data['_'];
  }

  /// Full quote + optional market depth for one symbol.
  Future<QuoteDetail?> fetchQuoteDetail(
    String symbol, {
    String? name,
    String exchange = 'NSE',
    bool forceRefresh = false,
  }) async {
    final sym = _bareSymbol(symbol);
    if (sym.isEmpty) return null;
    final ex = _normalizeExchange(exchange);
    await _ensureAuth();

    Map<String, dynamic>? quoteItem;
    try {
      final quotes = await _fetchQuotesHttp(
        sym,
        exchange: ex,
        forceRefresh: forceRefresh,
      );
      quoteItem = _extractQuoteItem(quotes, sym, exchange: ex);
    } catch (_) {}

    // Always merge live-ltp for LTP / previousClose / day change (Insider parity).
    Map<String, dynamic>? ltpItem;
    try {
      final map = await _fetchLiveLtpMap(
        [sym],
        isIndexSymbol: _isIndexSymbol(sym),
        refresh: forceRefresh,
        exchange: ex,
      );
      ltpItem = _lookupInParsedMap(map, sym, exchange: ex);
    } catch (_) {}

    final item = _mergeQuoteMaps(quoteItem, ltpItem);
    if (item == null) {
      return QuoteDetail(symbol: sym, name: name, exchange: ex);
    }

    final prices = _parsePriceFields(item);
    final ohlc = item['ohlc'] is Map ? item['ohlc'] as Map : null;
    final openRaw = _asDouble(item['open'] ??
            item['openPrice'] ??
            ohlc?['open']) ??
        prices.open;
    final highRaw = _asDouble(item['high'] ??
            item['highPrice'] ??
            ohlc?['high']) ??
        prices.high;
    final lowRaw = _asDouble(item['low'] ??
            item['lowPrice'] ??
            ohlc?['low']) ??
        prices.low;
    final prev = _asDouble(item['previousClose'] ??
            item['previous_close'] ??
            ohlc?['close']) ??
        prices.previousClose;
    // Provider often sends 0.0 for missing OHLC outside session.
    final open = (openRaw != null && openRaw > 0) ? openRaw : null;
    final high = (highRaw != null && highRaw > 0) ? highRaw : null;
    final low = (lowRaw != null && lowRaw > 0) ? lowRaw : null;
    final resolvedExchange = _normalizeExchange(
      (item['exchange'] ?? item['segment'] ?? ex).toString(),
    );

    final depth = item['marketDepth'] ?? item['depth'] ?? item['market_depth'];
    final buy = _parseDepthSide(depth, isBuy: true);
    final sell = _parseDepthSide(depth, isBuy: false);
    final volume = (_asDouble(item['volume'] ??
                item['totalTradedQuantity'] ??
                item['total_traded_quantity'] ??
                item['totalTradedVolume'] ??
                item['tradedQuantity'] ??
                item['vtt'] ??
                item['vol']) ??
            0)
        .round();

    return QuoteDetail(
      symbol: sym,
      name: name,
      exchange: resolvedExchange.isEmpty ? ex : resolvedExchange,
      ltp: prices.ltp,
      change: prices.change,
      changePercent: prices.changePercent,
      open: open,
      high: high,
      low: low,
      previousClose: prev,
      volume: volume > 0 ? volume : null,
      buyDepth: buy.take(5).toList(),
      sellDepth: sell.take(5).toList(),
    );
  }

  /// Prefer quotes OHLC/depth; overlay live-ltp price fields when stronger.
  Map<String, dynamic>? _mergeQuoteMaps(
    Map<String, dynamic>? quotes,
    Map<String, dynamic>? ltp,
  ) {
    if (quotes == null && ltp == null) return null;
    if (quotes == null) return Map<String, dynamic>.from(ltp!);
    if (ltp == null) return Map<String, dynamic>.from(quotes);

    final merged = Map<String, dynamic>.from(quotes);
    final ltpPrices = _parsePriceFields(ltp);
    final quotePrices = _parsePriceFields(quotes);

    if (ltpPrices.ltp > 0 &&
        (quotePrices.ltp <= 0 || ltpPrices.ltp != quotePrices.ltp)) {
      merged['lastPrice'] = ltpPrices.ltp;
      merged['ltp'] = ltpPrices.ltp;
    }
    if (ltpPrices.previousClose != null && ltpPrices.previousClose! > 0) {
      merged['previousClose'] = ltpPrices.previousClose;
    }
    if (ltpPrices.change != 0 || quotePrices.change == 0) {
      merged['change'] = ltpPrices.change;
    }
    if (ltpPrices.changePercent != 0 || quotePrices.changePercent == 0) {
      merged['changePercent'] = ltpPrices.changePercent;
    }
    final ltpEx = ltp['exchange'] ?? ltp['segment'];
    if (ltpEx != null && '$ltpEx'.trim().isNotEmpty) {
      merged['exchange'] = ltpEx;
    }
    return merged;
  }

  Map<String, dynamic>? _extractQuoteItem(
    Map<String, Object>? root,
    String symbol, {
    String exchange = 'NSE',
  }) {
    if (root == null) return null;
    Map data = root;
    if (root['quotes'] is Map) {
      data = root['quotes'] as Map;
    } else if (root['data'] is Map) {
      data = root['data'] as Map;
    }
    return _findSymbolMap(data, symbol, exchange: exchange);
  }

  Map<String, dynamic>? _findSymbolMap(
    Map data,
    String symbol, {
    String exchange = 'NSE',
  }) {
    final bare = _bareSymbol(symbol);
    final ex = _normalizeExchange(exchange);
    final candidates = <String>[
      '$ex:$bare',
      bare,
      symbol.trim().toUpperCase(),
      'NSE_EQ:$bare',
      'BSE_EQ:$bare',
    ];

    for (final want in candidates) {
      for (final k in data.keys) {
        final key = k.toString().toUpperCase();
        if (key == want ||
            (_bareSymbol(key) == bare && key.endsWith(':$bare'))) {
          final v = data[k];
          if (v is Map) return Map<String, dynamic>.from(v);
        }
      }
    }

    // Prefer exact exchange-qualified match when multiple exchanges present.
    for (final k in data.keys) {
      final key = k.toString().toUpperCase();
      if (_bareSymbol(key) == bare) {
        final v = data[k];
        if (v is Map) {
          if (key.startsWith('$ex:') || !key.contains(':')) {
            return Map<String, dynamic>.from(v);
          }
        }
      }
    }

    if (data.containsKey('lastPrice') ||
        data.containsKey('last_price') ||
        data.containsKey('ltp')) {
      return Map<String, dynamic>.from(data);
    }
    return null;
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
