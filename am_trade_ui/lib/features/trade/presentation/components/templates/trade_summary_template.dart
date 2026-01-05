import 'package:flutter/material.dart';

import '../../../internal/domain/entities/trade_summary.dart';

class TradeSummaryTemplate extends StatelessWidget {
  const TradeSummaryTemplate({
    required this.summary,
    required this.isLoading,
    super.key,
    this.errorMessage,
    this.onRefresh,
    this.isWebView = true,
  });
  final TradeSummary summary;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final bool isWebView;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            if (onRefresh != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(),
          const SizedBox(height: 24),
          _buildSectorAllocation(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTopGainers()),
              const SizedBox(width: 16),
              Expanded(child: _buildTopLosers()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final metrics = summary.metrics;
    final isPositive = (metrics.netProfitLoss ?? 0) >= 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Trades',
            value: '${metrics.totalTrades}',
            subtitle: '${metrics.openPositions} open positions',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Net P&L',
            value: '${isPositive ? '+' : ''}\$${(metrics.netProfitLoss ?? 0).toStringAsFixed(2)}',
            subtitle: '${isPositive ? '+' : ''}${(metrics.netProfitLossPercentage ?? 0).toStringAsFixed(2)}%',
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Win Rate',
            value: '${(metrics.winRate ?? 0).toStringAsFixed(1)}%',
            subtitle: '${metrics.winningTrades}W / ${metrics.losingTrades}L',
            color: (metrics.winRate ?? 0) >= 50 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    ),
  );

  Widget _buildSectorAllocation() {
    // Asset allocations will be available later in development
    if (summary.assetAllocations == null || summary.assetAllocations!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Asset Allocation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Asset allocation data will be available soon',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asset Allocation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...summary.assetAllocations!.map(
              (allocation) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(allocation.assetType, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          '${allocation.percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: allocation.percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_getAssetColor(allocation.assetType)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${allocation.value.toStringAsFixed(2)} • ${allocation.count} assets',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGainers() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Gainers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (summary.topGainers.isEmpty)
            const Text('No gainers')
          else
            ...summary.topGainers.map(
              (mover) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(mover.symbol),
                subtitle: Text(mover.name),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+\$${mover.change.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '+${mover.changePercentage.toStringAsFixed(2)}%',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _buildTopLosers() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Losers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (summary.topLosers.isEmpty)
            const Text('No losers')
          else
            ...summary.topLosers.map(
              (mover) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(mover.symbol),
                subtitle: Text(mover.name),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${mover.change.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${mover.changePercentage.toStringAsFixed(2)}%',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Color _getAssetColor(String assetType) {
    final colors = {
      'Stocks': Colors.blue,
      'Equity': Colors.blue,
      'Bonds': Colors.green,
      'Fixed Income': Colors.green,
      'Crypto': Colors.orange,
      'Cryptocurrency': Colors.orange,
      'Commodities': Colors.amber,
      'Real Estate': Colors.purple,
      'Cash': Colors.cyan,
      'Options': Colors.deepOrange,
      'Futures': Colors.red,
      'ETFs': Colors.teal,
      'Mutual Funds': Colors.indigo,
    };
    return colors[assetType] ?? Colors.grey;
  }
}
