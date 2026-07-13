import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../shared/models/am_mover_item.dart';

// ---------------------------------------------------------------------------
// _AmMoverTile — private tile used only inside AmTopMoversPanel.
//
// Animation spec (mirrors market dashboard MonthlyPerformanceCard style):
//   • AnimatedContainer + Matrix4.identity()..scale(1.03)
//     → scales paint only, layout stays fixed → zero overflow risk
//   • Duration: 250 ms, Curve: easeOutCubic
//   • Hover glow: accentColor.withOpacity(0.6), blurRadius 12, spreadRadius 1
//   • % pill: strengthens opacity + border on hover to prevent bg blending
// ---------------------------------------------------------------------------
class AmMoverTile extends StatefulWidget {
  const AmMoverTile({
    super.key,
    required this.item,
    required this.positiveColor,
    required this.negativeColor,
    required this.isDark,
  });

  final AmMoverItem item;

  /// Resolved gain color (caller passes MarketColors.positive or override).
  final Color positiveColor;

  /// Resolved loss color (caller passes MarketColors.negative or override).
  final Color negativeColor;

  final bool isDark;

  @override
  State<AmMoverTile> createState() => _AmMoverTileState();
}

class _AmMoverTileState extends State<AmMoverTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        widget.item.isGainer ? widget.positiveColor : widget.negativeColor;

    // Tile background tint — accent at low opacity
    final bgColor = accentColor.withOpacity(widget.isDark ? 0.14 : 0.10);

    // ── Pill colors: strengthen on hover so pill pops against tinted tile bg ──
    final pillBg = _isHovered
        ? accentColor.withOpacity(widget.isDark ? 0.28 : 0.18)
        : bgColor;
    final pillBorderColor =
        _isHovered ? accentColor.withOpacity(0.70) : accentColor.withOpacity(0.35);
    final pillTextColor =
        _isHovered ? (widget.isDark ? Colors.white : accentColor) : accentColor;

    // ── Primary text color — adapts to theme ──
    final primaryText = widget.isDark
        ? Colors.white.withOpacity(0.92)
        : const Color(0xFF0F172A);
    final secondaryText = widget.isDark
        ? Colors.white.withOpacity(0.55)
        : const Color(0xFF64748B);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        // ── Scale via Matrix4: layout size fixed → no overflow ──
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: _isHovered
            ? (Matrix4.identity()..scale(1.03))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: _isHovered
              ? bgColor
              : (widget.isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.025)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? accentColor.withOpacity(0.50)
                : accentColor.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  // ── Glow: 0.6 opacity, blur 12, spread 1 ──
                  BoxShadow(
                    color: accentColor.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // ── Squircle directional icon (28×28, radius 7) ──────────────
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                widget.item.isGainer
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 8),

            // ── Symbol + optional subtitle ───────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.item.symbol,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.item.subtitle != null)
                    Text(
                      widget.item.subtitle!,
                      style: TextStyle(
                        fontSize: 10,
                        color: secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // ── Price label ──────────────────────────────────────────────
            Text(
              widget.item.priceLabel,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: primaryText,
              ),
            ),
            const SizedBox(width: 8),

            // ── Percentage pill ──────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pillBorderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(_isHovered ? 0.35 : 0.15),
                    blurRadius: 6,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Text(
                widget.item.formattedChangePercent,
                style: TextStyle(
                  color: pillTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
