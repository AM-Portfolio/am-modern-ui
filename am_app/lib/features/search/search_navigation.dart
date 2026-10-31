import 'package:am_common/am_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:am_market_ui/features/equity_insider/providers/equity_insider_provider.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_paper_ui/providers/paper_symbol_discovery_provider.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/etf_search_result.dart';

import '../../core/router/app_routes.dart';
import '../../core/router/share_url_builder.dart';
import 'search_context.dart';

/// Central navigation for Global Search result taps.
class SearchNavigationHandler {
  SearchNavigationHandler(this.context, {this.container});

  final BuildContext context;
  final ProviderContainer? container;

  void openSecurity(String symbol, SearchContext searchContext) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;

    switch (searchContext) {
      case SearchContext.equityInsider:
        _setEquityInsiderSymbol(sym);
        context.go(AppRoutes.marketPath('equity-insider'));
        return;
      case SearchContext.fo:
        _setFoSymbol(sym);
        context.go(AppRoutes.marketPath('futures-options'));
        return;
      case SearchContext.paper:
        _setPaperSymbol(sym);
        context.go(AppRoutes.marketPath('paper'));
        return;
      case SearchContext.chart:
        // Keep the live chart pane in sync and always update the URL so the
        // symbol is shareable / reacts to query changes on remount.
        ChartSearchBridge.selectSymbol?.call(sym);
        context.go(AppRoutes.chartWorkspacePath(symbol: sym));
        return;
      case SearchContext.baskets:
        // Baskets keep portfolio discover navigation (handled via ETF path).
        context.go('/app/market/$sym');
        return;
      case SearchContext.portfolio:
        openHolding(sym);
        return;
      case SearchContext.market:
      case SearchContext.trade:
      case SearchContext.dashboard:
      case SearchContext.other:
        // Global / default equity search opens Chart with full stock info.
        ChartSearchBridge.selectSymbol?.call(sym);
        context.go(AppRoutes.chartWorkspacePath(symbol: sym));
    }
  }

  /// Stay on Portfolio Holdings and show only [symbol].
  void openHolding(String symbol) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    String? location;
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {}
    final id = ShareUrlBuilder.portfolioIdFromLocation(location ?? '') ??
        context.selectedPortfolioId ??
        'all';
    context.go(
      Uri(
        path: AppRoutes.portfolioPath(id, 'holdings'),
        queryParameters: {'q': sym},
      ).toString(),
    );
  }

  void openEtfOrBasket(EtfSearchResult result) {
    final portfolioId =
        ShareUrlBuilder.portfolioIdFromLocation(
          GoRouterState.of(context).matchedLocation,
        ) ??
        'all';
    // Land on baskets tab; explorer applies q via Discover filter.
    final base = AppRoutes.portfolioPath(portfolioId, 'baskets');
    final uri = Uri(
      path: base,
      queryParameters: {
        if (result.symbol.isNotEmpty) 'q': result.symbol,
        if (result.isin != null && result.isin!.isNotEmpty) 'isin': result.isin!,
      },
    );
    context.go(uri.toString());
  }

  /// Open Baskets Discover filtered to a catalog theme ETF query (e.g. GOLDBEES).
  void openBasketTheme({
    required String etfQuery,
    String? themeLabel,
  }) {
    final q = etfQuery.trim();
    if (q.isEmpty) {
      openCreateBasket();
      return;
    }
    openEtfOrBasket(
      EtfSearchResult(
        symbol: q,
        name: themeLabel?.trim().isNotEmpty == true ? themeLabel!.trim() : q,
      ),
    );
  }

  void openCreateBasket() {
    final portfolioId =
        ShareUrlBuilder.portfolioIdFromLocation(
          GoRouterState.of(context).matchedLocation,
        ) ??
        'all';
    context.go(AppRoutes.portfolioPath(portfolioId, 'baskets'));
  }

  void _setFoSymbol(String symbol) {
    final c = container;
    if (c == null) return;
    try {
      c.read(foActiveSymbolProvider.notifier).state = symbol;
    } catch (_) {
      // Provider may be unavailable outside market scope.
    }
  }

  void _setEquityInsiderSymbol(String symbol) {
    final c = container;
    if (c == null) return;
    try {
      c.read(equityInsiderActiveSymbolProvider.notifier).state = symbol;
    } catch (_) {
      // Provider may be unavailable outside market scope.
    }
  }

  void _setPaperSymbol(String symbol) {
    final c = container;
    if (c == null) return;
    try {
      c.read(paperSymbolDiscoveryProvider.notifier).state = symbol;
    } catch (_) {
      // Provider may be unavailable outside paper scope.
    }
  }
}
