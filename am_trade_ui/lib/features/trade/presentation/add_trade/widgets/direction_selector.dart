import 'package:flutter/material.dart';

import '../../../internal/domain/enums/trade_directions.dart';

/// Visual selector for trade direction (Long/Short)
class DirectionSelector extends StatelessWidget {
  const DirectionSelector({required this.selectedDirection, required this.onDirectionSelected, super.key});
  final TradeDirections? selectedDirection;
  final ValueChanged<TradeDirections> onDirectionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.swap_horiz, size: 16, color: theme.colorScheme.onTertiaryContainer),
            ),
            const SizedBox(width: 8),
            Text(
              'Direction',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        // Modern toggle-style buttons
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ModernDirectionButton(
                  direction: TradeDirections.long,
                  label: 'Long',
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.green,
                  isSelected: selectedDirection == TradeDirections.long,
                  onTap: () => onDirectionSelected(TradeDirections.long),
                  isMobile: isMobile,
                  position: _ButtonPosition.left,
                ),
              ),
              Expanded(
                child: _ModernDirectionButton(
                  direction: TradeDirections.short,
                  label: 'Short',
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.red,
                  isSelected: selectedDirection == TradeDirections.short,
                  onTap: () => onDirectionSelected(TradeDirections.short),
                  isMobile: isMobile,
                  position: _ButtonPosition.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ButtonPosition { left, right }

class _ModernDirectionButton extends StatelessWidget {
  const _ModernDirectionButton({
    required this.direction,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.isMobile,
    required this.position,
  });
  final TradeDirections direction;
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMobile;
  final _ButtonPosition position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: position == _ButtonPosition.left ? const Radius.circular(10) : Radius.zero,
          right: position == _ButtonPosition.right ? const Radius.circular(10) : Radius.zero,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 12 : 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.horizontal(
              left: position == _ButtonPosition.left ? const Radius.circular(10) : Radius.zero,
              right: position == _ButtonPosition.right ? const Radius.circular(10) : Radius.zero,
            ),
            border: isSelected
                ? Border.all(color: color.withOpacity(0.5), width: 1.5)
                : position == _ButtonPosition.left
                ? Border(right: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isMobile ? 18 : 20,
                color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.8),
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: isMobile ? 4 : 6),
                Icon(Icons.check_circle, color: color, size: isMobile ? 14 : 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
