import 'package:flutter_test/flutter_test.dart';
import 'package:am_market_common/providers/market_provider.dart';

void main() {
  group('MarketProvider.extractSparklineCloses', () {
    test('maps close/price/lastPrice/value and skips invalid', () {
      final points = [
        {'close': 100.0},
        {'price': 101},
        {'lastPrice': 102.5},
        {'value': 103},
        {'close': 0},
        {'close': 'bad'},
        <String, dynamic>{},
      ];

      final closes = MarketProvider.extractSparklineCloses(points);

      expect(closes, [100.0, 101.0, 102.5, 103.0]);
    });

    test('returns empty for empty input', () {
      expect(MarketProvider.extractSparklineCloses(const []), isEmpty);
    });

    test('sorts reverse-order points ascending by timestamp', () {
      final closes = MarketProvider.extractSparklineCloses([
        {'timestamp': 3000, 'close': 103.0},
        {'timestamp': 1000, 'close': 100.0},
        {'timestamp': 2000, 'close': 101.5},
      ]);
      expect(closes, [100.0, 101.5, 103.0]);
      expect(closes.last > closes.first, isTrue);
    });

    test('parses string timestamps and ignores non-positive closes', () {
      final closes = MarketProvider.extractSparklineCloses([
        {'date': '2024-01-03T00:00:00Z', 'close': 110.0},
        {'date': '2024-01-01T00:00:00Z', 'close': 0.0},
        {'date': '2024-01-02T00:00:00Z', 'price': 105.0},
      ]);
      expect(closes, [105.0, 110.0]);
    });
  });
}
