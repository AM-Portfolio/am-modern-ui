import 'package:flutter/material.dart';

import '../../../../../features/trade/internal/domain/enums/trade_directions.dart';
import '../../../../../features/trade/internal/domain/enums/enum_extensions.dart';
import '../../../../../features/trade/internal/domain/enums/trade_statuses.dart';
import '../../../../../features/trade/internal/domain/enums/enum_extensions.dart';

/// Compact inline Direction & Status selector for trade forms
class DirectionStatusSelector extends StatelessWidget {
  const DirectionStatusSelector({
    required this.selectedDirection,
    required this.selectedStatus,
    required this.onDirectionChanged,
    required this.onStatusChanged,
    super.key,
  });

  final TradeDirections selectedDirection;
  final TradeStatuses selectedStatus;
  final ValueChanged<TradeDirections> onDirectionChanged;
  final ValueChanged<TradeStatuses> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive breakpoints
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      child: isMobile ? _buildMobileLayout(theme) : _buildWebLayout(theme, isTablet, isDesktop),
    );
  }

  // Mobile layout: Direction and Status in same row, compact
  Widget _buildMobileLayout(ThemeData theme) => Row(
    children: [
      Expanded(child: _buildDirectionButtons(true, isFullWidth: true, showLabel: false)),
      const SizedBox(width: 8),
      Expanded(child: _buildStatusDropdown(theme, true)),
    ],
  );

  // Web layout: Side-by-side with labels
  Widget _buildWebLayout(ThemeData theme, bool isTablet, bool isDesktop) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildDirectionSection(theme, false),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      _buildStatusSection(theme, false),
    ],
  );

  // Direction section with label (for web/tablet/desktop)
  Widget _buildDirectionSection(ThemeData theme, bool isMobile) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: theme.colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(6)),
        child: Icon(Icons.swap_horiz, size: 16, color: theme.colorScheme.onTertiaryContainer),
      ),
      const SizedBox(width: 8),
      const SizedBox(width: 10),
      _buildDirectionButtons(isMobile, isFullWidth: false, showLabel: true),
    ],
  );

  // Status section with label (for web/tablet/desktop)
  Widget _buildStatusSection(ThemeData theme, bool isMobile) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(6)),
        child: Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSecondaryContainer),
      ),
      const SizedBox(width: 8),
      const SizedBox(width: 10),
      _buildStatusDropdown(theme, isMobile),
    ],
  );

  Widget _buildDirectionButtons(bool isMobile, {required bool isFullWidth, required bool showLabel}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (isFullWidth)
        Expanded(
          child: _ModernButton(
            isSelected: selectedDirection == TradeDirections.long,
            label: 'LONG',
            icon: Icons.arrow_upward_rounded,
            color: Colors.green,
            onTap: () => onDirectionChanged(TradeDirections.long),
            isMobile: isMobile,
          ),
        )
      else
        _ModernButton(
          isSelected: selectedDirection == TradeDirections.long,
          label: 'LONG',
          icon: Icons.arrow_upward_rounded,
          color: Colors.green,
          onTap: () => onDirectionChanged(TradeDirections.long),
          isMobile: isMobile,
        ),
      const SizedBox(width: 6),
      if (isFullWidth)
        Expanded(
          child: _ModernButton(
            isSelected: selectedDirection == TradeDirections.short,
            label: 'SHORT',
            icon: Icons.arrow_downward_rounded,
            color: Colors.red,
            onTap: () => onDirectionChanged(TradeDirections.short),
            isMobile: isMobile,
          ),
        )
      else
        _ModernButton(
          isSelected: selectedDirection == TradeDirections.short,
          label: 'SHORT',
          icon: Icons.arrow_downward_rounded,
          color: Colors.red,
          onTap: () => onDirectionChanged(TradeDirections.short),
          isMobile: isMobile,
        ),
    ],
  );

  Widget _buildStatusDropdown(ThemeData theme, bool isMobile) => Container(
    constraints: BoxConstraints(minWidth: isMobile ? 120 : 140),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface.withOpacity(0.6),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
    ),
    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 4 : 6),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<TradeStatuses>(
        value: selectedStatus,
        isDense: true,
        icon: Icon(Icons.arrow_drop_down, size: isMobile ? 20 : 24),
        onChanged: (newValue) {
          if (newValue != null) {
            onStatusChanged(newValue);
          }
        },
        items: TradeStatuses.values
            .map(
              (status) => DropdownMenuItem<TradeStatuses>(
                value: status,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(status), size: isMobile ? 16 : 18, color: _getStatusColor(status)),
                    const SizedBox(width: 8),
                    Text(status.displayName),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ),
  );

  IconData _getStatusIcon(TradeStatuses status) {
    switch (status) {
      case TradeStatuses.open:
        return Icons.lock_open_rounded;
      case TradeStatuses.win:
        return Icons.trending_up_rounded;
      case TradeStatuses.loss:
        return Icons.trending_down_rounded;
      case TradeStatuses.breakeven:
        return Icons.swap_horiz_rounded;
    }
  }

  Color _getStatusColor(TradeStatuses status) {
    switch (status) {
      case TradeStatuses.open:
        return Colors.orange;
      case TradeStatuses.win:
        return Colors.green;
      case TradeStatuses.loss:
        return Colors.red;
      case TradeStatuses.breakeven:
        return Colors.blue;
    }
  }
}

class _ModernButton extends StatelessWidget {
  const _ModernButton({
    required this.isSelected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isMobile,
  });

  final bool isSelected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(minWidth: isMobile ? 60 : 95, maxWidth: isMobile ? 100 : 150),
          padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12, horizontal: isMobile ? 8 : 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : theme.colorScheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : theme.colorScheme.outline.withOpacity(0.25),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.65),
                size: isMobile ? 18 : 21,
              ),
              SizedBox(width: isMobile ? 5 : 7),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.85),
                    letterSpacing: isMobile ? 0.1 : 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
