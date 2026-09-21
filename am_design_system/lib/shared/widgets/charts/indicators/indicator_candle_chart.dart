import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_colors.dart';

import '../chart_axis_scale.dart';
import '../chart_types.dart';
import 'chart_indicators.dart';

/// Candle chart with optional SMA/EMA overlays and RSI/MACD sub-panes.
class IndicatorCandleChart extends StatefulWidget {
  const IndicatorCandleChart({
    super.key,
    required this.candles,
    this.indicators = const {},
    this.upColor = AppColors.success,
    this.downColor = AppColors.error,
  });

  final List<CommonCandlePoint> candles;
  final Set<ChartIndicatorId> indicators;
  final Color upColor;
  final Color downColor;

  @override
  State<IndicatorCandleChart> createState() => _IndicatorCandleChartState();
}

class _IndicatorCandleChartState extends State<IndicatorCandleChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candles = widget.candles.where((c) => !c.close.isNaN).toList();
    if (candles.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final closes = candles.map((c) => c.close).toList();
    final overlays = computeOverlayIndicators(closes, widget.indicators);
    final panes = computePaneIndicators(closes, widget.indicators);
    final showRsi = panes.containsKey('rsi');
    final showMacd = panes.containsKey('macd');

    final lowsHighs = <double>[];
    for (final c in candles) {
      lowsHighs.addAll([c.open, c.high, c.low, c.close]);
    }
    for (final series in overlays.values) {
      for (final v in series) {
        if (v != null && v.isFinite) lowsHighs.add(v);
      }
    }
    final axis = ChartAxisScale.fromValues(lowsHighs);

    return Column(
      children: [
        Expanded(
          flex: showRsi || showMacd ? 3 : 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (d) =>
                    _selectAt(d.localPosition, constraints.biggest, candles),
                onHorizontalDragUpdate: (d) =>
                    _selectAt(d.localPosition, constraints.biggest, candles),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _CandleWithOverlayPainter(
                    candles: candles,
                    overlays: overlays,
                    minY: axis.minY,
                    maxY: axis.maxY,
                    ticks: axis.ticks,
                    upColor: widget.upColor,
                    downColor: widget.downColor,
                    gridColor: theme.dividerColor.withValues(alpha: 0.2),
                    labelColor: theme.hintColor,
                    selectedIndex: _selected,
                    formatY: axis.format,
                  ),
                ),
              );
            },
          ),
        ),
        if (showRsi)
          Expanded(
            flex: 1,
            child: _PaneChart(
              title: 'RSI',
              series: {
                'rsi': panes['rsi']!,
              },
              colors: { 'rsi': theme.colorScheme.primary },
              fixedMin: 0,
              fixedMax: 100,
              guideLines: const [30, 70],
              selectedIndex: _selected,
              length: candles.length,
            ),
          ),
        if (showMacd)
          Expanded(
            flex: 1,
            child: _PaneChart(
              title: 'MACD',
              series: {
                'macd': panes['macd']!,
                'signal': panes['macdSignal']!,
              },
              hist: panes['macdHist'],
              colors: {
                'macd': theme.colorScheme.primary,
                'signal': theme.colorScheme.tertiary,
              },
              selectedIndex: _selected,
              length: candles.length,
            ),
          ),
      ],
    );
  }

  void _selectAt(Offset pos, Size size, List<CommonCandlePoint> candles) {
    const leftPad = 52.0;
    final plotWidth = size.width - leftPad - 8;
    if (plotWidth <= 0 || candles.isEmpty) return;
    final t = ((pos.dx - leftPad) / plotWidth).clamp(0.0, 0.999);
    final index = (t * candles.length).floor();
    if (_selected != index) setState(() => _selected = index);
  }
}

class _PaneChart extends StatelessWidget {
  const _PaneChart({
    required this.title,
    required this.series,
    required this.colors,
    required this.length,
    this.hist,
    this.fixedMin,
    this.fixedMax,
    this.guideLines = const [],
    this.selectedIndex,
  });

  final String title;
  final Map<String, List<double?>> series;
  final Map<String, Color> colors;
  final List<double?>? hist;
  final double? fixedMin;
  final double? fixedMax;
  final List<double> guideLines;
  final int? selectedIndex;
  final int length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vals = <double>[];
    for (final s in series.values) {
      for (final v in s) {
        if (v != null && v.isFinite) vals.add(v);
      }
    }
    if (hist != null) {
      for (final v in hist!) {
        if (v != null && v.isFinite) vals.add(v);
      }
    }
    final minY = fixedMin ?? (vals.isEmpty ? 0 : vals.reduce(math.min));
    final maxY = fixedMax ?? (vals.isEmpty ? 1 : vals.reduce(math.max));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Text(title,
              style: TextStyle(fontSize: 10, color: theme.hintColor)),
        ),
        Expanded(
          child: CustomPaint(
            painter: _PanePainter(
              series: series,
              colors: colors,
              hist: hist,
              minY: minY,
              maxY: maxY,
              guideLines: guideLines,
              selectedIndex: selectedIndex,
              length: length,
              gridColor: theme.dividerColor.withValues(alpha: 0.2),
              labelColor: theme.hintColor,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _CandleWithOverlayPainter extends CustomPainter {
  _CandleWithOverlayPainter({
    required this.candles,
    required this.overlays,
    required this.minY,
    required this.maxY,
    required this.ticks,
    required this.upColor,
    required this.downColor,
    required this.gridColor,
    required this.labelColor,
    required this.selectedIndex,
    required this.formatY,
  });

  final List<CommonCandlePoint> candles;
  final Map<ChartIndicatorId, List<double?>> overlays;
  final double minY;
  final double maxY;
  final List<double> ticks;
  final Color upColor;
  final Color downColor;
  final Color gridColor;
  final Color labelColor;
  final int? selectedIndex;
  final String Function(double)? formatY;

  static const _overlayColors = {
    ChartIndicatorId.sma20: Color(0xFFFFB74D),
    ChartIndicatorId.sma50: Color(0xFF64B5F6),
    ChartIndicatorId.ema20: Color(0xFFCE93D8),
  };

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 52.0;
    const bottomPad = 18.0;
    const topPad = 8.0;
    final plot = Rect.fromLTWH(
      leftPad,
      topPad,
      math.max(0, size.width - leftPad - 8),
      math.max(0, size.height - topPad - bottomPad),
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    double yFor(double v) {
      final span = (maxY - minY) == 0 ? 1.0 : (maxY - minY);
      return plot.bottom - ((v - minY) / span) * plot.height;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final v in ticks) {
      final y = yFor(v);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    final tpStyle = TextStyle(fontSize: 10, color: labelColor);
    for (final v in ticks) {
      final label = formatY?.call(v) ?? v.toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(text: label, style: tpStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPad - 4);
      tp.paint(
          canvas, Offset(leftPad - 4 - tp.width, yFor(v) - tp.height / 2));
    }

    final n = candles.length;
    final slot = plot.width / n;
    for (var i = 0; i < n; i++) {
      final c = candles[i];
      final cx = plot.left + (i + 0.5) * slot;
      final bull = c.close >= c.open;
      final color = bull ? upColor : downColor;
      final wick = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, yFor(c.high)), Offset(cx, yFor(c.low)), wick);

      final bodyTop = math.min(yFor(c.open), yFor(c.close));
      final bodyBot = math.max(yFor(c.open), yFor(c.close));
      final bodyH = math.max(bodyBot - bodyTop, 1.5);
      final bodyW = math.max(slot * 0.5, 2.0).clamp(2.0, 14.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, (bodyTop + bodyBot) / 2),
            width: bodyW,
            height: bodyH,
          ),
          const Radius.circular(1),
        ),
        Paint()..color = color,
      );

      if (selectedIndex == i) {
        canvas.drawLine(
          Offset(cx, plot.top),
          Offset(cx, plot.bottom),
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..strokeWidth = 1,
        );
      }

      if ((c.xLabel ?? '').isNotEmpty &&
          (i == 0 || i == n - 1 || i % math.max(1, n ~/ 6) == 0)) {
        final tp = TextPainter(
          text: TextSpan(
            text: c.xLabel,
            style: TextStyle(fontSize: 10, color: labelColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, plot.bottom + 2));
      }
    }

    for (final entry in overlays.entries) {
      final color = _overlayColors[entry.key] ?? Colors.amber;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final path = Path();
      var started = false;
      for (var i = 0; i < entry.value.length; i++) {
        final v = entry.value[i];
        if (v == null || !v.isFinite) {
          started = false;
          continue;
        }
        final cx = plot.left + (i + 0.5) * slot;
        final cy = yFor(v);
        if (!started) {
          path.moveTo(cx, cy);
          started = true;
        } else {
          path.lineTo(cx, cy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CandleWithOverlayPainter old) =>
      old.candles != candles ||
      old.overlays != overlays ||
      old.selectedIndex != selectedIndex ||
      old.minY != minY ||
      old.maxY != maxY;
}

class _PanePainter extends CustomPainter {
  _PanePainter({
    required this.series,
    required this.colors,
    required this.minY,
    required this.maxY,
    required this.guideLines,
    required this.selectedIndex,
    required this.length,
    required this.gridColor,
    required this.labelColor,
    this.hist,
  });

  final Map<String, List<double?>> series;
  final Map<String, Color> colors;
  final List<double?>? hist;
  final double minY;
  final double maxY;
  final List<double> guideLines;
  final int? selectedIndex;
  final int length;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 52.0;
    const pad = 4.0;
    final plot = Rect.fromLTWH(
      leftPad,
      pad,
      math.max(0, size.width - leftPad - 8),
      math.max(0, size.height - pad * 2),
    );
    if (plot.width <= 0 || plot.height <= 0 || length == 0) return;

    double yFor(double v) {
      final span = (maxY - minY) == 0 ? 1.0 : (maxY - minY);
      return plot.bottom - ((v - minY) / span) * plot.height;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final g in guideLines) {
      canvas.drawLine(
        Offset(plot.left, yFor(g)),
        Offset(plot.right, yFor(g)),
        gridPaint,
      );
    }

    final slot = plot.width / length;

    if (hist != null) {
      for (var i = 0; i < hist!.length && i < length; i++) {
        final v = hist![i];
        if (v == null || !v.isFinite) continue;
        final cx = plot.left + (i + 0.5) * slot;
        final y0 = yFor(0);
        final y1 = yFor(v);
        canvas.drawRect(
          Rect.fromLTRB(cx - slot * 0.3, math.min(y0, y1), cx + slot * 0.3,
              math.max(y0, y1)),
          Paint()
            ..color = (v >= 0 ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.45),
        );
      }
    }

    for (final entry in series.entries) {
      final color = colors[entry.key] ?? Colors.blue;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      final path = Path();
      var started = false;
      for (var i = 0; i < entry.value.length && i < length; i++) {
        final v = entry.value[i];
        if (v == null || !v.isFinite) {
          started = false;
          continue;
        }
        final cx = plot.left + (i + 0.5) * slot;
        final cy = yFor(v);
        if (!started) {
          path.moveTo(cx, cy);
          started = true;
        } else {
          path.lineTo(cx, cy);
        }
      }
      canvas.drawPath(path, paint);
    }

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < length) {
      final cx = plot.left + (selectedIndex! + 0.5) * slot;
      canvas.drawLine(
        Offset(cx, plot.top),
        Offset(cx, plot.bottom),
        Paint()
          ..color = labelColor.withValues(alpha: 0.4)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PanePainter old) =>
      old.series != series ||
      old.hist != hist ||
      old.selectedIndex != selectedIndex ||
      old.minY != minY ||
      old.maxY != maxY;
}
