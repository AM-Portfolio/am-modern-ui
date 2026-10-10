import 'package:am_paper_ui/am_paper_ui.dart';
import 'package:am_trade_ui/features/trade/presentation/holdings/pages/trade_holdings_dashboard_web_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chart_portfolio_sidebar.dart';

/// Chart bottom Holdings: filters + holdings table (no empty history chart).
/// Row/symbol tap loads the symbol into the main terminal chart.
class ChartPortfolioHoldingsPanel extends ConsumerWidget {
  const ChartPortfolioHoldingsPanel({
    super.key,
    required this.onSelectSymbol,
  });

  final ValueChanged<String> onSelectSymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(chartSelectedPortfolioProvider);
    if (selected == null) {
      return Center(
        child: Text(
          'Select a portfolio in the sidebar to view holdings',
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (selected.isPaper) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Text(
              'Paper · Holdings',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ChartSidebarHoldings(
              onSelectSymbol: onSelectSymbol,
              hideTitle: true,
            ),
          ),
        ],
      );
    }

    // Chart bottom strip is already under the main price chart — skip the
    // empty portfolio-history block so holdings use the full panel height.
    return TradeHoldingsDashboardWebPage(
      key: ValueKey('holdings-${selected.id}'),
      portfolioId: selected.id,
      embedded: true,
      onNavigateToChart: onSelectSymbol,
    );
  }
}
