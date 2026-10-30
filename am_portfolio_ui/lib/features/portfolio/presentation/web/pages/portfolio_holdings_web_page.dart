import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_news_ui/am_news_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../internal/domain/entities/portfolio_holding.dart';
import '../../../providers/portfolio_providers.dart';
import '../mappers/advanced_holding_row_mapper.dart';

/// Portfolio Holdings tab — advanced DS template + portfolio holdings API.
///
/// News scrolls after the holdings list (aligned with main's news surface).
class PortfolioHoldingsWebPage extends ConsumerWidget {
  const PortfolioHoldingsWebPage({
    required this.portfolioId,
    super.key,
    this.portfolioName,
  });

  final String portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePortfolioId = context.selectedPortfolioId ?? portfolioId;
    final holdingsAsync = ref.watch(portfolioHoldingsProvider(activePortfolioId));
    String symbolQuery = '';
    try {
      symbolQuery =
          GoRouterState.of(context).uri.queryParameters['q']?.trim() ?? '';
    } catch (_) {}

    return holdingsAsync.when(
      loading: () => AdvancedHoldingsTemplate(
        holdings: const [],
        isLoading: true,
        accentColor: ModuleColors.portfolio,
      ),
      error: (err, _) => AdvancedHoldingsTemplate(
        holdings: const [],
        isLoading: false,
        errorMessage: err.toString(),
        accentColor: ModuleColors.portfolio,
        onRefresh: () =>
            ref.invalidate(portfolioHoldingsProvider(activePortfolioId)),
      ),
      data: (portfolioHoldings) {
        final visible = visibleHoldingsForCostPolicy(portfolioHoldings.holdings);
        final rows = mapPortfolioHoldingsToAdvancedRows(visible);
        final symbols = [
          for (final h in visible) h.symbol,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AdvancedHoldingsTemplate(
                holdings: rows,
                isLoading: false,
                accentColor: ModuleColors.portfolio,
                priceFreshnessLabel: portfolioHoldings.priceLabel,
                viewOnly: true,
                showCostColumns:
                    showHoldingsCostColumns(portfolioHoldings.holdings),
                initialSearchQuery: symbolQuery,
                onRefresh: () => ref
                    .invalidate(portfolioHoldingsProvider(activePortfolioId)),
              ),
            ),
            HoldingsNewsSection(
              symbols: symbols,
              surface: NewsUiSurface.portfolioHoldings,
            ),
          ],
        );
      },
    );
  }
}
