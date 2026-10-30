import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/trade_holding_view_model.dart';
import 'trade_overview_selector.dart';

/// Dialog to preview and select trades for a given date/period.
///
/// Theme-only: [context.colors], [AppRadii], [AppSpacing], Trade accent.
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

  Color _accent(BuildContext context) =>
      ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedTradeIds);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _accent(context);
    final periodText = _getPeriodText(context);

    return Dialog(
      backgroundColor: colors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.dialog),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadii.xl),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: AppRadii.button,
                    ),
                    child: Icon(Icons.analytics, color: accent, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trades for $periodText',
                          style: context.text.sectionTitle(compact: true).copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${widget.trades.length} trade'
                          '${widget.trades.length != 1 ? 's' : ''} · '
                          '${_selectedIds.length} selected',
                          style: context.text.caption(compact: true).copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.trades.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: widget.trades.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final trade = widget.trades[index];
                        final isSelected =
                            _selectedIds.contains(trade.tradeId);
                        return _buildTradeCard(
                          context,
                          trade,
                          isSelected,
                          accent,
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colors.border.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppButton(
                    text: 'Clear All',
                    type: AppButtonType.text,
                    icon: Icons.clear_all,
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () => setState(() => _selectedIds.clear()),
                    height: 36,
                    textColor: colors.textSecondary,
                  ),
                  Row(
                    children: [
                      AppButton(
                        text: 'Cancel',
                        type: AppButtonType.secondary,
                        isOutlined: true,
                        onPressed: () => Navigator.of(context).pop(),
                        height: 36,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      AppButton(
                        text:
                            'Link ${_selectedIds.length} Trade${_selectedIds.length != 1 ? 's' : ''}',
                        type: AppButtonType.primary,
                        icon: Icons.check,
                        backgroundColor: accent,
                        onPressed: () =>
                            Navigator.of(context).pop(_selectedIds.toList()),
                        height: 36,
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

  String _getPeriodText(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    switch (widget.periodType) {
      case TradePeriodType.daily:
        return DateFormat('MMM dd, yyyy', locale).format(widget.date);
      case TradePeriodType.weekly:
        final weekStart = widget.date
            .subtract(Duration(days: widget.date.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'Week of ${DateFormat('MMM dd', locale).format(weekStart)} - '
            '${DateFormat('MMM dd, yyyy', locale).format(weekEnd)}';
      case TradePeriodType.monthly:
        return DateFormat('MMMM yyyy', locale).format(widget.date);
      case TradePeriodType.yearly:
        return 'Year ${DateFormat('yyyy', locale).format(widget.date)}';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No trades found for this period',
            style: context.text.sectionTitle(compact: true).copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try selecting a different date or period',
            style: context.text.caption(compact: true).copyWith(
                  color: colors.textSecondary.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeCard(
    BuildContext context,
    TradeHoldingViewModel trade,
    bool isSelected,
    Color accent,
  ) {
    final colors = context.colors;
    final profitLoss = trade.profitLoss ?? 0.0;
    final profitLossPercentage = trade.profitLossPercentage ?? 0.0;
    final isProfitable = profitLoss >= 0;
    final statusColor = _getStatusColor(context, trade.status);
    final locale = Localizations.localeOf(context).toString();

    return Material(
      color: colors.cardSurface.withValues(alpha: 0),
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
        borderRadius: AppRadii.input,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? accent
                  : colors.border.withValues(alpha: 0.45),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: AppRadii.input,
            color: isSelected
                ? accent.withValues(alpha: 0.08)
                : colors.surface.withValues(alpha: 0.55),
          ),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: accent,
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                          child: Text(
                            trade.symbol,
                            style: context.text.label(compact: true).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (trade.status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm - AppSpacing.xxs,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppRadii.xs),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              trade.status!.replaceAll('_', ' '),
                              style:
                                  context.text.caption(compact: true).copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: AppTypeScale.xs,
                                      ),
                            ),
                          ),
                        const Spacer(),
                        if (trade.tradePositionType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: trade.tradePositionType == 'LONG'
                                  ? context.statusSuccess.withValues(alpha: 0.15)
                                  : context.statusError.withValues(alpha: 0.15),
                              borderRadius: AppRadii.button,
                              border: Border.all(
                                color: trade.tradePositionType == 'LONG'
                                    ? context.statusSuccess
                                        .withValues(alpha: 0.3)
                                    : context.statusError
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              trade.tradePositionType!,
                              style:
                                  context.text.caption(compact: true).copyWith(
                                        fontSize: AppTypeScale.xs,
                                        fontWeight: FontWeight.w600,
                                        color: trade.tradePositionType == 'LONG'
                                            ? context.statusSuccess
                                            : context.statusError,
                                      ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (trade.entryTimestamp != null)
                          _buildDetailChip(
                            context,
                            Icons.calendar_today,
                            DateFormat('MMM dd, yyyy', locale)
                                .format(trade.entryTimestamp!),
                          ),
                        _buildDetailChip(
                          context,
                          Icons.shopping_cart,
                          'Qty: ${trade.quantity ?? 0}',
                        ),
                        _buildDetailChip(
                          context,
                          Icons.currency_rupee,
                          trade.entryPrice?.toStringAsFixed(2) ?? '0.00',
                        ),
                        if (trade.exitPrice != null)
                          _buildDetailChip(
                            context,
                            Icons.exit_to_app,
                            trade.exitPrice!.toStringAsFixed(2),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + AppSpacing.xxs,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isProfitable
                      ? context.statusSuccess.withValues(alpha: 0.1)
                      : context.statusError.withValues(alpha: 0.1),
                  borderRadius: AppRadii.button,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isProfitable ? '+' : ''}${profitLoss.toStringAsFixed(2)}',
                      style: context.text.label(compact: true).copyWith(
                            fontWeight: FontWeight.w700,
                            color: isProfitable
                                ? context.statusSuccess
                                : context.statusError,
                          ),
                    ),
                    Text(
                      '${isProfitable ? '+' : ''}${profitLossPercentage.toStringAsFixed(2)}%',
                      style: context.text.caption(compact: true).copyWith(
                            color: isProfitable
                                ? context.statusSuccess
                                : context.statusError,
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

  Widget _buildDetailChip(BuildContext context, IconData icon, String label) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm - AppSpacing.xxs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: context.text.caption(compact: true).copyWith(
                  fontSize: AppTypeScale.xs,
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String? status) {
    if (status == null) return context.colors.textSecondary;

    switch (status.toUpperCase()) {
      case 'WIN':
        return context.statusSuccess;
      case 'LOSS':
        return context.statusError;
      case 'BREAK_EVEN':
        return context.statusWarning;
      default:
        return _accent(context);
    }
  }
}
