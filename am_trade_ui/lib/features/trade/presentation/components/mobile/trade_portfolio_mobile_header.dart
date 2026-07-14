import 'package:flutter/material.dart';

/// Compact portfolio discovery summary — full-width equal columns.
/// Layout per metric: icon + label on top, value centered below.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white54 : Colors.black45;
    final primary = Theme.of(context).colorScheme.primary;
    final pnlColor =
        totalNetProfitLoss >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    // Keep unused discovery stats available for API compatibility.
    assert(profitableCount >= 0 && totalTrades >= 0 && avgWinRate >= 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildMetricColumn(
                icon: Icons.folder_special_rounded,
                label: 'Portfolios',
                value: '$portfolioCount',
                color: primary,
                muted: muted,
              ),
            ),
            Expanded(
              child: _buildMetricColumn(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Value',
                value: '₹${_formatNum(totalValue)}',
                color: Colors.lightBlueAccent,
                muted: muted,
              ),
            ),
            Expanded(
              child: _buildMetricColumn(
                icon: totalNetProfitLoss >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                label: 'P&L',
                value:
                    '${totalNetProfitLoss >= 0 ? '+' : ''}₹${_formatNum(totalNetProfitLoss)}',
                color: pnlColor,
                muted: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNum(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  Widget _buildMetricColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color muted,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
