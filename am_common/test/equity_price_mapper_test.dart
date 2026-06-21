import 'package:flutter_test/flutter_test.dart';
import 'package:am_common/core/models/equity_price_mapper.dart';

void main() {
  test('stockTopicDestination builds gateway topic path', () {
    expect(stockTopicDestination('NIFTY 50'), '/topic/stock/NIFTY 50');
  });

  test('quoteChangeFromEquityPriceJson maps EquityPrice fields', () {
    final quote = quoteChangeFromEquityPriceJson({
      'symbol': 'RELIANCE',
      'lastPrice': 2450.5,
      'ohlcv': {
        'open': 2440.0,
        'high': 2460.0,
        'low': 2435.0,
        'close': 2445.0,
      },
    });

    expect(quote.lastPrice, 2450.5);
    expect(quote.open, 2440.0);
    expect(quote.high, 2460.0);
    expect(quote.low, 2435.0);
    expect(quote.close, 2445.0);
    expect(quote.previousClose, 2445.0);
    expect(quote.change, 5.5);
    expect(quote.changePercent, closeTo(0.22, 0.01));
  });

  test('quoteChangeFromEquityPriceJson computes change from ITC-style payload', () {
    final quote = quoteChangeFromEquityPriceJson({
      'symbol': 'ITC',
      'lastPrice': 289.28,
      'ohlcv': {
        'open': 289.8,
        'high': 290.6,
        'low': 289.28,
        'close': 289.85,
      },
      'exchange': 'MOCK',
    });

    expect(quote.change, -0.57);
    expect(quote.changePercent, closeTo(-0.2, 0.01));
    expect(quote.previousClose, 289.85);
  });

  test('quoteChangeFromEquityPriceJson uses explicit change fields when present', () {
    final quote = quoteChangeFromEquityPriceJson({
      'lastPrice': 100.0,
      'previousClose': 98.0,
      'change': 2.0,
      'changePercent': 2.04,
      'ohlcv': {'close': 98.0},
    });

    expect(quote.change, 2.0);
    expect(quote.changePercent, 2.04);
  });
}
