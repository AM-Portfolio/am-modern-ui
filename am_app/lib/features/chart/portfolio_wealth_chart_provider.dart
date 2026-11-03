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

  /// Encoded as `PORTFOLIO:<id>` or `PORTFOLIO:<id>|<displayName>`.
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
    // Keep API path IDs lowercase — backends treat UUID casing as significant.
    final id = portfolioId.trim().toLowerCase();
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

  /// Pick the series the Portfolio overview chart would plot.
  static List<OverlayPoint> resolveOverlayPoints(
    PortfolioOverlayHistory history, {
    String? portfolioId,
  }) {
    bool hasPlottable(List<OverlayPoint> pts) =>
        pts.any((p) => p.value.isFinite && p.value > 0);

    if (portfolioId != null && portfolioId.isNotEmpty && portfolioId != 'all') {
      final direct = history.byPortfolioId[portfolioId];
      if (direct != null && hasPlottable(direct)) return direct;

      final needle = portfolioId.toLowerCase();
      for (final e in history.byPortfolioId.entries) {
        if (e.key.toLowerCase() == needle && hasPlottable(e.value)) {
          return e.value;
        }
      }

      if (history.byPortfolioId.length == 1) {
        final only = history.byPortfolioId.values.first;
        if (hasPlottable(only)) return only;
      }

      for (final pts in history.byPortfolioId.values) {
        if (hasPlottable(pts)) return pts;
      }
    }

    if (hasPlottable(history.aggregate)) return history.aggregate;

    for (final pts in history.byPortfolioId.values) {
      if (hasPlottable(pts)) return pts;
    }
    return history.aggregate;
  }

  /// Same value extraction as [PortfolioHistoryChartWidget] for a single book.
  static List<ChartBar> barsFromHistoryRows(
    dynamic raw, {
    String? portfolioId,
  }) {
    final rows = _asObjectList(raw);
    final bars = <ChartBar>[];
    double? lastValid;
    final needle = portfolioId?.trim().toLowerCase();

    for (final row in rows) {
      final dateLabel = _stringOf(
            row,
            const ['snapshotDate', 'date', 'timestamp', 'time'],
          ) ??
          '';
      final t = _parseLabel(dateLabel, isIntraday: false);
      if (t == null) continue;

      double? value;
      final entries = row['portfolios'];
      if (entries is List && entries.isNotEmpty) {
        if (needle != null && needle.isNotEmpty && needle != 'all') {
          for (final entry in entries) {
            if (entry is! Map) continue;
            final map = Map<String, dynamic>.from(entry);
            final id = (_stringOf(map, const ['portfolioId', 'id']) ?? '')
                .toLowerCase();
            if (id != needle) continue;
            value = _numOf(map, const ['close', 'value', 'totalWealth']);
            break;
          }
        }
        // Overview fallback: portfolios.first.close
        if (value == null) {
          final first = entries.first;
          if (first is Map) {
            value = _numOf(
              Map<String, dynamic>.from(first),
              const ['close', 'value', 'totalWealth'],
            );
          }
        }
      }
      value ??= _numOf(
        row,
        const ['totalUserWealth', 'totalWealth', 'close', 'value'],
      );

      if (value == null || !value.isFinite || value <= 0) {
        if (lastValid != null && lastValid! > 0) {
          value = lastValid;
        } else {
          continue;
        }
      }
      lastValid = value;
      bars.add(ChartBar(
        time: t,
        open: value,
        high: value,
        low: value,
        close: value,
      ));
    }
    return bars;
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
    final client = await _getPortfolioClient();
    final singleId =
        (portfolioId != null && portfolioId.isNotEmpty && portfolioId != 'all')
            ? portfolioId.toLowerCase()
            : null;

    // 1) Same path as Portfolio overview (single book history).
    // 2) Fall back to all-books history and pick the series (dashboard overlay).
    final attempts = <String>[
      if (singleId != null) '/v1/portfolios/$singleId/history?timeFrame=$apiTf',
      '/v1/portfolios/history?timeFrame=$apiTf',
    ];

    Object? lastError;
    for (final path in attempts) {
      try {
        final raw = await client.get(
          path,
          parser: (data) => data,
        );
        var bars = barsFromHistoryRows(raw, portfolioId: singleId);
        if (bars.isEmpty) {
          // Overlay pivot (carry-forward) as a second parse of the same payload.
          final history = parsePortfolioOverlayHistory(raw, isIntraday: false);
          final points = resolveOverlayPoints(history, portfolioId: singleId);
          bars = [
            for (final p in points)
              if (_parseLabel(p.xLabel, isIntraday: false) != null &&
                  p.value.isFinite &&
                  p.value > 0)
                ChartBar(
                  time: _parseLabel(p.xLabel, isIntraday: false)!,
                  open: p.value,
                  high: p.value,
                  low: p.value,
                  close: p.value,
                ),
          ];
        }
        if (bars.isNotEmpty) {
          if (limit != null && bars.length > limit) {
            return bars.sublist(bars.length - limit);
          }
          return bars;
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw StateError(
      'No portfolio chart history for ${displayLabel(symbol)} '
      '($apiTf)${lastError != null ? ': $lastError' : ''}',
    );
  }

  /// Terminal TF → portfolio history `timeFrame` (same codes as Portfolio UI).
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

  static List<Map<String, dynamic>> _asObjectList(dynamic data) {
    if (data is List) {
      return [
        for (final e in data)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const [
        'points',
        'data',
        'content',
        'snapshots',
        'history',
      ]) {
        final inner = map[key];
        if (inner is List) return _asObjectList(inner);
      }
    }
    return const [];
  }

  static String? _stringOf(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static double? _numOf(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseLabel(String label, {required bool isIntraday}) {
    final s = label.trim();
    if (s.isEmpty) return null;
    if (isIntraday) {
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
