import 'package:flutter/material.dart';

import '../../../models/trade_holding_view_model.dart';
import '../widgets/info_card.dart';
import '../widgets/metric_card.dart';

/// Displays performance metrics and analytics for a trade.
///
/// This reusable component shows key performance indicators like:
/// - Risk/Reward ratio
/// - Profit/Loss metrics
/// - Win rate indicators
/// - Holding period analysis
class TradeMetricsSection extends StatelessWidget {
  const TradeMetricsSection({required this.holding, super.key});

  final TradeHoldingViewModel holding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildMetricsGrid(context), const SizedBox(height: 16), _buildPerformanceAnalysis(context)],
    ),
  );

  Widget _buildMetricsGrid(BuildContext context) {
    final isProfit = holding.isProfit;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 500 ? 2 : 1;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: columns == 2 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
              child: MetricCard(
                title: 'Profit/Loss',
                value: holding.displayProfitLoss,
                subtitle: holding.displayProfitLossPercentage,
                icon: isProfit ? Icons.trending_up : Icons.trending_down,
                color: isProfit ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(
              width: columns == 2 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
              child: MetricCard(
                title: 'Risk/Reward',
                value: holding.displayRiskRewardRatio,
                subtitle: _getRiskRewardLabel(holding.riskRewardRatio),
                icon: Icons.balance,
                color: _getRiskRewardColor(holding.riskRewardRatio),
              ),
            ),
            SizedBox(
              width: columns == 2 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
              child: MetricCard(
                title: 'Entry Price',
                value: holding.displayEntryPrice,
                subtitle: 'Per Share',
                icon: Icons.login,
                color: Colors.blue,
              ),
            ),
            SizedBox(
              width: columns == 2 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
              child: MetricCard(
                title: 'Current Price',
                value: holding.displayCurrentPrice,
                subtitle: 'Per Share',
                icon: Icons.show_chart,
                color: Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceAnalysis(BuildContext context) {
    final totalValue = (holding.currentPrice ?? 0.0) * (holding.quantity ?? 0);
    final totalInvested = (holding.entryPrice ?? 0.0) * (holding.quantity ?? 0);
    final currentPrice = holding.currentPrice ?? 0.0;
    final entryPrice = holding.entryPrice ?? 1.0; // Avoid division by zero
    final percentageMove = ((currentPrice - entryPrice) / entryPrice * 100).abs();

    return InfoCard(
      title: 'Performance Analysis',
      icon: Icons.analytics,
      iconColor: Colors.indigo,
      children: [
        _buildAnalysisRow(
          context,
          'Total Invested',
          '\$${totalInvested.toStringAsFixed(2)}',
          Icons.account_balance_wallet,
          Colors.blue,
        ),
        _buildAnalysisRow(
          context,
          'Current Value',
          '\$${totalValue.toStringAsFixed(2)}',
          Icons.account_balance,
          Colors.purple,
        ),
        _buildAnalysisRow(
          context,
          'Price Movement',
          '${percentageMove.toStringAsFixed(2)}%',
          holding.isProfit ? Icons.arrow_upward : Icons.arrow_downward,
          holding.isProfit ? Colors.green : Colors.red,
        ),
        _buildAnalysisRow(context, 'Holding Period', holding.displayHoldingPeriod, Icons.schedule, Colors.orange),
        if (holding.exitPrice != null)
          _buildAnalysisRow(context, 'Exit Price', holding.displayExitPrice, Icons.logout, Colors.teal),
      ],
    );
  }

  Widget _buildAnalysisRow(BuildContext context, String label, String value, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _getRiskRewardLabel(double? ratio) {
    if (ratio == null) return 'Not Available';
    if (ratio >= 2.0) return 'Excellent';
    if (ratio >= 1.5) return 'Good';
    if (ratio >= 1.0) return 'Fair';
    return 'Poor';
  }

  Color _getRiskRewardColor(double? ratio) {
    if (ratio == null) return Colors.grey;
    if (ratio >= 2.0) return Colors.green;
    if (ratio >= 1.5) return Colors.lightGreen;
    if (ratio >= 1.0) return Colors.orange;
    return Colors.red;
  }
}
