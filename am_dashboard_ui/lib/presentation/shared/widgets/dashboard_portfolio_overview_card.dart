import 'package:am_dashboard_ui/domain/models/portfolio_overview.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import 'glass_card.dart';

/// Portfolio overview card using design-system tokens.
class DashboardPortfolioOverviewCard extends StatelessWidget {
  final PortfolioOverview overview;
  final VoidCallback onTap;

  const DashboardPortfolioOverviewCard({
    super.key,
    required this.overview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final isPositive = overview.totalReturn >= 0;

    final onSurface = context.colors.textPrimary;
    final onSurfaceVariant = context.colors.textSecondary;

    final positiveBg = context.colors.statusSuccess.withValues(alpha: 0.15);
    final negativeBg = context.colors.statusError.withValues(alpha: 0.15);
    final trendBg = isPositive ? positiveBg : negativeBg;
    final trendColor =
        isPositive ? context.colors.statusSuccess : context.colors.statusError;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.card,
      child: AmGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  overview.type,
                  style: context.text.body().copyWith(
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invested',
                      style: context.text
                          .caption()
                          .copyWith(color: onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      currencyFormat.format(
                        overview.totalValue - overview.totalReturn,
                      ),
                      style: context.text.label().copyWith(
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Current',
                      style: context.text
                          .caption()
                          .copyWith(color: onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      currencyFormat.format(overview.totalValue),
                      style: context.text.body().copyWith(
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: trendBg,
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Returns',
                    style: context.text.caption().copyWith(
                          fontWeight: FontWeight.w600,
                          color: trendColor,
                        ),
                  ),
                  Text(
                    '${isPositive ? "+" : ""}${currencyFormat.format(overview.totalReturn)} (${overview.returnPercentage.toStringAsFixed(2)}%)',
                    style: context.text.caption().copyWith(
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
