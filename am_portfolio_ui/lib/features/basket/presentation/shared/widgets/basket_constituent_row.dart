import 'package:flutter/material.dart';

import '../../../domain/models/basket_opportunity.dart';
import '../../../domain/services/basket_currency_formatter.dart';
import '../../customize/widgets/customize_constituent_row_desktop.dart';
import '../../customize/widgets/customize_constituent_row_mobile.dart';
import '../../customize/widgets/customize_constituent_row_tablet.dart';
import '../../utils/basket_responsive.dart';

/// Unified constituent row for the customize step — delegates to the
/// mobile, tablet, or desktop layout based on viewport width.
class BasketConstituentRow extends StatelessWidget {
  final BasketItem item;
  final bool hasCalculated;
  final bool isExcluded;
  final double investmentAmount;
  final double? customWeightPercent;
  final double allocatedUnits;
  final double baseTargetQuantity;
  final int gapVsEtf;
  final bool canIncrease;
  final bool canDecrease;
  final int originalIdx;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onAddGap;
  final VoidCallback onSubstitute;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<int>? onTargetQtyChanged;
  final ValueChanged<int>? onDirectTargetQtySet;
  final ValueChanged<int>? onDirectTargetQtyChanged;

  const BasketConstituentRow({
    super.key,
    required this.item,
    required this.hasCalculated,
    required this.isExcluded,
    required this.investmentAmount,
    this.customWeightPercent,
    required this.allocatedUnits,
    required this.baseTargetQuantity,
    required this.gapVsEtf,
    required this.canIncrease,
    required this.canDecrease,
    required this.originalIdx,
    required this.onRemove,
    required this.onAdd,
    required this.onAddGap,
    required this.onSubstitute,
    required this.onQtyChanged,
    this.onTargetQtyChanged,
    this.onDirectTargetQtySet,
    this.onDirectTargetQtyChanged,
  });

  /// Invested amount label for mobile/tablet rows and desktop context.
  static String investedText(BasketItem item) {
    if (item.lastPrice == null) return '—';
    if ((item.buyQuantity == null || item.buyQuantity == 0) &&
        item.heldQuantity != null &&
        item.heldQuantity! > 0) {
      return BasketCurrencyFormatter.formatInr(
          item.heldQuantity! * item.lastPrice!);
    }
    if (item.buyQuantity == null || item.buyQuantity == 0) return '—';
    return BasketCurrencyFormatter.formatInr(
        item.lastPrice! * item.buyQuantity!);
  }

  @override
  Widget build(BuildContext context) {
    final invested = investedText(item);

    if (BasketResponsive.isMobile(context)) {
      return CustomizeConstituentRowMobile(
        item: item,
        hasCalculated: hasCalculated,
        investedText: invested,
        isExcluded: isExcluded,
        onRemove: onRemove,
        onAdd: onAdd,
        onAddGap: onAddGap,
        onSubstitute: onSubstitute,
        onQtyChanged: onQtyChanged,
        onTargetQtyChanged: onTargetQtyChanged,
        onDirectTargetQtySet: onDirectTargetQtySet,
        allocatedUnits: allocatedUnits,
        gapVsEtf: gapVsEtf,
        canIncrease: canIncrease,
        canDecrease: canDecrease,
      );
    }

    if (BasketResponsive.isTablet(context)) {
      return CustomizeConstituentRowTablet(
        item: item,
        hasCalculated: hasCalculated,
        investedText: invested,
        isExcluded: isExcluded,
        allocatedUnits: allocatedUnits,
        gapVsEtf: gapVsEtf,
        canIncrease: canIncrease,
        canDecrease: canDecrease,
        onRemove: onRemove,
        onAdd: onAdd,
        onAddGap: onAddGap,
        onSubstitute: onSubstitute,
        onQtyChanged: onQtyChanged,
        onTargetQtyChanged: onTargetQtyChanged,
        onDirectTargetQtySet: onDirectTargetQtySet,
      );
    }

    return CustomizeConstituentRowDesktop(
      item: item,
      hasCalculated: hasCalculated,
      investedText: invested,
      investmentAmount: investmentAmount,
      customWeightPercent: customWeightPercent,
      allocatedUnits: allocatedUnits,
      baseTargetQuantity: baseTargetQuantity,
      gapVsEtf: gapVsEtf,
      canIncrease: canIncrease,
      canDecrease: canDecrease,
      isExcluded: isExcluded,
      originalIdx: originalIdx,
      onRemove: onRemove,
      onAdd: onAdd,
      onAddGap: onAddGap,
      onSubstitute: onSubstitute,
      onQtyChanged: onQtyChanged,
      onTargetQtyChanged: onTargetQtyChanged,
      onDirectTargetQtySet: onDirectTargetQtySet,
      onDirectTargetQtyChanged: onDirectTargetQtyChanged,
    );
  }
}
