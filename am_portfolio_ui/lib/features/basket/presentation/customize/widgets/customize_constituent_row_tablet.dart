import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_opportunity.dart';
import '../../shared/widgets/basket_status_badge.dart';

class CustomizeConstituentRowTablet extends StatelessWidget {
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

  const CustomizeConstituentRowTablet({
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
      height: 52,
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: context.borderColor.withValues(alpha: 0.4))),
      ),
      child: Row(children: [
        const SizedBox(width: 12),
        Expanded(
            flex: 32,
            child: Row(children: [
              BasketStatusDot(status: item.status, isExcluded: isExcluded),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          item.status == ItemStatus.substitute &&
                                  item.userHoldingSymbol != null
                              ? item.userHoldingSymbol!
                              : item.stockSymbol,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isExcluded
                                  ? context.textTertiary
                                  : context.textPrimary,
                              decoration: isExcluded
                                  ? TextDecoration.lineThrough
                                  : null),
                          overflow: TextOverflow.ellipsis),
                      Text(item.sector,
                          style: TextStyle(
                              fontSize: 10, color: context.textTertiary),
                          overflow: TextOverflow.ellipsis),
                    ]),
              ),
            ])),
        Expanded(
            flex: 14,
            child: BasketStatusBadge(
                status: item.status, isExcluded: isExcluded)),
        Expanded(
            flex: 12,
            child: Text('${item.etfWeight.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12, color: context.textSecondary))),
        Expanded(
            flex: 18,
            child: Text(investedText,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: context.textPrimary))),
        Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: isExcluded
                  ? TextButton(
                      onPressed: onAdd,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero),
                      child: const Text('Restore'))
                  : isMissing
                      ? TextButton(
                          onPressed: onSubstitute,
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero),
                          child: const Text('Swap'))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: context.statusError),
                              onPressed: onRemove,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
            )),
        const SizedBox(width: 4),
      ]),
    );
  }
}
