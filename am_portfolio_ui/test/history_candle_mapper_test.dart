import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/utils/history_candle_mapper.dart';

void main() {
  group('HistoryCandleMapper', () {
    test('collapsed OHLC uses previous close as open', () {
      final candle = HistoryCandleMapper.derive(
        close: 933243.69,
        open: 933243.69,
        high: 933243.69,
        low: 933243.69,
        previousClose: 920000.00,
      );

      expect(candle, isNotNull);
      expect(candle!.open, 920000.00);
      expect(candle.close, 933243.69);
      expect(candle.high, 933243.69);
      expect(candle.low, 920000.00);
    });

    test('first day with collapsed OHLC is a doji at close', () {
      final candle = HistoryCandleMapper.derive(
        close: 100.0,
        open: 100.0,
        high: 100.0,
        low: 100.0,
      );

      expect(candle!.open, 100.0);
      expect(candle.high, 100.0);
      expect(candle.low, 100.0);
      expect(candle.close, 100.0);
    });

    test('keeps stored range when open/high/low differ from close', () {
      final candle = HistoryCandleMapper.derive(
        close: 110,
        open: 100,
        high: 120,
        low: 95,
        previousClose: 99,
      );

      expect(candle!.open, 100);
      expect(candle.high, 120);
      expect(candle.low, 95);
      expect(candle.close, 110);
    });

    test('skips invalid close', () {
      expect(HistoryCandleMapper.derive(close: null), isNull);
      expect(HistoryCandleMapper.derive(close: double.nan), isNull);
      expect(HistoryCandleMapper.derive(close: 0), isNull);
    });
  });
}
