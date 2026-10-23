import 'package:flutter_test/flutter_test.dart';
import 'package:am_market_common/models/top_mover_stock.dart';

void main() {
  group('TopMoverStock.fromJson', () {
    test('reads changePercent', () {
      final stock = TopMoverStock.fromJson({
        'symbol': 'RELIANCE',
        'lastPrice': 2500.5,
        'change': 12.3,
        'changePercent': 0.49,
        'volume': 1000,
      });
      expect(stock.changePercent, closeTo(0.49, 0.001));
    });

    test('falls back to changePercentage and pChange', () {
      final viaPercentage = TopMoverStock.fromJson({
        'symbol': 'TCS',
        'lastPrice': 1,
        'changePercentage': -1.25,
      });
      expect(viaPercentage.changePercent, closeTo(-1.25, 0.001));

      final viaPChange = TopMoverStock.fromJson({
        'symbol': 'INFY',
        'lastPrice': 1,
        'pChange': 2.5,
      });
      expect(viaPChange.changePercent, closeTo(2.5, 0.001));
    });
  });
}
