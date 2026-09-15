import 'package:flutter_test/flutter_test.dart';
import 'package:am_trade_ui/features/trade/presentation/analysis/models/timing_bucket.dart';

TimingBucket _bucket({
  required String key,
  required double avgPnl,
  int trades = 2,
  int? eligible,
}) {
  return TimingBucket(
    key: key,
    label: key,
    trades: trades,
    pnl: avgPnl * (eligible ?? trades),
    avgPnl: avgPnl,
    eligibleTrades: eligible ?? trades,
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

    test('uses server avgPnl and eligible when provided', () {
      final buckets = buildTimingBuckets(
        trades: {'SESSION_0915_1100': 4},
        profit: {'SESSION_0915_1100': 400},
        winRate: {'SESSION_0915_1100': 50},
        avgPnl: {'SESSION_0915_1100': 100},
        eligible: {'SESSION_0915_1100': 4},
        labelFor: formatSessionLabel,
      );
      expect(buckets, hasLength(1));
      expect(buckets.single.avgPnl, 100);
      expect(buckets.single.label, '9:15–11:00');
    });

    test('includeZeroTradeBuckets keeps empty session keys', () {
      final buckets = buildTimingBuckets(
        trades: {
          for (final k in kSessionKeys) k: k == 'OTHER' ? 2 : 0,
        },
        profit: {for (final k in kSessionKeys) k: 0.0},
        labelFor: formatSessionLabel,
        includeZeroTradeBuckets: true,
        orderedKeys: kSessionKeys,
      );
      expect(buckets, hasLength(5));
      expect(buckets.first.key, 'SESSION_0915_1100');
      expect(buckets.first.trades, 0);
      expect(buckets.last.key, 'OTHER');
      expect(buckets.last.trades, 2);
    });
  });

  group('sortForChart', () {
    test('sorts sessions in NSE order', () {
      final sorted = sortForChart(
        [
          _bucket(key: 'OTHER', avgPnl: 1),
          _bucket(key: 'SESSION_0915_1100', avgPnl: 1),
          _bucket(key: 'SESSION_1500_1530', avgPnl: 1),
        ],
        TimingDimension.session,
      );
      expect(
        sorted.map((b) => b.key).toList(),
        ['SESSION_0915_1100', 'SESSION_1500_1530', 'OTHER'],
      );
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
      expect(split.best.length, 3);
      expect(split.worst.length, 2);
      final keys = {
        ...split.best.map((b) => b.key),
        ...split.worst.map((b) => b.key),
      };
      expect(keys.length, split.best.length + split.worst.length);
      expect(split.best.first.key, 'a');
      expect(split.worst.first.key, 'e');
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
    });
  });

  group('rowsForRankView + min sample', () {
    test('Best ignores low-sample buckets', () {
      final buckets = [
        _bucket(key: 'hot', avgPnl: 999, trades: 1, eligible: 1),
        _bucket(key: 'solid', avgPnl: 50, trades: 5, eligible: 5),
        _bucket(key: 'ok', avgPnl: 10, trades: 4, eligible: 4),
        _bucket(key: 'meh', avgPnl: -5, trades: 3, eligible: 3),
      ];
      final best = rowsForRankView(buckets, TimingRankView.best);
      expect(best.map((b) => b.key), isNot(contains('hot')));
      expect(best.first.key, 'solid');

      final all = rowsForRankView(buckets, TimingRankView.all);
      expect(all.first.key, 'hot');
      expect(all.first.isLowSample, isTrue);
    });

    test('Best empty when no bucket meets min sample', () {
      final buckets = [
        _bucket(key: 'a', avgPnl: 10, trades: 1, eligible: 1),
        _bucket(key: 'b', avgPnl: -10, trades: 2, eligible: 2),
      ];
      expect(rowsForRankView(buckets, TimingRankView.best), isEmpty);
      expect(rowsForRankView(buckets, TimingRankView.worst), isEmpty);
    });

    test('Session All excludes zero-trade skeleton buckets', () {
      final sessions = buildTimingBuckets(
        trades: {
          for (final k in kSessionKeys) k: k == 'SESSION_0915_1100' ? 4 : 0,
        },
        profit: {
          for (final k in kSessionKeys)
            k: k == 'SESSION_0915_1100' ? 200.0 : 0.0,
        },
        avgPnl: {
          for (final k in kSessionKeys)
            k: k == 'SESSION_0915_1100' ? 50.0 : 0.0,
        },
        eligible: {
          for (final k in kSessionKeys) k: k == 'SESSION_0915_1100' ? 4 : 0,
        },
        labelFor: formatSessionLabel,
        includeZeroTradeBuckets: true,
        orderedKeys: kSessionKeys,
      );
      expect(sessions, hasLength(5));

      final all = rowsForRankView(sessions, TimingRankView.all);
      expect(all, hasLength(1));
      expect(all.single.key, 'SESSION_0915_1100');
      expect(all.single.avgPnl, 50);

      final best = rowsForRankView(sessions, TimingRankView.best);
      expect(best, hasLength(1));
      expect(best.single.key, 'SESSION_0915_1100');
    });

    test('All empty when every bucket has zero trades', () {
      final empty = buildTimingBuckets(
        trades: {for (final k in kSessionKeys) k: 0},
        profit: {for (final k in kSessionKeys) k: 0.0},
        labelFor: formatSessionLabel,
        includeZeroTradeBuckets: true,
        orderedKeys: kSessionKeys,
      );
      expect(rowsForRankView(empty, TimingRankView.all), isEmpty);
      expect(rowsForRankView(empty, TimingRankView.best), isEmpty);
    });
  });

  group('bucketsWithTrades', () {
    test('keeps only positive trade counts', () {
      final filtered = bucketsWithTrades([
        _bucket(key: 'a', avgPnl: 1, trades: 0),
        _bucket(key: 'b', avgPnl: 2, trades: 3),
      ]);
      expect(filtered.map((b) => b.key), ['b']);
    });
  });

  group('isLowSample', () {
    test('true only when 0 < eligible < min', () {
      expect(
        _bucket(key: 'a', avgPnl: 1, trades: 0, eligible: 0).isLowSample,
        isFalse,
      );
      expect(
        _bucket(key: 'b', avgPnl: 1, trades: 2, eligible: 2).isLowSample,
        isTrue,
      );
      expect(
        _bucket(key: 'c', avgPnl: 1, trades: 3, eligible: 3).isLowSample,
        isFalse,
      );
    });
  });

  group('label formatters', () {
    test('formatSessionLabel', () {
      expect(formatSessionLabel('SESSION_0915_1100'), '9:15–11:00');
      expect(formatSessionLabel('SESSION_1100_1300'), '11:00–1:00');
      expect(formatSessionLabel('SESSION_1300_1500'), '1:00–3:00');
      expect(formatSessionLabel('SESSION_1500_1530'), '3:00–3:30');
      expect(formatSessionLabel('OTHER'), 'Other');
    });

    test('formatWeekdayLabel / formatMonthLabel', () {
      expect(formatWeekdayLabel('MONDAY'), 'Mon');
      expect(formatMonthLabel('JANUARY'), 'Jan');
    });

    test('styleHintDisplayLabel', () {
      expect(styleHintDisplayLabel('SCALPER'), 'Scalper');
      expect(styleHintDisplayLabel('UNKNOWN'), 'Unknown');
    });
  });
}
