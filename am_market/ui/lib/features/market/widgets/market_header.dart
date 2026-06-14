import 'package:flutter/material.dart';
import 'timeframe_selector.dart';

class _MarketColors {
  static const background       = Color(0xFF0F1117);
  static const surface          = Color(0xFF1A1F2E);
  static const drawerBg         = Color(0xFF141824);
  static const border           = Color(0xFF2A3347);
  static const borderHover      = Color(0xFF3A4A63);
  static const textPrimary      = Color(0xFFE2E8F0);
  static const textMuted        = Color(0xFF64748B);
  static const textSecondary    = Color(0xFF94A3B8);
  static const accent           = Color(0xFF00C896);
  static const accentText       = Color(0xFF000000);
  static const positive         = Color(0xFF00C896);
  static const negative         = Color(0xFFF87171);
  static const posBadgeBg       = Color(0xFF0A2A1F);
  static const negBadgeBg       = Color(0xFF2A0A0A);
  static const blue             = Color(0xFF378ADD);
}

class MarketColors {
  static const background       = _MarketColors.background;
  static const surface          = _MarketColors.surface;
  static const drawerBg         = _MarketColors.drawerBg;
  static const border           = _MarketColors.border;
  static const borderHover      = _MarketColors.borderHover;
  static const textPrimary      = _MarketColors.textPrimary;
  static const textMuted        = _MarketColors.textMuted;
  static const textSecondary    = _MarketColors.textSecondary;
  static const accent           = _MarketColors.accent;
  static const accentText       = _MarketColors.accentText;
  static const positive         = _MarketColors.positive;
  static const negative         = _MarketColors.negative;
  static const posBadgeBg       = _MarketColors.posBadgeBg;
  static const negBadgeBg       = _MarketColors.negBadgeBg;
  static const blue             = _MarketColors.blue;
}

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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Section: Title + Subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Market Dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: MarketColors.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Real-time market overview',
              style: TextStyle(
                fontSize: 11,
                color: MarketColors.textMuted,
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
                color: MarketColors.textMuted,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.notifications_none, size: 20),
                color: MarketColors.textMuted,
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
    if (widget.isMobile) {
      return IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(
          Icons.grid_view_rounded,
          size: 18,
          color: Color(0xFF94A3B8),
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
              color: _isHovered ? MarketColors.accent : MarketColors.border,
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
                color: _isHovered ? MarketColors.accent : MarketColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'All indices',
                style: TextStyle(
                  fontSize: 12,
                  color: _isHovered ? MarketColors.accent : MarketColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
