import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_opportunity.dart';
import '../../shared/widgets/basket_status_badge.dart';
import 'customize_mini_stat.dart';

class CustomizeConstituentRowMobile extends StatelessWidget {
  final BasketItem item;
  final bool hasCalculated;
  final String investedText;
  final bool isExcluded;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onAddGap;
  final VoidCallback onSubstitute;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<int>? onTargetQtyChanged;

  const CustomizeConstituentRowMobile({
    super.key,
    required this.item,
    required this.hasCalculated,
    required this.investedText,
    required this.isExcluded,
    required this.onRemove,
    required this.onAdd,
    required this.onAddGap,
    required this.onSubstitute,
    required this.onQtyChanged,
    this.onTargetQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMissing = item.status == ItemStatus.missing && !isExcluded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            BasketStatusDot(status: item.status, isExcluded: isExcluded),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.status == ItemStatus.substitute &&
                        item.userHoldingSymbol != null
                    ? '${item.userHoldingSymbol!} (sub for ${item.stockSymbol})'
                    : item.stockSymbol,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isExcluded
                        ? context.textTertiary
                        : context.textPrimary,
                    decoration:
                        isExcluded ? TextDecoration.lineThrough : null),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            BasketStatusBadge(status: item.status, isExcluded: isExcluded),
            const SizedBox(width: 4),
            if (isExcluded)
              TextButton(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero),
                child: const Text('Restore'),
              )
            else if (isMissing)
              TextButton(
                onPressed: onSubstitute,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero),
                child: const Text('Swap'),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz,
                        size: 20, color: context.textSecondary),
                    onSelected: (val) {
                      if (val == 'remove') onRemove();
                      if (val == 'substitute') onSubstitute();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove from basket')),
                      if (item.alternatives.isNotEmpty)
                        const PopupMenuItem(
                            value: 'substitute',
                            child: Text('Find substitute')),
                    ],
                  ),
                ],
              ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            CustomizeMiniStat(
                label: 'ETF Wt.',
                value: '${item.etfWeight.toStringAsFixed(1)}%'),
            const SizedBox(width: 16),
            if (item.lastPrice != null)
              CustomizeMiniStat(
                  label: 'Price',
                  value: '₹${item.lastPrice!.toStringAsFixed(1)}'),
            const SizedBox(width: 16),
            CustomizeMiniStat(label: 'Invested', value: investedText),
          ]),
          if ((item.heldQuantity ?? 0) > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.statusSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: context.statusSuccess.withValues(alpha: 0.3)),
              ),
              child: Text(
                  'Held: ${item.heldQuantity!.toInt()} units @ ₹${item.heldAveragePrice?.toStringAsFixed(0) ?? "—"}',
                  style: TextStyle(
                      fontSize: 10,
                      color: context.statusSuccess,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
      ),
    );
  }
}
