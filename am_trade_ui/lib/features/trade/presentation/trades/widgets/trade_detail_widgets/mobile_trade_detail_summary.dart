import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../models/trade_holding_view_model.dart';

/// Compact mobile summary: P&L + value + Qty / Avg / Entry row (mock layout).
class MobileTradeDetailSummary extends StatelessWidget {
  const MobileTradeDetailSummary({required this.trade, super.key});

  final TradeHoldingViewModel trade;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pnlColor =
        trade.isProfit ? context.marketPositive : context.marketNegative;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: context.shadow(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'P&L',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      trade.displayProfitLoss,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: pnlColor,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: pnlColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      child: Text(
                        trade.displayProfitLossPercentage,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: pnlColor,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Current Value',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      trade.displayCurrentValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: colors.divider),
          ),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.swap_vert,
                  iconColor: ModuleColors.trade,
                  title: 'Qty',
                  value: trade.displayQuantity,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.currency_rupee,
                  iconColor: colors.statusWarning,
                  title: 'Avg',
                  value: trade.displayAvgPrice,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.show_chart,
                  iconColor: colors.statusInfo,
                  title: 'Entry',
                  value: trade.displayEntryPrice,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.textSecondary,
                      fontSize: AppTypeScale.xs,
                    ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypeScale.sm + 1,
                      color: context.colors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
