/// One timing bucket (hour, weekday, or month) for Analysis → Timing rankings.
class TimingBucket {
  const TimingBucket({
    required this.key,
    required this.label,
    required this.trades,
    required this.pnl,
    required this.expectancy,
    this.winRatePercent,
  });

  final String key;
  final String label;
  final int trades;
  final double pnl;
  final double expectancy;
  final double? winRatePercent;
}

/// Best / worst split with no overlapping keys.
class TimingRankSplit {
  const TimingRankSplit({required this.best, required this.worst});

  final List<TimingBucket> best;
  final List<TimingBucket> worst;
}

enum TimingDimension { hour, weekday, month }

List<TimingBucket> buildTimingBuckets({
  required Map<String, int> trades,
  required Map<String, double> profit,
  Map<String, double> winRate = const {},
  required String Function(String key) labelFor,
}) {
  final keys = <String>{...trades.keys, ...profit.keys};
  final buckets = <TimingBucket>[];
  for (final key in keys) {
    final count = trades[key] ?? 0;
    if (count <= 0) continue;
    final pnl = profit[key] ?? 0;
    buckets.add(
      TimingBucket(
        key: key,
        label: labelFor(key),
        trades: count,
        pnl: pnl,
        expectancy: pnl / count,
        winRatePercent: winRate[key],
      ),
    );
  }
  return buckets;
}

/// Chronological order for charts (not expectancy rank).
List<TimingBucket> sortForChart(
  List<TimingBucket> buckets,
  TimingDimension dimension,
) {
  final sorted = [...buckets];
  switch (dimension) {
    case TimingDimension.hour:
      sorted.sort((a, b) {
        final ah = int.tryParse(a.key) ?? 0;
        final bh = int.tryParse(b.key) ?? 0;
        return ah.compareTo(bh);
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

TimingRankSplit splitBestWorst(List<TimingBucket> buckets, {int take = 5}) {
  if (buckets.isEmpty) {
    return const TimingRankSplit(best: [], worst: []);
  }

  final byExpectancy = [...buckets]
    ..sort((a, b) => b.expectancy.compareTo(a.expectancy));

  if (byExpectancy.length == 1) {
    return TimingRankSplit(best: byExpectancy, worst: const []);
  }

  final n = take.clamp(1, byExpectancy.length);
  final best = byExpectancy.take(n).toList();
  final bestKeys = best.map((b) => b.key).toSet();
  final worst = byExpectancy.reversed
      .where((b) => !bestKeys.contains(b.key))
      .take(n)
      .toList();

  return TimingRankSplit(best: best, worst: worst);
}

String formatEntryHourLabel(String key) {
  final hour = int.tryParse(key);
  if (hour == null || hour < 0 || hour > 23) return key;
  return '${hour.toString().padLeft(2, '0')}:00';
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
