import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_detail.dart';
import 'bd_dashboard_math.dart';

class BdFooterBar extends StatelessWidget {
  final BasketDetail basket;
  final DateTime lastFetchedAt;

  const BdFooterBar({
    super.key,
    required this.basket,
    required this.lastFetchedAt,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final hasMarket = BdDashboardMath.basketHasMarketPrices(basket);
    final pnlColor = !hasMarket
        ? context.colors.textSecondary
        : (basket.totalPnL >= 0 ? context.statusSuccess : context.statusError);
    final timeFmt = DateFormat('MMM dd, yyyy • hh:mm a');

    final stats = [
      _FooterStat('Total Investment', fmt.format(basket.totalInvestedValue), false, null),
      _FooterStat('Current Value', fmt.format(basket.totalCurrentValue), false, null),
      _FooterStat(
        'Unrealized P&L',
        hasMarket
            ? '${BdDashboardMath.formatPnlAmount(basket.totalPnL, fmt, hasMarket: true)} (${BdDashboardMath.formatPnlPercent(basket.pnlPercent, hasMarket: true)})'
            : 'At cost',
        hasMarket && basket.totalPnL >= 0,
        pnlColor,
      ),
      _FooterStat(
        'Last Updated',
        timeFmt.format(basket.updatedAt ?? lastFetchedAt),
        false,
        null,
      ),
    ];

    final isWide = MediaQuery.sizeOf(context).width >= AmBreakpoints.tablet;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? AppSpacing.xl : AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: isWide
              ? Row(
                  children: stats
                      .map((s) => Expanded(child: _StatCell(context: context, stat: s)))
                      .toList(),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: stats
                        .map((s) => SizedBox(
                              width: 168,
                              child: _StatCell(context: context, stat: s),
                            ))
                        .toList(),
                  ),
                ),
        ),
      ),
    );
  }
}

class _FooterStat {
  final String label;
  final String value;
  final bool highlight;
  final Color? valueColor;

  const _FooterStat(this.label, this.value, this.highlight, this.valueColor);
}

class _StatCell extends StatelessWidget {
  final BuildContext context;
  final _FooterStat stat;

  const _StatCell({required this.context, required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: this.context.colors.textSecondary,
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            stat.value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: stat.valueColor ??
                      (stat.highlight
                          ? this.context.statusSuccess
                          : this.context.colors.textPrimary),
                ),
          ),
        ],
      ),
    );
  }
}
