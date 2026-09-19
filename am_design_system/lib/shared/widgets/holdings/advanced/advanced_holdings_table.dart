import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/color_extensions.dart';
import 'advanced_holding_row.dart';

/// Table layout for [AdvancedHoldingsTemplate].
class AdvancedHoldingsTable extends StatelessWidget {
  const AdvancedHoldingsTable({
    required this.holdings,
    required this.accent,
    required this.onSort,
    super.key,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onRowTap,
    this.onSymbolTap,
  });

  final List<AdvancedHoldingRow> holdings;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Color accent;
  final void Function(int columnIndex, bool ascending) onSort;
  final ValueChanged<AdvancedHoldingRow>? onRowTap;
  final ValueChanged<String>? onSymbolTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: holdings.length,
            itemBuilder: (context, index) =>
                _buildRow(context, holdings[index], index),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _headerCell(context, 'Symbol', 2, 0),
            _headerCell(context, 'Company', 2, 1),
            _headerCell(context, 'Qty', 1, 2, isNumeric: true),
            _headerCell(context, 'Avg Price', 1, 3, isNumeric: true),
            _headerCell(context, 'LTP', 1, 4, isNumeric: true),
            _headerCell(context, 'Value', 1, 5, isNumeric: true),
            _headerCell(context, 'P&L', 1, 6, isNumeric: true),
            _headerCell(context, 'P&L %', 1, 7, isNumeric: true),
            _headerCell(context, 'Weight', 1, 8, isNumeric: true),
          ],
        ),
      );

  Widget _headerCell(
    BuildContext context,
    String label,
    int flex,
    int columnIndex, {
    bool isNumeric = false,
  }) {
    final isSorted = sortColumnIndex == columnIndex;
    final theme = Theme.of(context);
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(columnIndex, isSorted ? !sortAscending : true),
        child: Row(
          mainAxisAlignment:
              isNumeric ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSorted)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    AdvancedHoldingRow holding,
    int index,
  ) {
    final isPositive = holding.isProfit;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onRowTap != null ? () => onRowTap!(holding) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: index.isEven
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onSymbolTap != null
                    ? () => onSymbolTap!(holding.displaySymbol)
                    : null,
                child: _symbolCell(holding),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                holding.displayCompanyName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                holding.displayQuantity,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                holding.displayAvgPrice,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                holding.displayCurrentPrice,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                holding.displayCurrentValue,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _pnlCell(context, holding.displayProfitLoss, isPositive),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _pnlPctCell(
                  context,
                  holding.displayProfitLossPercentage,
                  isPositive,
                ),
              ),
            ),
            Expanded(
              child: Text(
                holding.displayWeight,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _symbolCell(AdvancedHoldingRow holding) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.8),
                  accent.withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                holding.displaySymbol.length >= 2
                    ? holding.displaySymbol.substring(0, 2).toUpperCase()
                    : '•',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              holding.displaySymbol,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _pnlCell(BuildContext context, String value, bool isPositive) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color:
                isPositive ? context.marketPositive : context.marketNegative,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPositive
                    ? context.marketPositive
                    : context.marketNegative,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );

  Widget _pnlPctCell(BuildContext context, String value, bool isPositive) {
    final color =
        isPositive ? context.marketPositive : context.marketNegative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}
