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
    final accent =
        isBest ? ModuleColors.analytics : theme.colorScheme.error;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      padding: const EdgeInsets.all(14),
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
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'by Expectancy',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                emptyMessage ?? 'No data in this range',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            _header(context, bucketLabel),
            const Divider(height: 12),
            ...rows.map((b) => _row(context, b)),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String bucketLabel) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          child: Text('Expect.', style: style, textAlign: TextAlign.end),
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
    final pnlColor = bucket.pnl >= 0
        ? ModuleColors.analytics
        : theme.colorScheme.error;
    final expColor = bucket.expectancy >= 0
        ? ModuleColors.analytics
        : theme.colorScheme.error;
    final body = theme.textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              bucket.label,
              style: body?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text('${bucket.trades}',
                style: body, textAlign: TextAlign.end),
          ),
          Expanded(
            child: Text(
              bucket.winRatePercent == null
                  ? '—'
                  : '${bucket.winRatePercent!.toStringAsFixed(0)}%',
              style: body,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _inr.format(bucket.expectancy),
              style: body?.copyWith(color: expColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _inr.format(bucket.pnl),
              style: body?.copyWith(color: pnlColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
