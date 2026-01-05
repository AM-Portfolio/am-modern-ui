import 'package:flutter/material.dart';

import '../../../internal/domain/enums/trade_statuses.dart';

/// Visual selector for trade status
class StatusSelector extends StatelessWidget {
  const StatusSelector({required this.selectedStatus, required this.onStatusSelected, super.key});
  final TradeStatuses? selectedStatus;
  final ValueChanged<TradeStatuses> onStatusSelected;

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
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 8),
            Text(
              'Status',
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
                child: _ModernStatusButton(
                  status: TradeStatuses.open,
                  label: 'Open',
                  icon: Icons.lock_open_rounded,
                  selectedIcon: Icons.lock_open,
                  color: Colors.orange,
                  isSelected: selectedStatus == TradeStatuses.open,
                  onTap: () => onStatusSelected(TradeStatuses.open),
                  isMobile: isMobile,
                  position: _StatusButtonPosition.left,
                ),
              ),
              Expanded(
                child: _ModernStatusButton(
                  status: TradeStatuses.win,
                  label: 'Win',
                  icon: Icons.trending_up_outlined,
                  selectedIcon: Icons.trending_up_rounded,
                  color: Colors.green,
                  isSelected: selectedStatus == TradeStatuses.win,
                  onTap: () => onStatusSelected(TradeStatuses.win),
                  isMobile: isMobile,
                  position: _StatusButtonPosition.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _StatusButtonPosition { left, right }

class _ModernStatusButton extends StatelessWidget {
  const _ModernStatusButton({
    required this.status,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.isMobile,
    required this.position,
  });
  final TradeStatuses status;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMobile;
  final _StatusButtonPosition position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: position == _StatusButtonPosition.left ? const Radius.circular(10) : Radius.zero,
          right: position == _StatusButtonPosition.right ? const Radius.circular(10) : Radius.zero,
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
              left: position == _StatusButtonPosition.left ? const Radius.circular(10) : Radius.zero,
              right: position == _StatusButtonPosition.right ? const Radius.circular(10) : Radius.zero,
            ),
            border: isSelected
                ? Border.all(color: color.withOpacity(0.5), width: 1.5)
                : position == _StatusButtonPosition.left
                ? Border(right: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  key: ValueKey(isSelected),
                  size: isMobile ? 20 : 22,
                  color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}
