import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../../providers/trade_internal_providers.dart';
import '../../../holdings/components/trade_holdings_advanced_template.dart';
import '../../../models/trade_holding_view_model.dart';

class SimilarTradesSection extends ConsumerWidget {
  const SimilarTradesSection({
    required this.trade,
        required this.portfolioId,
    this.symbolFilter,
    super.key,
  });

  final TradeHoldingViewModel trade;
    final String portfolioId;
  final String? symbolFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdingsAsync = ref.watch(tradeHoldingsStreamProvider(portfolioId));

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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(context, similarTrades.length, filterSymbol),
              // Advanced Table with constrained height
              SizedBox(
                height: 320,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ModuleColors.trade.withOpacity(0.08), ModuleColors.trade.withOpacity(0.03)],
      ),
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: ModuleColors.trade.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.history, size: 16, color: ModuleColors.trade),
        ),
        const SizedBox(width: 8),
        Text(
          'Similar Trades ($count)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ModuleColors.trade.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ModuleColors.trade.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt, size: 12, color: ModuleColors.trade),
              const SizedBox(width: 4),
              Text(
                'Symbol: $symbol',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ModuleColors.trade),
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
