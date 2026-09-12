import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compact single-row mobile card for a today's paper order.
class PaperOrderMobileCard extends StatelessWidget {
  const PaperOrderMobileCard({
    super.key,
    required this.side,
    required this.symbol,
    required this.orderType,
    required this.qty,
    required this.price,
    required this.status,
    required this.timeLabel,
  });

  final String side;
  final String symbol;
  final String orderType;
  final double qty;
  final double price;
  final String status;
  final String timeLabel;

  Color _sideColor(BuildContext context) {
    final colors = context.colors;
    return side == 'SELL'
        ? colors.marketNegativeIndicator
        : colors.actionPrimaryBg;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');
    final qtyLabel =
        qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 2);
    final priceLabel = price > 0 ? '₹${fmt.format(price)}' : '—';
    final textTheme = Theme.of(context).textTheme;
    final sideColor = _sideColor(context);

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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      side,
                      style: textTheme.labelSmall?.copyWith(
                        color: sideColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$orderType · Qty $qtyLabel · $status',
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
                priceLabel,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeLabel,
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
