import 'package:flutter/material.dart';
import 'package:am_design_system/shared/models/holding.dart';

/// Comprehensive widget for controlling portfolio display options
class PortfolioDisplayController extends StatelessWidget {
  const PortfolioDisplayController({
    required this.selectedChangeType,
    required this.selectedDisplayFormat,
    required this.selectedSortBy,
    required this.sortAscending,
    required this.onChangeTypeChanged,
    required this.onDisplayFormatChanged,
    required this.onSortByChanged,
    required this.onSortOrderChanged,
    this.accentColor,
    super.key,
  });

  final HoldingsChangeType selectedChangeType;
  final HoldingsDisplayFormat selectedDisplayFormat;
  final HoldingsSortBy selectedSortBy;
  final bool sortAscending;
  final ValueChanged<HoldingsChangeType> onChangeTypeChanged;
  final ValueChanged<HoldingsDisplayFormat> onDisplayFormatChanged;
  final ValueChanged<HoldingsSortBy> onSortByChanged;
  final ValueChanged<bool> onSortOrderChanged;

  /// Module brand accent (e.g. [ModuleColors.portfolio]). Falls back to theme primary.
  final Color? accentColor;

  Color _accent(BuildContext context) =>
      accentColor ?? Theme.of(context).primaryColor;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Display Toggle (Today/Total)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selectedChangeType == HoldingsChangeType.daily
                  ? accent.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: GestureDetector(
              onTap: () => onChangeTypeChanged(
                selectedChangeType == HoldingsChangeType.daily
                    ? HoldingsChangeType.total
                    : HoldingsChangeType.daily,
              ),
              child: Text(
                selectedChangeType == HoldingsChangeType.daily
                    ? 'Today'
                    : 'Total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selectedChangeType == HoldingsChangeType.daily
                      ? accent
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Format Toggle ($ / %)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selectedDisplayFormat == HoldingsDisplayFormat.value
                  ? accent.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: GestureDetector(
              onTap: () => onDisplayFormatChanged(
                selectedDisplayFormat == HoldingsDisplayFormat.value
                    ? HoldingsDisplayFormat.percentage
                    : HoldingsDisplayFormat.value,
              ),
              child: Text(
                selectedDisplayFormat == HoldingsDisplayFormat.value
                    ? r'$'
                    : '%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selectedDisplayFormat == HoldingsDisplayFormat.value
                      ? accent
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Sort Options - Tap to cycle through
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortButton(context, 'Name', HoldingsSortBy.symbol, accent),
              const SizedBox(width: 12),
              _buildSortButton(context, 'P&L', HoldingsSortBy.gainLoss, accent),
              const SizedBox(width: 12),
              _buildSortButton(
                  context, 'P&L%', HoldingsSortBy.gainLossPercent, accent),
              const SizedBox(width: 12),
              _buildSortButton(
                  context, 'Value', HoldingsSortBy.currentValue, accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(
    BuildContext context,
    String label,
    HoldingsSortBy sortBy,
    Color accent,
  ) {
    final isSelected = selectedSortBy == sortBy;
    final isAscending = sortAscending;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          onSortOrderChanged(!sortAscending);
        } else {
          onSortByChanged(sortBy);
          if (!sortAscending) {
            onSortOrderChanged(true);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? accent
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 2),
              Icon(
                isAscending
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Legacy widget for backward compatibility
/// @deprecated Use PortfolioDisplayController instead
@Deprecated('Use PortfolioDisplayController instead')
class ChangeDisplaySelector extends StatelessWidget {
  const ChangeDisplaySelector({
    required this.selectedType,
    required this.selectedFormat,
    required this.onTypeChanged,
    required this.onFormatChanged,
    super.key,
  });
  final HoldingsChangeType selectedType;
  final HoldingsDisplayFormat selectedFormat;
  final ValueChanged<HoldingsChangeType> onTypeChanged;
  final ValueChanged<HoldingsDisplayFormat> onFormatChanged;

  @override
  Widget build(BuildContext context) => PortfolioDisplayController(
        selectedChangeType: selectedType,
        selectedDisplayFormat: selectedFormat,
        selectedSortBy: HoldingsSortBy.symbol,
        sortAscending: true,
        onChangeTypeChanged: onTypeChanged,
        onDisplayFormatChanged: onFormatChanged,
        onSortByChanged: (_) {},
        onSortOrderChanged: (_) {},
      );
}

/// Legacy enum for backward compatibility
/// @deprecated Use HoldingsDisplayFormat instead
@Deprecated('Use HoldingsDisplayFormat instead')
typedef ChangeFormat = HoldingsDisplayFormat;
