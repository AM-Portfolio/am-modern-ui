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
              Expanded(child: _buildPortfolioCard(context, isMobile)),
              const SizedBox(width: 16),
              Expanded(child: _buildInvestedCard(context)),
              const SizedBox(width: 16),
              Expanded(child: _buildReturnCard(context)),
              const SizedBox(width: 16),
              Expanded(child: _buildPortfoliosCard(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortfolioCard(BuildContext context, bool isMobile) {
    final currencyFormat = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final isPositiveDay = summary.dayChangePercentage >= 0;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const onSurface = Colors.white; 
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : Colors.white70;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total Portfolio Value',
          style: TextStyle(
            color: onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(summary.totalValue),
          style: TextStyle(
            color: onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '${isPositiveDay ? "+" : ""}${summary.dayChangePercentage}% Today',
              style: TextStyle(
                color: isPositiveDay ? const Color(0xFF00C853) : const Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ],
    );

    if (!isDark) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(79, 70, 229, 0.25),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: content,
      );
    }

    return AmGlassCard(
      padding: const EdgeInsets.all(16),
      child: content,
    );
  }

  Widget _buildInvestedCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AmGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total Invested',
            style: TextStyle(
              color: onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(summary.totalInvested),
            style: TextStyle(
              color: onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Principal Capital',
            style: TextStyle(
              color: onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 2);
    final isPositiveReturn = summary.totalGainLoss >= 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isPositiveReturn 
        ? (isDark ? const Color(0xFF10B981) : const Color(0xFF00C853))
        : (isDark ? const Color(0xFFEF4444) : const Color(0xFFD50000));

    return AmGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total Return',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${isPositiveReturn ? "+" : "-"}${currencyFormat.format(summary.totalGainLoss.abs())}',
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${isPositiveReturn ? "+" : ""}${percentFormat.format(summary.totalGainLossPercentage / 100)}',
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
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
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AmGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Active Portfolios',
            style: TextStyle(
              color: onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.totalPortfolios.toString(),
            style: TextStyle(
              color: onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Live Strategies',
            style: TextStyle(
              color: onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
