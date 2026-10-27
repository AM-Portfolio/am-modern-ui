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
    final bgColor = accentColor.withValues(alpha: widget.isDark ? 0.14 : 0.10);


    // ── Primary text color — adapts to theme ──
    final primaryText = widget.isDark
        ? Colors.white.withValues(alpha: 0.92)
        : const Color(0xFF0F172A);
    final secondaryText = widget.isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF64748B);

    final hasDistinctSubtitle = widget.item.subtitle != null &&
        widget.item.subtitle!.trim().isNotEmpty &&
        widget.item.subtitle!.trim().toUpperCase() !=
            widget.item.symbol.trim().toUpperCase();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = constraints.maxWidth;
          final isCompact = tileWidth < 235;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            transform: _isHovered
                ? Matrix4.diagonal3Values(1.025, 1.025, 1.0)
                : Matrix4.identity(),
            transformAlignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 7),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 10,
              vertical: isCompact ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: _isHovered
                  ? bgColor
                  : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.025)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? accentColor.withValues(alpha: 0.50)
                    : accentColor.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: _isHovered
                  ? [
                      // ── Glow: 0.6 opacity, blur 12, spread 1 ──
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // ── Squircle directional icon ──────────────
                Container(
                  width: isCompact ? 24 : 28,
                  height: isCompact ? 24 : 28,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(isCompact ? 6 : 7),
                  ),
                  child: Icon(
                    widget.item.isGainer
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: isCompact ? 13 : 14,
                    color: accentColor,
                  ),
                ),
                SizedBox(width: isCompact ? 6 : 8),

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
                          fontSize: isCompact ? 12 : 13,
                          color: primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasDistinctSubtitle)
                        Text(
                          widget.item.subtitle!,
                          style: TextStyle(
                            fontSize: isCompact ? 9 : 10,
                            color: secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // ── Price + Open % (never squished, clean typography without capsule) ─
                if (isCompact)
                  // Stacked right column: Price on line 1, open % on line 2
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.priceLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          color: primaryText,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.formattedChangePercent,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  )
                else
                  // Wide horizontal row: Price and Pill side-by-side
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.item.priceLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: primaryText,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.item.formattedChangePercent,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );

  }
}
