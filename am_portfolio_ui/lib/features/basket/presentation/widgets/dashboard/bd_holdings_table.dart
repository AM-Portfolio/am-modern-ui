import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_detail.dart';
import '../../shared/basket_panel_styles.dart';
import 'bd_dashboard_math.dart';
import 'bd_holding_row.dart';

class BdHoldingsTable extends StatelessWidget {
  final List<BasketLineDetail> lines;
  final double totalCurrentValue;

  const BdHoldingsTable({
    super.key,
    required this.lines,
    required this.totalCurrentValue,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(child: Text('No holdings to display', style: TextStyle(color: context.colors.textSecondary))),
      );
    }

    final sorted = BdDashboardMath.sortedByWeight(lines, totalCurrentValue);

    Widget headerCell(String text, {TextAlign align = TextAlign.left}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: align,
          ),
        );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          color: context.backgroundColor,
          child: Row(
            children: [
              Expanded(flex: 28, child: headerCell('Stock / Company')),
              Expanded(flex: 18, child: headerCell('Weightage (%)')),
              Expanded(flex: 8, child: headerCell('Units')),
              Expanded(flex: 14, child: headerCell('Current Value (₹)')),
              Expanded(flex: 12, child: headerCell('P&L (₹)')),
              Expanded(flex: 10, child: headerCell('P&L (%)')),
            ],
          ),
        ),
        ...sorted.map((line) {
          final weight = BdDashboardMath.basketWeightPercent(line, totalCurrentValue);
          return BdHoldingRow(
            line: line,
            weightPercent: weight,
          );
        }),
      ],
    );
  }
}

class BdHoldingCard extends StatelessWidget {
  final BasketLineDetail line;
  final double weightPercent;

  const BdHoldingCard({
    super.key,
    required this.line,
    required this.weightPercent,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final hasMarket = BdDashboardMath.hasMarketPrice(line);
    final pnlPct = BdDashboardMath.pnlPercent(line);
    final pnlColor = !hasMarket
        ? context.colors.textSecondary
        : (line.pnl >= 0 ? context.statusSuccess : context.statusError);
    final lineValue = BdDashboardMath.lineCurrentValue(line);

    final theme = Theme.of(context);
    final colors = context.colors;
    final initial = line.symbol.isNotEmpty ? line.symbol[0] : '?';
    final meta = [
      '${line.quantity.toInt()} units',
      'Wt ${weightPercent.toStringAsFixed(1)}%',
      fmt.format(lineValue),
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BasketPanelStyles.insetPanel(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: ModuleColors.portfolio.withValues(alpha: 0.15),
            child: Text(
              initial,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ModuleColors.portfolio,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.symbol,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: LinearProgressIndicator(
                    value: (weightPercent / 100.0).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: colors.border.withValues(alpha: 0.4),
                    color: ModuleColors.portfolio,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            BdDashboardMath.formatPnlPercent(pnlPct, hasMarket: hasMarket),
            style: theme.textTheme.labelMedium?.copyWith(
              color: pnlColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
