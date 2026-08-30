import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_opportunity.dart';
import 'fp_panel_header.dart';
import 'fp_stock_row.dart';
import 'fp_status_pill.dart';

class FpBasketPanel extends StatelessWidget {
  final List<BasketItem> finalItems;
  final double replicaScore;
  final double actualInvestmentCost;
  final int heldCount;
  final int subCount;

  const FpBasketPanel({
    super.key,
    required this.finalItems,
    required this.replicaScore,
    required this.actualInvestmentCost,
    required this.heldCount,
    required this.subCount,
  });

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

    // Filter to only held or substitute
    final displayItems = finalItems.where((i) => i.status == ItemStatus.held || i.status == ItemStatus.substitute).toList();

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
          // Column Headers
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
                  child: Text('Value (₹)', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Status', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
                ),
              ],
            ),
          ),
          Divider(color: context.colors.border, height: 1),
          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                final item = displayItems[index];
                final value = (item.buyQuantity ?? 0) * (item.lastPrice ?? 0);
                return FpStockRow(
                  symbol: item.stockSymbol,
                  sector: item.sector,
                  weightage: item.rebalancedWeight ?? item.etfWeight,
                  value: value,
                  statusPill: _buildStatusPill(context, item),
                  showValue: true,
                  showStatus: true,
                  isEven: index % 2 == 0,
                );
              },
            ),
          ),
          // Footer
          Divider(color: context.colors.border, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            child: Row(
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
                    '${replicaScore.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4, // Takes space of Value + Status
                  child: Text(
                    fmtValue.format(actualInvestmentCost),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
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
