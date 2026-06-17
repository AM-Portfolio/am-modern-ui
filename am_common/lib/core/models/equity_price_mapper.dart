import 'price_update_model.dart';

/// STOMP destination for per-symbol price relay from am-gateway Kafka relay.
String stockTopicDestination(String symbol) => '/topic/stock/$symbol';

/// Maps gateway `/topic/stock/{symbol}` payload ([EquityPrice] JSON) to [QuoteChange].
QuoteChange quoteChangeFromEquityPriceJson(Map<String, dynamic> json) {
  final ohlcv = json['ohlcv'] as Map<String, dynamic>?;
  return QuoteChange(
    lastPrice: _toDouble(json['lastPrice']),
    open: _toDouble(ohlcv?['open']),
    high: _toDouble(ohlcv?['high']),
    low: _toDouble(ohlcv?['low']),
    close: _toDouble(ohlcv?['close']),
    previousClose: _toDouble(ohlcv?['close']),
  );
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
