import 'package:flutter_test/flutter_test.dart';
import 'package:am_market_common/services/api_service.dart';

void main() {
  group('parseHeatmapPayload', () {
    test('flat symbol→pct map', () {
      final m = parseHeatmapPayload({
        'NIFTY PHARMA': 1.66,
        'NIFTY IT': -0.59,
        'SENSEX': 0,
      });
      expect(m.length, 3);
      expect(m['NIFTY PHARMA'], 1.66);
      expect(m['NIFTY IT'], -0.59);
      expect(m['SENSEX'], 0);
    });

    test('wrapped under heatmap key', () {
      final m = parseHeatmapPayload({
        'heatmap': {
          'RELIANCE': 1.2,
          'TCS': -0.5,
        },
        'symbol': 'NIFTY 50',
      });
      expect(m.length, 2);
      expect(m['RELIANCE'], 1.2);
      expect(m.containsKey('symbol'), isFalse);
    });

    test('skips non-numeric top-level junk without throwing', () {
      final m = parseHeatmapPayload({
        'NIFTY 100': 1.0,
        'meta': {'ok': true},
      });
      expect(m, {'NIFTY 100': 1.0});
    });

    test('nested pChange objects', () {
      final m = parseHeatmapPayload({
        'RELIANCE': {'pChange': 2.5, 'ltp': 100},
        'INFY': {'changePercent': -1.1},
      });
      expect(m['RELIANCE'], 2.5);
      expect(m['INFY'], -1.1);
    });
  });
}
