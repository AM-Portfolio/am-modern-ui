import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/portfolio_overview_providers.dart';
import '../../../providers/trade_internal_providers.dart';
import '../../components/templates/trade_portfolio_discovery_template.dart';
import '../../models/trade_portfolio_view_model.dart';

class TradePortfolioListWebPage extends ConsumerWidget {
  const TradePortfolioListWebPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // enrichedTradePortfoliosProvider stitches together:
    //   - Realized metrics (Win Rate, Net P&L) from am-trade-management
    //   - Live Unrealized metrics (Portfolio Value, Gain/Loss) from am-portfolio
    // If am-portfolio is unavailable, it degrades gracefully to realized-only data.
    final portfoliosAsync = ref.watch(enrichedTradePortfoliosProvider);

    void handleRefresh() {
      // Invalidate both the upstream providers so fresh data is fetched
      ref.invalidate(tradePortfoliosStreamProvider);
      ref.invalidate(enrichedTradePortfoliosProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Portfolios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: handleRefresh,
          ),
        ],
      ),
      body: portfoliosAsync.when(
        data: (portfolios) => TradePortfolioDiscoveryTemplate(
          portfolios: portfolios,
          isLoading: false,
          onPortfolioSelected: (portfolio) => _navigateToHoldings(context, portfolio),
          onRefresh: handleRefresh,
          isWebView: true,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => TradePortfolioDiscoveryTemplate(
          portfolios: const <TradePortfolioViewModel>[],
          isLoading: false,
          errorMessage: error.toString(),
          onPortfolioSelected: (_) {},
          onRefresh: handleRefresh,
          isWebView: true,
        ),
      ),
    );
  }

  void _navigateToHoldings(BuildContext context, TradePortfolioViewModel portfolio) {
    Navigator.pushNamed(
      context,
      '/trade/holdings/${portfolio.id}',
      arguments: {'portfolioId': portfolio.id},
    );
  }
}
