import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart' as ds;
import '../../internal/domain/entities/portfolio_analytics.dart';

/// Widget displaying top movers (gainers and losers) in the portfolio
/// Shows stocks with highest gains and losses with performance metrics
class MoversWidget extends StatefulWidget {
  const MoversWidget({
    super.key,
    this.movers,
    this.isLoading = false,
    this.error,
  });
  final Movers? movers;
  final bool isLoading;
  final String? error;

  @override
  State<MoversWidget> createState() => _MoversWidgetState();
}

class _MoversWidgetState extends State<MoversWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ds.AppCard(
    margin: const EdgeInsets.all(8.0),
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_graph,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Top Movers',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(height: 380, child: _buildContent(context)),
      ],
    ),
  );

  Widget _buildContent(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load movers data',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (widget.movers == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.data_usage_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'No movers data available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text('Gainers (${widget.movers!.topGainers.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_down, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text('Losers (${widget.movers!.topLosers.length})'),
                ],
              ),
            ),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMoversList(context, widget.movers!.topGainers, true),
              _buildMoversList(context, widget.movers!.topLosers, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoversList(
    BuildContext context,
    List<Stock> stocks,
    bool isGainers,
  ) {
    if (stocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isGainers ? Icons.trending_up : Icons.trending_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'No ${isGainers ? 'gainers' : 'losers'} found',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        final stock = stocks[index];
        return _buildMoverTile(context, stock, isGainers);
      },
    );
  }

  Widget _buildMoverTile(BuildContext context, Stock stock, bool isGainer) {
    final color = isGainer ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Symbol with colored indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stock.symbol,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stock.companyName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${stock.lastPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Percentage change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '₹${stock.changeAmount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: color.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
