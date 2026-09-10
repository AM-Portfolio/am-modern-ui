import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Mobile card for a single today's filled paper order.
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
        ? colors.statusError
        : colors.marketPositiveIndicator;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');
    final qtyLabel =
        qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 2);
    final priceLabel = price > 0 ? '₹${fmt.format(price)}' : '—';

    return AmEntityMobileCard(
      leading: AmLetterAvatar(text: symbol),
      title: Text(
        symbol,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      titleBadge: Text(
        side,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _sideColor(context),
              fontWeight: FontWeight.w700,
            ),
      ),
      subtitle: timeLabel,
      primaryMetric: Text(
        priceLabel,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      metrics: [
        AmCardMetricItem(label: 'Type', valueText: orderType),
        AmCardMetricItem(label: 'Qty', valueText: qtyLabel),
        AmCardMetricItem(label: 'Status', valueText: status),
        AmCardMetricItem(
          label: 'Side',
          valueText: side,
          valueColor: _sideColor(context),
        ),
      ],
      cardColor: colors.cardSurface,
      borderColor: colors.divider,
    );
  }
}
