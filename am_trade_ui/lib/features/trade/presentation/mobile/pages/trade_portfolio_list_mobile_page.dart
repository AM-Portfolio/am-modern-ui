import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/trade_internal_providers.dart';
import '../../components/templates/trade_portfolio_discovery_template.dart';
import '../../models/trade_portfolio_view_model.dart';

class TradePortfolioListMobilePage extends ConsumerWidget {
  const TradePortfolioListMobilePage({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfoliosAsync = ref.watch(tradePortfoliosStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Portfolios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(tradePortfoliosStreamProvider(userId));
            },
          ),
        ],
      ),
      body: portfoliosAsync.when(
        data: (portfolios) => TradePortfolioDiscoveryTemplate(
          portfolios: portfolios,
          isLoading: false,
          onPortfolioSelected: (portfolio) => _navigateToHoldings(context, portfolio),
          onRefresh: () {
            ref.invalidate(tradePortfoliosStreamProvider(userId));
          },
          isWebView: false,
        ),
        loading: () => TradePortfolioDiscoveryTemplate(
          portfolios: const [],
          isLoading: true,
          onPortfolioSelected: (_) {},
          isWebView: false,
        ),
        error: (error, stack) => TradePortfolioDiscoveryTemplate(
          portfolios: const <TradePortfolioViewModel>[],
          isLoading: false,
          errorMessage: error.toString(),
          onPortfolioSelected: (_) {},
          onRefresh: () {
            ref.invalidate(tradePortfoliosStreamProvider(userId));
          },
          isWebView: false,
        ),
      ),
    );
  }

  void _navigateToHoldings(BuildContext context, TradePortfolioViewModel portfolio) {
    Navigator.pushNamed(
      context,
      '/trade/holdings/${portfolio.id}',
      arguments: {'userId': userId, 'portfolioName': portfolio.name},
    );
  }
}
