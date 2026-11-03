import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_news_ui/am_news_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../internal/domain/entities/portfolio_holding.dart';
import '../../../providers/portfolio_providers.dart';
import '../mappers/advanced_holding_row_mapper.dart';
import '../widgets/cas_account_directory_panel.dart';
import '../widgets/cas_asset_class_filter.dart';
import '../widgets/cas_folio_panel.dart';
import '../widgets/cas_status_banner.dart';
import '../widgets/nps_status_banner.dart';

/// Portfolio Holdings tab — advanced DS template + portfolio holdings API.
///
/// News scrolls after the holdings list (aligned with main's news surface).
class PortfolioHoldingsWebPage extends ConsumerStatefulWidget {
  const PortfolioHoldingsWebPage({
    required this.portfolioId,
    super.key,
    this.portfolioName,
  });

  final String portfolioId;
  final String? portfolioName;

  @override
  ConsumerState<PortfolioHoldingsWebPage> createState() =>
      _PortfolioHoldingsWebPageState();
}

class _PortfolioHoldingsWebPageState
    extends ConsumerState<PortfolioHoldingsWebPage> {
  String? _assetClassFilter;
  bool _npsDefaultApplied = false;

  static bool _looksLikeNpsPortfolio(String? name, String? id) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('nps')) return true;
    final i = (id ?? '').toLowerCase();
    return i.contains('nps');
  }

  static bool _isNpsHolding(PortfolioHolding h) {
    return h.assetClass.toLowerCase() == 'nps';
  }

  @override
  Widget build(BuildContext context) {
    final activePortfolioId =
        context.selectedPortfolioId ?? widget.portfolioId;
    final holdingsAsync =
        ref.watch(portfolioHoldingsProvider(activePortfolioId));
    String symbolQuery = '';
    try {
      symbolQuery =
          GoRouterState.of(context).uri.queryParameters['q']?.trim() ?? '';
    } catch (_) {}

    final selectedName =
        context.selectedPortfolioName ?? widget.portfolioName;
    if (!_npsDefaultApplied &&
        _looksLikeNpsPortfolio(selectedName, activePortfolioId)) {
      _npsDefaultApplied = true;
      _assetClassFilter = 'nps';
    }

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
        var visible = visibleHoldingsForCostPolicy(portfolioHoldings.holdings);
        if (_assetClassFilter == 'nps') {
          visible = visible.where(_isNpsHolding).toList();
        } else if (_assetClassFilter != null) {
          final want = _assetClassFilter!.toLowerCase();
          visible = visible
              .where(
                (h) =>
                    !_isNpsHolding(h) &&
                    (h.assetClass.toLowerCase() == want ||
                        (want == 'equity' &&
                            (h.assetClass.isEmpty ||
                                h.assetClass.toUpperCase() == 'EQUITY'))),
              )
              .toList();
        } else {
          // All / default: exclude NPS rows (NPS chip owns that view).
          visible = visible.where((h) => !_isNpsHolding(h)).toList();
        }
        final rows = mapPortfolioHoldingsToAdvancedRows(visible);
        final symbols = [
          for (final h in visible) h.symbol,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CasStatusBanner(),
            const NpsStatusBanner(),
            CasAssetClassFilter(
              value: _assetClassFilter,
              onChanged: (v) => setState(() => _assetClassFilter = v),
            ),
            const CasAccountDirectoryPanel(),
            CasFolioPanel(portfolioId: activePortfolioId),
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
