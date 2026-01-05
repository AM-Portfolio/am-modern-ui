import 'package:flutter/material.dart';
import 'package:am_design_system/shared/models/holding.dart';
import '../../tables/sortable_table.dart';
import 'holdings_layout_builder.dart';

/// Table layout builder for holdings (web-optimized)
class TableLayoutBuilder extends HoldingsLayoutBuilder {
  @override
  Widget build(
    BuildContext context,
    List<Holding> holdings, {
    required HoldingsSortBy sortBy,
    required bool sortAscending,
    required HoldingsDisplayFormat displayFormat,
    required HoldingsChangeType changeType,
    ValueChanged<Holding>? onHoldingTap,
    double? width,
    double? height,
  }) {
    final theme = Theme.of(context);
    final sortedHoldings = sortHoldings(holdings, sortBy, sortAscending);

    // Calculate responsive row height
    final baseFontSize = theme.textTheme.bodyMedium?.fontSize ?? 14.0;
    final textScale = MediaQuery.textScaleFactorOf(context);
    final rowHeight = (baseFontSize * 2.6 * textScale).clamp(40.0, 64.0);

    return SortableTable<Holding>(
      items: sortedHoldings,
      columns: _buildColumns(displayFormat, changeType, theme),
      initialSortColumnIndex: _getSortColumnIndex(sortBy),
      onItemTap: onHoldingTap,
      rowHeight: rowHeight,
    );
  }

  int _getSortColumnIndex(HoldingsSortBy sortBy) {
    switch (sortBy) {
      case HoldingsSortBy.symbol:
        return 0;
      case HoldingsSortBy.quantity:
        return 1;
      case HoldingsSortBy.currentValue:
        return 2;
      case HoldingsSortBy.gainLoss:
      case HoldingsSortBy.gainLossPercent:
        return 3;
      default:
        return 2;
    }
  }

  List<SortableColumn<Holding>> _buildColumns(
    HoldingsDisplayFormat displayFormat,
    HoldingsChangeType changeType,
    ThemeData theme,
  ) {
    return [
      // Symbol column
      SortableColumn<Holding>(
        title: 'Symbol',
        sortBy: (holding) => holding.symbol,
        builder: (holding) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              holding.symbol,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              holding.sector,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),

      // Quantity column
      SortableColumn<Holding>(
        title: 'Qty',
        sortBy: (holding) => holding.quantity,
        builder: (holding) => Text(
          holding.quantity.toString(),
          overflow: TextOverflow.ellipsis,
        ),
      ),

      // Current Value column
      SortableColumn<Holding>(
        title: 'Curr Value',
        textAlign: TextAlign.end,
        sortBy: (holding) => holding.currentValue,
        builder: (holding) => Text(
          formatCurrency(holding.currentValue),
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ),

      // Gain/Loss column
      SortableColumn<Holding>(
        title: changeType == HoldingsChangeType.daily ? 'Today' : 'Gain/Loss',
        textAlign: TextAlign.end,
        sortBy: (holding) => getChangeValue(holding, changeType),
        builder: (holding) {
          final changeValue = getChangeValue(holding, changeType);
          final changePercent = getChangePercentage(holding, changeType);
          final isPositive = changeValue >= 0;
          final valueColor =
              isPositive ? Colors.green.shade700 : Colors.red.shade700;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (displayFormat != HoldingsDisplayFormat.percentage)
                Text(
                  '${isPositive ? "+" : ""}${formatCurrency(changeValue)}',
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              if (displayFormat != HoldingsDisplayFormat.value)
                Text(
                  formatPercentage(changePercent),
                  style: TextStyle(
                    color: valueColor,
                    fontSize: displayFormat == HoldingsDisplayFormat.both ? 11 : null,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          );
        },
      ),
    ];
  }
}
