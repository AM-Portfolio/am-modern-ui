import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:am_design_system/core/module/module_color_provider.dart';
import 'package:am_design_system/core/theme/app_radii.dart';
import 'package:am_design_system/core/theme/app_spacing.dart';
import 'package:am_design_system/core/theme/app_type_scale.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

typedef AmValueFormatter = String Function(double value);

/// A compact theme-aware numeric meter with an optional flame thumb.
///
/// The marker is the value pointer. Its center and the active fill endpoint
/// use the same clamped position, which prevents a gap at very small values.
class AmValueMeter extends StatefulWidget {
  const AmValueMeter({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    this.suffix = '',
    this.accentColor,
    this.showFlame = true,
    this.showSurface = true,
    this.valueFormatter,
    this.semanticLabel,
  }) : assert(maxValue > 0);

  final double value;
  final double maxValue;
  final String label;
  final String suffix;
  final Color? accentColor;
  final bool showFlame;

  /// Renders only the meter content when the parent surface owns the chrome.
  final bool showSurface;
  final AmValueFormatter? valueFormatter;
  final String? semanticLabel;

  @override
  State<AmValueMeter> createState() => _AmValueMeterState();
}

class _AmValueMeterState extends State<AmValueMeter>
    with SingleTickerProviderStateMixin {
  static const _trackHeight = 5.0;
  static const _markerSize = 32.0;
  static const _markerRadius = _markerSize / 2;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AmValueMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showFlame != widget.showFlame) _syncAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _syncAnimation() {
    if (!widget.showFlame ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      _animationController.stop();
      return;
    }
    if (!_animationController.isAnimating) {
      _animationController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = widget.accentColor ??
        ModuleColorProvider.maybeOf(context) ??
        Theme.of(context).colorScheme.primary;
    final maxValue =
        widget.maxValue.isFinite && widget.maxValue > 0 ? widget.maxValue : 1.0;
    final safeValue =
        widget.value.isFinite ? math.max(0.0, widget.value).toDouble() : 0.0;
    final progress = (safeValue / maxValue).clamp(0.0, 1.0);
    final displayValue =
        widget.valueFormatter?.call(safeValue) ?? _formatValue(safeValue);
    final semanticValue =
        '${widget.semanticLabel ?? widget.label}: $displayValue${widget.suffix}';
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      container: true,
      label: semanticValue,
      value: safeValue > maxValue
          ? '$displayValue${widget.suffix}, above the displayed scale'
          : '$displayValue${widget.suffix}',
      child: Container(
        padding: widget.showSurface
            ? const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm + 4,
                AppSpacing.md,
                AppSpacing.sm + 2,
              )
            : EdgeInsets.zero,
        decoration: widget.showSurface
            ? BoxDecoration(
                color: colors.cardSurface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: colors.border),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: AppTypeScale.sm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Text(
                  '$displayValue${widget.suffix}',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: AppTypeScale.h3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 5),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final valueX = width * progress;
                final markerX = math.min(
                  math.max(valueX, _markerRadius),
                  math.max(_markerRadius, width - _markerRadius),
                );

                return SizedBox(
                  height: 43,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: _markerRadius - (_trackHeight / 2),
                        child: SizedBox(
                          height: _trackHeight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.divider,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                width: markerX,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(99),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.34),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      for (var index = 0; index <= 5; index++)
                        Positioned(
                          left: width * index / 5 - 0.5,
                          top: _markerRadius - 8,
                          child: Container(
                            width: 1,
                            height: 16,
                            color: colors.textTertiary.withValues(alpha: 0.45),
                          ),
                        ),
                      if (widget.showFlame)
                        Positioned(
                          left: markerX,
                          top: _markerRadius,
                          child: Transform.translate(
                            offset: const Offset(
                                -_markerRadius, -_markerSize * 0.65),
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                final phase = reduceMotion
                                    ? 0.0
                                    : math.sin(_animationController.value *
                                        math.pi *
                                        2);
                                return Transform.translate(
                                  offset: Offset(0, phase * 0.7),
                                  child: child,
                                );
                              },
                              child: ExcludeSemantics(
                                child: CustomPaint(
                                  size: const Size(_markerSize, _markerSize),
                                  painter: _FlamePainter(
                                    accent: accent,
                                    contrast: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var index = 0; index <= 5; index++)
                  Text(
                    '${_formatValue(maxValue * index / 5)}${widget.suffix}',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: AppTypeScale.sm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter({required this.accent, required this.contrast});

  final Color accent;
  final Color contrast;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale, scale);

    final outer = Path()
      ..moveTo(12.9, 1)
      ..cubicTo(14, 5.4, 10.5, 7.5, 9.2, 10.8)
      ..cubicTo(8.6, 12.3, 8.6, 13.6, 9, 14.9)
      ..cubicTo(7.1, 13.7, 6.6, 11.7, 7, 9.7)
      ..cubicTo(4.4, 12.4, 3, 15.6, 3, 19.1)
      ..cubicTo(3, 24.6, 6.8, 29, 12, 29)
      ..cubicTo(17.2, 29, 21, 24.6, 21, 19.1)
      ..cubicTo(21, 13.9, 18.4, 10.5, 15.7, 7.6)
      ..cubicTo(15.9, 10.9, 14.4, 12.2, 13.1, 12.9)
      ..cubicTo(14.1, 8.4, 15.4, 6.1, 12.9, 1)
      ..close();
    canvas.drawPath(outer, Paint()..color = accent);

    final inner = Path()
      ..moveTo(12.3, 15)
      ..cubicTo(14.4, 17.6, 16, 19.4, 16, 21.5)
      ..cubicTo(16, 24.2, 14.3, 26, 12, 26)
      ..cubicTo(9.7, 26, 8, 24.2, 8, 21.7)
      ..cubicTo(8, 19.8, 9.2, 18, 12.3, 15)
      ..close();
    canvas.drawPath(inner, Paint()..color = contrast.withValues(alpha: 0.92));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.contrast != contrast;
}
