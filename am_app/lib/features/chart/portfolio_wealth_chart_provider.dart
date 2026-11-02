import 'package:am_chart_ui/am_chart_ui.dart';
import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:am_dashboard_ui/domain/models/overlay_history_parser.dart';

/// Chart terminal history: market OHLC, or portfolio wealth when symbol is
/// `PORTFOLIO:<id>`, `OVERALL`, or `Overall` (same feed as Portfolio section).
class PortfolioWealthHistoricalProvider implements HistoricalDataProvider {
  PortfolioWealthHistoricalProvider({
    required HistoricalDataProvider market,
    required Future<ApiClient> Function() getPortfolioClient,
  })  : _market = market,
        _getPortfolioClient = getPortfolioClient;

  final HistoricalDataProvider _market;
  final Future<ApiClient> Function() _getPortfolioClient;

  static const portfolioPrefix = 'PORTFOLIO:';

  /// Encoded as `PORTFOLIO:<uuid>` or `PORTFOLIO:<uuid>|<displayName>`.
  static bool isPortfolioWealthSymbol(String symbol) {
    final u = symbol.trim().toUpperCase();
    return u == 'OVERALL' ||
        u == 'OVERALL - NSE' ||
        u == OverlayChartIds.overall.toUpperCase() ||
        u.startsWith(portfolioPrefix);
  }

  static String? portfolioIdFromSymbol(String symbol) {
    final s = symbol.trim();
    final u = s.toUpperCase();
    if (u == 'OVERALL' ||
        u == 'OVERALL - NSE' ||
        u == OverlayChartIds.overall.toUpperCase() ||
        s.toLowerCase() == 'overall') {
      return null; // all portfolios aggregate
    }
    if (u.startsWith(portfolioPrefix)) {
      final rest = s.substring(portfolioPrefix.length);
      final id = rest.split('|').first.trim();
      return id.isEmpty ? null : id;
    }
    return null;
  }

  static String encodePortfolioSymbol(String portfolioId, {String? name}) {
    final id = portfolioId.trim();
    final n = name?.trim();
    if (n != null && n.isNotEmpty) {
      return '$portfolioPrefix$id|$n';
    }
    return '$portfolioPrefix$id';
  }

  static String displayLabel(String symbol) {
    final s = symbol.trim();
    final u = s.toUpperCase();
    if (u == 'OVERALL' ||
        u == 'OVERALL - NSE' ||
        u == OverlayChartIds.overall.toUpperCase() ||
        s.toLowerCase() == 'overall') {
      return 'Overall';
    }
    if (u.startsWith(portfolioPrefix)) {
      final rest = s.substring(portfolioPrefix.length);
      final parts = rest.split('|');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        return parts[1].trim();
      }
      return 'Portfolio';
    }
    return symbol;
  }

  @override
  bool get isMock => _market.isMock;

  @override
  Future<List<ChartBar>> getBars({
    required String symbol,
    required String timeframe,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    if (!isPortfolioWealthSymbol(symbol)) {
      return _market.getBars(
        symbol: symbol,
        timeframe: timeframe,
        from: from,
        to: to,
        limit: limit,
      );
    }

    final portfolioId = portfolioIdFromSymbol(symbol);
    final apiTf = _apiTimeFrame(timeframe);
    final isIntraday = apiTf == '1D';
    final client = await _getPortfolioClient();
    final singleId = (portfolioId != null &&
            portfolioId.isNotEmpty &&
            portfolioId != 'all')
        ? portfolioId
        : null;
    final path = singleId == null
        ? (isIntraday ? '/v1/portfolios/intraday' : '/v1/portfolios/history')
        : (isIntraday
            ? '/v1/portfolios/$singleId/intraday'
            : '/v1/portfolios/$singleId/history');
    final raw = await client.get(
      path,
      queryParams: isIntraday ? null : {'timeFrame': apiTf},
      parser: (data) => data,
    );
    final history = parsePortfolioOverlayHistory(raw, isIntraday: isIntraday);

    List<OverlayPoint> points = history.aggregate;
    if (singleId != null && history.byPortfolioId.containsKey(singleId)) {
      points = history.byPortfolioId[singleId] ?? points;
    }

    final bars = <ChartBar>[];
    for (final p in points) {
      final t = _parseLabel(p.xLabel, isIntraday: isIntraday);
      if (t == null || !p.value.isFinite || p.value <= 0) continue;
      bars.add(ChartBar(
        time: t,
        open: p.value,
        high: p.value,
        low: p.value,
        close: p.value,
      ));
    }
    if (limit != null && bars.length > limit) {
      return bars.sublist(bars.length - limit);
    }
    return bars;
  }

  /// Terminal TF → portfolio history `timeFrame` / intraday.
  static String _apiTimeFrame(String timeframe) {
    switch (timeframe.toUpperCase()) {
      case '5M':
      case '15M':
      case '1H':
      case '1D':
        return '1D';
      case '1W':
        return '1W';
      case '1M':
      case '1MO':
        return '1M';
      case '1Y':
      case '1YR':
      case '12M':
        return '1Y';
      default:
        return '1D';
    }
  }

  static DateTime? _parseLabel(String label, {required bool isIntraday}) {
    final s = label.trim();
    if (s.isEmpty) return null;
    if (isIntraday) {
      // "09:15" or "9:15 AM"
      final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s);
      if (m != null) {
        final h = int.parse(m.group(1)!);
        final min = int.parse(m.group(2)!);
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, h, min);
      }
    }
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    // dd-MM-yyyy / yyyy-MM-dd already covered; try slash dates
    final parts = s.split(RegExp(r'[/-]'));
    if (parts.length == 3) {
      try {
        if (parts[0].length == 4) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } catch (_) {}
    }
    return null;
  }
}
