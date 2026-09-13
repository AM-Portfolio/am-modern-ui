import 'package:flutter_test/flutter_test.dart';
import 'package:am_trade_ui/features/trade/presentation/analysis/models/timing_bucket.dart';

TimingBucket _bucket({
  required String key,
  required double avgPnl,
  int trades = 2,
}) {
  return TimingBucket(
    key: key,
    label: key,
    trades: trades,
    pnl: avgPnl * trades,
    avgPnl: avgPnl,
  );
}

void main() {
  group('buildTimingBuckets', () {
    test('returns empty for empty maps', () {
      final buckets = buildTimingBuckets(
        trades: {},
        profit: {},
        labelFor: (k) => k,
      );
      expect(buckets, isEmpty);
    });

    test('skips count <= 0 and computes avgPnl = pnl / count', () {
      final buckets = buildTimingBuckets(
        trades: {'9': 4, '10': 0, '11': -1},
        profit: {'9': 400, '10': 99, '11': 50},
        winRate: {'9': 50},
        labelFor: formatEntryHourLabel,
      );
      expect(buckets, hasLength(1));
      expect(buckets.single.key, '9');
      expect(buckets.single.avgPnl, 100);
      expect(buckets.single.winRatePercent, 50);
      expect(buckets.single.label, '09:00');
    });
  });

  group('sortForChart', () {
    test('sorts hours numerically', () {
      final sorted = sortForChart(
        [
          _bucket(key: '14', avgPnl: 1),
          _bucket(key: '9', avgPnl: 1),
          _bucket(key: '11', avgPnl: 1),
        ],
        TimingDimension.hour,
      );
      expect(sorted.map((b) => b.key).toList(), ['9', '11', '14']);
    });

    test('sorts weekdays Mon→Sun', () {
      final sorted = sortForChart(
        [
          _bucket(key: 'FRIDAY', avgPnl: 1),
          _bucket(key: 'MONDAY', avgPnl: 1),
          _bucket(key: 'WEDNESDAY', avgPnl: 1),
        ],
        TimingDimension.weekday,
      );
      expect(
        sorted.map((b) => b.key).toList(),
        ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
      );
    });

    test('sorts months Jan→Dec', () {
      final sorted = sortForChart(
        [
          _bucket(key: 'MARCH', avgPnl: 1),
          _bucket(key: 'JANUARY', avgPnl: 1),
          _bucket(key: 'FEBRUARY', avgPnl: 1),
        ],
        TimingDimension.month,
      );
      expect(
        sorted.map((b) => b.key).toList(),
        ['JANUARY', 'FEBRUARY', 'MARCH'],
      );
    });
  });

  group('splitBestWorst', () {
    test('empty → empty/empty', () {
      final split = splitBestWorst([]);
      expect(split.best, isEmpty);
      expect(split.worst, isEmpty);
    });

    test('single bucket → best only', () {
      final split = splitBestWorst([_bucket(key: 'a', avgPnl: 10)]);
      expect(split.best, hasLength(1));
      expect(split.worst, isEmpty);
    });

    test('exactly 5 buckets → both sides non-empty, no overlap', () {
      final buckets = [
        _bucket(key: 'a', avgPnl: 50),
        _bucket(key: 'b', avgPnl: 40),
        _bucket(key: 'c', avgPnl: 30),
        _bucket(key: 'd', avgPnl: 20),
        _bucket(key: 'e', avgPnl: 10),
      ];
      final split = splitBestWorst(buckets);
      expect(split.best, isNotEmpty);
      expect(split.worst, isNotEmpty);
      expect(split.best.length, 3); // ceil(5/2)
      expect(split.worst.length, 2);
      final keys = {...split.best.map((b) => b.key), ...split.worst.map((b) => b.key)};
      expect(keys.length, split.best.length + split.worst.length);
      expect(split.best.first.key, 'a');
      expect(split.worst.first.key, 'e');
    });

    test('7 buckets → ceil(n/2) best, remaining worst, no overlap', () {
      final buckets = List.generate(
        7,
        (i) => _bucket(key: '$i', avgPnl: (7 - i).toDouble()),
      );
      final split = splitBestWorst(buckets);
      expect(split.best.length, 4);
      expect(split.worst.length, 3);
      final overlap = split.best.map((b) => b.key).toSet().intersection(
            split.worst.map((b) => b.key).toSet(),
          );
      expect(overlap, isEmpty);
    });

    test('11+ buckets → top 5 / bottom 5, no overlap', () {
      final buckets = List.generate(
        11,
        (i) => _bucket(key: '$i', avgPnl: (11 - i).toDouble()),
      );
      final split = splitBestWorst(buckets);
      expect(split.best.length, 5);
      expect(split.worst.length, 5);
      expect(split.best.first.key, '0');
      expect(split.worst.first.key, '10');
      final overlap = split.best.map((b) => b.key).toSet().intersection(
            split.worst.map((b) => b.key).toSet(),
          );
      expect(overlap, isEmpty);
    });
  });

  group('label formatters', () {
    test('formatEntryHourLabel', () {
      expect(formatEntryHourLabel('9'), '09:00');
      expect(formatEntryHourLabel('bad'), 'bad');
    });

    test('formatWeekdayLabel / formatMonthLabel', () {
      expect(formatWeekdayLabel('MONDAY'), 'Mon');
      expect(formatMonthLabel('JANUARY'), 'Jan');
    });
  });
}
