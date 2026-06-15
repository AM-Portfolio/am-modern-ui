import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'glass_card.dart';

/// Pixel-perfect Lumina 4-Card Summary grid based on the new screenshot.
class DashboardSummaryWidget extends StatelessWidget {
  final DashboardSummary summary;

  const DashboardSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return Column(
            children: [
              _buildPortfolioCard(context, isMobile),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInvestedCard(context)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildReturnCard(context)),
                ],
              ),
              const SizedBox(height: 16),
              _buildPortfoliosCard(context),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 4, child: _buildPortfolioCard(context, isMobile)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildInvestedCard(context)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildReturnCard(context)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildPortfoliosCard(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortfolioCard(BuildContext context, bool isMobile) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 0);
    final isPositiveDay = summary.dayChangePercentage >= 0;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const onSurface = Colors.white; 
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : Colors.white70;
    final primary = isDark ? const Color(0xFF60A5FA) : Colors.white;
    final iconBg = isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.2);
    final progressBg = isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.2);
    final progressFg = isDark ? const Color(0xFF001246) : Colors.white;

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'TOTAL PORTFOLIO VALUE',
                    style: TextStyle(
                      color: onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline, size: 12, color: onSurfaceVariant),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.wallet, size: 14, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$ ${currencyFormat.format(summary.totalValue).substring(1)}',
            style: TextStyle(
              color: onSurface,
              fontSize: isMobile ? 32 : 36,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
              letterSpacing: -1,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
          // Progress bar line
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: progressBg,
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.65, // Example progress
              child: Container(
                decoration: BoxDecoration(
                  color: progressFg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositiveDay ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: const Color(0xFF00C853), // Green
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositiveDay ? "" : ""}${summary.dayChangePercentage}% Today',
                style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      );

    if (!isDark) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E3192), Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.06),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: content,
      );
    }

    return AmGlassCard(
      padding: const EdgeInsets.all(24),
      child: content,
    );
  }

  Widget _buildInvestedCard(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final iconBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final primary = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2E3192);

    return AmGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL\nINVESTED',
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  height: 1.2,
                  fontFamily: 'Inter',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.account_balance, size: 14, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currencyFormat.format(summary.totalInvested),
            style: TextStyle(
              color: onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Text(
            'Principal\nCapital',
            style: TextStyle(
              color: onSurfaceVariant,
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 0);
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 2);
    final isPositiveReturn = summary.totalGainLoss >= 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final errorColor = isDark ? const Color(0xFFEF4444) : const Color(0xFFD50000);
    final successColor = isDark ? const Color(0xFF10B981) : const Color(0xFF00C853);
    final valueColor = isPositiveReturn ? successColor : errorColor;
    
    final iconBg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEE);

    return AmGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL\nRETURN',
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  height: 1.2,
                  fontFamily: 'Inter',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPositiveReturn 
                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9))
                      : iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isPositiveReturn ? Icons.trending_up : Icons.trending_down, 
                  size: 14, 
                  color: valueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${isPositiveReturn ? "" : "-"}\$${currencyFormat.format(summary.totalGainLoss.abs()).substring(1)}',
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Text(
            '${isPositiveReturn ? "+" : ""}${percentFormat.format(summary.totalGainLossPercentage / 100)}',
            style: TextStyle(
              color: onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfoliosCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final iconBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final primary = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2E3192);

    return AmGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE\nPORTFOLIOS',
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  height: 1.2,
                  fontFamily: 'Inter',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.language, size: 14, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            summary.totalPortfolios.toString(),
            style: TextStyle(
              color: onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Text(
            'Live\nStrategies',
            style: TextStyle(
              color: onSurfaceVariant,
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
