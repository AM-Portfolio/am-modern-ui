import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/trade_internal_providers.dart';
import '../../../holdings/components/trade_holdings_advanced_template.dart';
import '../../../models/trade_holding_view_model.dart';

class SimilarTradesSection extends ConsumerWidget {
  const SimilarTradesSection({
    required this.trade,
    required this.userId,
    required this.portfolioId,
    this.symbolFilter,
    super.key,
  });

  final TradeHoldingViewModel trade;
  final String userId;
  final String portfolioId;
  final String? symbolFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (userId: userId, portfolioId: portfolioId);
    final holdingsAsync = ref.watch(tradeHoldingsStreamProvider(params));

    return holdingsAsync.when(
      data: (tradeHoldings) {
        // Filter trades based on symbol filter or current trade symbol
        final filterSymbol = symbolFilter?.trim().toUpperCase() ?? trade.symbol;
        final similarTrades = tradeHoldings.holdings
            .where((h) => h.symbol.toUpperCase() == filterSymbol.toUpperCase())
            .toList();

        if (similarTrades.isEmpty) {
          return _buildEmptyState(context, filterSymbol);
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(context, similarTrades.length, filterSymbol),
              // Advanced Table with constrained height
              SizedBox(
                height: 500,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: TradeHoldingsAdvancedTemplate(holdings: similarTrades, isLoading: false, itemsPerPage: 10),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()),
      ),
      error: (error, _) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildHeader(BuildContext context, int count, String symbol) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue.shade600.withOpacity(0.08), Colors.blue.shade600.withOpacity(0.03)],
      ),
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade600.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.history, size: 20, color: Colors.blue.shade600),
        ),
        const SizedBox(width: 12),
        Text(
          'All Similar Trades Executed ($count)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade600.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade600.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt, size: 14, color: Colors.blue.shade600),
              const SizedBox(width: 6),
              Text(
                'Symbol: $symbol',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade600),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildEmptyState(BuildContext context, String symbol) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No trades found for symbol: $symbol',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for a different symbol',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          ),
        ],
      ),
    ),
  );

  Widget _buildErrorState(BuildContext context, String error) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error loading similar trades',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
