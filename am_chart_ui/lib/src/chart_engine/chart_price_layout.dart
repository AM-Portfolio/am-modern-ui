import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import '../providers/chart_models.dart';

/// Shared candle-plot price ↔ Y mapping (excludes volume band).
class ChartPriceLayout {
  const ChartPriceLayout({
    required this.plot,
    required this.candlePlot,
    required this.volumePlot,
    required this.minPrice,
    required this.maxPrice,
    required this.startIndex,
    required this.visibleCount,
  });

  static const leftInset = 8.0;
  static const rightInset = 56.0;
  static const topInset = 8.0;
  static const bottomInset = 24.0;
  static const volumeFrac = 0.20;

  final Rect plot;
  final Rect candlePlot;
  final Rect volumePlot;
  final double minPrice;
  final double maxPrice;
  final int startIndex;
  final int visibleCount;

  double yFor(double price) {
    final span = maxPrice - minPrice;
    if (span <= 0 || candlePlot.height <= 0) return candlePlot.center.dy;
    return candlePlot.bottom -
        ((price - minPrice) / span) * candlePlot.height;
  }

  double priceAt(double y) {
    final span = maxPrice - minPrice;
    if (span <= 0 || candlePlot.height <= 0) return minPrice;
    final t = ((candlePlot.bottom - y) / candlePlot.height).clamp(0.0, 1.0);
    return minPrice + t * span;
  }

  bool get isValid =>
      candlePlot.width > 0 &&
      candlePlot.height > 0 &&
      maxPrice > minPrice;

  /// Same visible-window + Y range rules as [AdvancedChartCanvas] painter.
  static ChartPriceLayout fromBars({
    required List<ChartBar> bars,
    required Size size,
    required double zoom,
    required double pan,
    double? yMinOverride,
    double? yMaxOverride,
  }) {
    final plot = Rect.fromLTWH(
      leftInset,
      topInset,
      math.max(0, size.width - leftInset - rightInset),
      math.max(0, size.height - topInset - bottomInset),
    );
    final volumeH = plot.height * volumeFrac;
    final candlePlot = Rect.fromLTRB(
      plot.left,
      plot.top,
      plot.right,
      plot.bottom - volumeH,
    );
    final volumePlot = Rect.fromLTRB(
      plot.left,
      candlePlot.bottom,
      plot.right,
      plot.bottom,
    );

    if (bars.isEmpty || plot.width <= 0 || plot.height <= 0) {
      return ChartPriceLayout(
        plot: plot,
        candlePlot: candlePlot,
        volumePlot: volumePlot,
        minPrice: 0,
        maxPrice: 1,
        startIndex: 0,
        visibleCount: 0,
      );
    }

    final defaultBase = math.min(bars.length, 36);
    final visible =
        math.max(4, (defaultBase / zoom).round()).clamp(4, bars.length);
    final maxStart = math.max(0, bars.length - visible);
    final start = (maxStart + (-pan / 8).round()).clamp(0, maxStart);
    final end = math.min(bars.length - 1, start + visible - 1);
    final slice = bars.sublist(start, end + 1);

    var minP = slice.map((b) => b.low).reduce(math.min);
    var maxP = slice.map((b) => b.high).reduce(math.max);
    if (minP == maxP) {
      minP -= 1;
      maxP += 1;
    }
    final pad = (maxP - minP) * 0.05;
    minP -= pad;
    maxP += pad;
    if (yMinOverride != null && yMaxOverride != null) {
      minP = yMinOverride;
      maxP = yMaxOverride;
      if (minP == maxP) {
        minP -= 1;
        maxP += 1;
      }
    }

    return ChartPriceLayout(
      plot: plot,
      candlePlot: candlePlot,
      volumePlot: volumePlot,
      minPrice: minP,
      maxPrice: maxP,
      startIndex: start,
      visibleCount: visible,
    );
  }
}
