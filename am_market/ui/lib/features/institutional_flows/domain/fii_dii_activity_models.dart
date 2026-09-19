import 'package:am_market_ui/features/market_analysis/internal/domain/models/institutional_flow_series.dart';

/// Local period for FII/DII Activity (not global app TF).
enum FiiDiiPeriod { daily, weekly, monthly, yearly }

extension FiiDiiPeriodX on FiiDiiPeriod {
  String get label => switch (this) {
        FiiDiiPeriod.daily => 'Daily',
        FiiDiiPeriod.weekly => 'Weekly',
        FiiDiiPeriod.monthly => 'Monthly',
        FiiDiiPeriod.yearly => 'Yearly',
      };

  /// Upstox interval used to load raw series.
  String get apiInterval => switch (this) {
        FiiDiiPeriod.daily || FiiDiiPeriod.weekly => '1D',
        FiiDiiPeriod.monthly || FiiDiiPeriod.yearly => '1M',
      };

  /// History range for Nifty join.
  String get niftyHistoryRange => switch (this) {
        FiiDiiPeriod.daily || FiiDiiPeriod.weekly => '3M',
        FiiDiiPeriod.monthly => '1Y',
        FiiDiiPeriod.yearly => '5Y',
      };
}

/// Segment selector for the activity table.
enum FiiDiiSegment {
  fiiCash,
  diiCash,
  fiiIdxFut,
  fiiIdxOpt,
  fiiStkFut,
  fiiStkOpt,
}

extension FiiDiiSegmentX on FiiDiiSegment {
  String get label => switch (this) {
        FiiDiiSegment.fiiCash => 'FII Cash',
        FiiDiiSegment.diiCash => 'DII Cash',
        FiiDiiSegment.fiiIdxFut => 'FII Idx Fut',
        FiiDiiSegment.fiiIdxOpt => 'FII Idx Opt',
        FiiDiiSegment.fiiStkFut => 'FII Stk Fut',
        FiiDiiSegment.fiiStkOpt => 'FII Stk Opt',
      };

  double amountOf(FlowDayNets n) => switch (this) {
        FiiDiiSegment.fiiCash => n.fiiCash,
        FiiDiiSegment.diiCash => n.diiCash,
        FiiDiiSegment.fiiIdxFut => n.fiiFutures,
        FiiDiiSegment.fiiIdxOpt => n.fiiOptions,
        FiiDiiSegment.fiiStkFut => n.fiiStockFutures,
        FiiDiiSegment.fiiStkOpt => n.fiiStockOptions,
      };
}

class NiftyPoint {
  const NiftyPoint({
    required this.close,
    this.change = 0,
    this.chgPct = 0,
  });

  final double close;
  final double change;
  final double chgPct;
}

class FiiDiiPeriodBucket {
  const FiiDiiPeriodBucket({
    required this.periodStart,
    required this.nets,
    required this.dateLabel,
    this.nifty,
  });

  final DateTime periodStart;
  final FlowDayNets nets;
  final String dateLabel;
  final NiftyPoint? nifty;
}

class FiiDiiSummaryCardVm {
  const FiiDiiSummaryCardVm({
    required this.dateLabel,
    required this.nets,
    this.nifty,
  });

  final String dateLabel;
  final FlowDayNets nets;
  final NiftyPoint? nifty;

  double get net => nets.net;
  double get netDerivatives => nets.fiiDerivativesNet;
}

class FiiDiiActivityRowVm {
  const FiiDiiActivityRowVm({
    required this.dateLabel,
    required this.amountCr,
    required this.barRatio,
    this.nifty,
    this.change,
    this.chgPct,
  });

  final String dateLabel;
  final double amountCr;

  /// -1..1 for bar width (relative to max abs in page).
  final double barRatio;
  final double? nifty;
  final double? change;
  final double? chgPct;
}

class FiiDiiActivityVm {
  const FiiDiiActivityVm({
    this.cards = const [],
    this.rows = const [],
    this.buckets = const [],
    this.loading = false,
    this.error,
  });

  final List<FiiDiiSummaryCardVm> cards;
  final List<FiiDiiActivityRowVm> rows;
  final List<FiiDiiPeriodBucket> buckets;
  final bool loading;
  final String? error;

  FiiDiiActivityVm withSegment(FiiDiiSegment segment) => FiiDiiActivityVm(
        cards: cards,
        buckets: buckets,
        rows: buildActivityRows(buckets: buckets, segment: segment),
        error: error,
      );
}

const fiiDiiIntroCopy =
    'Domestic Institutional Investors (DIIs) and Foreign Institutional '
    'Investors (FIIs) are entities that purchase and sell stocks of companies '
    'on a large scale. Their actions have the potential to influence the '
    'movement of the market in the short term.';

// --- Aggregations (pure; unit-tested) ---

/// Monday of the ISO week containing [d] (local date, no time).
DateTime weekStartMonday(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  final weekday = day.weekday; // Mon=1 .. Sun=7
  return day.subtract(Duration(days: weekday - 1));
}

Map<DateTime, FlowDayNets> aggregateFlowWeeks(Map<DateTime, FlowDayNets> byDay) {
  final weeks = <DateTime, FlowDayNets>{};
  final keys = byDay.keys.toList()..sort();
  for (final d in keys) {
    final w = weekStartMonday(d);
    final cur = byDay[d]!;
    final prev = weeks[w];
    weeks[w] = prev == null
        ? FlowDayNets(
            day: w,
            fiiCash: cur.fiiCash,
            diiCash: cur.diiCash,
            fiiFutures: cur.fiiFutures,
            fiiOptions: cur.fiiOptions,
            fiiStockFutures: cur.fiiStockFutures,
            fiiStockOptions: cur.fiiStockOptions,
          )
        : prev + cur;
  }
  return weeks;
}

Map<DateTime, FlowDayNets> aggregateFlowYears(Map<DateTime, FlowDayNets> byMonth) {
  final years = <DateTime, FlowDayNets>{};
  final keys = byMonth.keys.toList()..sort();
  for (final d in keys) {
    final y = DateTime(d.year);
    final cur = byMonth[d]!;
    final prev = years[y];
    years[y] = prev == null
        ? FlowDayNets(
            day: y,
            fiiCash: cur.fiiCash,
            diiCash: cur.diiCash,
            fiiFutures: cur.fiiFutures,
            fiiOptions: cur.fiiOptions,
            fiiStockFutures: cur.fiiStockFutures,
            fiiStockOptions: cur.fiiStockOptions,
          )
        : prev + cur;
  }
  return years;
}

String formatFiiDiiDate(DateTime d, FiiDiiPeriod period) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  switch (period) {
    case FiiDiiPeriod.daily:
      return '${d.day} ${months[d.month - 1]}';
    case FiiDiiPeriod.weekly:
      final end = d.add(const Duration(days: 4));
      return '${d.day} ${months[d.month - 1]} – ${end.day} ${months[end.month - 1]}';
    case FiiDiiPeriod.monthly:
      return '${months[d.month - 1]} ${d.year}';
    case FiiDiiPeriod.yearly:
      return '${d.year}';
  }
}

/// Parse OHLC history maps into day → close.
Map<DateTime, double> niftyClosesFromHistory(
  List<Map<String, dynamic>> points,
) {
  final out = <DateTime, double>{};
  for (final p in points) {
    final rawTime = p['time'] ?? p['timestamp'] ?? p['date'];
    final rawClose = p['close'] ?? p['lastPrice'] ?? p['price'];
    if (rawTime == null || rawClose == null) continue;
    DateTime? day;
    if (rawTime is int) {
      day = DateTime.fromMillisecondsSinceEpoch(rawTime, isUtc: true).toLocal();
    } else if (rawTime is String) {
      day = DateTime.tryParse(rawTime);
    }
    final close = rawClose is num
        ? rawClose.toDouble()
        : double.tryParse(rawClose.toString());
    if (day == null || close == null) continue;
    out[DateTime(day.year, day.month, day.day)] = close;
  }
  return out;
}

NiftyPoint? niftyForPeriod({
  required DateTime periodStart,
  required FiiDiiPeriod period,
  required Map<DateTime, double> closes,
  required List<DateTime> sessionsInPeriod,
}) {
  if (sessionsInPeriod.isEmpty && closes.isEmpty) return null;
  final sortedSessions = [...sessionsInPeriod]..sort();
  DateTime endKey;
  DateTime startKey;
  if (sortedSessions.isNotEmpty) {
    startKey = sortedSessions.first;
    endKey = sortedSessions.last;
  } else {
    startKey = periodStart;
    endKey = periodStart;
  }
  final endClose = closes[endKey] ?? _nearestClose(closes, endKey);
  if (endClose == null) return null;
  double? startClose;
  if (period == FiiDiiPeriod.daily) {
    // Prior session close for day change.
    final prior = closes.keys.where((d) => d.isBefore(endKey)).toList()..sort();
    startClose = prior.isEmpty ? endClose : closes[prior.last];
  } else {
    startClose = closes[startKey] ?? _nearestClose(closes, startKey) ?? endClose;
  }
  final change = endClose - (startClose ?? endClose);
  final base = startClose ?? endClose;
  final chgPct = base.abs() < 1e-9 ? 0.0 : (change / base) * 100;
  return NiftyPoint(close: endClose, change: change, chgPct: chgPct);
}

double? _nearestClose(Map<DateTime, double> closes, DateTime day) {
  if (closes.containsKey(day)) return closes[day];
  final keys = closes.keys.toList()..sort();
  if (keys.isEmpty) return null;
  DateTime? best;
  for (final k in keys) {
    if (!k.isAfter(day)) best = k;
  }
  return best == null ? null : closes[best];
}

double barRatioFor(double amount, double maxAbs) {
  if (maxAbs <= 0) return 0;
  final r = amount / maxAbs;
  if (r > 1) return 1;
  if (r < -1) return -1;
  return r;
}

List<FiiDiiActivityRowVm> buildActivityRows({
  required List<FiiDiiPeriodBucket> buckets,
  required FiiDiiSegment segment,
}) {
  if (buckets.isEmpty) return const [];
  final amounts = [for (final b in buckets) segment.amountOf(b.nets)];
  final maxAbs = amounts.map((a) => a.abs()).fold<double>(0, (a, b) => a > b ? a : b);
  return [
    for (var i = 0; i < buckets.length; i++)
      FiiDiiActivityRowVm(
        dateLabel: buckets[i].dateLabel,
        amountCr: amounts[i],
        barRatio: barRatioFor(amounts[i], maxAbs),
        nifty: buckets[i].nifty?.close,
        change: buckets[i].nifty?.change,
        chgPct: buckets[i].nifty?.chgPct,
      ),
  ];
}
