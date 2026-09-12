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

  /// Keep labels readable while maximizing plot radius inside the card.
  static double _labelPad(double side) => (side * 0.18).clamp(44.0, 58.0);

  void _onTapUp(TapUpDetails d) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        math.min(size.width, size.height) / 2 - _labelPad(size.shortestSide);
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
          fontWeight: FontWeight.w700,
          fontSize: 11,
          height: 1.12,
        );

    return Semantics(
      label: widget.semanticsLabel ?? 'Risk radar chart',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math
              .min(
                constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 260.0,
                constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 260.0,
              )
              .clamp(168.0, 320.0);

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
                          reduceMotion: _reduceMotion,
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
    required this.reduceMotion,
    this.labelStyle,
  });

  final List<RiskAxis> axes;
  final Color color;
  final double sweepAngle;
  final String? selectedAxisId;
  final String? focusAxisId;
  final double labelPad;
  final bool reduceMotion;
  final TextStyle? labelStyle;

  bool _idMatch(String? a, String id) =>
      a != null && a.toUpperCase() == id.toUpperCase();

  Color _axisColor(int i) => riskRadarAxisAccent(axes[i].id);

  @override
  void paint(Canvas canvas, Size size) {
    final n = axes.length;
    if (n < 3) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - labelPad;
    const gold = kRiskRadarPolygonGold;

    // Foreshortened pedestal stage (elliptical rings below plot center).
    final stage = Offset(center.dx, center.dy + radius * 0.1);
    canvas.drawOval(
      Rect.fromCenter(
        center: stage,
        width: radius * 1.88,
        height: radius * 0.58,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          stage,
          radius * 0.95,
          [
            gold.withValues(alpha: 0.16),
            gold.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          const [0.0, 0.5, 1.0],
        ),
    );
    for (var i = 0; i < 3; i++) {
      final t = 1.0 - i * 0.14;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(stage.dx, stage.dy + i * 2.0),
          width: radius * 1.78 * t,
          height: radius * 0.48 * t,
        ),
        Paint()
          ..color = gold.withValues(alpha: 0.26 - i * 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 0 ? 1.45 : 1.05,
      );
    }

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
          ..color = gold.withValues(alpha: ringI == 4 ? 0.4 : 0.12 + ringI * 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringI == 4 ? 1.5 : 1.0,
      );
    }

    for (var i = 0; i < n; i++) {
      final ac = _axisColor(i);
      final selected = _idMatch(selectedAxisId, axes[i].id);
      final focused = !selected && _idMatch(focusAxisId, axes[i].id);
      canvas.drawLine(
        center,
        pt(i, 1),
        Paint()
          ..color = ac.withValues(
            alpha: selected ? 0.7 : (focused ? 0.42 : 0.28),
          )
          ..strokeWidth = selected ? 2.1 : (focused ? 1.35 : 1.1),
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

    // Soft gold glow behind polygon.
    canvas.drawPath(
      data,
      Paint()
        ..color = gold.withValues(alpha: 0.22)
        ..maskFilter = reduceMotion
            ? null
            : const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      data,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius * 0.9,
          [
            gold.withValues(alpha: 0.42),
            gold.withValues(alpha: 0.12),
          ],
        ),
    );
    canvas.drawPath(
      data,
      Paint()
        ..color = gold.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      data,
      Paint()
        ..color = gold.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
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
            gold.withValues(alpha: 0.0),
            gold.withValues(alpha: 0.2),
            gold.withValues(alpha: 0.0),
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
        ..color = gold.withValues(alpha: 0.8)
        ..strokeWidth = 1.45
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < n; i++) {
      final ac = _axisColor(i);
      final selected = _idMatch(selectedAxisId, axes[i].id);
      final focused = !selected && _idMatch(focusAxisId, axes[i].id);
      final p = dataPts[i];
      final r = selected ? 6.2 : (focused ? 4.2 : 3.4);
      canvas.drawCircle(
        p,
        r + (selected ? 5 : 3),
        Paint()
          ..color = ac.withValues(alpha: selected ? 0.4 : (focused ? 0.22 : 0.1))
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 1.8 : 1.3,
      );
      canvas.drawCircle(p, r, Paint()..color = ac);
      if (selected) {
        canvas.drawCircle(
          p,
          r * 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }

    final style = labelStyle ??
        TextStyle(
          color: color.withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.12,
        );

    for (var i = 0; i < n; i++) {
      final ac = _axisColor(i);
      final selected = _idMatch(selectedAxisId, axes[i].id);
      final focused = !selected && _idMatch(focusAxisId, axes[i].id);
      final tipPt = pt(i, 1);
      final dir = Offset(tipPt.dx - center.dx, tipPt.dy - center.dy);
      final len = dir.distance;
      final unit = len > 0.1
          ? Offset(dir.dx / len, dir.dy / len)
          : const Offset(0, -1);

      final compact = riskRadarChartScoreLabel(axes[i].riskScore);
      final lines = riskRadarChartNameLines(axes[i]);
      final nameText = lines.line2.isEmpty
          ? '${lines.line1} $compact'
          : '${lines.line1}\n${lines.line2} $compact';
      final tp = TextPainter(
        text: TextSpan(
          text: nameText,
          style: style.copyWith(
            color: ac.withValues(
              alpha: selected ? 1.0 : (focused ? 0.95 : 0.85),
            ),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: math.max(96, labelPad + 28));

      // Push the text block fully past the tip so half the label does not
      // sit back on the spider. Uses existing labelPad / corner slack —
      // does not grow the card or shrink plot radius.
      const tipClearance = 8.0;
      final extentAlong =
          tp.width * unit.dx.abs() * 0.5 + tp.height * unit.dy.abs() * 0.5;
      // Prefer empty corners for left/right tips (slight upward bias).
      final cornerBias = switch (i % 4) {
        1 => const Offset(2, -5), // right
        3 => const Offset(-2, -5), // left
        0 => const Offset(0, -2), // top
        _ => const Offset(0, 2), // bottom
      };
      final anchor =
          tipPt + unit * (tipClearance + extentAlong) + cornerBias;
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
        oldDelegate.reduceMotion != reduceMotion ||
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
