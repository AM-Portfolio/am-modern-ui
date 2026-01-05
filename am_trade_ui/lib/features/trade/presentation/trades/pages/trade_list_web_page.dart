import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/trade_internal_providers.dart';
import '../../models/trade_holding_view_model.dart';
import 'trade_detail_view_page.dart';

/// Web page for displaying all trades in a list view
class TradeListWebPage extends ConsumerStatefulWidget {
  const TradeListWebPage({required this.userId, required this.portfolioId, this.onNavigateToChart, super.key});

  final String userId;
  final String portfolioId;
  final Function(String symbol)? onNavigateToChart;

  @override
  ConsumerState<TradeListWebPage> createState() => _TradeListWebPageState();
}

class _TradeListWebPageState extends ConsumerState<TradeListWebPage> {
  TradeHoldingViewModel? _selectedTrade;
  bool _isListVisible = true;

  @override
  Widget build(BuildContext context) {
    final params = (userId: widget.userId, portfolioId: widget.portfolioId);
    final holdingsAsync = ref.watch(tradeHoldingsStreamProvider(params));

    return Scaffold(
      body: holdingsAsync.when(
        data: (tradeHoldings) {
          final holdings = tradeHoldings.holdings;

          if (holdings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No Trades Found', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Add your first trade to get started', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale();
          }

          return Row(
            children: [
              // Left sidebar - Trade list
              _buildTradeSidebar(holdings),

              // Right side - Trade detail or placeholder
              Expanded(child: _selectedTrade != null ? _buildTradeDetailView() : _buildEmptyState()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading trades', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(error.toString(), style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(tradeHoldingsStreamProvider(params));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Trade sidebar - expanded or collapsed
  Widget _buildTradeSidebar(List<TradeHoldingViewModel> holdings) {
    // If trade is selected and list is not visible, show only expand icon
    if (_selectedTrade != null && !_isListVisible) {
      return Container(
        width: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                setState(() {
                  _isListVisible = true;
                });
              },
              tooltip: 'Show trade list',
            ),
            const SizedBox(height: 8),
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                'All Trades (${holdings.length})',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ).animate().slideX(begin: -0.2, end: 0, duration: 300.ms);
    }

    // Full sidebar with trade list
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(2, 0))],
      ),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                ],
              ),
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Trades',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${holdings.length} trades',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedTrade != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isListVisible = false;
                      });
                    },
                    tooltip: 'Hide trade list',
                  ),
              ],
            ),
          ),

          // Trade list
          Expanded(
            child: ListView.builder(
              itemCount: holdings.length,
              itemBuilder: (context, index) {
                final holding = holdings[index];
                final isSelected = _selectedTrade?.tradeId == holding.tradeId;

                return _buildTradeSidebarItem(holding, isSelected)
                    .animate().fadeIn(delay: (30 * index).ms).slideX(begin: -0.1, end: 0);
              },
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: -0.1, end: 0, duration: 300.ms);
  }

  Widget _buildTradeSidebarItem(TradeHoldingViewModel holding, bool isSelected) {
    final isProfit = holding.isProfit;
    final statusColor = _getStatusColor(holding.status);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : Colors.transparent,
        border: Border(
          left: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 4),
          bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTrade = holding;
              _isListVisible = false; // Hide sidebar when trade selected
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Symbol and Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(holding.status), size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            holding.displaySymbol,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        holding.displayStatus.toUpperCase(),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor.withOpacity(0.7)),
                      ),
                    ),
                    if (widget.onNavigateToChart != null) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.show_chart, size: 16),
                          tooltip: 'View Chart',
                          color: statusColor.withOpacity(0.7),
                          onPressed: () => widget.onNavigateToChart!(holding.displaySymbol),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Company Name
                Text(
                  holding.displayCompanyName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Quantity
                Text(
                  'Qty: ${holding.displayQuantity}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 8),

                // P&L
                Row(
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up : Icons.trending_down,
                      color: isProfit ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      holding.displayProfitLossPercentage,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isProfit ? Colors.green : Colors.red,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      holding.displayProfitLoss,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isProfit ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.touch_app, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text('Select a Trade', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Choose a trade from the sidebar to view details',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 600.ms);

  Widget _buildTradeDetailView() {
    if (_selectedTrade == null) return const SizedBox();

    return TradeDetailViewPage(
      trade: _selectedTrade!,
      userId: widget.userId,
      portfolioId: widget.portfolioId,
      onNavigateToChart: widget.onNavigateToChart,
      onClose: () {
        setState(() {
          _selectedTrade = null;
        });
      },
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
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
}
