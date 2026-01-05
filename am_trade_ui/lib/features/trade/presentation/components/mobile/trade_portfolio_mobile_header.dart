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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.02),
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Highlighted Portfolio Count and Value
        Row(
          children: [
            // Portfolio count - prominent
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.folder_special, color: Theme.of(context).colorScheme.primary, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Portfolios',
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '$portfolioCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Total value - prominent
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue.withOpacity(0.15), Colors.blue.withOpacity(0.05)]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.attach_money, color: Colors.blue, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Value',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '\$${totalValue.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onRefresh != null) const SizedBox(width: 4),
            if (onRefresh != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                iconSize: 18,
                onPressed: onRefresh,
                visualDensity: VisualDensity.compact,
                color: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.all(4),
              ),
          ],
        ),

        const SizedBox(height: 6),

        // Compact Secondary Stats - Single row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCompactStat(
                context,
                'Profitable',
                '$profitableCount/$portfolioCount',
                Icons.trending_up,
                Colors.green,
              ),
              const SizedBox(width: 4),
              _buildCompactStat(context, 'Trades', '$totalTrades', Icons.swap_horiz, Colors.purple),
              const SizedBox(width: 4),
              _buildCompactStat(
                context,
                'P&L',
                '${totalNetProfitLoss >= 0 ? '+' : ''}\$${totalNetProfitLoss.toStringAsFixed(0)}',
                totalNetProfitLoss >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                totalNetProfitLoss >= 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              _buildCompactStat(
                context,
                'Win Rate',
                '${avgWinRate.toStringAsFixed(0)}%',
                Icons.percent,
                avgWinRate >= 50 ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildCompactStat(BuildContext context, String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 8, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    ),
  );
}
