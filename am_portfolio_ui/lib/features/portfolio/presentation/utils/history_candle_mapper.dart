import 'dart:math' as math;

/// Derived OHLC for one history point.
class DerivedOhlc {
  final double open;
  final double high;
  final double low;
  final double close;

  const DerivedOhlc({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}

/// Builds candle OHLC from a daily snapshot.
///
/// EOD snapshots often store open=high=low=close. In that case [open] is the
/// previous day's close so candles show daily change instead of flat dojis.
class HistoryCandleMapper {
  static const _eps = 0.01;

  static bool storedRangeDiffers({
    double? open,
    double? high,
    double? low,
    required double close,
  }) {
    bool differs(double? v) => v != null && (v - close).abs() > _eps;
    return differs(open) || differs(high) || differs(low);
  }

  static DerivedOhlc? derive({
    required double? close,
    double? open,
    double? high,
    double? low,
    double? previousClose,
  }) {
    if (close == null || close.isNaN || close <= 0) return null;

    final double o;
    final double h;
    final double l;
    if (storedRangeDiffers(open: open, high: high, low: low, close: close)) {
      o = open ?? previousClose ?? close;
      h = high ?? math.max(o, close);
      l = low ?? math.min(o, close);
    } else {
      o = previousClose ?? open ?? close;
      h = math.max(o, close);
      l = math.min(o, close);
    }

    return DerivedOhlc(
      open: o,
      high: math.max(h, math.max(o, close)),
      low: math.min(l, math.min(o, close)),
      close: close,
    );
  }
}
