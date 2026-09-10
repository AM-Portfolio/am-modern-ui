import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Mobile card for a single open paper position.
class PaperPositionMobileCard extends StatelessWidget {
  const PaperPositionMobileCard({
    super.key,
    required this.symbol,
    required this.qty,
    required this.avg,
    required this.ltp,
    required this.unrealized,
    required this.unrealizedPct,
  });

  final String symbol;
  final double qty;
  final double avg;
  final double ltp;
  final double unrealized;
  final double unrealizedPct;

  Color _pnlColor(BuildContext context, double v) {
    final colors = context.colors;
    if (v > 0) return colors.marketPositiveIndicator;
    if (v < 0) return colors.marketNegativeIndicator;
    return colors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');
    final pnlColor = _pnlColor(context, unrealized);

    return AmEntityMobileCard(
      leading: AmLetterAvatar(text: symbol),
      title: Text(
        symbol,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      primaryMetric: Text(
        '₹${fmt.format(unrealized)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: pnlColor,
              fontWeight: FontWeight.w700,
            ),
      ),
      secondaryMetric: Text(
        '${unrealizedPct.toStringAsFixed(2)}%',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _pnlColor(context, unrealizedPct),
            ),
      ),
      metrics: [
        AmCardMetricItem(
          label: 'Qty',
          valueText: qty.toStringAsFixed(0),
        ),
        AmCardMetricItem(
          label: 'Avg',
          valueText: avg > 0 ? fmt.format(avg) : '—',
        ),
        AmCardMetricItem(
          label: 'LTP',
          valueText: ltp > 0 ? fmt.format(ltp) : '—',
        ),
        AmCardMetricItem(
          label: 'P&L',
          valueText: '₹${fmt.format(unrealized)}',
          valueColor: pnlColor,
          isHighlighted: true,
        ),
      ],
      cardColor: colors.cardSurface,
      borderColor: colors.divider,
    );
  }
}
