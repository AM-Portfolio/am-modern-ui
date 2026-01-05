import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/trade_holding_view_model.dart';

/// Period type for trade overview
enum TradePeriodType { daily, weekly, monthly, yearly }

/// Widget to select and preview trades for a given date/period
class TradeOverviewSelector extends StatelessWidget {
  const TradeOverviewSelector({
    required this.selectedDate,
    required this.selectedPeriod,
    required this.selectedTradeIds,
    required this.onDateChanged,
    required this.onPeriodChanged,
    required this.onTradesSelected,
    required this.onViewTrades,
    this.availableTrades = const [],
    this.readOnly = false,
    super.key,
  });

  final DateTime selectedDate;
  final TradePeriodType selectedPeriod;
  final List<String> selectedTradeIds;
  final List<TradeHoldingViewModel> availableTrades;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TradePeriodType> onPeriodChanged;
  final ValueChanged<List<String>> onTradesSelected;
  final VoidCallback onViewTrades;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tradesCount = availableTrades.length;
    final selectedCount = selectedTradeIds.length;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Trade Overview',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // In view mode with linked trades, show a button to view them
          if (readOnly && selectedCount > 0) ...[
            _buildViewLinkedTradesButton(theme, selectedCount),
          ] else ...[
            // Edit mode - show period selector and date picker
            _buildPeriodSelector(theme),
            const SizedBox(height: 8),

            // Date selector
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_getDateRangeText(), style: theme.textTheme.bodyMedium)),
                    Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),

            // View Trades button - always visible in edit mode
            const SizedBox(height: 12),
            _buildViewTradesButton(theme, tradesCount, selectedCount),
          ],
        ],
      ),
    );
  }

  Widget _buildViewLinkedTradesButton(ThemeData theme, int count) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onViewTrades,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.link, size: 20, color: theme.colorScheme.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Linked Trades',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count trade${count != 1 ? 's' : ''} linked to this entry',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
          ],
        ),
      ),
    ),
  );

  Widget _buildPeriodSelector(ThemeData theme) => Row(
    children: [
      Expanded(
        child: SegmentedButton<TradePeriodType>(
          segments: const [
            ButtonSegment(value: TradePeriodType.daily, label: Text('Day'), icon: Icon(Icons.today, size: 14)),
            ButtonSegment(value: TradePeriodType.weekly, label: Text('Week'), icon: Icon(Icons.view_week, size: 14)),
            ButtonSegment(
              value: TradePeriodType.monthly,
              label: Text('Month'),
              icon: Icon(Icons.calendar_month, size: 14),
            ),
            ButtonSegment(
              value: TradePeriodType.yearly,
              label: Text('Year'),
              icon: Icon(Icons.calendar_today_outlined, size: 14),
            ),
          ],
          selected: {selectedPeriod},
          onSelectionChanged: (newSelection) {
            onPeriodChanged(newSelection.first);
          },
          style: ButtonStyle(
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 10)),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    ],
  );

  String _getDateRangeText() {
    switch (selectedPeriod) {
      case TradePeriodType.daily:
        return DateFormat('MMM dd, yyyy').format(selectedDate);
      case TradePeriodType.weekly:
        final weekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('MMM dd').format(weekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';
      case TradePeriodType.monthly:
        return DateFormat('MMMM yyyy').format(selectedDate);
      case TradePeriodType.yearly:
        return DateFormat('yyyy').format(selectedDate);
    }
  }

  Widget _buildViewTradesButton(ThemeData theme, int total, int selected) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: total > 0 ? onViewTrades : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: total > 0
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: total > 0 ? theme.colorScheme.primary.withOpacity(0.4) : theme.dividerColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: total > 0
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                total > 0 ? Icons.visibility_outlined : Icons.info_outline,
                size: 18,
                color: total > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total > 0 ? 'View & Link Trades' : 'No Trades Available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: total > 0 ? null : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total > 0
                        ? '$total available${selected > 0 ? ' â€¢ $selected selected' : ''}'
                        : 'Select a date with trades',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: total > 0
                          ? (selected > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontWeight: selected > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (total > 0) Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    ),
  );

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }
}

