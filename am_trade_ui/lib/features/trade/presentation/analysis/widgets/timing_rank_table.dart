import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../models/timing_bucket.dart';
import 'timing_kpi_row.dart';

/// Ranked table for Analysis → Timing (All / Best / Worst) — mock-aligned layout.
class TimingRankTable extends StatelessWidget {
  const TimingRankTable({
    super.key,
    required this.title,
    required this.bucketLabel,
    required this.rows,
    this.emptyMessage,
    this.subtitle = 'Ranked by Avg PnL',
    this.showLowSampleBadges = true,
    this.showFormulaFooter = true,
  });

  final String title;
  final String bucketLabel;
  final List<TimingBucket> rows;
  final String? emptyMessage;
  final String subtitle;
  final bool showLowSampleBadges;
  final bool showFormulaFooter;

  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static const winRateTooltip =
      'Win % = trades with PnL > 0 ÷ trades with non-null PnL. Break-even is not a win.';
  static const avgPnlTooltip =
      'Avg PnL = sum of non-null PnL ÷ trades with non-null PnL.';
  static const rrTooltip =
      'R:R = avg win ÷ |avg loss| in this bucket (not stop-based R-multiple).';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: colors.border.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title — $subtitle',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                emptyMessage ?? 'No data in this range',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 720),
                child: Column(
                  children: [
                    _header(context, bucketLabel),
                    const SizedBox(height: AppSpacing.xs),
                    for (var i = 0; i < rows.length; i++)
                      _row(context, rows[i], i + 1, i.isOdd),
                  ],
                ),
              ),
            ),
            if (showFormulaFooter)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colors.border.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: Text(
                  'Win % = wins (PnL > 0) ÷ eligible (non-null PnL). '
                  'Avg PnL = Σ PnL ÷ eligible. '
                  'R:R = avg win ÷ |avg loss| (— when undefined). '
                  'Best/Worst need ≥$minTradesForRank eligible trades.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String bucketLabel) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
        );
    return Row(
      children: [
        SizedBox(width: 28, child: Text('#', style: style)),
        Expanded(flex: 3, child: Text(bucketLabel, style: style)),
        Expanded(child: Text('Trades', style: style, textAlign: TextAlign.end)),
        Expanded(
          child: Tooltip(
            message: winRateTooltip,
            child: Text('Win %', style: style, textAlign: TextAlign.end),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('Total P&L', style: style, textAlign: TextAlign.end),
        ),
        Expanded(
          flex: 2,
          child: Tooltip(
            message: avgPnlTooltip,
            child: Text('Avg P&L', style: style, textAlign: TextAlign.end),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('Avg Hold', style: style, textAlign: TextAlign.end),
        ),
        Expanded(
          flex: 2,
          child: Tooltip(
            message: rrTooltip,
            child: Text('R:R', style: style, textAlign: TextAlign.end),
          ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    TimingBucket bucket,
    int index,
    bool striped,
  ) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final pnlColor =
        bucket.pnl >= 0 ? context.statusSuccess : context.statusError;
    final avgColor =
        bucket.avgPnl >= 0 ? context.statusSuccess : context.statusError;
    final winColor = bucket.winRatePercent == null
        ? colors.textSecondary
        : (bucket.winRatePercent! >= 50
            ? context.statusSuccess
            : context.statusError);
    final rr = bucket.riskReward;
    final rrColor = rr == null
        ? colors.textSecondary
        : (rr >= 1 ? context.statusSuccess : context.statusError);
    final body = theme.textTheme.bodySmall;

    return Container(
      color: striped
          ? colors.textPrimary.withValues(alpha: 0.03)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: body?.copyWith(color: colors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  bucket.label,
                  style: body?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (showLowSampleBadges && bucket.isLowSample)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: ModuleColors.trade.withValues(alpha: 0.12),
                      borderRadius: AppRadii.chip,
                      border: Border.all(
                        color: ModuleColors.trade.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'Low sample',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: ModuleColors.trade,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${bucket.trades}',
              style: body?.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            child: Text(
              bucket.winRatePercent == null
                  ? '—'
                  : '${bucket.winRatePercent!.toStringAsFixed(0)}%',
              style: body?.copyWith(
                color: winColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _signedInr(bucket.pnl),
              style:
                  body?.copyWith(color: pnlColor, fontWeight: FontWeight.w700),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              bucket.eligibleTrades == 0 && bucket.winRatePercent == null
                  ? '—'
                  : _signedInr(bucket.avgPnl),
              style:
                  body?.copyWith(color: avgColor, fontWeight: FontWeight.w700),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              bucket.avgHoldMinutes == null
                  ? '—'
                  : formatHoldDuration(bucket.avgHoldMinutes!),
              style: body?.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  rr == null ? '—' : rr.toStringAsFixed(1),
                  style: body?.copyWith(
                    color: rrColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (rr != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 36,
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (rr / 3).clamp(0.0, 1.0),
                        backgroundColor:
                            colors.border.withValues(alpha: 0.25),
                        color: rrColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _signedInr(double value) {
    final formatted = _inr.format(value.abs());
    if (value > 0) return '+$formatted';
    if (value < 0) return '-$formatted';
    return formatted;
  }
}
