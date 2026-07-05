import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

class MarketHeader extends StatelessWidget {
  final VoidCallback onAllIndicesPressed;

  const MarketHeader({
    required this.onAllIndicesPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Market Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: MarketColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Real-time market overview',
                style: TextStyle(
                  fontSize: 11,
                  color: MarketColors.textMuted(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const GlobalTimeFrameBar(),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMobile) ...[
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.search, size: 20),
                color: MarketColors.textMuted(context),
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.notifications_none, size: 20),
                color: MarketColors.textMuted(context),
                onPressed: () {},
              ),
              const SizedBox(width: 12),
            ],
            _AllIndicesButton(
              isMobile: isMobile,
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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 10 : 12,
            vertical: widget.isMobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? MarketColors.borderStrong(context).withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: MarketColors.borderStrong(context),
              width: MarketColors.borderWidth(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: widget.isMobile ? 14 : 16,
                color: MarketColors.textMuted(context),
              ),
              if (!widget.isMobile) ...[
                const SizedBox(width: 6),
                Text(
                  'All indices',
                  style: TextStyle(
                    fontSize: 12,
                    color: MarketColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
