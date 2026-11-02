import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_type_scale.dart';
import '../../../core/theme/color_extensions.dart';
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
    this.onTap,
  });

  final AmMoverItem item;

  /// Resolved gain color (caller passes MarketColors.positive or override).
  final Color positiveColor;

  /// Resolved loss color (caller passes MarketColors.negative or override).
  final Color negativeColor;

  final bool isDark;

  /// Optional activation callback. When omitted, the tile remains display-only.
  final VoidCallback? onTap;

  @override
  State<AmMoverTile> createState() => _AmMoverTileState();
}

class _AmMoverTileState extends State<AmMoverTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor =
        widget.item.isGainer ? widget.positiveColor : widget.negativeColor;

    // Tile background tint — accent at low opacity
    final bgColor = accentColor.withValues(alpha: widget.isDark ? 0.14 : 0.10);
    final primaryText = colors.textPrimary;
    final secondaryText = colors.textSecondary;
    final idleSurface = colors.cardSurface.withValues(
      alpha: widget.isDark ? 0.55 : 0.92,
    );

    final hasDistinctSubtitle = widget.item.subtitle != null &&
        widget.item.subtitle!.trim().isNotEmpty &&
        widget.item.subtitle!.trim().toUpperCase() !=
            widget.item.symbol.trim().toUpperCase();

    return Semantics(
      container: true,
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      label: widget.onTap == null
          ? widget.item.symbol
          : '${widget.item.symbol}, ${widget.item.isGainer ? 'gainer' : 'loser'}',
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadii.md),
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
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm - 1),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? AppSpacing.sm : 10,
                    vertical: isCompact ? 7 : AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: _isHovered ? bgColor : idleSurface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
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
                          borderRadius: BorderRadius.circular(
                            isCompact ? AppRadii.xs + 2 : 7,
                          ),
                        ),
                        child: Icon(
                          widget.item.isGainer
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: isCompact ? AppTypeScale.md : AppTypeScale.base,
                          color: accentColor,
                        ),
                      ),
                      SizedBox(
                        width: isCompact ? 6 : AppSpacing.sm,
                      ),

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
                                fontSize: isCompact
                                    ? AppTypeScale.sm
                                    : AppTypeScale.md,
                                color: primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hasDistinctSubtitle)
                              Text(
                                widget.item.subtitle!,
                                style: TextStyle(
                                  fontSize: AppTypeScale.xs,
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
                                fontSize: AppTypeScale.sm,
                                color: primaryText,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              widget.item.formattedChangePercent,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: AppTypeScale.xs,
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
                                fontSize: AppTypeScale.sm,
                                color: primaryText,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              widget.item.formattedChangePercent,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: AppTypeScale.sm,
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
          ),
        ),
      ),
    );
  }
}
