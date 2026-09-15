import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../models/timing_bucket.dart';
import 'timing_kpi_row.dart';

<<<<<<< HEAD
/// Breakdown table for Analysis → Timing — fixed columns matching the mock.
=======
/// Ranked table for Analysis → Timing (All / Best / Worst) — mock-aligned layout.
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
class TimingRankTable extends StatelessWidget {
  const TimingRankTable({
    super.key,
    required this.title,
    required this.bucketLabel,
    required this.rows,
    this.emptyMessage,
<<<<<<< HEAD
    this.showLowSampleBadges = true,
=======
    this.subtitle = 'Ranked by Avg PnL',
    this.showLowSampleBadges = true,
    this.showFormulaFooter = true,
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
  });

  final String title;
  final String bucketLabel;
  final List<TimingBucket> rows;
  final String? emptyMessage;
<<<<<<< HEAD
  final bool showLowSampleBadges;
=======
  final String subtitle;
  final bool showLowSampleBadges;
  final bool showFormulaFooter;
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70

  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

<<<<<<< HEAD
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
=======
  static const winRateTooltip =
      'Win % = trades with PnL > 0 ÷ trades with non-null PnL. Break-even is not a win.';
  static const avgPnlTooltip =
      'Avg PnL = sum of non-null PnL ÷ trades with non-null PnL.';
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
<<<<<<< HEAD
=======
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: colors.border.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
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
<<<<<<< HEAD
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
=======
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
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
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
<<<<<<< HEAD
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
=======
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _header(context, bucketLabel),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (var i = 0; i < rows.length; i++)
              _row(context, rows[i], i + 1, i.isOdd),
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
                  'Avg PnL = Σ PnL ÷ eligible. Best/Worst need ≥$minTradesForRank eligible trades.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
          ],
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
        ],
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );
<<<<<<< HEAD
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          _cell(bucketLabel.toUpperCase(), _sessionW, style, TextAlign.start),
          _cell('TRADES', _tradesW, style, TextAlign.end),
          _cell('WIN RATE', _winW, style, TextAlign.end),
          _cell('TOTAL P&L (₹)', _pnlW, style, TextAlign.end),
          _cell('AVG P&L (₹)', _avgW, style, TextAlign.end),
          _cell('AVG HOLD TIME', _holdW, style, TextAlign.end),
          _cell('R:R', _rrW, style, TextAlign.end),
        ],
      ),
    );
  }

  Widget _dataRow(BuildContext context, TimingBucket bucket, bool striped) {
=======
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text('#', style: style),
        ),
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
          child: Tooltip(
            message: avgPnlTooltip,
            child: Text('Avg PnL', style: style, textAlign: TextAlign.end),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('PnL', style: style, textAlign: TextAlign.end),
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
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
    final theme = Theme.of(context);
    final colors = context.colors;
    final body = theme.textTheme.bodyMedium;
    final pnlColor =
        bucket.pnl >= 0 ? context.statusSuccess : context.statusError;
    final avgColor =
        bucket.avgPnl >= 0 ? context.statusSuccess : context.statusError;
    final winColor = bucket.winRatePercent == null
        ? colors.textSecondary
        : (bucket.winRatePercent! >= 50
            ? context.statusSuccess
            : context.statusError);
<<<<<<< HEAD
    final rr = bucket.riskReward;

    return Container(
      color: striped
          ? colors.textPrimary.withValues(alpha: 0.025)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md - 2,
=======
    final body = theme.textTheme.bodySmall;

    return Container(
      color: striped
          ? colors.textPrimary.withValues(alpha: 0.03)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
<<<<<<< HEAD
            width: _sessionW,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    bucket.label,
                    style: body?.copyWith(
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
                      vertical: 1,
=======
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
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
                    ),
                    decoration: BoxDecoration(
                      color: ModuleColors.trade.withValues(alpha: 0.12),
                      borderRadius: AppRadii.chip,
<<<<<<< HEAD
                    ),
                    child: Text(
                      'Low',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: ModuleColors.trade,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
=======
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
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
              ],
            ),
          ),
          _cell(
            '${bucket.trades}',
            _tradesW,
            body?.copyWith(color: colors.textPrimary),
            TextAlign.end,
          ),
<<<<<<< HEAD
          _cell(
            bucket.winRatePercent == null
                ? '—'
                : '${bucket.winRatePercent!.toStringAsFixed(0)}%',
            _winW,
            body?.copyWith(color: winColor, fontWeight: FontWeight.w600),
            TextAlign.end,
          ),
          _cell(
            _signedInr(bucket.pnl),
            _pnlW,
            body?.copyWith(color: pnlColor, fontWeight: FontWeight.w700),
            TextAlign.end,
          ),
          _cell(
            bucket.eligibleTrades == 0 && bucket.winRatePercent == null
                ? '—'
                : _signedInr(bucket.avgPnl),
            _avgW,
            body?.copyWith(color: avgColor, fontWeight: FontWeight.w700),
            TextAlign.end,
          ),
          _cell(
            bucket.avgHoldMinutes == null
                ? '—'
                : formatHoldDuration(bucket.avgHoldMinutes!),
            _holdW,
            body?.copyWith(color: colors.textPrimary),
            TextAlign.end,
          ),
          SizedBox(
            width: _rrW,
            child: _RrCell(value: rr),
=======
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
              _signedInr(bucket.pnl),
              style:
                  body?.copyWith(color: pnlColor, fontWeight: FontWeight.w700),
              textAlign: TextAlign.end,
            ),
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
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

=======
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
  String _signedInr(double value) {
    final formatted = _inr.format(value.abs());
    if (value > 0) return '+$formatted';
    if (value < 0) return '-$formatted';
    return formatted;
  }
<<<<<<< HEAD
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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: barColor,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 56,
          height: 8,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
=======
>>>>>>> 75c323b63e8098e2ccf5c9a5530797fcf6bb5d70
}
