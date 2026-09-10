import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compact single-row mobile card for an open paper position.
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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty ${qty.toStringAsFixed(0)} · Avg ${avg > 0 ? fmt.format(avg) : '—'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₹${fmt.format(unrealized)}',
                style: textTheme.titleSmall?.copyWith(
                  color: pnlColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'LTP ${ltp > 0 ? fmt.format(ltp) : '—'}',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
