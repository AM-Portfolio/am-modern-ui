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
  });
}
