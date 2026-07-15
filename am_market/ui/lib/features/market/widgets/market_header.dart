import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

/// Compact chip used in the app bar / header to open the All Indices panel.
class AllIndicesChip extends StatefulWidget {
  final VoidCallback onPressed;

  /// Icon-only control for tight app-bar slots.
  final bool iconOnly;

  /// Slightly denser padding / type (non-icon mode).
  final bool compact;

  const AllIndicesChip({
    required this.onPressed,
    this.iconOnly = false,
    this.compact = false,
    super.key,
  });

  @override
  State<AllIndicesChip> createState() => _AllIndicesChipState();
}

class _AllIndicesChipState extends State<AllIndicesChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF00D1FF);

    if (widget.iconOnly) {
      return Tooltip(
        message: 'All Indices',
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? accent.withValues(alpha: 0.16)
                      : accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: accent,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 8 : 10,
              vertical: widget.compact ? 6 : 7,
            ),
            decoration: BoxDecoration(
              color: _isHovered
                  ? accent.withValues(alpha: 0.14)
                  : accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accent.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: widget.compact ? 15 : 16,
                  color: accent,
                ),
                const SizedBox(width: 6),
                Text(
                  'All Indices',
                  style: TextStyle(
                    fontSize: widget.compact ? 12 : 13,
                    color: MarketColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Desktop/tablet header — All Indices + timeframe. Hidden on mobile (lives in app bar).
class MarketHeader extends StatelessWidget {
  final VoidCallback onAllIndicesPressed;

  const MarketHeader({
    required this.onAllIndicesPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Mobile: All Indices sits in the app bar left of "Market Data".
    if (isMobile) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AllIndicesChip(onPressed: onAllIndicesPressed),
        const Spacer(),
        const GlobalTimeFrameBar(),
      ],
    );
  }
}
