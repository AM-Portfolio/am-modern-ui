import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'chart_axis_scale.dart';
import 'chart_types.dart';

/// Interactive OHLC candle chart (custom paint — fl_chart has no candlestick).
class CandleChartView extends StatefulWidget {
  final List<CommonCandlePoint> candles;
  final CommonChartConfig config;
  final Color upColor;
  final Color downColor;

  const CandleChartView({
    super.key,
    required this.candles,
    required this.config,
    this.upColor = AppColors.success,
    this.downColor = AppColors.error,
  });

  @override
  State<CandleChartView> createState() => _CandleChartViewState();
}

class _CandleChartViewState extends State<CandleChartView> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candles = widget.candles.where((c) => !c.close.isNaN).toList();
    if (candles.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final lowsHighs = <double>[];
    for (final c in candles) {
      lowsHighs.addAll([c.open, c.high, c.low, c.close]);
    }
    final axis = ChartAxisScale.fromValues(lowsHighs);
    // Always use one scale for bounds AND ticks so 1W/1M candles are not
    // plotted on an expanded range while labels stay on the tight crop.
    final minY = axis.minY;
    final maxY = axis.maxY;
    final ticks = axis.ticks;

    final selected = _selected != null && _selected! >= 0 && _selected! < candles.length
        ? candles[_selected!]
        : null;

    return Column(
      children: [
        if (widget.config.showTooltips && selected != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${selected.xLabel ?? ''}  O ${_fmt(selected.open)}  H ${_fmt(selected.high)}  L ${_fmt(selected.low)}  C ${_fmt(selected.close)}',
              style: TextStyle(fontSize: 11, color: theme.hintColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (d) => _selectAt(d.localPosition, constraints.biggest, candles),
                onHorizontalDragUpdate: (d) =>
                    _selectAt(d.localPosition, constraints.biggest, candles),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _CandlePainter(
                    candles: candles,
                    minY: minY,
                    maxY: maxY,
                    ticks: ticks,
                    upColor: widget.upColor,
                    downColor: widget.downColor,
                    gridColor: theme.dividerColor.withValues(alpha: 0.2),
                    labelColor: theme.hintColor,
                    selectedIndex: _selected,
                    formatY: widget.config.formatYLabel ?? axis.format,
                    showGrid: widget.config.showGrid,
                    showTitles: widget.config.showTitles,
                  ),
                ),
              );
            },
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

  static String _fmt(double v) {
    if (v.abs() >= 1000) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}

class _CandlePainter extends CustomPainter {
  final List<CommonCandlePoint> candles;
  final double minY;
  final double maxY;
  final List<double> ticks;
  final Color upColor;
  final Color downColor;
  final Color gridColor;
  final Color labelColor;
  final int? selectedIndex;
  final String Function(double)? formatY;
  final bool showGrid;
  final bool showTitles;

  _CandlePainter({
    required this.candles,
    required this.minY,
    required this.maxY,
    required this.ticks,
    required this.upColor,
    required this.downColor,
    required this.gridColor,
    required this.labelColor,
    required this.selectedIndex,
    required this.formatY,
    required this.showGrid,
    required this.showTitles,
  });

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
    if (showGrid) {
      for (final v in ticks) {
        final y = yFor(v);
        canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      }
    }

    if (showTitles) {
      final tpStyle = TextStyle(fontSize: 10, color: labelColor);
      for (final v in ticks) {
        final label = formatY?.call(v) ?? v.toStringAsFixed(0);
        final tp = TextPainter(
          text: TextSpan(text: label, style: tpStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: leftPad - 4);
        tp.paint(canvas, Offset(leftPad - 4 - tp.width, yFor(v) - tp.height / 2));
      }
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

      if (showTitles && (c.xLabel ?? '').isNotEmpty) {
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
  }

  @override
  bool shouldRepaint(covariant _CandlePainter old) =>
      old.candles != candles ||
      old.selectedIndex != selectedIndex ||
      old.minY != minY ||
      old.maxY != maxY ||
      old.ticks != ticks;
}
