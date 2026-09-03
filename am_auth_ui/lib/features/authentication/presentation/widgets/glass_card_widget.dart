import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium Liquid Glass Card — Pixel Perfect to image (1).png
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
    this.enableMotion = true,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.isCompact ? 28.0 : 32.0;
    final pad = widget.isCompact
        ? 22.0
        : (widget.maxWidth != null && widget.maxWidth! > 600 ? 28.0 : 36.0);

    // ── Material & Colors ───────────────────────────────────────────────────
    // Dark Theme: 100% UNCHANGED
    // Light Theme: Crystal base (12% opacity)
    final baseFill = isDark
        ? const Color(0xFF141C2D).withValues(alpha: 0.22)
        : const Color(0xFFF8F9FF).withValues(alpha: 0.12);

    // 3-stop Internal Gradient
    final gradStart = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.35);
    final gradCenter = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF8F9FF).withValues(alpha: 0.15);
    final gradEnd = isDark
        ? Colors.white.withValues(alpha: 0.02)
        : const Color(0xFFE8ECFF).withValues(alpha: 0.06);

    // Borders & Edge Specular Highlights
    final outerBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.white.withValues(alpha: 0.24);
    final topHighlightColor = isDark
        ? Colors.white.withValues(alpha: 0.60)
        : Colors.white.withValues(alpha: 0.55);
    final leftHighlightColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.35);

    // Layered Shadows (Dark theme: 100% unchanged, Light theme: layered subtle blue bloom & soft contact shadow)
    final shadowList = isDark
        ? [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.30),
              blurRadius: 40,
              spreadRadius: -2,
              offset: const Offset(16, 12),
            ),
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.20),
              blurRadius: 60,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ]
        : [
            // Layer 1: Tiny contact shadow
            BoxShadow(
              color: const Color(0xFF1E2850).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            // Layer 2: Large soft ambient shadow
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
              blurRadius: 40,
              spreadRadius: -4,
              offset: const Offset(0, 16),
            ),
            // Layer 3: Very subtle blue bloom
            BoxShadow(
              color: const Color(0xFF7896FF).withValues(alpha: 0.10),
              blurRadius: 70,
              offset: const Offset(0, 20),
            ),
          ];

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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                boxShadow: shadowList,
              ),
              child: ColorFiltered(
              // saturate(185%) brightness(108%) contrast(104%)
              colorFilter: ColorFilter.matrix(_satBrightnessMatrix(
                saturation: 1.85,
                brightness: 1.08,
                contrast: 1.04,
              )),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: baseFill,
                      borderRadius: BorderRadius.circular(r),
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
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Polished glass edge highlights
                        // Note: non-uniform BorderSide colors cannot use borderRadius
                        // (Flutter assertion). Parent ClipRRect already clips corners.
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: topHighlightColor, width: 1.2),
                                left: BorderSide(color: leftHighlightColor, width: 1.0),
                              ),
                            ),
                          ),
                        ),

                        // Soft corner reflection (Upper-Left)
                        if (!isDark)
                          Positioned(
                            top: -40,
                            left: -40,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.30),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Mouse-following light reflection
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
                                      Colors.white.withValues(alpha: isDark ? 0.08 : 0.12),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Content
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
          ),
        ),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

Float64List _satBrightnessMatrix({
  required double saturation,
  required double brightness,
  double contrast = 1.0,
}) {
  const rw = 0.299, gw = 0.587, bw = 0.114;

  final s = saturation * brightness * contrast;
  final b = brightness * contrast;
  final cOffset = (1.0 - contrast) * 0.5 * 255;

  return Float64List.fromList([
    rw + (1 - rw) * s, gw - gw * s,       bw - bw * s,       0, cOffset,
    rw - rw * s,       gw + (1 - gw) * s, bw - bw * s,       0, cOffset,
    rw - rw * s,       gw - gw * s,       bw + (1 - bw) * s, 0, cOffset,
    0,                 0,                 0,                  b, 0,
  ]);
}


