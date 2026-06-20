import 'price_update_model.dart';

/// STOMP destination for per-symbol price relay from am-gateway Kafka relay.
String stockTopicDestination(String symbol) => '/topic/stock/$symbol';

/// Maps gateway `/topic/stock/{symbol}` payload ([EquityPrice] JSON) to [QuoteChange].
QuoteChange quoteChangeFromEquityPriceJson(Map<String, dynamic> json) {
  final ohlcv = json['ohlcv'] as Map<String, dynamic>?;
  final lastPrice = _toDouble(json['lastPrice']);
  final previousClose = _toDouble(json['previousClose']) ??
      _toDouble(ohlcv?['close']);

  var change = _toDouble(json['change']);
  var changePercent = _toDouble(json['changePercent']);

  if (change == null &&
      lastPrice != null &&
      previousClose != null &&
      previousClose != 0) {
    change = _round2(lastPrice - previousClose);
  }
  if (changePercent == null &&
      change != null &&
      previousClose != null &&
      previousClose != 0) {
    changePercent = _round2((change / previousClose) * 100);
  }

  return QuoteChange(
    lastPrice: lastPrice,
    open: _toDouble(ohlcv?['open']),
    high: _toDouble(ohlcv?['high']),
    low: _toDouble(ohlcv?['low']),
    close: _toDouble(ohlcv?['close']),
    previousClose: previousClose,
    change: change,
    changePercent: changePercent,
  );
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

double _round2(double value) => (value * 100).roundToDouble() / 100;
