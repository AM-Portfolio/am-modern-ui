import 'package:flutter/material.dart';
import '../../internal/domain/entities/portfolio_summary.dart';

/// Reusable portfolio summary widget that displays comprehensive portfolio metrics
class PortfolioSummaryWidget extends StatelessWidget {
  const PortfolioSummaryWidget({
    required this.summary,
    super.key,
    this.onViewHoldings,
    this.onViewAnalysis,
  });
  final PortfolioSummary summary;
  final VoidCallback? onViewHoldings;
  final VoidCallback? onViewAnalysis;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Portfolio Value Card with fixed values
        _buildMainValueCard(context),
        const SizedBox(height: 12),

        // Dynamic Market Data Card
        _buildDynamicMarketCard(context),
        const SizedBox(height: 16),

        // Quick Actions
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'View Holdings',
                Icons.list_alt,
                onViewHoldings,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Analysis',
                Icons.analytics,
                onViewAnalysis,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  /// Build the main portfolio value card with total value and percentage
  Widget _buildMainValueCard(BuildContext context) {
    final isPositive = summary.totalGainLoss >= 0;
    final color = isPositive
        ? (Colors.green[700] ?? Colors.green)
        : (Colors.red[700] ?? Colors.red);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with last updated
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Portfolio Value',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(summary.lastUpdated),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Total value and percentage together
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  summary.formattedTotalValue,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: color,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${summary.totalGainLossPercentage.toStringAsFixed(2)}%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Compact Investment Overview
            Row(
              children: [
                Expanded(
                  child: _buildCompactOverviewItem(
                    context,
                    'Invested',
                    '₹${summary.totalInvested.toStringAsFixed(0)}',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactOverviewItem(
                    context,
                    'Current',
                    '₹${summary.totalValue.toStringAsFixed(0)}',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactOverviewItem(
                    context,
                    'Holdings',
                    summary.totalHoldings.toString(),
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build dynamic market data card that changes frequently
  Widget _buildDynamicMarketCard(BuildContext context) => Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Row
          Row(
            children: [
              Expanded(
                child: _buildCompactPerformanceItem(
                  context,
                  "Today's Change",
                  summary.formattedTodayChange,
                  '${summary.todayChangePercentage.toStringAsFixed(2)}%',
                  summary.isTodayPositive,
                  Icons.today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactPerformanceItem(
                  context,
                  'Total Returns',
                  summary.formattedGainLoss,
                  '${summary.totalGainLossPercentage.toStringAsFixed(2)}%',
                  summary.isProfitable,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gainers/Losers Row
          Row(
            children: [
              Expanded(
                child: _buildCompactGainerLoserItem(
                  context,
                  'Today',
                  summary.todayGainersCount,
                  summary.todayLosersCount,
                  Icons.today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactGainerLoserItem(
                  context,
                  'Overall',
                  summary.gainersCount,
                  summary.losersCount,
                  Icons.analytics,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  /// Build compact performance item
  Widget _buildCompactPerformanceItem(
    BuildContext context,
    String title,
    String value,
    String percentage,
    bool isPositive,
    IconData icon,
  ) {
    final color = isPositive
        ? (Colors.green[700] ?? Colors.green)
        : (Colors.red[700] ?? Colors.red);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          percentage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build compact overview item
  Widget _buildCompactOverviewItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  /// Build compact gainer/loser item
  Widget _buildCompactGainerLoserItem(
    BuildContext context,
    String label,
    int gainersCount,
    int losersCount,
    IconData icon,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
      const SizedBox(height: 4),
      RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          children: [
            TextSpan(
              text: gainersCount.toString(),
              style: const TextStyle(color: Colors.green),
            ),
            TextSpan(
              text: '/',
              style: TextStyle(color: Colors.grey[600]),
            ),
            TextSpan(
              text: losersCount.toString(),
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    ],
  );

  /// Format datetime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback? onTap,
  ) => Card(
    elevation: 2,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
