import 'package:flutter_test/flutter_test.dart';
import 'package:am_market_common/models/market_data.dart';

void main() {
  group('global index quote availability', () {
    test('treats a suspended response without a positive price as unavailable',
        () {
      final index = StockIndicesMarketData.fromJson({
        'indexSymbol': 'IXIC',
        'metadata': {'segment': 'GLOBAL', 'suspended': true},
      });

      expect(index.isGlobal, isTrue);
      expect(index.hasValidPrice, isFalse);
      expect(index.lastPrice, 0);
    });

    test('retains a verified last price when it is marked non-live', () {
      final index = StockIndicesMarketData.fromJson({
        'indexSymbol': 'DJI',
        'metadata': {
          'segment': 'GLOBAL',
          'suspended': true,
          'last': 40123.5,
          'change': 0,
          'percChange': 0,
        },
      });

      expect(index.isGlobal, isTrue);
      expect(index.hasValidPrice, isTrue);
      expect(index.suspended, isTrue);
    });

    test('derives 1D change from lastPrice and pChange when change is 0', () {
      final index = StockIndicesMarketData.fromJson({
        'indexSymbol': 'HSI',
        'metadata': {
          'segment': 'GLOBAL',
          'last': 23093.37,
          'percChange': 0.69,
        },
      });

      expect(index.change, greaterThan(150.0));
      expect(index.pChange, 0.69);
    });

    test('derives 1D change from lastPrice and previousClose when change is 0', () {
      final index = StockIndicesMarketData.fromJson({
        'indexSymbol': 'DJI',
        'lastPrice': 52318.06,
        'previousClose': 52889.37,
      });

      expect(index.change, closeTo(-571.31, 0.01));
      expect(index.pChange, closeTo(-1.08, 0.01));
    });
  });
}
