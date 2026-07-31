import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium Liquid Glass Card — Pixel Perfect to image (1).png
class GlassCardWidget extends StatefulWidget {
  final Widget child;
  final bool isCompact;
  final double? maxWidth;

  const GlassCardWidget({
    super.key,
    required this.child,
    this.isCompact = false,
    this.maxWidth,
  });

  @override
  State<GlassCardWidget> createState() => _GlassCardWidgetState();
}

class _GlassCardWidgetState extends State<GlassCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  Offset _parallax = Offset.zero;   // card translation (max ±5 px)
  Offset _reflPos = Offset.zero;    // cursor position inside card

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scale = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    _opacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent e) {
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _parallax = Offset.zero;
      _reflPos = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.isCompact ? 28.0 : 32.0;   // border radius matching image (1).png
    final pad = widget.isCompact ? 24.0 : 36.0; // inner padding

    // ── Material & Colors matching image (1).png ───────────────────────────
    final baseFill = isDark
        ? const Color(0xFF141C2D).withValues(alpha: 0.22)
        : const Color(0xFFE5E8FF).withValues(alpha: 0.35);

    // 3-stop Gradient
    final gradStart = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.65);
    final gradCenter = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF0F2FF).withValues(alpha: 0.25);
    final gradEnd = isDark
        ? Colors.white.withValues(alpha: 0.02)
        : const Color(0xFFDFE3FF).withValues(alpha: 0.15);

    // Borders & Edge Specular Highlights
    final outerBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.white.withValues(alpha: 0.75);
    final topHighlightColor = isDark
        ? Colors.white.withValues(alpha: 0.60)
        : Colors.white.withValues(alpha: 0.95);
    final leftHighlightColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.70);

    // Layered Shadows matching image (1).png (Vibrant Purple Glow on Right & Bottom)
    final shadowList = [
      // Vibrant purple glow on right and bottom-right edge
      BoxShadow(
        color: (isDark ? const Color(0xFF8B5CF6) : const Color(0xFFA855F7)).withValues(alpha: isDark ? 0.30 : 0.25),
        blurRadius: 40,
        spreadRadius: -2,
        offset: const Offset(16, 12),
      ),
      // Soft ambient indigo shadow below
      BoxShadow(
        color: (isDark ? const Color(0xFF4F46E5) : const Color(0xFF6366F1)).withValues(alpha: isDark ? 0.20 : 0.15),
        blurRadius: 60,
        offset: const Offset(0, 16),
      ),
      // Tight depth drop shadow
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ];

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: MouseRegion(
          onHover: _onHover,
          onExit: _onExit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_parallax.dx, _parallax.dy, 0),
            constraints: BoxConstraints(
              maxWidth: widget.maxWidth ?? (widget.isCompact ? double.infinity : 440),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r),
              boxShadow: shadowList,
            ),
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(_satBrightnessMatrix(
                saturation: 1.8,
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
                        width: 1.2,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [gradStart, gradCenter, gradEnd],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Upper-left polished glass edge highlights
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(r - 1),
                              border: Border(
                                top: BorderSide(color: topHighlightColor, width: 1.5),
                                left: BorderSide(color: leftHighlightColor, width: 1.2),
                              ),
                            ),
                          ),
                        ),

                        // Corner lens flare specular highlight (Top-Left)
                        if (!isDark)
                          Positioned(
                            top: -30,
                            left: -30,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.80),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Mouse-following reflection
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
                                      Colors.white.withValues(alpha: isDark ? 0.08 : 0.22),
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


