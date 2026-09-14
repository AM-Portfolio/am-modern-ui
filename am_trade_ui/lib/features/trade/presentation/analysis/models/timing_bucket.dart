/// One timing bucket (session, weekday, or month) for Analysis → Timing.
class TimingBucket {
  const TimingBucket({
    required this.key,
    required this.label,
    required this.trades,
    required this.pnl,
    required this.avgPnl,
    this.winRatePercent,
    this.eligibleTrades = 0,
  });

  final String key;
  final String label;
  final int trades;
  final double pnl;
  /// Avg PnL from server when present; else `pnl / eligible` (eligible only).
  final double avgPnl;
  final double? winRatePercent;
  /// Trades with non-null PnL (Win% / Avg PnL denominator).
  final int eligibleTrades;

  bool get isLowSample => eligibleTrades > 0 && eligibleTrades < minTradesForRank;
}

/// Default minimum eligible trades to appear in Best/Worst rankings.
const int minTradesForRank = 3;

/// Stable NSE session keys (must match backend).
const List<String> kSessionKeys = [
  'SESSION_0915_1100',
  'SESSION_1100_1300',
  'SESSION_1300_1500',
  'SESSION_1500_1530',
  'OTHER',
];

/// Best / worst split with no overlapping keys.
class TimingRankSplit {
  const TimingRankSplit({required this.best, required this.worst});

  final List<TimingBucket> best;
  final List<TimingBucket> worst;
}

enum TimingDimension { session, weekday, month }

enum TimingRankView { all, best, worst }

List<TimingBucket> buildTimingBuckets({
  required Map<String, int> trades,
  required Map<String, double> profit,
  Map<String, double> winRate = const {},
  Map<String, double> avgPnl = const {},
  Map<String, int> eligible = const {},
  required String Function(String key) labelFor,
  bool includeZeroTradeBuckets = false,
  List<String>? orderedKeys,
}) {
  final keys = orderedKeys != null
      ? [...orderedKeys]
      : <String>{...trades.keys, ...profit.keys}.toList();

  final buckets = <TimingBucket>[];
  for (final key in keys) {
    final count = trades[key] ?? 0;
    if (!includeZeroTradeBuckets && count <= 0) continue;
    final pnl = profit[key] ?? 0;
    final eligibleCount = eligible[key] ?? (winRate.containsKey(key) ? count : 0);
    final serverAvg = avgPnl[key];
    final computedAvg = eligibleCount > 0 ? pnl / eligibleCount : 0.0;
    buckets.add(
      TimingBucket(
        key: key,
        label: labelFor(key),
        trades: count,
        pnl: pnl,
        avgPnl: serverAvg ?? computedAvg,
        winRatePercent: winRate[key],
        eligibleTrades: eligibleCount,
      ),
    );
  }
  return buckets;
}

/// Chronological / session order for charts (not avg-PnL rank).
List<TimingBucket> sortForChart(
  List<TimingBucket> buckets,
  TimingDimension dimension,
) {
  final sorted = [...buckets];
  switch (dimension) {
    case TimingDimension.session:
      sorted.sort((a, b) {
        final ai = kSessionKeys.indexOf(a.key);
        final bi = kSessionKeys.indexOf(b.key);
        return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
      });
    case TimingDimension.weekday:
      const order = {
        'MONDAY': 0,
        'TUESDAY': 1,
        'WEDNESDAY': 2,
        'THURSDAY': 3,
        'FRIDAY': 4,
        'SATURDAY': 5,
        'SUNDAY': 6,
      };
      sorted.sort(
        (a, b) => (order[a.key.toUpperCase()] ?? 99)
            .compareTo(order[b.key.toUpperCase()] ?? 99),
      );
    case TimingDimension.month:
      const order = {
        'JANUARY': 0,
        'FEBRUARY': 1,
        'MARCH': 2,
        'APRIL': 3,
        'MAY': 4,
        'JUNE': 5,
        'JULY': 6,
        'AUGUST': 7,
        'SEPTEMBER': 8,
        'OCTOBER': 9,
        'NOVEMBER': 10,
        'DECEMBER': 11,
      };
      sorted.sort(
        (a, b) => (order[a.key.toUpperCase()] ?? 99)
            .compareTo(order[b.key.toUpperCase()] ?? 99),
      );
  }
  return sorted;
}

List<TimingBucket> sortByAvgPnlDesc(List<TimingBucket> buckets) {
  final sorted = [...buckets]..sort((a, b) => b.avgPnl.compareTo(a.avgPnl));
  return sorted;
}

/// Buckets eligible for Best/Worst (eligible trades ≥ [minTrades]).
List<TimingBucket> qualifyingForRank(
  List<TimingBucket> buckets, {
  int minTrades = minTradesForRank,
}) {
  return buckets.where((b) => b.eligibleTrades >= minTrades).toList();
}

/// Split into best / worst by [TimingBucket.avgPnl] with no overlapping keys.
TimingRankSplit splitBestWorst(List<TimingBucket> buckets, {int take = 5}) {
  if (buckets.isEmpty) {
    return const TimingRankSplit(best: [], worst: []);
  }

  final byAvgPnl = [...buckets]..sort((a, b) => b.avgPnl.compareTo(a.avgPnl));

  if (byAvgPnl.length == 1) {
    return TimingRankSplit(best: byAvgPnl, worst: const []);
  }

  final n = byAvgPnl.length;
  final maxTake = take.clamp(1, n);
  final bestCount = n <= take * 2
      ? (n / 2).ceil().clamp(1, maxTake)
      : maxTake;

  final best = byAvgPnl.take(bestCount).toList();
  final bestKeys = best.map((b) => b.key).toSet();
  final worst = byAvgPnl.reversed
      .where((b) => !bestKeys.contains(b.key))
      .take(maxTake)
      .toList();

  return TimingRankSplit(best: best, worst: worst);
}

/// Buckets with at least one trade (rank tables — not chart skeletons).
List<TimingBucket> bucketsWithTrades(List<TimingBucket> buckets) {
  return buckets.where((b) => b.trades > 0).toList();
}

/// Rows for the unified ranking card based on view + min sample.
///
/// Chart may include zero-trade session skeletons; All/Best/Worst never do.
List<TimingBucket> rowsForRankView(
  List<TimingBucket> allBuckets,
  TimingRankView view, {
  int minTrades = minTradesForRank,
}) {
  final ranked = bucketsWithTrades(allBuckets);
  switch (view) {
    case TimingRankView.all:
      return sortByAvgPnlDesc(ranked);
    case TimingRankView.best:
    case TimingRankView.worst:
      final qualifying = qualifyingForRank(ranked, minTrades: minTrades);
      if (qualifying.isEmpty) return const [];
      final split = splitBestWorst(qualifying);
      return view == TimingRankView.best ? split.best : split.worst;
  }
}

String formatSessionLabel(String key) {
  const map = {
    'SESSION_0915_1100': '9:15–11:00',
    'SESSION_1100_1300': '11:00–1:00',
    'SESSION_1300_1500': '1:00–3:00',
    'SESSION_1500_1530': '3:00–3:30',
    'OTHER': 'Other',
  };
  return map[key] ?? key;
}

String formatWeekdayLabel(String key) {
  const map = {
    'MONDAY': 'Mon',
    'TUESDAY': 'Tue',
    'WEDNESDAY': 'Wed',
    'THURSDAY': 'Thu',
    'FRIDAY': 'Fri',
    'SATURDAY': 'Sat',
    'SUNDAY': 'Sun',
  };
  return map[key.toUpperCase()] ?? key;
}

String formatMonthLabel(String key) {
  const map = {
    'JANUARY': 'Jan',
    'FEBRUARY': 'Feb',
    'MARCH': 'Mar',
    'APRIL': 'Apr',
    'MAY': 'May',
    'JUNE': 'Jun',
    'JULY': 'Jul',
    'AUGUST': 'Aug',
    'SEPTEMBER': 'Sep',
    'OCTOBER': 'Oct',
    'NOVEMBER': 'Nov',
    'DECEMBER': 'Dec',
  };
  return map[key.toUpperCase()] ?? key;
}

String styleHintDisplayLabel(String style) {
  switch (style.toUpperCase()) {
    case 'SCALPER':
      return 'Scalper';
    case 'INTRADAY':
      return 'Intraday';
    case 'SWING':
      return 'Swing';
    case 'MIXED':
      return 'Mixed';
    case 'UNKNOWN':
    default:
      return 'Unknown';
  }
}
