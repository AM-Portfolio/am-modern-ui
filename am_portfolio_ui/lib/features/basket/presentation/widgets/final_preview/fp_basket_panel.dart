import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../utils/basket_allocation_math.dart';
import '../../utils/basket_responsive.dart';
import 'fp_panel_header.dart';
import 'fp_stock_row.dart';
import 'fp_status_pill.dart';

class FpBasketPanel extends StatelessWidget {
  final List<BasketItem> finalItems;
  final double replicaScore;
  final double investmentAmount;
  final double actualInvestmentCost;
  final int heldCount;
  final int subCount;

  const FpBasketPanel({
    super.key,
    required this.finalItems,
    required this.replicaScore,
    required this.investmentAmount,
    required this.actualInvestmentCost,
    required this.heldCount,
    required this.subCount,
  });

  /// Share of the intended basket budget this line represents.
  static double basketLineWeight(BasketItem item) =>
      BasketAllocationMath.basketLineWeight(item);

  /// Rupee allocation for this line in the basket being created (not just fresh buys).
  static double basketLineValue(BasketItem item, double investmentAmount) =>
      BasketAllocationMath.basketLineValue(item, investmentAmount);

  FpStatusPill _buildStatusPill(BuildContext context, BasketItem item) {
    if (item.status == ItemStatus.held) {
      return FpStatusPill(
        label: 'Direct Match',
        color: context.statusSuccess,
      );
    } else if (item.status == ItemStatus.substitute) {
      String? subLabel;
      if (item.userHoldingSymbol != null && item.userHoldingSymbol != item.stockSymbol) {
        subLabel = 'By ${item.userHoldingSymbol}';
      }
      return FpStatusPill(
        label: 'Substituted',
        subLabel: subLabel,
        color: context.colors.actionPrimaryBg,
      );
    }
    // Should not reach here for missing/excluded items
    return FpStatusPill(
      label: 'Unknown',
      color: context.colors.textTertiary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmtValue = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final compact = BasketResponsive.useCompactPreview(context);

    // Filter to only held or substitute
    final displayItems = finalItems.where((i) => i.status == ItemStatus.held || i.status == ItemStatus.substitute).toList();
    final totalBasketValue = displayItems.fold(
      0.0,
      (sum, item) => sum + basketLineValue(item, investmentAmount),
    );
    final totalBasketWeight = displayItems.fold(
      0.0,
      (sum, item) => sum + basketLineWeight(item),
    );

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FpPanelHeader(
            icon: Icons.shopping_basket_outlined,
            iconBg: Colors.pinkAccent,
            title: 'Your Custom Basket',
            subtitle: '${finalItems.length} Constituents',
            constituentsBadge: '', // Empty because it's replaced by chips
            chips: [
              FpStatChip(
                label: 'Coverage',
                value: '${replicaScore.toStringAsFixed(0)}%',
                valueColor: replicaScore >= 90 ? context.statusSuccess : context.statusWarning,
              ),
              FpStatChip(
                label: 'Held',
                value: heldCount.toString(),
                valueColor: context.statusSuccess,
              ),
              FpStatChip(
                label: 'Substituted',
                value: subCount.toString(),
                valueColor: context.colors.actionPrimaryBg,
              ),
            ],
          ),
          Divider(color: context.colors.border, height: 1),
          if (!compact) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Stock', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Weightage (%)', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Allocation (₹)', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Status', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
                  ),
                ],
              ),
            ),
            Divider(color: context.colors.border, height: 1),
          ],
          // Rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
                final item = displayItems[index];
                final weight = basketLineWeight(item);
                final value = basketLineValue(item, investmentAmount);
                final freshBuy = (item.buyQuantity ?? 0) * (item.lastPrice ?? 0);
                return FpStockRow(
                  symbol: item.status == ItemStatus.substitute &&
                          item.userHoldingSymbol != null
                      ? item.userHoldingSymbol!
                      : item.stockSymbol,
                  sector: item.sector,
                  weightage: weight,
                  value: value,
                  valueSubLabel: freshBuy > 0 && freshBuy < value
                      ? 'Buy ${fmtValue.format(freshBuy)}'
                      : (freshBuy == 0 && value > 0 ? 'Covered' : null),
                  statusPill: _buildStatusPill(context, item),
                  showValue: true,
                  showStatus: true,
                  isEven: index % 2 == 0,
                );
              },
            ),
          // Footer
          Divider(color: context.colors.border, height: 1),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.md : AppSpacing.lg,
              vertical: compact ? AppSpacing.sm : AppSpacing.lg,
            ),
            child: compact
                ? Text(
                    [
                      'Total ${totalBasketWeight.toStringAsFixed(1)}%',
                      fmtValue.format(totalBasketValue),
                      if (actualInvestmentCost > 0 &&
                          actualInvestmentCost != totalBasketValue)
                        'Fresh ${fmtValue.format(actualInvestmentCost)}',
                    ].join(' · '),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Total',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${totalBasketWeight.toStringAsFixed(1)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fmtValue.format(totalBasketValue),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            if (actualInvestmentCost > 0 &&
                                actualInvestmentCost != totalBasketValue)
                              Text(
                                'Fresh orders ${fmtValue.format(actualInvestmentCost)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
