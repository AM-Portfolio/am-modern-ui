import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../models/timing_bucket.dart';
import 'timing_kpi_row.dart';

/// Breakdown table for Analysis → Timing — design-system [SortableTable].
class TimingRankTable extends StatelessWidget {
  const TimingRankTable({
    super.key,
    required this.title,
    required this.bucketLabel,
    required this.rows,
    this.avgColumnLabel = 'AVG P&L (₹)',
    this.emptyMessage,
    this.showLowSampleBadges = true,
  });

  final String title;
  final String bucketLabel;
  final List<TimingBucket> rows;
  final String avgColumnLabel;
  final String? emptyMessage;
  final bool showLowSampleBadges;

  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return AppCard(
      padded: false,
      elevation: 0,
      backgroundColor: colors.cardSurface,
      margin: EdgeInsets.zero,
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
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colors.border.withValues(alpha: 0.35),
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
          else
            AmAdaptiveTableCardView<TimingBucket>(
              items: rows,
              breakpoint: 720,
              spacing: AppSpacing.sm,
              padding: const EdgeInsets.all(AppSpacing.md),
              tableBuilder: (context, items) => SortableTable<TimingBucket>(
                items: items,
                shrinkWrap: true,
                rowHeight: 48,
                initialSortColumnIndex: 3,
                initialSortDirection: SortDirection.descending,
                headerTextStyle: context.text.caption(compact: true).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                columns: _columns(context),
              ),
              cardBuilder: (context, bucket, _) =>
                  _TimingBucketCard(
                    bucket: bucket,
                    avgColumnLabel: avgColumnLabel,
                    showLowSampleBadges: showLowSampleBadges,
                  ),
            ),
        ],
      ),
    );
  }

  List<SortableColumn<TimingBucket>> _columns(BuildContext context) {
    final colors = context.colors;
    final body = context.text.body(compact: true);

    return [
      SortableColumn<TimingBucket>(
        title: bucketLabel.toUpperCase(),
        flex: 2,
        sortBy: (b) => b.label,
        builder: (bucket) => Row(
          children: [
            Flexible(
              child: Text(
                bucket.label,
                style: body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showLowSampleBadges && bucket.isLowSample) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: ModuleColors.trade.withValues(alpha: 0.12),
                  borderRadius: AppRadii.chip,
                ),
                child: Text(
                  'Low',
                  style: context.text.caption(compact: true).copyWith(
                        color: ModuleColors.trade,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
      SortableColumn<TimingBucket>(
        title: 'TRADES',
        sortBy: (b) => b.trades,
        textAlign: TextAlign.end,
        builder: (bucket) => Text(
          '${bucket.trades}',
          textAlign: TextAlign.end,
          style: body.copyWith(color: colors.textPrimary),
        ),
      ),
      SortableColumn<TimingBucket>(
        title: 'WIN RATE',
        sortBy: (b) => b.winRatePercent,
        textAlign: TextAlign.end,
        builder: (bucket) {
          final winColor = bucket.winRatePercent == null
              ? colors.textSecondary
              : (bucket.winRatePercent! >= 50
                  ? context.statusSuccess
                  : context.statusError);
          return Text(
            bucket.winRatePercent == null
                ? '—'
                : '${bucket.winRatePercent!.toStringAsFixed(0)}%',
            textAlign: TextAlign.end,
            style: body.copyWith(color: winColor, fontWeight: FontWeight.w600),
          );
        },
      ),
      SortableColumn<TimingBucket>(
        title: 'TOTAL P&L (₹)',
        flex: 2,
        sortBy: (b) => b.pnl,
        textAlign: TextAlign.end,
        builder: (bucket) {
          final pnlColor =
              bucket.pnl >= 0 ? context.statusSuccess : context.statusError;
          return Text(
            _signedInr(bucket.pnl),
            textAlign: TextAlign.end,
            style: body.copyWith(color: pnlColor, fontWeight: FontWeight.w700),
          );
        },
      ),
      SortableColumn<TimingBucket>(
        title: avgColumnLabel,
        flex: 2,
        sortBy: (b) => b.avgPnl,
        textAlign: TextAlign.end,
        builder: (bucket) {
          final avgColor =
              bucket.avgPnl >= 0 ? context.statusSuccess : context.statusError;
          final text = bucket.eligibleTrades == 0 && bucket.winRatePercent == null
              ? '—'
              : _signedInr(bucket.avgPnl);
          return Text(
            text,
            textAlign: TextAlign.end,
            style: body.copyWith(color: avgColor, fontWeight: FontWeight.w700),
          );
        },
      ),
      SortableColumn<TimingBucket>(
        title: 'AVG HOLD TIME',
        flex: 2,
        sortBy: (b) => b.avgHoldMinutes,
        textAlign: TextAlign.end,
        builder: (bucket) => Text(
          bucket.avgHoldMinutes == null
              ? '—'
              : formatHoldDuration(bucket.avgHoldMinutes!),
          textAlign: TextAlign.end,
          style: body.copyWith(color: colors.textPrimary),
        ),
      ),
      SortableColumn<TimingBucket>(
        title: 'R:R',
        flex: 2,
        sortBy: (b) => b.riskReward,
        textAlign: TextAlign.end,
        builder: (bucket) => _RrCell(value: bucket.riskReward),
      ),
    ];
  }

  static String _signedInr(double value) {
    final formatted = _inr.format(value.abs());
    if (value > 0) return '+$formatted';
    if (value < 0) return '-$formatted';
    return formatted;
  }
}

class _TimingBucketCard extends StatelessWidget {
  const _TimingBucketCard({
    required this.bucket,
    required this.avgColumnLabel,
    required this.showLowSampleBadges,
  });

  final TimingBucket bucket;
  final String avgColumnLabel;
  final bool showLowSampleBadges;

  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pnlColor =
        bucket.pnl >= 0 ? context.statusSuccess : context.statusError;

    return AppCard(
      elevation: 0,
      backgroundColor: colors.cardSurface,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bucket.label,
                  style: context.text.body(compact: true).copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                ),
              ),
              if (showLowSampleBadges && bucket.isLowSample)
                Text(
                  'Low',
                  style: context.text.caption(compact: true).copyWith(
                        color: ModuleColors.trade,
                        fontWeight: FontWeight.w700,
                      ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _kv(context, 'Trades', '${bucket.trades}'),
          _kv(
            context,
            'Win rate',
            bucket.winRatePercent == null
                ? '—'
                : '${bucket.winRatePercent!.toStringAsFixed(0)}%',
          ),
          _kv(context, 'Total P&L', _signedInr(bucket.pnl), valueColor: pnlColor),
          _kv(
            context,
            avgColumnLabel,
            bucket.eligibleTrades == 0 && bucket.winRatePercent == null
                ? '—'
                : _signedInr(bucket.avgPnl),
          ),
          _kv(
            context,
            'Avg hold',
            bucket.avgHoldMinutes == null
                ? '—'
                : formatHoldDuration(bucket.avgHoldMinutes!),
          ),
          _kv(
            context,
            'R:R',
            bucket.riskReward?.toStringAsFixed(1) ?? '—',
          ),
        ],
      ),
    );
  }

  Widget _kv(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.caption(compact: true).copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: context.text.body(compact: true).copyWith(
                  color: valueColor ?? colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  static String _signedInr(double value) {
    final formatted = _inr.format(value.abs());
    if (value > 0) return '+$formatted';
    if (value < 0) return '-$formatted';
    return formatted;
  }
}

/// R:R value + horizontal bar (green ≥1, red &lt;1).
class _RrCell extends StatelessWidget {
  const _RrCell({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (value == null) {
      return Text(
        '—',
        textAlign: TextAlign.end,
        style: context.text.body(compact: true).copyWith(
              color: colors.textSecondary,
            ),
      );
    }

    final rr = value!;
    final barColor =
        rr >= 1.0 ? context.statusSuccess : context.statusError;
    final fraction = (rr.abs() / 3.0).clamp(0.08, 1.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          rr.toStringAsFixed(1),
          style: context.text.body(compact: true).copyWith(
                color: barColor,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 56,
          height: AppSpacing.sm,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
