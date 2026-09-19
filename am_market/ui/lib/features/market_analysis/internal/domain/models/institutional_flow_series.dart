import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/market_info_models.dart';

/// Shared FII/DII segment keys.
abstract final class FlowSegments {
  static const cash = 'NSE_EQ|CASH';
  static const indexFutures = 'NSE_FO|INDEX_FUTURES';
  static const indexOptions = 'NSE_FO|INDEX_OPTIONS';
  static const stockFutures = 'NSE_FO|STOCK_FUTURES';
  static const stockOptions = 'NSE_FO|STOCK_OPTIONS';

  static const List<String> fiiAll = [
    cash,
    indexFutures,
    indexOptions,
    stockFutures,
    stockOptions,
  ];
}

/// Map dashboard TF → Upstox FII/DII interval (`1D` | `1M`).
/// Day/week/multi-month calendars need daily points; year+ uses monthly.
String flowsIntervalForTf(String tf) {
  switch (tf.toUpperCase()) {
    case '1D':
    case '1W':
    case '1M':
    case '3M':
    case '6M':
      return '1D';
    default:
      return '1M';
  }
}

/// True when Positioning calendar should show monthly cards (not day grid).
bool positioningUsesMonthlyCards(String tf) {
  final u = tf.toUpperCase();
  return u == '1Y' ||
      u == '3Y' ||
      u == '5Y' ||
      u == '10Y' ||
      u == 'ALL';
}

/// Aggregate day nets into calendar-month keys (year-month-01).
Map<DateTime, FlowDayNets> aggregateFlowMonths(Map<DateTime, FlowDayNets> byDay) {
  final months = <DateTime, FlowDayNets>{};
  final keys = byDay.keys.toList()..sort();
  for (final d in keys) {
    final m = DateTime(d.year, d.month);
    final cur = byDay[d]!;
    final prev = months[m];
    if (prev == null) {
      months[m] = FlowDayNets(
        day: m,
        fiiCash: cur.fiiCash,
        diiCash: cur.diiCash,
        fiiFutures: cur.fiiFutures,
        fiiOptions: cur.fiiOptions,
        fiiStockFutures: cur.fiiStockFutures,
        fiiStockOptions: cur.fiiStockOptions,
      );
    } else {
      months[m] = FlowDayNets(
        day: m,
        fiiCash: prev.fiiCash + cur.fiiCash,
        diiCash: prev.diiCash + cur.diiCash,
        fiiFutures: prev.fiiFutures + cur.fiiFutures,
        fiiOptions: prev.fiiOptions + cur.fiiOptions,
        fiiStockFutures: prev.fiiStockFutures + cur.fiiStockFutures,
        fiiStockOptions: prev.fiiStockOptions + cur.fiiStockOptions,
      );
    }
  }
  return months;
}

/// One trading day of segment nets.
class FlowDayNets {
  const FlowDayNets({
    required this.day,
    this.fiiCash = 0,
    this.diiCash = 0,
    this.fiiFutures = 0,
    this.fiiOptions = 0,
    this.fiiStockFutures = 0,
    this.fiiStockOptions = 0,
  });

  final DateTime day;
  final double fiiCash;
  final double diiCash;
  final double fiiFutures;
  final double fiiOptions;
  final double fiiStockFutures;
  final double fiiStockOptions;

  double get fiiIndexNet => fiiFutures + fiiOptions;
  double get fiiDerivativesNet =>
      fiiFutures + fiiOptions + fiiStockFutures + fiiStockOptions;
  double get cashNet => fiiCash + diiCash;
  double get net => cashNet + fiiDerivativesNet;

  FlowDayNets operator +(FlowDayNets o) => FlowDayNets(
        day: day,
        fiiCash: fiiCash + o.fiiCash,
        diiCash: diiCash + o.diiCash,
        fiiFutures: fiiFutures + o.fiiFutures,
        fiiOptions: fiiOptions + o.fiiOptions,
        fiiStockFutures: fiiStockFutures + o.fiiStockFutures,
        fiiStockOptions: fiiStockOptions + o.fiiStockOptions,
      );
}

String compactFlowNet(double value) {
  final abs = value.abs();
  if (abs >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
  if (abs >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toStringAsFixed(0);
}

Map<DateTime, double> dailyNetsForSegment(
  InstitutionalFlowResponse? response,
  String segment,
) {
  final out = <DateTime, double>{};
  if (response == null) return out;
  for (final row in response.data[segment] ?? const <InstitutionalFlowRecord>[]) {
    final t = row.time;
    final day = DateTime(t.year, t.month, t.day);
    out[day] = (out[day] ?? 0) + row.netAmount;
  }
  return out;
}

/// Merge FII + DII segment dailies into one day map.
Map<DateTime, FlowDayNets> mergeFlowDays({
  InstitutionalFlowResponse? fii,
  InstitutionalFlowResponse? dii,
}) {
  final fiiCash = dailyNetsForSegment(fii, FlowSegments.cash);
  final diiCash = dailyNetsForSegment(dii, FlowSegments.cash);
  final fut = dailyNetsForSegment(fii, FlowSegments.indexFutures);
  final opt = dailyNetsForSegment(fii, FlowSegments.indexOptions);
  final stkFut = dailyNetsForSegment(fii, FlowSegments.stockFutures);
  final stkOpt = dailyNetsForSegment(fii, FlowSegments.stockOptions);
  final days = <DateTime>{
    ...fiiCash.keys,
    ...diiCash.keys,
    ...fut.keys,
    ...opt.keys,
    ...stkFut.keys,
    ...stkOpt.keys,
  };
  final out = <DateTime, FlowDayNets>{};
  for (final d in days) {
    out[d] = FlowDayNets(
      day: d,
      fiiCash: fiiCash[d] ?? 0,
      diiCash: diiCash[d] ?? 0,
      fiiFutures: fut[d] ?? 0,
      fiiOptions: opt[d] ?? 0,
      fiiStockFutures: stkFut[d] ?? 0,
      fiiStockOptions: stkOpt[d] ?? 0,
    );
  }
  return out;
}

List<DateTime> visibleFlowDays(List<DateTime> sorted, String tf) {
  final u = tf.toUpperCase();
  if (sorted.isEmpty) return const [];
  if (u == '1D') return [sorted.last];
  if (u == '1W') {
    return sorted.length > 5 ? sorted.sublist(sorted.length - 5) : sorted;
  }
  if (u == '1M') {
    final newest = sorted.last;
    final start = DateTime(newest.year, newest.month);
    return sorted.where((d) => !d.isBefore(start)).toList();
  }
  if (u == '3M') {
    final newest = sorted.last;
    final start = DateTime(newest.year, newest.month - 2, 1);
    return sorted.where((d) => !d.isBefore(start)).toList();
  }
  if (u == '6M') {
    final newest = sorted.last;
    final start = DateTime(newest.year, newest.month - 5, 1);
    return sorted.where((d) => !d.isBefore(start)).toList();
  }
  // 1Y+: callers use monthly aggregation; return all points.
  return sorted;
}

/// Build chart series from flow history (absolute nets — chart % mode still works).
MultiSeriesChartData flowSeriesChartData({
  required Map<DateTime, FlowDayNets> byDay,
  bool includeFiiCash = false,
  bool includeDiiCash = false,
  bool includeFiiFutures = false,
  bool includeFiiOptions = false,
  bool includeFiiIndexNet = false,
}) {
  final days = byDay.keys.toList()..sort();
  if (days.length < 2) return const MultiSeriesChartData(series: {});

  List<MultiSeriesPoint> shifted(double Function(FlowDayNets) pick) {
    final raw = [for (final d in days) pick(byDay[d]!)];
    final minV = raw.reduce((a, b) => a < b ? a : b);
    final offset = minV < 1 ? (1 - minV) : 0.0;
    return [
      for (var i = 0; i < days.length; i++)
        MultiSeriesPoint(
          time:
              '${days[i].year.toString().padLeft(4, '0')}-${days[i].month.toString().padLeft(2, '0')}-${days[i].day.toString().padLeft(2, '0')}',
          value: raw[i] + offset,
        ),
    ];
  }

  final series = <String, List<MultiSeriesPoint>>{};
  void add(String label, bool on, double Function(FlowDayNets) pick) {
    if (!on) return;
    final pts = shifted(pick);
    if (pts.length >= 2) series[label] = pts;
  }

  add('FII cash', includeFiiCash, (d) => d.fiiCash);
  add('DII cash', includeDiiCash, (d) => d.diiCash);
  add('FII futures', includeFiiFutures, (d) => d.fiiFutures);
  add('FII options', includeFiiOptions, (d) => d.fiiOptions);
  add('FII index net', includeFiiIndexNet, (d) => d.fiiIndexNet);

  return MultiSeriesChartData(series: series);
}
