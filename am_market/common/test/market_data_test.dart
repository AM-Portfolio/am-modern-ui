import 'package:flutter_test/flutter_test.dart';
import 'package:am_market_common/models/market_data.dart';

void main() {
  group('StockIndicesMarketData Parsing Tests', () {
    test('Should parse successfully from nested metadata structure', () {
      final jsonInput = {
        "indexSymbol": "NIFTY 50",
        "data": [],
        "metadata": {
          "last": 26000.5,
          "change": 120.25,
          "percChange": 0.46
        }
      };

      final parsed = StockIndicesMarketData.fromJson(jsonInput);

      expect(parsed.indexSymbol, equals('NIFTY 50'));
      expect(parsed.lastPrice, equals(26000.5));
      expect(parsed.change, equals(120.25));
      expect(parsed.pChange, equals(0.46));
    });

    test('Should fall back successfully to legacy top-level values', () {
      final jsonInput = {
        "indexSymbol": "NIFTY 50",
        "lastPrice": 25000.0,
        "change": 50.0,
        "pChange": 0.20,
        "data": []
      };

      final parsed = StockIndicesMarketData.fromJson(jsonInput);

      expect(parsed.indexSymbol, equals('NIFTY 50'));
      expect(parsed.lastPrice, equals(25000.0));
      expect(parsed.change, equals(50.0));
      expect(parsed.pChange, equals(0.20));
    });
  });
}
