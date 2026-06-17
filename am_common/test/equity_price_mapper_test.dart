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
  });
}
