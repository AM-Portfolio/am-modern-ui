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
  });
}
