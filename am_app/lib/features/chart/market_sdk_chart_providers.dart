import 'package:am_chart_ui/am_chart_ui.dart';
import 'package:am_common/am_common.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:get_it/get_it.dart';

/// Live OHLC from Market Analytics API (same source as Equity Insider).
class MarketSdkHistoricalProvider implements HistoricalDataProvider {
  MarketSdkHistoricalProvider({MarketDataSdkService? sdk})
      : _sdk = sdk ?? MarketDataSdkService();

  final MarketDataSdkService _sdk;

  @override
  bool get isMock => false;

  Future<void> _auth() async {
    try {
      if (GetIt.I.isRegistered<SecureStorageService>()) {
        final token = await GetIt.I<SecureStorageService>().getAccessToken();
        if (token != null && token.isNotEmpty) {
          _sdk.setAuthentication(token);
        }
      }
    } catch (_) {}
  }

  @override
  Future<List<ChartBar>> getBars({
    required String symbol,
    required String timeframe,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    await _auth();
    final chartSymbol = _chartSymbol(symbol);
    final range = _apiRange(timeframe);
    final isIndex = _isIndex(symbol);

    final response = await _sdk.analyticsApi.getHistoricalCharts(
      chartSymbol,
      range: range,
      isIndexSymbol: isIndex,
    );

    final points = <ChartBar>[];
    if (response != null && response.data.isNotEmpty) {
      final symKey = response.data.keys.firstWhere(
        (k) =>
            k.toUpperCase() == chartSymbol.toUpperCase() ||
            k.toUpperCase() == symbol.toUpperCase(),
        orElse: () => response.data.keys.first,
      );
      final historical = response.data[symKey];
      if (historical != null) {
        for (final dp in historical.dataPoints) {
          final t = dp.time;
          final c = dp.close;
          if (t == null || c == null) continue;
          points.add(ChartBar(
            time: t,
            open: dp.open ?? c,
            high: dp.high ?? c,
            low: dp.low ?? c,
            close: c,
            volume: (dp.volume ?? 0).toDouble(),
          ));
        }
      }
    }

    if (points.isEmpty && range == '1W') {
      return getBars(symbol: symbol, timeframe: '1D', from: from, to: to, limit: limit);
    }

    if (limit != null && points.length > limit) {
      return points.sublist(points.length - limit);
    }
    return points;
  }

  static String _chartSymbol(String symbol) {
    final s = symbol.trim();
    if (s.toUpperCase().startsWith('BSE:') || s.toUpperCase().startsWith('NSE:')) {
      return s;
    }
    return s;
  }

  /// Map terminal TF codes to analytics `range` (1D / 1W / 1M / …).
  static String _apiRange(String timeframe) {
    switch (timeframe.toUpperCase()) {
      case '1W':
        return '1W';
      case '1MO':
      case '1MONTH':
        return '1M';
      case '1Y':
      case '1YR':
      case '12M':
        return '1Y';
      case '1D':
        return '1D';
      // Intraday chips (1M/5M/15M/1H) → session range
      default:
        return '1D';
    }
  }

  static bool _isIndex(String symbol) {
    final u = symbol.toUpperCase().replaceAll(':', ' ');
    return u.contains('NIFTY') ||
        u.contains('SENSEX') ||
        u.contains('BANKNIFTY') ||
        u.contains('FINNIFTY') ||
        u.contains('MIDCPNIFTY');
  }
}

class MarketSdkMarketDataProvider implements MarketDataProvider {
  MarketSdkMarketDataProvider({MarketDataSdkService? sdk})
      : _sdk = sdk ?? MarketDataSdkService();

  final MarketDataSdkService _sdk;

  Future<void> _auth() async {
    try {
      if (GetIt.I.isRegistered<SecureStorageService>()) {
        final token = await GetIt.I<SecureStorageService>().getAccessToken();
        if (token != null && token.isNotEmpty) {
          _sdk.setAuthentication(token);
        }
      }
    } catch (_) {}
  }

  @override
  Future<List<WatchlistSymbol>> search(String query) async {
    await _auth();
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      final results = await _sdk.securityApi.search(
        q,
        smartRecommendations: false,
        category: 'ALL',
        limit: 12,
      );
      if (results == null) return const [];
      return [
        for (final d in results)
          if (d.key?.symbol != null && d.key!.symbol!.isNotEmpty)
            WatchlistSymbol(
              symbol: d.key!.symbol!,
              exchange: 'NSE',
              last: 0,
              changePct: 0,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<ChartQuote?> getQuote(String symbol) async {
    await _auth();
    final isIndex = MarketSdkHistoricalProvider._isIndex(symbol);
    try {
      final ltpRes = await _sdk.marketDataApi.getLiveLTP(
        symbol,
        isIndexSymbol: isIndex,
      );
      if (ltpRes == null || ltpRes['data'] is! Map) return null;
      final dataMap = ltpRes['data'] as Map;
      final symKey = dataMap.keys.firstWhere(
        (k) =>
            k.toString().toUpperCase() == symbol.toUpperCase() ||
            k.toString().toUpperCase().endsWith(symbol.toUpperCase()),
        orElse: () => dataMap.keys.isEmpty ? null : dataMap.keys.first,
      );
      if (symKey == null) return null;
      final item = dataMap[symKey];
      if (item is! Map) return null;
      final lp = (item['lastPrice'] as num?)?.toDouble();
      if (lp == null) return null;
      final prev = (item['previousClose'] as num?)?.toDouble() ?? lp;
      final changePct = prev == 0 ? 0.0 : ((lp - prev) / prev) * 100;
      final exch = (item['exchange'] as String?) ??
          (symbol.toUpperCase().contains('SENSEX') ? 'BSE' : 'NSE');
      return ChartQuote(
        symbol: symbol,
        exchange: exch,
        last: lp,
        changePct: changePct,
        volume: (item['volume'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
