import 'package:am_dashboard_ui/domain/models/portfolio_overview.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PortfolioOverviewCard extends StatelessWidget {
  final PortfolioOverview overview;
  final VoidCallback? onTap;

  const PortfolioOverviewCard({
    super.key,
    required this.overview,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 0);
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildIcon(context),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overview.type,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(overview.totalValue),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  percentFormat.format(overview.returnPercentage / 100),
                  style: TextStyle(
                    color: _getColor(context, overview.returnPercentage),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(overview.totalReturn),
                  style: TextStyle(
                    color: _getColor(context, overview.totalReturn),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.arrow_forward_ios, size: 16, color: context.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    IconData icon;
    Color color;

    if (overview.type.contains("AM")) {
      icon = Icons.account_balance;
      color = context.statusInfo;
    } else {
      icon = Icons.show_chart;
      color = AppColors.portfolioAccent;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }

  Color _getColor(BuildContext context, double value) {
    if (value > 0) return context.statusSuccess;
    if (value < 0) return context.statusError;
    return context.textSecondary;
  }
}
