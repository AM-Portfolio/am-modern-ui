import 'package:am_app/features/search/adapters/holdings_search_adapter.dart';
import 'package:am_common/am_common.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_holding.dart';
import 'package:am_portfolio_ui/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

PortfolioHolding _irfc() {
  return const PortfolioHolding(
    id: 'IRFC',
    symbol: 'IRFC',
    name: 'IRFC',
    companyName: 'INDIAN RAILWAY FINANCE CORPORATION',
    sector: 'Finance',
    industry: 'NBFC',
    quantity: 10,
    avgPrice: 100,
    currentPrice: 120,
    investedAmount: 1000,
    currentValue: 1200,
    todayChange: 2,
    todayChangePercentage: 1,
    totalGainLoss: 200,
    totalGainLossPercentage: 20,
    portfolioWeight: 19,
  );
}

void main() {
  testWidgets('cached holdings use selected portfolio when URL has no id',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        portfolioHoldingsProvider('p1').overrideWith(
          (ref) => PortfolioHoldings(
            holdings: [_irfc()],
            lastUpdated: DateTime(2026, 10, 27),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/app/portfolio/holdings',
      routes: [
        GoRoute(
          path: '/app/portfolio/:tab',
          builder: (_, __) => const Scaffold(body: Text('holdings-page')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: PortfolioSelectionScope(
          initialPortfolioId: 'p1',
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pump();

    final ctx = tester.element(find.text('holdings-page'));
    final hits = HoldingsSearchAdapter().cached(
      container: container,
      navContext: ctx,
    );
    expect(hits.map((h) => h.symbol), ['IRFC']);

    final matched = HoldingsSearchAdapter().matching(
      query: 'irfc',
      container: container,
      navContext: ctx,
    );
    expect(matched, isNotEmpty);
    expect(matched.first.symbol, 'IRFC');
  });
}
