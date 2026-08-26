import 'dart:math' as math;

/// Indian-rupee Y-axis: nice ticks, a minimum ~8% value band, and K / L / Cr labels.
class ChartAxisScale {
  const ChartAxisScale({
    required this.minY,
    required this.maxY,
    required this.ticks,
    required this.unit,
    required this.step,
  });

  final double minY;
  final double maxY;
  final List<double> ticks;
  final ChartAxisUnit unit;
  final double step;

  /// Formats [v] with this scale's unit so every tick shares one suffix.
  String format(double v) => compactRupee(v, unit: unit);

  static ChartAxisScale fromValues(
    Iterable<double> values, {
    double minBandFraction = 0.08,
  }) {
    final nums = values.where((v) => v.isFinite).toList();
    if (nums.isEmpty) {
      return const ChartAxisScale(
        minY: 0,
        maxY: 1,
        ticks: [0, 0.25, 0.5, 0.75, 1],
        unit: ChartAxisUnit.rupee,
        step: 0.25,
      );
    }
    return fromRange(
      nums.reduce(math.min),
      nums.reduce(math.max),
      minBandFraction: minBandFraction,
    );
  }

  static ChartAxisScale fromRange(
    double dataMin,
    double dataMax, {
    double minBandFraction = 0.08,
  }) {
    if (dataMax < dataMin) {
      final tmp = dataMin;
      dataMin = dataMax;
      dataMax = tmp;
    }
    final floorAtZero = dataMin >= 0;
    final mid = (dataMin + dataMax) / 2;
    var range = dataMax - dataMin;
    final magnitude = [mid.abs(), dataMin.abs(), dataMax.abs()].reduce(math.max);
    final minSpan = math.max(magnitude * minBandFraction, 1.0);
    if (range < minSpan) {
      final extra = (minSpan - range) / 2;
      dataMin -= extra;
      dataMax += extra;
      range = dataMax - dataMin;
    }

    const tickCount = 5;
    final step = _niceNum(range / (tickCount - 1), round: true);
    var niceMin = (dataMin / step).floor() * step;
    var niceMax = (dataMax / step).ceil() * step;
    if (floorAtZero && niceMin < 0) niceMin = 0;
    if (niceMax <= niceMin) niceMax = niceMin + step;

    final ticks = <double>[];
    for (var t = niceMin; t <= niceMax + step * 0.25; t += step) {
      ticks.add(_snap(t));
      if (ticks.length >= 8) break;
    }
    if (ticks.isEmpty) {
      ticks.addAll([niceMin, niceMax]);
    }

    final unit = unitFor(niceMax.abs() > niceMin.abs() ? niceMax : niceMin);
    return ChartAxisScale(
      minY: ticks.first,
      maxY: ticks.last,
      ticks: ticks,
      unit: unit,
      step: step,
    );
  }

  static ChartAxisUnit unitFor(double value) {
    final a = value.abs();
    if (a >= 1e7) return ChartAxisUnit.crore;
    if (a >= 1e5) return ChartAxisUnit.lakh;
    if (a >= 1e3) return ChartAxisUnit.thousand;
    return ChartAxisUnit.rupee;
  }

  /// Compact Indian numbering. Pass [unit] so a whole axis shares one suffix.
  static String compactRupee(double v, {ChartAxisUnit? unit}) {
    if (v == 0) return '0';
    final u = unit ?? unitFor(v);
    switch (u) {
      case ChartAxisUnit.crore:
        return '${_fixed(v / 1e7, 2)}Cr';
      case ChartAxisUnit.lakh:
        return '${_fixed(v / 1e5, 2)}L';
      case ChartAxisUnit.thousand:
        return '${_fixed(v / 1e3, 1)}K';
      case ChartAxisUnit.rupee:
        if (v.abs() < 10) return v.toStringAsFixed(2);
        return v.round().toString();
    }
  }

  static double _niceNum(double x, {required bool round}) {
    if (x <= 0 || !x.isFinite) return 1;
    final exp = (math.log(x) / math.ln10).floor();
    final f = x / math.pow(10, exp);
    late final double nf;
    if (round) {
      if (f < 1.5) {
        nf = 1;
      } else if (f < 3) {
        nf = 2;
      } else if (f < 7) {
        nf = 5;
      } else {
        nf = 10;
      }
    } else {
      if (f <= 1) {
        nf = 1;
      } else if (f <= 2) {
        nf = 2;
      } else if (f <= 5) {
        nf = 5;
      } else {
        nf = 10;
      }
    }
    return nf * math.pow(10, exp).toDouble();
  }

  static double _snap(double v) => (v * 1e9).round() / 1e9;

  static String _fixed(double v, int decimals) {
    var s = v.toStringAsFixed(decimals);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }
}

enum ChartAxisUnit { crore, lakh, thousand, rupee }
