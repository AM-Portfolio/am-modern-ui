import 'package:am_design_system/shared/widgets/charts/chart_series_window.dart';
import 'package:am_design_system/shared/widgets/charts/indicators/chart_indicators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rebasePreNormalizedPercent', () {
    test('shifts each series so first finite is 0', () {
      final combined = [
        {'time': '2026-01-01', 'A': -25.0, 'B': 10.0},
        {'time': '2026-02-01', 'A': -10.0, 'B': 20.0},
        {'time': '2026-03-01', 'A': 5.0, 'B': 15.0},
      ];
      rebasePreNormalizedPercent(combined, ['A', 'B']);
      expect(combined[0]['A'], 0.0);
      expect(combined[1]['A'], 15.0);
      expect(combined[2]['A'], 30.0);
      expect(combined[0]['B'], 0.0);
      expect(combined[1]['B'], 10.0);
      expect(combined[2]['B'], 5.0);
    });
  });

  group('padCombinedTimelineToToday', () {
    test('appends today when last point is older', () {
      final combined = [
        {'time': '2026-07-01', 'A': 3.0},
        {'time': '2026-07-15', 'A': 5.0},
      ];
      final out = padCombinedTimelineToToday(
        combined: combined,
        seriesKeys: ['A'],
        today: DateTime(2026, 9, 21),
        timeFrameCode: '6M',
        isIntraday: false,
      );
      expect(out.length, 3);
      expect(out.last['time'], '2026-09-21');
      expect(out.last['A'], 5.0);
    });

    test('skips pad for 1D', () {
      final combined = [
        {'time': '2026-09-21T10:00', 'A': 1.0},
      ];
      final out = padCombinedTimelineToToday(
        combined: combined,
        seriesKeys: ['A'],
        today: DateTime(2026, 9, 21),
        timeFrameCode: '1D',
        isIntraday: false,
      );
      expect(out.length, 1);
    });
  });

  group('xAxisLabelInterval', () {
    test('6M targets about 6 ticks', () {
      expect(
        xAxisLabelInterval(visibleCount: 120, timeFrameCode: '6M'),
        20,
      );
    });
  });

  group('indicators', () {
    test('sma warm-up then averages', () {
      final closes = [1.0, 2.0, 3.0, 4.0, 5.0];
      final s = sma(closes, 3);
      expect(s[0], isNull);
      expect(s[1], isNull);
      expect(s[2], closeTo(2.0, 1e-9));
      expect(s[3], closeTo(3.0, 1e-9));
      expect(s[4], closeTo(4.0, 1e-9));
    });

    test('rsi returns values in 0-100 after warm-up', () {
      final closes = List<double>.generate(30, (i) => 100 + i * 0.5);
      final r = rsi(closes, period: 14);
      expect(r[14], isNotNull);
      expect(r[14]!, greaterThan(50));
      expect(r[14]!, lessThanOrEqualTo(100));
    });

    test('macd produces line after slow EMA warm-up', () {
      final closes = List<double>.generate(60, (i) => 100.0 + i);
      final m = macd(closes);
      expect(m.macdLine.where((v) => v != null).length, greaterThan(10));
      expect(m.signalLine.where((v) => v != null).length, greaterThan(5));
    });
  });
}
