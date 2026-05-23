import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/trade_holding_view_model.dart';
import 'trade_overview_selector.dart';

/// Dialog to preview and select trades for a given date/period
class TradePreviewDialog extends StatefulWidget {
  const TradePreviewDialog({
    required this.date,
    required this.trades,
    required this.selectedTradeIds,
    this.periodType = TradePeriodType.daily,
    super.key,
  });

  final DateTime date;
  final List<TradeHoldingViewModel> trades;
  final List<String> selectedTradeIds;
  final TradePeriodType periodType;

  @override
  State<TradePreviewDialog> createState() => _TradePreviewDialogState();
}

class _TradePreviewDialogState extends State<TradePreviewDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedTradeIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodText = _getPeriodText();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.analytics, color: theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trades for $periodText',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.trades.length} trade${widget.trades.length != 1 ? 's' : ''} â€¢ ${_selectedIds.length} selected',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),

            // Trade List
            Expanded(
              child: widget.trades.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.trades.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final trade = widget.trades[index];
                        final isSelected = _selectedIds.contains(trade.tradeId);
                        return _buildTradeCard(theme, trade, isSelected);
                      },
                    ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            setState(() => _selectedIds.clear());
                          },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                  ),
                  Row(
                    children: [
                      OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text('Link ${_selectedIds.length} Trade${_selectedIds.length != 1 ? 's' : ''}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodText() {
    switch (widget.periodType) {
      case TradePeriodType.daily:
        return DateFormat('MMM dd, yyyy').format(widget.date);
      case TradePeriodType.weekly:
        final weekStart = widget.date.subtract(Duration(days: widget.date.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'Week of ${DateFormat('MMM dd').format(weekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';
      case TradePeriodType.monthly:
        return DateFormat('MMMM yyyy').format(widget.date);
      case TradePeriodType.yearly:
        return 'Year ${DateFormat('yyyy').format(widget.date)}';
    }
  }

  Widget _buildEmptyState(ThemeData theme) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          'No trades found for this period',
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
          'Try selecting a different date or period',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
        ),
      ],
    ),
  );

  Widget _buildTradeCard(ThemeData theme, TradeHoldingViewModel trade, bool isSelected) {
    final profitLoss = trade.profitLoss ?? 0.0;
    final profitLossPercentage = trade.profitLossPercentage ?? 0.0;
    final isProfitable = profitLoss >= 0;
    final statusColor = _getStatusColor(theme, trade.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(trade.tradeId);
            } else {
              _selectedIds.add(trade.tradeId);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.1) : theme.colorScheme.surface,
          ),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIds.add(trade.tradeId);
                    } else {
                      _selectedIds.remove(trade.tradeId);
                    }
                  });
                },
              ),
              const SizedBox(width: 12),

              // Trade Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Symbol
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            trade.symbol,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status
                        if (trade.status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              trade.status!.replaceAll('_', ' '),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),

                        const Spacer(),

                        // Position Type
                        if (trade.tradePositionType != null)
                          Chip(
                            label: Text(
                              trade.tradePositionType!,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: trade.tradePositionType == 'LONG'
                                ? Colors.green.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),
                            side: BorderSide(
                              color: trade.tradePositionType == 'LONG'
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Trade details
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (trade.entryTimestamp != null)
                          _buildDetailChip(
                            theme,
                            Icons.calendar_today,
                            DateFormat('MMM dd, yyyy').format(trade.entryTimestamp!),
                          ),
                        _buildDetailChip(theme, Icons.shopping_cart, 'Qty: ${trade.quantity ?? 0}'),
                        _buildDetailChip(theme, Icons.currency_rupee, trade.entryPrice?.toStringAsFixed(2) ?? '0.00'),
                        if (trade.exitPrice != null)
                          _buildDetailChip(theme, Icons.exit_to_app, trade.exitPrice!.toStringAsFixed(2)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // P&L
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isProfitable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isProfitable ? '+' : ''}${profitLoss.toStringAsFixed(2)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isProfitable ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    Text(
                      '${isProfitable ? '+' : ''}${profitLossPercentage.toStringAsFixed(2)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isProfitable ? Colors.green[600] : Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(ThemeData theme, IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );

  Color _getStatusColor(ThemeData theme, String? status) {
    if (status == null) return theme.colorScheme.onSurfaceVariant;

    switch (status.toUpperCase()) {
      case 'WIN':
        return Colors.green[700]!;
      case 'LOSS':
        return Colors.red[700]!;
      case 'BREAK_EVEN':
        return Colors.orange[700]!;
      default:
        return theme.colorScheme.primary;
    }
  }
}

