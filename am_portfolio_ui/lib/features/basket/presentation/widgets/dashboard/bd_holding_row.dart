import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_detail.dart';
import 'bd_dashboard_math.dart';

class BdHoldingRow extends StatelessWidget {
  final BasketLineDetail line;
  final double weightPercent;

  const BdHoldingRow({
    super.key,
    required this.line,
    required this.weightPercent,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final hasMarket = BdDashboardMath.hasMarketPrice(line);
    final pnlPct = BdDashboardMath.pnlPercent(line);
    final pnlColor = !hasMarket
        ? context.colors.textSecondary
        : (line.pnl >= 0 ? context.statusSuccess : context.statusError);
    final lineValue = BdDashboardMath.lineCurrentValue(line);
    final barValue = (weightPercent / 100.0).clamp(0.0, 1.0);
    final isSubstitute = line.status.toUpperCase() == 'SUBSTITUTE';
    final displaySymbol = line.symbol;
    final company = line.companyName?.isNotEmpty == true ? line.companyName! : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 28,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: ModuleColors.portfolio.withValues(alpha: 0.15),
                  child: Text(
                    displaySymbol.isNotEmpty ? displaySymbol[0] : '?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ModuleColors.portfolio),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displaySymbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(company, style: TextStyle(fontSize: 11, color: context.colors.textSecondary), overflow: TextOverflow.ellipsis),
                      if (isSubstitute && line.coversEtfSymbol?.isNotEmpty == true)
                        Text(
                          'sub for ${line.coversEtfSymbol}',
                          style: TextStyle(fontSize: 10, color: context.colors.textTertiary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weightPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: barValue,
                          minHeight: 4,
                          backgroundColor: context.colors.border,
                          valueColor: AlwaysStoppedAnimation(
                            ModuleColors.portfolio,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(flex: 8, child: Text('${line.quantity.toInt()}', style: const TextStyle(fontSize: 12))),
          Expanded(flex: 14, child: Text(fmt.format(lineValue), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(
            flex: 12,
            child: Text(
              BdDashboardMath.formatPnlAmount(line.pnl, fmt, hasMarket: hasMarket),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pnlColor),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              BdDashboardMath.formatPnlPercent(pnlPct, hasMarket: hasMarket),
              style: TextStyle(fontSize: 12, color: pnlColor),
            ),
          ),
        ],
      ),
    );
  }
}
