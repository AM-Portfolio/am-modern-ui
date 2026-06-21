import 'package:am_dashboard_ui/domain/models/portfolio_overview.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'glass_card.dart';

/// Pixel-perfect Lumina Portfolio Overview Card matching the image.
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
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic Colors
    final onSurface = isDark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final primary = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2E3192);
    
    final positiveBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9);
    final negativeBg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEE);
    final trendBg = isPositive ? positiveBg : negativeBg;
    final trendColor = isPositive ? const Color(0xFF00C853) : const Color(0xFFD50000);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AmGlassCard(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  overview.type,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invested',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurfaceVariant,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(overview.totalValue - overview.totalReturn),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurfaceVariant,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(overview.totalValue),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: trendBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Returns',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    '${isPositive ? "+" : ""}${currencyFormat.format(overview.totalReturn)} (${overview.returnPercentage.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: trendColor,
                      fontFamily: 'Inter',
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
