import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_opportunity.dart';
import '../../shared/widgets/basket_status_badge.dart';
import 'customize_qty_stepper.dart';

class CustomizeConstituentRowTablet extends StatelessWidget {
  final BasketItem item;
  final bool hasCalculated;
  final String investedText;
  final bool isExcluded;
  final double allocatedUnits;
  final int gapVsEtf;
  final bool canIncrease;
  final bool canDecrease;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onAddGap;
  final VoidCallback onSubstitute;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<int>? onTargetQtyChanged;
  final ValueChanged<int>? onDirectTargetQtySet;

  const CustomizeConstituentRowTablet({
    super.key,
    required this.item,
    required this.hasCalculated,
    required this.investedText,
    required this.isExcluded,
    required this.allocatedUnits,
    required this.gapVsEtf,
    required this.canIncrease,
    required this.canDecrease,
    required this.onRemove,
    required this.onAdd,
    required this.onAddGap,
    required this.onSubstitute,
    required this.onQtyChanged,
    this.onTargetQtyChanged,
    this.onDirectTargetQtySet,
  });

  @override
  Widget build(BuildContext context) {
    final isMissing = item.status == ItemStatus.missing && !isExcluded;
    final priceOk = item.lastPrice != null && item.lastPrice! > 0;
    final showStepper = hasCalculated &&
        onTargetQtyChanged != null &&
        priceOk &&
        (item.heldQuantity ?? 0) > 0 &&
        !isExcluded &&
        !isMissing;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: context.borderColor.withValues(alpha: 0.4))),
      ),
      child: Row(children: [
        const SizedBox(width: 12),
        Expanded(
            flex: 3,
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
        BasketStatusBadge(status: item.status, isExcluded: isExcluded),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(investedText,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: context.textPrimary)),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: showStepper
              ? CustomizeQtyStepper(
                  compact: true,
                  canIncrease: canIncrease,
                  canDecrease: canDecrease,
                  onDecrease: () => onTargetQtyChanged!(-1),
                  onIncrease: () => onTargetQtyChanged!(1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      allocatedUnits > 0
                          ? '${allocatedUnits.toInt()}'
                          : '—',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                )
              : Text(
                  priceOk && allocatedUnits > 0
                      ? '${allocatedUnits.toInt()}'
                      : '—',
                  style: TextStyle(fontSize: 12, color: context.textTertiary),
                ),
        ),
        const SizedBox(width: 8),
        CustomizeGapPill(
          gapVsEtf: gapVsEtf,
          priceOk: priceOk && (item.heldQuantity ?? 0) > 0,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, left: 4),
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
                  : IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: context.statusError),
                      onPressed: onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
        ),
      ]),
    );
  }
}
