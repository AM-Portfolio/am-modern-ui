import 'package:flutter/material.dart';

import '../../../models/trade_holding_view_model.dart';
import '../widgets/info_card.dart';

/// Displays performance charts and visual indicators for a trade.
///
/// This reusable component shows:
/// - Performance summary
/// - Visual indicators
/// - Status badges
/// - Future: Charts and graphs (placeholder for now)
class TradePerformanceSection extends StatelessWidget {
  const TradePerformanceSection({required this.holding, super.key});

  final TradeHoldingViewModel holding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPerformanceSummary(context),
        const SizedBox(height: 16),
        _buildStatusIndicators(context),
        const SizedBox(height: 16),
        _buildChartPlaceholder(context),
      ],
    ),
  );

  Widget _buildPerformanceSummary(BuildContext context) {
    final isProfit = holding.isProfit;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              if (isProfit) Colors.green.withOpacity(0.1) else Colors.red.withOpacity(0.1),
              if (isProfit) Colors.green.withOpacity(0.05) else Colors.red.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              isProfit ? Icons.trending_up : Icons.trending_down,
              size: 64,
              color: isProfit ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              isProfit ? 'Profitable Trade' : 'Loss Trade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isProfit ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              holding.displayProfitLoss,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isProfit ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 4),
            Text(
              holding.displayProfitLossPercentage,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: isProfit ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Held for ${holding.displayHoldingPeriod}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicators(BuildContext context) => InfoCard(
    title: 'Trade Status',
    icon: Icons.info_outline,
    iconColor: Colors.blue,
    children: [
      Row(
        children: [
          Expanded(
            child: _buildIndicator(
              context,
              'Status',
              holding.displayStatus.toUpperCase(),
              _getStatusColor(holding.status),
              _getStatusIcon(holding.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildIndicator(context, 'Executions', '${holding.executionCount}', Colors.purple, Icons.swap_horiz),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _buildIndicator(context, 'Quantity', holding.displayQuantity, Colors.indigo, Icons.numbers)),
          const SizedBox(width: 12),
          Expanded(
            child: _buildIndicator(
              context,
              'R:R Ratio',
              holding.displayRiskRewardRatio,
              _getRiskRewardColor(holding.riskRewardRatio),
              Icons.balance,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildIndicator(BuildContext context, String label, String value, Color color, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildChartPlaceholder(BuildContext context) => InfoCard(
    title: 'Performance Chart',
    icon: Icons.show_chart,
    iconColor: Colors.teal,
    children: [
      Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Chart visualization coming soon',
                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text('Price movement and performance trends', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    ],
  );

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'WIN':
        return Colors.green;
      case 'LOSS':
        return Colors.red;
      case 'BREAK_EVEN':
        return Colors.orange;
      case 'OPEN':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toUpperCase()) {
      case 'WIN':
        return Icons.check_circle;
      case 'LOSS':
        return Icons.cancel;
      case 'BREAK_EVEN':
        return Icons.remove_circle;
      case 'OPEN':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  Color _getRiskRewardColor(double? ratio) {
    if (ratio == null) return Colors.grey;
    if (ratio >= 2.0) return Colors.green;
    if (ratio >= 1.5) return Colors.lightGreen;
    if (ratio >= 1.0) return Colors.orange;
    return Colors.red;
  }
}
