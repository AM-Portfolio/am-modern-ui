/// Client-side technical indicators for analysis candle charts.

enum ChartIndicatorId {
  sma20,
  sma50,
  ema20,
  rsi14,
  macd,
}

extension ChartIndicatorIdX on ChartIndicatorId {
  String get label => switch (this) {
        ChartIndicatorId.sma20 => 'SMA 20',
        ChartIndicatorId.sma50 => 'SMA 50',
        ChartIndicatorId.ema20 => 'EMA 20',
        ChartIndicatorId.rsi14 => 'RSI 14',
        ChartIndicatorId.macd => 'MACD',
      };

  bool get isOverlay => switch (this) {
        ChartIndicatorId.sma20 ||
        ChartIndicatorId.sma50 ||
        ChartIndicatorId.ema20 =>
          true,
        ChartIndicatorId.rsi14 || ChartIndicatorId.macd => false,
      };
}

/// Simple moving average; leading values are null until [period] samples exist.
List<double?> sma(List<double> closes, int period) {
  if (period <= 0) return List.filled(closes.length, null);
  final out = List<double?>.filled(closes.length, null);
  double sum = 0;
  for (var i = 0; i < closes.length; i++) {
    sum += closes[i];
    if (i >= period) sum -= closes[i - period];
    if (i >= period - 1) out[i] = sum / period;
  }
  return out;
}

List<double?> ema(List<double> closes, int period) {
  if (period <= 0 || closes.isEmpty) {
    return List.filled(closes.length, null);
  }
  final out = List<double?>.filled(closes.length, null);
  final k = 2.0 / (period + 1);
  double? prev;
  for (var i = 0; i < closes.length; i++) {
    if (i < period - 1) continue;
    if (prev == null) {
      double sum = 0;
      for (var j = i - period + 1; j <= i; j++) {
        sum += closes[j];
      }
      prev = sum / period;
      out[i] = prev;
    } else {
      prev = closes[i] * k + prev * (1 - k);
      out[i] = prev;
    }
  }
  return out;
}

/// Wilder RSI; values in 0–100, null until warm-up.
List<double?> rsi(List<double> closes, {int period = 14}) {
  final out = List<double?>.filled(closes.length, null);
  if (closes.length <= period) return out;

  double avgGain = 0;
  double avgLoss = 0;
  for (var i = 1; i <= period; i++) {
    final d = closes[i] - closes[i - 1];
    if (d >= 0) {
      avgGain += d;
    } else {
      avgLoss -= d;
    }
  }
  avgGain /= period;
  avgLoss /= period;
  out[period] = avgLoss == 0 ? 100 : 100 - (100 / (1 + avgGain / avgLoss));

  for (var i = period + 1; i < closes.length; i++) {
    final d = closes[i] - closes[i - 1];
    final gain = d > 0 ? d : 0.0;
    final loss = d < 0 ? -d : 0.0;
    avgGain = (avgGain * (period - 1) + gain) / period;
    avgLoss = (avgLoss * (period - 1) + loss) / period;
    out[i] = avgLoss == 0 ? 100 : 100 - (100 / (1 + avgGain / avgLoss));
  }
  return out;
}

class MacdResult {
  const MacdResult({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });

  final List<double?> macdLine;
  final List<double?> signalLine;
  final List<double?> histogram;
}

MacdResult macd(
  List<double> closes, {
  int fast = 12,
  int slow = 26,
  int signal = 9,
}) {
  final emaFast = ema(closes, fast);
  final emaSlow = ema(closes, slow);
  final macdLine = List<double?>.generate(closes.length, (i) {
    final a = emaFast[i];
    final b = emaSlow[i];
    if (a == null || b == null) return null;
    return a - b;
  });

  // Signal = EMA of MACD line (skip nulls by carrying finite MACD only).
  final signalLine = List<double?>.filled(closes.length, null);
  final hist = List<double?>.filled(closes.length, null);
  final k = 2.0 / (signal + 1);
  double? prevSignal;
  var warm = 0;
  for (var i = 0; i < closes.length; i++) {
    final m = macdLine[i];
    if (m == null) continue;
    warm++;
    if (prevSignal == null) {
      if (warm < signal) continue;
      // Seed with SMA of last [signal] finite MACD values.
      double sum = 0;
      var count = 0;
      for (var j = i; j >= 0 && count < signal; j--) {
        final v = macdLine[j];
        if (v == null) continue;
        sum += v;
        count++;
      }
      if (count < signal) continue;
      prevSignal = sum / signal;
    } else {
      prevSignal = m * k + prevSignal * (1 - k);
    }
    signalLine[i] = prevSignal;
    hist[i] = m - prevSignal;
  }
  return MacdResult(
    macdLine: macdLine,
    signalLine: signalLine,
    histogram: hist,
  );
}

/// Compute overlay / pane series for the selected indicator set.
Map<ChartIndicatorId, List<double?>> computeOverlayIndicators(
  List<double> closes,
  Set<ChartIndicatorId> selected,
) {
  final out = <ChartIndicatorId, List<double?>>{};
  if (selected.contains(ChartIndicatorId.sma20)) {
    out[ChartIndicatorId.sma20] = sma(closes, 20);
  }
  if (selected.contains(ChartIndicatorId.sma50)) {
    out[ChartIndicatorId.sma50] = sma(closes, 50);
  }
  if (selected.contains(ChartIndicatorId.ema20)) {
    out[ChartIndicatorId.ema20] = ema(closes, 20);
  }
  return out;
}

Map<String, List<double?>> computePaneIndicators(
  List<double> closes,
  Set<ChartIndicatorId> selected,
) {
  final out = <String, List<double?>>{};
  if (selected.contains(ChartIndicatorId.rsi14)) {
    out['rsi'] = rsi(closes, period: 14);
  }
  if (selected.contains(ChartIndicatorId.macd)) {
    final m = macd(closes);
    out['macd'] = m.macdLine;
    out['macdSignal'] = m.signalLine;
    out['macdHist'] = m.histogram;
  }
  return out;
}
