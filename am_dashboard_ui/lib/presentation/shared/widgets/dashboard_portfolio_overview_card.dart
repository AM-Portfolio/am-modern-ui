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
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        overview.type,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Invested: ${currencyFormat.format(overview.totalValue - overview.totalReturn)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurfaceVariant,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: trendBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPositive ? Icons.arrow_outward : Icons.arrow_downward,
                    color: trendColor,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currencyFormat.format(overview.totalValue),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isPositive ? "+" : ""}${currencyFormat.format(overview.totalReturn)} (${overview.returnPercentage.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: trendColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
