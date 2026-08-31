import 'package:am_design_system/shared/widgets/charts/multi_series_chart_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiSeriesChartData.fromLegacyMaps', () {
    test('builds series from time/close maps', () {
      final data = MultiSeriesChartData.fromLegacyMaps({
        'NIFTY 50': [
          {'time': '2026-08-20', 'close': 24000},
          {'time': '2026-08-21', 'close': 24100},
        ],
      });
      expect(data.labels(), ['NIFTY 50']);
      expect(data.series['NIFTY 50']!.length, 2);
    });

    test('skips series with fewer than two points', () {
      final data = MultiSeriesChartData.fromLegacyMaps({
        'Empty': [
          {'time': '2026-08-20', 'close': 100},
        ],
      });
      expect(data.labels(), isEmpty);
    });
  });

  group('MultiSeriesChartData.fromRows', () {
    test('normalizes intraday time-only labels', () {
      final data = MultiSeriesChartData.fromRows(
        [
          {'time': '09:15', 'close': 100},
          {'time': '09:30', 'close': 101},
        ],
        label: 'Overall',
        isIntraday: true,
        referenceDate: DateTime(2026, 8, 29),
      );
      expect(data.labels(), ['Overall']);
      expect(
        data.series['Overall']!.first.time,
        '2026-08-29T09:15:00',
      );
    });
  });

  group('MultiSeriesChartData.merge', () {
    test('merges distinct labels', () {
      final a = MultiSeriesChartData.fromRows(
        [
          {'time': '2026-08-20', 'close': 100},
          {'time': '2026-08-21', 'close': 110},
        ],
        label: 'A',
        isIntraday: false,
      );
      final b = MultiSeriesChartData.fromRows(
        [
          {'time': '2026-08-20', 'close': 24000},
          {'time': '2026-08-21', 'close': 24100},
        ],
        label: 'B',
        isIntraday: false,
      );
      final merged = MultiSeriesChartData.merge([a, b]);
      expect(merged.labels(), ['A', 'B']);
    });

    test('skips duplicate labels by default', () {
      final a = MultiSeriesChartData.fromRows(
        [
          {'time': '2026-08-20', 'close': 100},
          {'time': '2026-08-21', 'close': 110},
        ],
        label: 'Same',
        isIntraday: false,
      );
      final b = MultiSeriesChartData.fromRows(
        [
          {'time': '2026-08-20', 'close': 200},
          {'time': '2026-08-21', 'close': 220},
        ],
        label: 'Same',
        isIntraday: false,
      );
      final merged = MultiSeriesChartData.merge([a, b]);
      expect(merged.series['Same']!.first.value, 100);
    });
  });
}
