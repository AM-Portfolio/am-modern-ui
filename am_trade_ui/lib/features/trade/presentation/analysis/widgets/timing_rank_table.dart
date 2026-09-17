import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../models/timing_bucket.dart';
import 'timing_kpi_row.dart';

/// Breakdown table for Analysis → Timing — fixed columns matching the mock.
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

  // Fixed column widths so header/body never collapse into each other.
  static const double _sessionW = 140;
  static const double _tradesW = 72;
  static const double _winW = 88;
  static const double _pnlW = 120;
  static const double _avgW = 110;
  static const double _holdW = 110;
  static const double _rrW = 120;
  static const double _tableMinWidth =
      _sessionW + _tradesW + _winW + _pnlW + _avgW + _holdW + _rrW + 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
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
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth < _tableMinWidth
                    ? _tableMinWidth
                    : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Column(
                      children: [
                        _headerRow(context),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colors.border.withValues(alpha: 0.25),
                        ),
                        for (var i = 0; i < rows.length; i++) ...[
                          _dataRow(context, rows[i], i.isOdd),
                          if (i < rows.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: colors.border.withValues(alpha: 0.15),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    final style = context.text.caption(compact: true).copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _cell(bucketLabel.toUpperCase(), _sessionW, style, TextAlign.start),
          _cell('TRADES', _tradesW, style, TextAlign.end),
          _cell('WIN RATE', _winW, style, TextAlign.end),
          _cell('TOTAL P&L (₹)', _pnlW, style, TextAlign.end),
          _cell(avgColumnLabel, _avgW, style, TextAlign.end),
          _cell('AVG HOLD TIME', _holdW, style, TextAlign.end),
          _cell('R:R', _rrW, style, TextAlign.end),
        ],
      ),
    );
  }

  Widget _dataRow(BuildContext context, TimingBucket bucket, bool striped) {
    final colors = context.colors;
    final body = context.text.body(compact: true);
    final pnlColor =
        bucket.pnl >= 0 ? context.statusSuccess : context.statusError;
    final avgColor =
        bucket.avgPnl >= 0 ? context.statusSuccess : context.statusError;
    final winColor = bucket.winRatePercent == null
        ? colors.textSecondary
        : (bucket.winRatePercent! >= 50
            ? context.statusSuccess
            : context.statusError);

    return Container(
      color: striped
          ? colors.textPrimary.withValues(alpha: 0.025)
          : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _sessionW,
            child: Row(
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
          _cell(
            '${bucket.trades}',
            _tradesW,
            body.copyWith(color: colors.textPrimary),
            TextAlign.end,
          ),
          _cell(
            bucket.winRatePercent == null
                ? '—'
                : '${bucket.winRatePercent!.toStringAsFixed(0)}%',
            _winW,
            body.copyWith(color: winColor, fontWeight: FontWeight.w600),
            TextAlign.end,
          ),
          _cell(
            _signedInr(bucket.pnl),
            _pnlW,
            body.copyWith(color: pnlColor, fontWeight: FontWeight.w700),
            TextAlign.end,
          ),
          _cell(
            bucket.eligibleTrades == 0 && bucket.winRatePercent == null
                ? '—'
                : _signedInr(bucket.avgPnl),
            _avgW,
            body.copyWith(color: avgColor, fontWeight: FontWeight.w700),
            TextAlign.end,
          ),
          _cell(
            bucket.avgHoldMinutes == null
                ? '—'
                : formatHoldDuration(bucket.avgHoldMinutes!),
            _holdW,
            body.copyWith(color: colors.textPrimary),
            TextAlign.end,
          ),
          SizedBox(
            width: _rrW,
            child: _RrCell(value: bucket.riskReward),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    String text,
    double width,
    TextStyle? style,
    TextAlign align,
  ) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: style,
        textAlign: align,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
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

/// R:R value + mock-style horizontal bar (green ≥1, red &lt;1).
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
    // Cap visual at 3.0 for scale; keep a minimum visible stub.
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
