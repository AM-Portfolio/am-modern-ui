import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/mf_scheme_view.dart';

class MfFundCard extends StatelessWidget {
  const MfFundCard({
    required this.fund,
    required this.period,
    required this.onTap,
    this.onInvest,
    this.onSip,
    super.key,
  });

  final MfSchemeView fund;
  final MfReturnPeriod period;
  final VoidCallback onTap;
  final VoidCallback? onInvest;
  final VoidCallback? onSip;

  Color _accent(BuildContext context) =>
      ModuleColorProvider.maybeOf(context) ?? ModuleColors.mutualFund;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final ret = fund.returnFor(period.apiKey);
    final navFmt = NumberFormat('#,##0.00');
    final pctFmt = NumberFormat('+0.00%;-0.00%');
    final navUp = (fund.navChangePercent ?? 0) >= 0;
    final retUp = (ret ?? 0) >= 0;
    final showReturn = ret != null;
    final showMinSip = fund.minSip != null;
    final showMinInvest = fund.minLumpsum != null;
    final showAum = fund.displayAum != null;
    final showTer = fund.displayExpenseRatio != null;
    // Second strip only when real catalog fields exist — never empty placeholders.
    final showMetricsRow =
        showMinSip || showMinInvest || showAum || showTer;
    final aumFmt = NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 0);
    final avatarLabel =
        fund.amcLabel.isNotEmpty ? fund.amcLabel : fund.category;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AmcAvatar(label: avatarLabel, accent: accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fund.shortName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                            height: 1.25,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fund.metaLine,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Right rail: return when known, else EOD NAV (honest dig surface).
              if (showReturn)
                _RightStat(
                  value: pctFmt.format(ret / 100),
                  label: '${period.label} return',
                  valueColor: retUp
                      ? context.marketPositive
                      : context.marketNegative,
                )
              else
                _RightStat(
                  value: fund.nav != null
                      ? '₹${navFmt.format(fund.nav)}'
                      : '—',
                  label: fund.metricsIllustrative ? 'NAV' : 'EOD NAV',
                  valueColor: context.textPrimary,
                  subValue: fund.navChangePercent == null
                      ? null
                      : pctFmt.format(fund.navChangePercent! / 100),
                  subColor: navUp
                      ? context.marketPositive
                      : context.marketNegative,
                ),
            ],
          ),
          if (showMetricsRow) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  for (final m in [
                    if (showMinInvest)
                      _Metric(
                        label: 'Min invest',
                        value: '₹${fund.minLumpsum!.toStringAsFixed(0)}',
                      ),
                    if (showMinSip)
                      _Metric(
                        label: 'Min SIP',
                        value: '₹${fund.minSip!.toStringAsFixed(0)}',
                      ),
                    if (showAum)
                      _Metric(
                        label: 'AUM',
                        value: aumFmt.format(fund.displayAum),
                      ),
                    if (showTer)
                      _Metric(
                        label: 'Expense ratio',
                        value:
                            '${fund.displayExpenseRatio!.toStringAsFixed(2)}%',
                      ),
                  ].indexed) ...[
                    if (m.$1 > 0)
                      Container(
                        width: 1,
                        height: 36,
                        color: context.borderColor,
                      ),
                    Expanded(child: m.$2),
                  ],
                ],
              ),
            ),
          ],
          if (fund.returns.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _ReturnsStrip(
              returns: fund.returns,
              selected: period,
              accent: accent,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    if (fund.amcLabel.isNotEmpty) fund.amcLabel,
                    fund.isin,
                    if (!fund.digPurchaseEnabled)
                      'Browse only'
                    else if (fund.navStale)
                      'EOD stale'
                    else if (fund.navCaption.isNotEmpty)
                      fund.navCaption,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onSip != null)
                TextButton(onPressed: onSip, child: const Text('SIP')),
              if (onInvest != null) ...[
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: onInvest,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Invest'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RightStat extends StatelessWidget {
  const _RightStat({
    required this.value,
    required this.label,
    required this.valueColor,
    this.subValue,
    this.subColor,
  });

  final String value;
  final String label;
  final Color valueColor;
  final String? subValue;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.textSecondary,
              ),
        ),
        if (subValue != null)
          Text(
            subValue!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: subColor ?? context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
      ],
    );
  }
}

class _AmcAvatar extends StatelessWidget {
  const _AmcAvatar({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final letter = label.trim().isEmpty ? 'F' : label.trim()[0].toUpperCase();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.textSecondary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? context.textPrimary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReturnsStrip extends StatelessWidget {
  const _ReturnsStrip({
    required this.returns,
    required this.selected,
    required this.accent,
  });

  final Map<String, double?> returns;
  final MfReturnPeriod selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final keys = ['1M', '3M', '1Y', '3Y', '5Y'];
    final pctFmt = NumberFormat('+0.0%;-0.0%');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final k in keys)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: k == selected.apiKey
                      ? accent.withValues(alpha: 0.12)
                      : context.surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: k == selected.apiKey
                        ? accent.withValues(alpha: 0.4)
                        : context.borderColor,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      k,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.textSecondary,
                          ),
                    ),
                    Text(
                      returns[k] == null
                          ? '—'
                          : pctFmt.format(returns[k]! / 100),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: returns[k] == null
                                ? context.textSecondary
                                : (returns[k]! >= 0
                                    ? context.marketPositive
                                    : context.marketNegative),
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
