import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';

/// Frosted glass shell for auth pages.
///
/// Blur + tint live on a background layer only; [child] stays outside the
/// filter so text stays sharp on Flutter web.
class GlassCardWidget extends StatefulWidget {
  final Widget child;
  final bool isCompact;
  final double? maxWidth;
  final bool enableMotion;

  const GlassCardWidget({
    super.key,
    required this.child,
    this.isCompact = false,
    this.maxWidth,
    this.enableMotion = false,
  });

  @override
  State<GlassCardWidget> createState() => _GlassCardWidgetState();
}

class _GlassCardWidgetState extends State<GlassCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  Offset _parallax = Offset.zero;
  Offset _reflPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.enableMotion ? 520 : 1),
    );
    _scale = Tween<double>(
      begin: widget.enableMotion ? 0.96 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    _opacity = Tween<double>(begin: widget.enableMotion ? 0.0 : 1.0, end: 1.0)
        .animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent e) {
    if (!widget.enableMotion || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final sz = box.size;
    final lp = e.localPosition;
    setState(() {
      _parallax = Offset(
        ((lp.dx / sz.width) - 0.5) * 8,
        ((lp.dy / sz.height) - 0.5) * 8,
      );
      _reflPos = lp;
    });
  }

  void _onExit(PointerEvent e) {
    if (!widget.enableMotion || !mounted) return;
    setState(() {
      _parallax = Offset.zero;
      _reflPos = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;
    final r = widget.isCompact ? 28.0 : 32.0;
    final pad = widget.isCompact
        ? 22.0
        : (widget.maxWidth != null && widget.maxWidth! > 600 ? 28.0 : 36.0);

    // Light frost: glass stays readable while particles remain clearly visible.
    final baseFill = colors.cardSurface.withValues(alpha: isDark ? 0.22 : 0.30);
    final gradStart = colors.surface.withValues(alpha: isDark ? 0.16 : 0.22);
    final gradCenter = colors.surface.withValues(alpha: isDark ? 0.08 : 0.12);
    final gradEnd = colors.scaffoldBackground.withValues(alpha: isDark ? 0.04 : 0.08);
    final outerBorderColor = colors.border.withValues(alpha: isDark ? 0.45 : 0.55);
    final topHighlightColor = colors.textPrimary.withValues(alpha: 0.28);
    final leftHighlightColor = colors.textPrimary.withValues(alpha: 0.14);

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: MouseRegion(
          onHover: _onHover,
          onExit: _onExit,
          child: Transform.translate(
            offset: _parallax,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: widget.maxWidth ??
                    (widget.isCompact ? double.infinity : 440),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(r),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: baseFill,
                            border: Border.all(
                              color: outerBorderColor,
                              width: 1.0,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [gradStart, gradCenter, gradEnd],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: topHighlightColor,
                              width: 1.2,
                            ),
                            left: BorderSide(
                              color: leftHighlightColor,
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isDark)
                      Positioned(
                        top: -40,
                        left: -40,
                        child: IgnorePointer(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  colors.textPrimary.withValues(alpha: 0.12),
                                  colors.textPrimary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_reflPos != Offset.zero)
                      Positioned(
                        left: _reflPos.dx - 150,
                        top: _reflPos.dy - 150,
                        child: IgnorePointer(
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  colors.textPrimary.withValues(
                                    alpha: isDark ? 0.06 : 0.10,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(pad),
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
