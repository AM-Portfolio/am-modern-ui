import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
    this.zoomEpoch = 0,
    this.zoomDelta = 1.0,
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

  /// Increment to trigger animated zoom in/out transition.
  final int zoomEpoch;

  /// Multiplier to apply to zoom on [zoomEpoch] change.
  final double zoomDelta;

  @override
  State<AdvancedChartCanvas> createState() => _AdvancedChartCanvasState();
}

class _AdvancedChartCanvasState extends State<AdvancedChartCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zoomAnimCtrl;
  Animation<double>? _zoomAnim;

  double _zoom = 1.0;
  double _pan = 0;
  int? _localHoverIndex;
  double _scaleStartZoom = 1.0;
  Offset _lastFocalPoint = Offset.zero;
  int _lastPointerCount = 0;

  int? get _displayHoverIndex {
    if (_localHoverIndex != null) return _localHoverIndex;
    final ext = widget.externalCrosshairTime;
    if (ext == null) return null;
    return _nearestIndexForTime(ext);
  }

  @override
  void initState() {
    super.initState();
    _zoomAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (_zoomAnim != null) {
          setState(() {
            _zoom = _zoomAnim!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _zoomAnimCtrl.dispose();
    super.dispose();
  }

  void _animateZoomTo(double targetZoom) {
    final clamped = targetZoom.clamp(0.2, 10.0);
    _zoomAnim = Tween<double>(
      begin: _zoom,
      end: clamped,
    ).animate(CurvedAnimation(
      parent: _zoomAnimCtrl,
      curve: Curves.easeOutCubic,
    ));
    _zoomAnimCtrl.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant AdvancedChartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewEpoch != widget.viewEpoch) {
      _animateZoomTo(1.0);
      setState(() => _pan = 0);
    } else if (oldWidget.zoomEpoch != widget.zoomEpoch &&
        widget.zoomEpoch > 0) {
      _animateZoomTo(_zoom * widget.zoomDelta);
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

  void _onScroll(PointerScrollEvent e) {
    if (!widget.panZoomEnabled) return;
    // Mouse wheel or trackpad scroll directly zooms in and out
    final factor = e.scrollDelta.dy < 0 ? 1.15 : 0.87;
    _animateZoomTo(_zoom * factor);
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
              Listener(
                onPointerHover: (e) =>
                    _updateHover(e.localPosition, constraints.biggest),
                onPointerSignal: (e) {
                  if (e is PointerScrollEvent) _onScroll(e);
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTapDown: (details) {
                    if (!widget.panZoomEnabled) return;
                    // Double-tap fingertip transition to zoom in or reset
                    final target = _zoom > 1.4 ? 1.0 : 2.2;
                    _animateZoomTo(target);
                  },
                  onScaleStart: (details) {
                    if (!widget.panZoomEnabled) return;
                    _zoomAnimCtrl.stop();
                    _scaleStartZoom = _zoom;
                    _lastFocalPoint = details.localFocalPoint;
                    _lastPointerCount = details.pointerCount;
                    _updateHover(details.localFocalPoint, constraints.biggest);
                  },
                  onScaleUpdate: (details) {
                    if (!widget.panZoomEnabled) return;
                    _updateHover(details.localFocalPoint, constraints.biggest);

                    if (details.pointerCount != _lastPointerCount) {
                      _scaleStartZoom = _zoom;
                      _lastFocalPoint = details.localFocalPoint;
                      _lastPointerCount = details.pointerCount;
                      return;
                    }

                    if (details.pointerCount >= 2 ||
                        (details.scale - 1.0).abs() > 0.05) {
                      // Fingertip pinch zoom in and zoom out
                      final targetZoom =
                          (_scaleStartZoom * details.scale).clamp(0.2, 10.0);
                      setState(() {
                        _zoom = targetZoom;
                      });
                    } else {
                      // Single fingertip horizontal pan along timeline
                      final dx =
                          details.localFocalPoint.dx - _lastFocalPoint.dx;
                      final n = widget.bars.length;
                      final visible = _visibleCount(n);
                      final startBefore = _startIndex(n, visible);
                      setState(() {
                        _pan += dx;
                      });
                      final startAfter = _startIndex(n, visible);
                      if (startBefore <= 0 && startAfter <= 0 && dx > 0) {
                        widget.onNeedOlderHistory?.call();
                      }
                    }
                    _lastFocalPoint = details.localFocalPoint;
                  },
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
                      upColor: context.marketPositive,
                      downColor: context.marketNegative,
                      accent: theme.colorScheme.primary,
                      badgeBackground: theme.colorScheme.inverseSurface,
                      badgeForeground: theme.colorScheme.onInverseSurface,
                    ),
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
                      color: context.statusWarning.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'MOCK DATA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.colors.actionPrimaryFg,
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
    final base = math.min(n, 36);
    return math.max(4, (base / _zoom).round()).clamp(4, n);
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
    final isDaily = bar.time.hour == 0 && bar.time.minute == 0;
    final fmt = isDaily
        ? DateFormat('dd MMM yyyy')
        : DateFormat('dd MMM HH:mm');
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
    required this.badgeBackground,
    required this.badgeForeground,
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
  final Color badgeBackground;
  final Color badgeForeground;

  @override
  void paint(Canvas canvas, Size size) {
    // Left flush (shared tools rail owns the workspace left); price scale right.
    const left = 8.0;
    const right = 56.0;
    const bottom = 24.0;
    const top = 8.0;
    final plot = Rect.fromLTWH(
      left,
      top,
      math.max(0, size.width - left - right),
      math.max(0, size.height - top - bottom),
    );
    if (plot.width <= 0 || plot.height <= 0 || bars.isEmpty) return;

    final defaultBase = math.min(bars.length, 36);
    final visible = math
        .max(4, (defaultBase / zoom).round())
        .clamp(4, bars.length);
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

    final totalSpan = slice.isNotEmpty
        ? slice.last.time.difference(slice.first.time).abs()
        : Duration.zero;
    final allZeroTime =
        slice.every((b) => b.time.hour == 0 && b.time.minute == 0);

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

      final hoverBar = slice[i];
      final isDaily = hoverBar.time.hour == 0 && hoverBar.time.minute == 0;
      final hoverTimeStr = isDaily
          ? DateFormat('d MMM yyyy').format(hoverBar.time)
          : (totalSpan.inDays > 1
              ? DateFormat('d MMM HH:mm').format(hoverBar.time)
              : DateFormat('HH:mm').format(hoverBar.time));

      final hoverTp = TextPainter(
        text: TextSpan(
          text: hoverTimeStr,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: badgeForeground,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final badgeW = hoverTp.width + 10;
      final badgeH = hoverTp.height + 4;
      final badgeX = (cx - badgeW / 2).clamp(plot.left, plot.right - badgeW);
      final badgeY = plot.bottom + 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
          const Radius.circular(3),
        ),
        Paint()..color = badgeBackground,
      );
      hoverTp.paint(canvas, Offset(badgeX + 5, badgeY + 2));
    }

    // X labels (smart format based on timeframe & date range)
    final step = math.max(1, slice.length ~/ 6);
    for (var i = 0; i < slice.length; i += step) {
      final cx = plot.left + (i + 0.5) * slot;
      final barTime = slice[i].time;
      final String labelStr;
      if (allZeroTime || totalSpan.inDays > 1) {
        if (totalSpan.inDays > 365) {
          labelStr = DateFormat('MMM yy').format(barTime);
        } else if (totalSpan.inDays > 60) {
          labelStr = DateFormat('MMM d').format(barTime);
        } else {
          labelStr = DateFormat('d MMM').format(barTime);
        }
      } else {
        labelStr = DateFormat('HH:mm').format(barTime);
      }

      final tp = TextPainter(
        text: TextSpan(
          text: labelStr,
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
    final wickW = (slot * 0.08).clamp(1.0, 3.0);
    final bodyW = (slot * 0.72).clamp(2.0, 48.0);
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
          ..strokeWidth = wickW,
      );
      final top = math.min(yFor(b.open), yFor(b.close));
      final bot = math.max(yFor(b.open), yFor(b.close));
      final rect = Rect.fromCenter(
        center: Offset(cx, (top + bot) / 2),
        width: bodyW,
        height: math.max(bot - top, 1.5),
      );
      if (hollow && bull) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = wickW,
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
    final barW = (slot * 0.08).clamp(1.0, 3.0);
    final tickW = (slot * 0.32).clamp(2.0, 20.0);
    for (var i = 0; i < slice.length; i++) {
      final b = slice[i];
      final cx = plot.left + (i + 0.5) * slot;
      final color = b.close >= b.open ? upColor : downColor;
      final p = Paint()
        ..color = color
        ..strokeWidth = barW
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, yFor(b.high)), Offset(cx, yFor(b.low)), p);
      canvas.drawLine(
        Offset(cx - tickW, yFor(b.open)),
        Offset(cx, yFor(b.open)),
        p,
      );
      canvas.drawLine(
        Offset(cx, yFor(b.close)),
        Offset(cx + tickW, yFor(b.close)),
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
    final colW = (slot * 0.72).clamp(2.0, 48.0);
    for (var i = 0; i < slice.length; i++) {
      final b = slice[i];
      final cx = plot.left + (i + 0.5) * slot;
      final color = b.close >= b.open ? upColor : downColor;
      final y0 = yFor(b.open);
      final y1 = yFor(b.close);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, (y0 + y1) / 2),
          width: colW,
          height: math.max((y1 - y0).abs(), 1.5),
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
