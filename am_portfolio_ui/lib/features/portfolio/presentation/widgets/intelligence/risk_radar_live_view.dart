import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import 'risk_radar_math.dart';

/// Fixed flat live Risk Radar — full grid visible; no center popup.
class RiskRadarLiveView extends StatefulWidget {
  const RiskRadarLiveView({
    required this.axes,
    required this.color,
    this.selectedAxisId,
    this.focusAxisId,
    this.onAxisSelected,
    this.onSweepAxis,
    this.semanticsLabel,
    super.key,
  });

  final List<RiskAxis> axes;
  final Color color;
  final String? selectedAxisId;
  final String? focusAxisId;
  final ValueChanged<String?>? onAxisSelected;
  final ValueChanged<String>? onSweepAxis;
  final String? semanticsLabel;

  @override
  State<RiskRadarLiveView> createState() => _RiskRadarLiveViewState();
}

class _RiskRadarLiveViewState extends State<RiskRadarLiveView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;
  int? _lastSweepIndex;

  bool get _reduceMotion {
    final mq = MediaQuery.maybeOf(context);
    return mq?.disableAnimations == true;
  }

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (kRiskRadarSweepSeconds * 1000).round(),
      ),
    )..addListener(_onSweepTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSweep());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSweep();
  }

  void _syncSweep() {
    if (!mounted) return;
    final ticking = TickerMode.of(context);
    if (_reduceMotion || !ticking) {
      if (_sweep.isAnimating) _sweep.stop();
      return;
    }
    if (!_sweep.isAnimating) _sweep.repeat();
  }

  void _onSweepTick() {
    if (_reduceMotion) return;
    final n = widget.axes.length;
    if (n < 3) return;
    final angle = -math.pi / 2 + _sweep.value * 2 * math.pi;
    final idx = riskRadarSweepHitAxis(sweepAngle: angle, n: n);
    if (idx < 0 || idx == _lastSweepIndex) return;
    _lastSweepIndex = idx;
    widget.onSweepAxis?.call(widget.axes[idx].id);
  }

  @override
  void dispose() {
    _sweep.removeListener(_onSweepTick);
    _sweep.dispose();
    super.dispose();
  }

  double get _sweepAngle {
    if (_reduceMotion) {
      final focus = widget.selectedAxisId ?? widget.focusAxisId;
      if (focus != null) {
        final i = widget.axes.indexWhere(
          (a) => a.id.toUpperCase() == focus.toUpperCase(),
        );
        if (i >= 0) return riskRadarAxisAngle(i, widget.axes.length);
      }
      return -math.pi / 2;
    }
    return -math.pi / 2 + _sweep.value * 2 * math.pi;
  }

  static double _labelPad(double side) => (side * 0.18).clamp(38.0, 52.0);

  void _onTapUp(TapUpDetails d) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _labelPad(size.shortestSide);
    final idx = riskRadarHitTestFlat(
      local: d.localPosition,
      axes: widget.axes,
      center: center,
      radius: radius,
    );
    if (idx < 0) {
      widget.onAxisSelected?.call(null);
      return;
    }
    final id = widget.axes[idx].id;
    widget.onAxisSelected?.call(
      widget.selectedAxisId?.toUpperCase() == id.toUpperCase() ? null : id,
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncSweep();
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).hintColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        );

    return Semantics(
      label: widget.semanticsLabel ?? 'Risk radar chart',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math
              .min(
                constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 240.0,
                constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 240.0,
              )
              .clamp(168.0, 280.0);

          return SizedBox(
            width: side,
            height: side,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _onTapUp,
              child: ClipRect(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _sweep,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _RiskRadarLivePainter(
                          axes: widget.axes,
                          color: widget.color,
                          sweepAngle: _sweepAngle,
                          selectedAxisId: widget.selectedAxisId,
                          focusAxisId: widget.focusAxisId,
                          labelPad: _labelPad(side),
                          labelStyle: labelStyle,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RiskRadarLivePainter extends CustomPainter {
  _RiskRadarLivePainter({
    required this.axes,
    required this.color,
    required this.sweepAngle,
    required this.selectedAxisId,
    required this.focusAxisId,
    required this.labelPad,
    this.labelStyle,
  });

  final List<RiskAxis> axes;
  final Color color;
  final double sweepAngle;
  final String? selectedAxisId;
  final String? focusAxisId;
  final double labelPad;
  final TextStyle? labelStyle;

  bool _idMatch(String? a, String id) =>
      a != null && a.toUpperCase() == id.toUpperCase();

  @override
  void paint(Canvas canvas, Size size) {
    final n = axes.length;
    if (n < 3) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - labelPad;

    canvas.drawCircle(
      center,
      radius * 1.06,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius * 1.06,
          [
            color.withValues(alpha: 0.07),
            Colors.transparent,
          ],
        ),
    );

    Offset pt(int i, double frac) => riskRadarFlatPoint(
          center: center,
          radius: radius,
          angle: riskRadarAxisAngle(i, n),
          radiusFraction: frac,
        );

    Path ring(double frac) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = pt(i, frac);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      return path;
    }

    for (var ringI = 1; ringI <= 4; ringI++) {
      final frac = ringI / 4;
      canvas.drawPath(
        ring(frac),
        Paint()
          ..color =
              color.withValues(alpha: ringI == 4 ? 0.55 : 0.16 + ringI * 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringI == 4 ? 1.6 : 1.05,
      );
    }

    for (var i = 0; i < n; i++) {
      canvas.drawLine(
        center,
        pt(i, 1),
        Paint()
          ..color = color.withValues(alpha: 0.28)
          ..strokeWidth = 1.1,
      );
    }

    final data = Path();
    final dataPts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final p = pt(i, riskRadarVisualT(axes[i].riskScore));
      dataPts.add(p);
      if (i == 0) {
        data.moveTo(p.dx, p.dy);
      } else {
        data.lineTo(p.dx, p.dy);
      }
    }
    data.close();
    canvas.drawPath(
      data,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius * 0.9,
          [
            color.withValues(alpha: 0.38),
            color.withValues(alpha: 0.12),
          ],
        ),
    );
    canvas.drawPath(
      data,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      data,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeJoin = StrokeJoin.round,
    );

    // Soft sweep (no center text overlay).
    final sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        sweepAngle - kRiskRadarSweepHalfWidth,
        kRiskRadarSweepHalfWidth * 2,
        false,
      )
      ..close();
    canvas.drawPath(
      sweepPath,
      Paint()
        ..shader = ui.Gradient.sweep(
          center,
          [
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.0),
          ],
          const [0.0, 0.5, 1.0],
          TileMode.clamp,
          sweepAngle - kRiskRadarSweepHalfWidth,
          sweepAngle + kRiskRadarSweepHalfWidth,
        ),
    );
    final tip = Offset(
      center.dx + radius * math.cos(sweepAngle),
      center.dy + radius * math.sin(sweepAngle),
    );
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..strokeWidth = 1.45
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < n; i++) {
      final selected = _idMatch(selectedAxisId, axes[i].id);
      final focused = _idMatch(focusAxisId, axes[i].id);
      final active = selected || focused;
      final p = dataPts[i];
      final r = selected ? 5.5 : (focused ? 4.4 : 3.3);
      canvas.drawCircle(
        p,
        r + 3,
        Paint()
          ..color = color.withValues(alpha: active ? 0.28 : 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      canvas.drawCircle(p, r, Paint()..color = color);
      canvas.drawLine(
        p,
        pt(i, 1),
        Paint()
          ..color = color.withValues(alpha: active ? 0.35 : 0.12)
          ..strokeWidth = 1,
      );
    }

    final style = labelStyle ??
        TextStyle(
          color: color.withValues(alpha: 0.85),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        );

    // Axis labels outside the diamond, fully inside the canvas.
    for (var i = 0; i < n; i++) {
      final selected = _idMatch(selectedAxisId, axes[i].id);
      final focused = _idMatch(focusAxisId, axes[i].id);
      final tipPt = pt(i, 1);
      final dir = Offset(tipPt.dx - center.dx, tipPt.dy - center.dy);
      final len = dir.distance;
      final unit = len > 0.1
          ? Offset(dir.dx / len, dir.dy / len)
          : const Offset(0, -1);

      final tp = TextPainter(
        text: TextSpan(
          text: riskRadarAxisLabel(axes[i]),
          style: style.copyWith(
            color: (style.color ?? color).withValues(
              alpha: selected || focused ? 1.0 : 0.8,
            ),
            fontWeight:
                selected || focused ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: labelPad + 20);

      // Place label in the margin between rim and canvas edge.
      final gap = (labelPad - tp.height) * 0.45;
      final anchor = tipPt + unit * (8 + gap);
      var dx = anchor.dx - tp.width / 2;
      var dy = anchor.dy - tp.height / 2;
      const edge = 2.0;
      dx = dx.clamp(edge, size.width - tp.width - edge);
      dy = dy.clamp(edge, size.height - tp.height - edge);
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _RiskRadarLivePainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.selectedAxisId != selectedAxisId ||
        oldDelegate.focusAxisId != focusAxisId ||
        oldDelegate.labelPad != labelPad ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.axes.length != axes.length) {
      return true;
    }
    for (var i = 0; i < axes.length; i++) {
      if (oldDelegate.axes[i].id != axes[i].id ||
          oldDelegate.axes[i].riskScore != axes[i].riskScore) {
        return true;
      }
    }
    return false;
  }
}
