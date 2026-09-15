import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../models/timing_bucket.dart';

/// Single ranked table (Best or Worst) for Analysis → Timing.
class TimingRankTable extends StatelessWidget {
  const TimingRankTable({
    super.key,
    required this.title,
    required this.bucketLabel,
    required this.rows,
    required this.isBest,
    this.emptyMessage,
  });

  final String title;
  final String bucketLabel;
  final List<TimingBucket> rows;
  final bool isBest;
  final String? emptyMessage;

  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final accent =
        isBest ? context.statusSuccess : context.statusError;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.45),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md - AppSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isBest ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: AppSpacing.sm - AppSpacing.xxs),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'by Avg PnL',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xxs),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg - 4),
              child: Text(
                emptyMessage ?? 'No data in this range',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            _header(context, bucketLabel),
            Divider(height: AppSpacing.md - AppSpacing.xs, color: colors.divider),
            ...rows.map((b) => _row(context, b)),
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
        Expanded(flex: 2, child: Text(bucketLabel, style: style)),
        Expanded(child: Text('Trades', style: style, textAlign: TextAlign.end)),
        Expanded(
            child: Text('Win %', style: style, textAlign: TextAlign.end)),
        Expanded(
          flex: 2,
          child: Text('Avg PnL', style: style, textAlign: TextAlign.end),
        ),
        Expanded(
          flex: 2,
          child: Text('PnL', style: style, textAlign: TextAlign.end),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, TimingBucket bucket) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final pnlColor =
        bucket.pnl >= 0 ? context.statusSuccess : context.statusError;
    final avgColor =
        bucket.avgPnl >= 0 ? context.statusSuccess : context.statusError;
    final body = theme.textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              bucket.label,
              style: body?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
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
              style: body?.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _inr.format(bucket.avgPnl),
              style:
                  body?.copyWith(color: avgColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _inr.format(bucket.pnl),
              style:
                  body?.copyWith(color: pnlColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
