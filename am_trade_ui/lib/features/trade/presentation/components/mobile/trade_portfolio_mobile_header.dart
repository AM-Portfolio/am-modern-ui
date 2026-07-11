import 'package:flutter/material.dart';

class TradePortfolioMobileHeader extends StatelessWidget {
  const TradePortfolioMobileHeader({
    required this.portfolioCount,
    required this.totalValue,
    required this.profitableCount,
    required this.totalTrades,
    required this.totalNetProfitLoss,
    required this.avgWinRate,
    super.key,
    this.onRefresh,
  });
  final int portfolioCount;
  final double totalValue;
  final int profitableCount;
  final int totalTrades;
  final double totalNetProfitLoss;
  final double avgWinRate;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.02),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            _buildModernStatBadge(
              context,
              label: 'Portfolios',
              value: '$portfolioCount',
              icon: Icons.folder_special_rounded,
              iconColor: Colors.white,
              iconBgColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            _buildModernStatBadge(
              context,
              label: 'Total Value',
              value: '₹${_formatNum(totalValue)}',
              icon: Icons.account_balance_wallet_rounded,
              iconColor: Colors.white,
              iconBgColor: Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildModernStatBadge(
              context,
              label: 'Profitable',
              value: '$profitableCount/$portfolioCount',
              icon: Icons.trending_up_rounded,
              iconColor: Colors.white,
              iconBgColor: const Color(0xFF10B981),
              valueColor: const Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            _buildModernStatBadge(
              context,
              label: 'Total Trades',
              value: '$totalTrades',
              icon: Icons.swap_horiz_rounded,
              iconColor: Colors.white,
              iconBgColor: Colors.purple,
            ),
            const SizedBox(width: 8),
            _buildModernStatBadge(
              context,
              label: 'Trade P&L',
              value: '${totalNetProfitLoss >= 0 ? '+' : ''}₹${_formatNum(totalNetProfitLoss)}',
              icon: totalNetProfitLoss >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              iconColor: Colors.white,
              iconBgColor: totalNetProfitLoss >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              valueColor: totalNetProfitLoss >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 8),
            _buildModernStatBadge(
              context,
              label: 'Avg Win Rate',
              value: '${avgWinRate.toStringAsFixed(1)}%',
              icon: Icons.percent_rounded,
              iconColor: Colors.white,
              iconBgColor: avgWinRate >= 50 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              valueColor: avgWinRate >= 50 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNum(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(2);
  }

  Widget _buildModernStatBadge(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D2D45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
