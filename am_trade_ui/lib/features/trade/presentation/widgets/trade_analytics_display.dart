import 'package:flutter/material.dart';

import '../models/trade_calendar_view_model.dart';

/// Widget to display trade analytics summary
class TradeAnalyticsDisplay extends StatelessWidget {
  const TradeAnalyticsDisplay({required this.analytics, super.key});

  final TradeAnalyticsSummary analytics;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Trade Analytics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      // Main metrics cards
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _buildMainMetricsCards(context),
      ),

      const SizedBox(height: 16),

      // Performance metrics
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _buildPerformanceMetrics(context),
      ),

      const SizedBox(height: 16),

      // Risk metrics
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _buildRiskMetrics(context),
      ),
    ],
  );

  Widget _buildMainMetricsCards(BuildContext context) => Row(
    children: [
      // Total P&L Card
      Expanded(
        child: _MetricCard(
          title: 'Total P&L',
          value: analytics.formattedTotalProfitLoss,
          icon: Icons.account_balance_wallet,
          color: analytics.totalProfitLoss >= 0 ? Colors.green : Colors.red,
          subtitle: '${analytics.totalTrades} trades',
        ),
      ),
      const SizedBox(width: 12),

      // Win Rate Card
      Expanded(
        child: _MetricCard(
          title: 'Win Rate',
          value: analytics.formattedWinRate,
          icon: Icons.trending_up,
          color: analytics.winRate >= 50 ? Colors.green : Colors.orange,
          subtitle: '${analytics.winningTrades}W/${analytics.losingTrades}L',
        ),
      ),
      const SizedBox(width: 12),

      // Average Per Trade Card
      Expanded(
        child: _MetricCard(
          title: 'Avg/Trade',
          value: analytics.formattedAverageProfit,
          icon: Icons.show_chart,
          color: analytics.averageProfitPerTrade >= 0
              ? Colors.green
              : Colors.red,
          subtitle: 'Per trade',
        ),
      ),
    ],
  );

  Widget _buildPerformanceMetrics(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Breakdown',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricRow(
                  label: 'Winning Trades',
                  value: '${analytics.winningTrades}',
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _MetricRow(
                  label: 'Losing Trades',
                  value: '${analytics.losingTrades}',
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _MetricRow(
                  label: 'Profitable Days',
                  value: '${analytics.profitableDays}',
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _MetricRow(
                  label: 'Losing Days',
                  value: '${analytics.losingDays}',
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _MetricRow(
                  label: 'Profit Factor',
                  value: analytics.formattedProfitFactor,
                  color: analytics.profitFactor >= 1.0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              Expanded(
                child: _MetricRow(
                  label: 'Unique Symbols',
                  value: '${analytics.uniqueSymbolsCount}',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildRiskMetrics(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Management',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricRow(
                  label: 'Risk:Reward Ratio',
                  value: analytics.formattedRiskRewardRatio,
                  color: analytics.averageRiskRewardRatio >= 1.5
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              Expanded(
                child: _MetricRow(
                  label: 'Total Risk',
                  value: '₹${analytics.totalRiskAmount.toStringAsFixed(0)}',
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _MetricRow(
                  label: 'Avg Holding Days',
                  value: analytics.averageHoldingTimeDays.toStringAsFixed(1),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: _MetricRow(
                  label: 'Avg ROE',
                  value:
                      '${analytics.averageReturnOnEquity.toStringAsFixed(2)}%',
                  color: analytics.averageReturnOnEquity >= 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Individual metric card widget
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    ),
  );
}

/// Metric row widget for detailed breakdowns
class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
