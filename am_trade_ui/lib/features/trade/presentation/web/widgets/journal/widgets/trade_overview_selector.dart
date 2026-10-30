import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/trade_holding_view_model.dart';

/// Period type for trade overview
enum TradePeriodType { daily, weekly, monthly, yearly }

/// Widget to select and preview trades for a given date/period.
///
/// Theme-only: [context.colors], [AppRadii], [AppSpacing], Trade accent.
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
    /// When true, omit inner card chrome — parent supplies
    /// [JournalFieldDecoration.borderLabel] (same as Notes / Title).
    this.embedded = false,
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
  final bool embedded;

  Color _accent(BuildContext context) =>
      ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _accent(context);
    final tradesCount = availableTrades.length;
    final selectedCount = selectedTradeIds.length;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded) ...[
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 18, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Trade Overview',
                style: context.text.label(compact: true).copyWith(
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (readOnly && selectedCount > 0) ...[
          _buildViewLinkedTradesButton(context, selectedCount, accent),
        ] else ...[
          _buildPeriodSelector(context, accent),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: AppRadii.button,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.45),
                ),
                borderRadius: AppRadii.button,
                color: colors.cardSurface,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _getDateRangeText(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.body(compact: true).copyWith(
                            color: colors.textPrimary,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildViewTradesButton(
            context,
            tradesCount,
            selectedCount,
            accent,
          ),
        ],
      ],
    );

    if (embedded) return body;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border.withValues(alpha: 0.45)),
        borderRadius: AppRadii.input,
        color: colors.surface.withValues(alpha: 0.45),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: body,
    );
  }

  Widget _buildViewLinkedTradesButton(
    BuildContext context,
    int count,
    Color accent,
  ) {
    final colors = context.colors;
    return Material(
      color: colors.cardSurface.withValues(alpha: 0),
      child: InkWell(
        onTap: onViewTrades,
        borderRadius: AppRadii.button,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: AppRadii.button,
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: AppRadii.button,
                ),
                child: Icon(Icons.link, size: 20, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View Linked Trades',
                      style: context.text.body(compact: true).copyWith(
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '$count trade${count != 1 ? 's' : ''} linked to this entry',
                      style: context.text.caption(compact: true).copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, Color accent) {
    final colors = context.colors;
    // Labels only — icons force a min width that overflows the right rail
    // when the module sidebar expands.
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = !constraints.maxWidth.isFinite ||
            constraints.maxWidth < 280;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<TradePeriodType>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: TradePeriodType.daily,
                label: Text(narrow ? 'D' : 'Day'),
              ),
              ButtonSegment(
                value: TradePeriodType.weekly,
                label: Text(narrow ? 'W' : 'Week'),
              ),
              ButtonSegment(
                value: TradePeriodType.monthly,
                label: Text(narrow ? 'M' : 'Month'),
              ),
              ButtonSegment(
                value: TradePeriodType.yearly,
                label: Text(narrow ? 'Y' : 'Year'),
              ),
            ],
            selected: {selectedPeriod},
            onSelectionChanged: (newSelection) {
              onPeriodChanged(newSelection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: WidgetStateProperty.all(
                context.text.caption(compact: true).copyWith(
                      fontSize: AppTypeScale.xs,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm - AppSpacing.xxs,
                  vertical: AppSpacing.xs,
                ),
              ),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.actionPrimaryFg;
                }
                return colors.textSecondary;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.actionPrimaryBg;
                }
                return colors.surface.withValues(alpha: 0.55);
              }),
              side: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return BorderSide(color: colors.actionPrimaryBg);
                }
                return BorderSide(color: colors.border.withValues(alpha: 0.4));
              }),
            ),
          ),
        );
      },
    );
  }

  String _getDateRangeText(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    switch (selectedPeriod) {
      case TradePeriodType.daily:
        return DateFormat('MMM dd, yyyy', locale).format(selectedDate);
      case TradePeriodType.weekly:
        final weekStart = selectedDate
            .subtract(Duration(days: selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('MMM dd', locale).format(weekStart)} - '
            '${DateFormat('MMM dd, yyyy', locale).format(weekEnd)}';
      case TradePeriodType.monthly:
        return DateFormat('MMMM yyyy', locale).format(selectedDate);
      case TradePeriodType.yearly:
        return DateFormat('yyyy', locale).format(selectedDate);
    }
  }

  Widget _buildViewTradesButton(
    BuildContext context,
    int total,
    int selected,
    Color accent,
  ) {
    final colors = context.colors;
    final active = total > 0;
    return Material(
      color: colors.cardSurface.withValues(alpha: 0),
      child: InkWell(
        onTap: active ? onViewTrades : null,
        borderRadius: AppRadii.button,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.10)
                : colors.surface.withValues(alpha: 0.35),
            borderRadius: AppRadii.button,
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.35)
                  : colors.border.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm - AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: active
                      ? accent.withValues(alpha: 0.15)
                      : colors.surface.withValues(alpha: 0.55),
                  borderRadius: AppRadii.button,
                ),
                child: Icon(
                  active ? Icons.visibility_outlined : Icons.info_outline,
                  size: 18,
                  color: active ? accent : colors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active ? 'View & Link Trades' : 'No Trades Available',
                      style: context.text.body(compact: true).copyWith(
                            fontWeight: FontWeight.w600,
                            color: active
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      active
                          ? '$total available${selected > 0 ? ' · $selected selected' : ''}'
                          : 'Select a date with trades',
                      style: context.text.caption(compact: true).copyWith(
                            color: active && selected > 0
                                ? accent
                                : colors.textSecondary,
                            fontWeight: selected > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                    ),
                  ],
                ),
              ),
              if (active)
                Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final colors = context.colors;
    final accent = _accent(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: accent,
                onPrimary: colors.actionPrimaryFg,
              ),
        ),
        child: child!,
      ),
    );

    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }
}
