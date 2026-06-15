import 'package:flutter/material.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'timeframe_selector.dart';

class MarketHeader extends StatelessWidget {
  final String selectedTimeframe;
  final ValueChanged<String> onTimeframeChanged;
  final VoidCallback onAllIndicesPressed;

  const MarketHeader({
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
    required this.onAllIndicesPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final mt = context.marketTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Section: Title + Subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Market Dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: mt.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Real-time market overview',
              style: TextStyle(
                fontSize: 11,
                color: mt.textMuted,
              ),
            ),
          ],
        ),

        // Center/Right Section
        if (isMobile)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.search, size: 20),
                color: mt.textMuted,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.notifications_none, size: 20),
                color: mt.textMuted,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              _AllIndicesButton(
                isMobile: true,
                onPressed: onAllIndicesPressed,
              ),
            ],
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TimeframeSelector(
                selectedTimeframe: selectedTimeframe,
                onTimeframeChanged: onTimeframeChanged,
              ),
              const SizedBox(width: 10),
              _AllIndicesButton(
                isMobile: false,
                onPressed: onAllIndicesPressed,
              ),
            ],
          ),
      ],
    );
  }
}

class _AllIndicesButton extends StatefulWidget {
  final bool isMobile;
  final VoidCallback onPressed;

  const _AllIndicesButton({
    required this.isMobile,
    required this.onPressed,
  });

  @override
  State<_AllIndicesButton> createState() => _AllIndicesButtonState();
}

class _AllIndicesButtonState extends State<_AllIndicesButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final mt = context.marketTheme;

    if (widget.isMobile) {
      return IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          Icons.grid_view_rounded,
          size: 18,
          color: mt.textSecondary,
        ),
        tooltip: 'All indices',
        onPressed: widget.onPressed,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: _isHovered ? mt.accent : mt.border,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 14,
                color: _isHovered ? mt.accent : mt.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'All indices',
                style: TextStyle(
                  fontSize: 12,
                  color: _isHovered ? mt.accent : mt.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
