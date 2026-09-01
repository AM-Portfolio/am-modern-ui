import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_detail.dart';
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(line.symbol.isNotEmpty ? line.symbol[0] : '?'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (line.companyName?.isNotEmpty == true)
                        Text(line.companyName!, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                    ],
                  ),
                ),
                Text('${weightPercent.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (weightPercent / 100.0).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: context.colors.border,
                valueColor: AlwaysStoppedAnimation(context.colors.actionPrimaryBg),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${line.quantity.toInt()} units'),
                Text(fmt.format(lineValue)),
                Text(
                  BdDashboardMath.formatPnlPercent(pnlPct, hasMarket: hasMarket),
                  style: TextStyle(color: pnlColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
