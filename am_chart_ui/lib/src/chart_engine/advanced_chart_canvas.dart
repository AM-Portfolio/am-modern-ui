import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../chart_types/chart_type_id.dart';
import '../providers/chart_models.dart';

class ChartViewport {
  const ChartViewport({
    required this.startIndex,
    required this.endIndex,
    required this.minPrice,
    required this.maxPrice,
  });

  final int startIndex;
  final int endIndex;
  final double minPrice;
  final double maxPrice;

  int get barCount => math.max(1, endIndex - startIndex + 1);
}

/// Interactive OHLC chart surface for Phase 1 chart types.
class AdvancedChartCanvas extends StatefulWidget {
  const AdvancedChartCanvas({
    super.key,
    required this.bars,
    required this.chartType,
    this.isMock = false,
    this.onCrosshair,
    this.externalCrosshairTime,
    this.panZoomEnabled = true,
    this.onNeedOlderHistory,
    this.viewEpoch = 0,
  });

  final List<ChartBar> bars;
  final ChartTypeId chartType;
  final bool isMock;
  final void Function(ChartBar? bar)? onCrosshair;

  /// Synced multi-pane crosshair: show nearest bar at this time when not locally hovering.
  final DateTime? externalCrosshairTime;

  /// When false, pointer drag does not pan (drawing tools own the gestures).
  final bool panZoomEnabled;

  /// Fired when wheel/pan requests older data past the left edge of loaded bars.
  final VoidCallback? onNeedOlderHistory;

  /// Increment to reset zoom/pan (Fit).
  final int viewEpoch;

  @override
  State<AdvancedChartCanvas> createState() => _AdvancedChartCanvasState();
}

class _AdvancedChartCanvasState extends State<AdvancedChartCanvas> {
  double _zoom = 1.0;
  double _pan = 0;
  int? _localHoverIndex;
  Offset? _dragOrigin;
  double _panAtDragStart = 0;

  int? get _displayHoverIndex {
    if (_localHoverIndex != null) return _localHoverIndex;
    final ext = widget.externalCrosshairTime;
    if (ext == null) return null;
    return _nearestIndexForTime(ext);
  }

  @override
  void didUpdateWidget(covariant AdvancedChartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewEpoch != widget.viewEpoch) {
      _zoom = 1.0;
      _pan = 0;
    }
  }

  int? _nearestIndexForTime(DateTime time) {
    final bars = widget.bars;
    if (bars.isEmpty) return null;
    var best = 0;
    var bestDelta = (bars[0].time.difference(time)).abs();
    for (var i = 1; i < bars.length; i++) {
      final d = (bars[i].time.difference(time)).abs();
      if (d < bestDelta) {
        bestDelta = d;
        best = i;
      }
    }
    return best;
  }

  void _clearLocalHover() {
    if (_localHoverIndex == null) return;
    setState(() => _localHoverIndex = null);
    widget.onCrosshair?.call(null);
  }

  bool get _ctrlPressed =>
      HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isMetaPressed;

  void _onScroll(PointerScrollEvent e) {
    if (!widget.panZoomEnabled) return;
    if (_ctrlPressed) {
      setState(() {
        final delta = e.scrollDelta.dy > 0 ? 0.92 : 1.08;
        _zoom = (_zoom * delta).clamp(0.4, 8.0);
      });
      return;
    }

    // Wheel pans X: scroll down → older (left), up → newer (right).
    final n = widget.bars.length;
    final visible = _visibleCount(n);
    final maxStart = math.max(0, n - visible);
    final startBefore = _startIndex(n, visible);
    final panDelta =
        -e.scrollDelta.dy; // invert: down dy>0 → older → decrease start
    setState(() {
      _pan += panDelta;
    });
    final startAfter = _startIndex(n, visible);
    if (startBefore <= 0 && startAfter <= 0 && e.scrollDelta.dy > 0) {
      widget.onNeedOlderHistory?.call();
    } else if (maxStart > 0 && startBefore == 0 && e.scrollDelta.dy > 0) {
      widget.onNeedOlderHistory?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.bars.isEmpty) {
      return const Center(child: Text('No chart data'));
    }

    final hover = _displayHoverIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onExit: (_) => _clearLocalHover(),
          child: Stack(
            children: [
              // Pointer-only gestures — avoid GestureDetector pan+scale assert.
              Listener(
                onPointerHover: (e) =>
                    _updateHover(e.localPosition, constraints.biggest),
                onPointerSignal: (e) {
                  if (e is PointerScrollEvent) _onScroll(e);
                },
                onPointerDown: (e) {
                  if (!widget.panZoomEnabled) return;
                  _dragOrigin = e.localPosition;
                  _panAtDragStart = _pan;
                  _updateHover(e.localPosition, constraints.biggest);
                },
                onPointerMove: (e) {
                  _updateHover(e.localPosition, constraints.biggest);
                  if (!widget.panZoomEnabled) return;
                  final origin = _dragOrigin;
                  if (origin == null) return;
                  final n = widget.bars.length;
                  final visible = _visibleCount(n);
                  final startBefore = _startIndex(n, visible);
                  setState(() {
                    _pan = _panAtDragStart + (e.localPosition.dx - origin.dx);
                  });
                  final startAfter = _startIndex(n, visible);
                  if (startBefore <= 0 &&
                      startAfter <= 0 &&
                      e.localPosition.dx > origin.dx) {
                    widget.onNeedOlderHistory?.call();
                  }
                },
                onPointerUp: (_) => _dragOrigin = null,
                onPointerCancel: (_) => _dragOrigin = null,
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _ChartPainter(
                    bars: widget.bars,
                    chartType: widget.chartType,
                    zoom: _zoom,
                    pan: _pan,
                    hoverIndex: hover,
                    gridColor: theme.dividerColor.withValues(alpha: 0.25),
                    labelColor: theme.hintColor,
                    upColor: const Color(0xFF26A69A),
                    downColor: const Color(0xFFEF5350),
                    accent: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (widget.isMock)
                Positioned(
                  left: 12,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'MOCK DATA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              if (hover != null && hover >= 0 && hover < widget.bars.length)
                Positioned(
                  right: 12,
                  top: 8,
                  child: _OhlcBadge(bar: widget.bars[hover]),
                ),
            ],
          ),
        );
      },
    );
  }

  void _updateHover(Offset pos, Size size) {
    // Price scale is on the right — plot starts flush on the left.
    const left = 8.0;
    const right = 56.0;
    final plotW = size.width - left - right;
    if (plotW <= 0 || widget.bars.isEmpty) return;
    final visible = _visibleCount(widget.bars.length);
    final start = _startIndex(widget.bars.length, visible);
    final t = ((pos.dx - left) / plotW).clamp(0.0, 0.999);
    final idx = (start + t * visible).floor().clamp(0, widget.bars.length - 1);
    if (_localHoverIndex != idx) {
      setState(() => _localHoverIndex = idx);
      widget.onCrosshair?.call(widget.bars[idx]);
    }
  }

  int _visibleCount(int n) {
    final base = math.min(n, 80);
    return math.max(10, (base / _zoom).round()).clamp(10, n);
  }

  int _startIndex(int n, int visible) {
    final maxStart = math.max(0, n - visible);
    final shift = (-_pan / 8).round();
    return (maxStart + shift).clamp(0, maxStart);
  }
}

class _OhlcBadge extends StatelessWidget {
  const _OhlcBadge({required this.bar});
  final ChartBar bar;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM HH:mm');
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.dividerColor),
      ),
      child: DefaultTextStyle(
        style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fmt.format(bar.time),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('O ${bar.open.toStringAsFixed(2)}'),
            Text('H ${bar.high.toStringAsFixed(2)}'),
            Text('L ${bar.low.toStringAsFixed(2)}'),
            Text('C ${bar.close.toStringAsFixed(2)}'),
            Text('V ${bar.volume.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.bars,
    required this.chartType,
    required this.zoom,
    required this.pan,
    required this.hoverIndex,
    required this.gridColor,
    required this.labelColor,
    required this.upColor,
    required this.downColor,
    required this.accent,
  });

  final List<ChartBar> bars;
  final ChartTypeId chartType;
  final double zoom;
  final double pan;
  final int? hoverIndex;
  final Color gridColor;
  final Color labelColor;
  final Color upColor;
  final Color downColor;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Left flush (shared tools rail owns the workspace left); price scale right.
    const left = 8.0;
    const right = 56.0;
    const bottom = 22.0;
    const top = 8.0;
    final plot = Rect.fromLTWH(
      left,
      top,
      math.max(0, size.width - left - right),
      math.max(0, size.height - top - bottom),
    );
    if (plot.width <= 0 || plot.height <= 0 || bars.isEmpty) return;

    final visible = math
        .max(10, (math.min(bars.length, 80) / zoom).round())
        .clamp(10, bars.length);
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

    double yFor(double p) =>
        plot.bottom - ((p - minP) / (maxP - minP)) * plot.height;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      final price = maxP - (maxP - minP) * i / 4;
      final tp = TextPainter(
        text: TextSpan(
          text: price.toStringAsFixed(price >= 1000 ? 0 : 2),
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: right - 4);
      tp.paint(canvas, Offset(plot.right + 4, y - tp.height / 2));
    }

    final slot = plot.width / slice.length;
    final last = slice.last.close;
    final priceLine = Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(plot.left, yFor(last)),
      Offset(plot.right, yFor(last)),
      priceLine,
    );

    switch (chartType) {
      case ChartTypeId.line:
      case ChartTypeId.area:
      case ChartTypeId.baseline:
        _paintLine(
          canvas,
          plot,
          slice,
          slot,
          yFor,
          fill: chartType != ChartTypeId.line,
        );
        break;
      case ChartTypeId.columns:
        _paintColumns(canvas, plot, slice, slot, yFor);
        break;
      case ChartTypeId.ohlcBar:
        _paintOhlc(canvas, plot, slice, slot, yFor);
        break;
      case ChartTypeId.hollowCandle:
        _paintCandles(canvas, plot, slice, slot, yFor, hollow: true);
        break;
      case ChartTypeId.candlestick:
      case ChartTypeId.heikinAshi:
      case ChartTypeId.volumeCandles:
      case ChartTypeId.highLow:
      case ChartTypeId.hlcArea:
      case ChartTypeId.renko:
      case ChartTypeId.range:
      case ChartTypeId.kagi:
      case ChartTypeId.pointFigure:
      case ChartTypeId.lineBreak:
      case ChartTypeId.footprint:
      case ChartTypeId.tpo:
      case ChartTypeId.volumeProfile:
        _paintCandles(canvas, plot, slice, slot, yFor, hollow: false);
        break;
    }

    if (hoverIndex != null && hoverIndex! >= start && hoverIndex! <= end) {
      final i = hoverIndex! - start;
      final cx = plot.left + (i + 0.5) * slot;
      canvas.drawLine(
        Offset(cx, plot.top),
        Offset(cx, plot.bottom),
        Paint()
          ..color = accent.withValues(alpha: 0.45)
          ..strokeWidth = 1,
      );
    }

    // X labels
    final fmt = DateFormat('HH:mm');
    final step = math.max(1, slice.length ~/ 6);
    for (var i = 0; i < slice.length; i += step) {
      final cx = plot.left + (i + 0.5) * slot;
      final tp = TextPainter(
        text: TextSpan(
          text: fmt.format(slice[i].time),
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, plot.bottom + 4));
    }
  }

  void _paintCandles(
    Canvas canvas,
    Rect plot,
    List<ChartBar> slice,
    double slot,
    double Function(double) yFor, {
    required bool hollow,
  }) {
    for (var i = 0; i < slice.length; i++) {
      final b = slice[i];
      final cx = plot.left + (i + 0.5) * slot;
      final bull = b.close >= b.open;
      final color = bull ? upColor : downColor;
      canvas.drawLine(
        Offset(cx, yFor(b.high)),
        Offset(cx, yFor(b.low)),
        Paint()
          ..color = color
          ..strokeWidth = 1.2,
      );
      final top = math.min(yFor(b.open), yFor(b.close));
      final bot = math.max(yFor(b.open), yFor(b.close));
      final w = math.max(slot * 0.55, 2.0).clamp(2.0, 14.0);
      final rect = Rect.fromCenter(
        center: Offset(cx, (top + bot) / 2),
        width: w,
        height: math.max(bot - top, 1.5),
      );
      if (hollow && bull) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      } else {
        canvas.drawRect(rect, Paint()..color = color);
      }
    }
  }

  void _paintOhlc(
    Canvas canvas,
    Rect plot,
    List<ChartBar> slice,
    double slot,
    double Function(double) yFor,
  ) {
    for (var i = 0; i < slice.length; i++) {
      final b = slice[i];
      final cx = plot.left + (i + 0.5) * slot;
      final color = b.close >= b.open ? upColor : downColor;
      final p = Paint()
        ..color = color
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, yFor(b.high)), Offset(cx, yFor(b.low)), p);
      canvas.drawLine(
        Offset(cx - slot * 0.25, yFor(b.open)),
        Offset(cx, yFor(b.open)),
        p,
      );
      canvas.drawLine(
        Offset(cx, yFor(b.close)),
        Offset(cx + slot * 0.25, yFor(b.close)),
        p,
      );
    }
  }

  void _paintLine(
    Canvas canvas,
    Rect plot,
    List<ChartBar> slice,
    double slot,
    double Function(double) yFor, {
    required bool fill,
  }) {
    final path = Path();
    for (var i = 0; i < slice.length; i++) {
      final cx = plot.left + (i + 0.5) * slot;
      final cy = yFor(slice[i].close);
      if (i == 0) {
        path.moveTo(cx, cy);
      } else {
        path.lineTo(cx, cy);
      }
    }
    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(plot.left + (slice.length - 0.5) * slot, plot.bottom)
        ..lineTo(plot.left + 0.5 * slot, plot.bottom)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(plot.left, plot.top),
            Offset(plot.left, plot.bottom),
            [accent.withValues(alpha: 0.35), accent.withValues(alpha: 0.02)],
          ),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintColumns(
    Canvas canvas,
    Rect plot,
    List<ChartBar> slice,
    double slot,
    double Function(double) yFor,
  ) {
    for (var i = 0; i < slice.length; i++) {
      final b = slice[i];
      final cx = plot.left + (i + 0.5) * slot;
      final color = b.close >= b.open ? upColor : downColor;
      final y0 = yFor(b.open);
      final y1 = yFor(b.close);
      canvas.drawRect(
        Rect.fromLTRB(
          cx - slot * 0.3,
          math.min(y0, y1),
          cx + slot * 0.3,
          math.max(y0, y1),
        ),
        Paint()..color = color.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.bars != bars ||
      old.chartType != chartType ||
      old.zoom != zoom ||
      old.pan != pan ||
      old.hoverIndex != hoverIndex;
}
