import 'package:am_common/am_common.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:get_it/get_it.dart';

import 'quote_models.dart';
import 'watchlist_models.dart';

/// Market search + live LTP / quotes — same path as Equity Insider.
class PaperMarketClient {
  PaperMarketClient({MarketDataSdkService? sdk})
      : _sdk = sdk ?? MarketDataSdkService();

  final MarketDataSdkService _sdk;
  bool _authAttempted = false;

  Future<void> _ensureAuth() async {
    if (_authAttempted) return;
    _authAttempted = true;
    try {
      if (GetIt.I.isRegistered<SecureStorageService>()) {
        final token = await GetIt.I<SecureStorageService>().getAccessToken();
        if (token != null && token.isNotEmpty) {
          _sdk.setAuthentication(token);
        }
      }
    } catch (_) {}
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
    final symbols = rows.map((r) => r.symbol).where((s) => s.isNotEmpty).toList();
    if (symbols.isEmpty) return rows;

    try {
      final ltpRes = await _sdk.marketDataApi.getLiveLTP(
        symbols.join(','),
        isIndexSymbol: false,
      );
      if (ltpRes == null || ltpRes['data'] is! Map) return rows;
      final dataMap = ltpRes['data'] as Map;

      return rows.map((row) {
        final item = _findSymbolMap(dataMap, row.symbol);
        if (item == null) return row;
        final parsed = _parsePriceFields(item);
        if (parsed.ltp <= 0) return row;
        return row.copyWith(
          ltp: parsed.ltp,
          change: parsed.change,
          changePercent: parsed.changePercent,
        );
      }).toList();
    } catch (_) {
      return rows;
    }
  }

  /// Full quote + optional market depth for one symbol.
  Future<QuoteDetail?> fetchQuoteDetail(String symbol, {String? name}) async {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return null;
    await _ensureAuth();

    Map<String, dynamic>? item;
    try {
      final quotes = await _sdk.marketDataApi.getQuotes(sym);
      item = _extractQuoteItem(quotes, sym);
    } catch (_) {}

    if (item == null) {
      try {
        final ltpRes = await _sdk.marketDataApi.getLiveLTP(
          sym,
          isIndexSymbol: false,
        );
        item = _extractQuoteItem(ltpRes, sym);
      } catch (_) {}
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
      if (data.containsKey('lastPrice') || data.containsKey('last_price')) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    }
    return Map<String, dynamic>.from(data[key] as Map);
  }

  _PriceFields _parsePriceFields(Map item) {
    final lp = _asDouble(item['lastPrice'] ?? item['last_price'] ?? item['ltp']) ??
        0;
    final prev = _asDouble(item['previousClose'] ?? item['previous_close']);
    final change = _asDouble(item['change'] ?? item['net_change']) ??
        (prev != null && prev > 0 && lp > 0 ? lp - prev : 0.0);
    final changePct = _asDouble(
          item['changePercent'] ?? item['change_percent'] ?? item['pChange'],
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
