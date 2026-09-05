import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_opportunity.dart';
import '../../shared/basket_item_status_theme.dart';
import '../../shared/widgets/basket_status_badge.dart';
import 'customize_qty_stepper.dart';

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
  final ValueChanged<int>? onDirectTargetQtySet;
  final double? customWeightPercent;
  final double allocatedUnits;
  final int gapVsEtf;
  final bool canIncrease;
  final bool canDecrease;

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
    this.onDirectTargetQtySet,
    this.customWeightPercent,
    this.allocatedUnits = 0,
    this.gapVsEtf = 0,
    this.canIncrease = false,
    this.canDecrease = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final isMissing = item.status == ItemStatus.missing && !isExcluded;
    final displaySymbol = item.status == ItemStatus.substitute &&
            item.userHoldingSymbol != null
        ? item.userHoldingSymbol!
        : item.stockSymbol;
    final initial =
        displaySymbol.isNotEmpty ? displaySymbol[0].toUpperCase() : '?';

    final etfW = item.etfWeight.clamp(0.0, 100.0);
    final heldQty = item.heldQuantity;
    final metaParts = <String>[
      if (item.status == ItemStatus.substitute &&
          (item.userHoldingSymbol?.isNotEmpty ?? false))
        'sub for ${item.stockSymbol}',
      'Wt ${etfW.toStringAsFixed(1)}%',
      'Inv $investedText',
      if (heldQty != null && heldQty > 0) 'Held ${heldQty.toInt()}',
    ];

    final fillRatio = etfW <= 0
        ? 0.0
        : ((customWeightPercent ?? 0) / etfW).clamp(0.0, 1.0);
    final barColor = BasketItemStatusTheme.colorFor(
      context,
      item.status,
      isExcluded: isExcluded,
    );

    final showAdjust = hasCalculated &&
        onTargetQtyChanged != null &&
        !isExcluded &&
        !isMissing &&
        (heldQty ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      ModuleColors.portfolio.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ModuleColors.portfolio,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displaySymbol,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isExcluded
                              ? colors.textTertiary
                              : colors.textPrimary,
                          decoration: isExcluded
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metaParts.join(' · '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: LinearProgressIndicator(
                          value: fillRatio,
                          minHeight: 4,
                          backgroundColor:
                              colors.border.withValues(alpha: 0.4),
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                BasketStatusBadge(status: item.status, isExcluded: isExcluded),
                const SizedBox(width: 2),
                if (isExcluded)
                  TextButton(
                    onPressed: onAdd,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Restore'),
                  )
                else if (isMissing)
                  TextButton(
                    onPressed: onSubstitute,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Swap'),
                  )
                else
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_horiz,
                        size: 18, color: colors.textSecondary),
                    onSelected: (val) {
                      if (val == 'remove') onRemove();
                      if (val == 'substitute') onSubstitute();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove from basket'),
                      ),
                      if (item.alternatives.isNotEmpty)
                        const PopupMenuItem(
                          value: 'substitute',
                          child: Text('Find substitute'),
                        ),
                    ],
                  ),
              ],
            ),
            if (showAdjust) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  CustomizeGapPill(
                    gapVsEtf: gapVsEtf,
                    priceOk: item.lastPrice != null && item.lastPrice! > 0,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        (item.lastPrice == null || item.lastPrice! <= 0)
                            ? null
                            : () => showCustomizeQtySheet(
                                  context: context,
                                  item: item,
                                  allocatedUnits: allocatedUnits.toInt(),
                                  gapVsEtf: gapVsEtf,
                                  onDelta: onTargetQtyChanged!,
                                  onSetQty: onDirectTargetQtySet,
                                ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      allocatedUnits > 0
                          ? 'Adjust ${allocatedUnits.toInt()} units'
                          : 'Adjust qty',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
