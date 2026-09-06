import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../utils/basket_responsive.dart';
import 'fp_panel_header.dart';
import 'fp_stock_row.dart';

class FpEtfPanel extends StatelessWidget {
  final BasketOpportunity originalOpportunity;

  const FpEtfPanel({
    super.key,
    required this.originalOpportunity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final composition = originalOpportunity.composition;
    final compact = BasketResponsive.useCompactPreview(context);

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
            icon: Icons.auto_awesome,
            iconBg: ModuleColors.portfolio,
            title: 'Original ETF',
            subtitle: originalOpportunity.etfName,
            constituentsBadge: '${composition.length} Constituents',
          ),
          Divider(color: context.colors.border, height: 1),
          if (!compact) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 0,
                    child: Text('Stock', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
                  ),
                  Expanded(
                    flex: 0,
                    child: Text('Weightage (%)', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
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
            itemCount: composition.length,
            itemBuilder: (context, index) {
                final item = composition[index];
                return FpStockRow(
                  symbol: item.stockSymbol,
                  sector: item.sector,
                  weightage: item.etfWeight,
                  showValue: false,
                  showStatus: false,
                  isEven: index % 2 == 0,
                );
              },
            ),
          // Footer
          Divider(color: context.colors.border, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  '100%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
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
