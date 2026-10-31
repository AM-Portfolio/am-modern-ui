import 'dart:async';

import 'package:am_common/am_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'adapters/basket_catalog_search_adapter.dart';
import 'adapters/etf_basket_search_adapter.dart';
import 'adapters/holdings_search_adapter.dart';
import 'adapters/securities_search_adapter.dart';
import 'search_context.dart';
import 'search_context_registry.dart';
import 'search_navigation.dart';
import 'search_relevance.dart';

class UnifiedSearchSnapshot {
  const UnifiedSearchSnapshot({
    required this.items,
    required this.query,
    required this.requestId,
    this.isLoading = false,
    this.error,
  });

  final List<CommandItem> items;
  final String query;
  final int requestId;
  final bool isLoading;
  final String? error;
}

/// Debounced multi-adapter Global Search engine.
class UnifiedSearchEngine {
  UnifiedSearchEngine({
    SecuritiesSearchAdapter? securities,
    EtfBasketSearchAdapter? etfBasket,
    BasketCatalogSearchAdapter? catalog,
    HoldingsSearchAdapter? holdings,
    this.debounce = const Duration(milliseconds: 180),
  })  : _securities = securities ?? SecuritiesSearchAdapter(),
        _etfBasket = etfBasket ?? EtfBasketSearchAdapter(),
        _catalog = catalog ?? BasketCatalogSearchAdapter(),
        _holdings = holdings ?? HoldingsSearchAdapter();

  final SecuritiesSearchAdapter _securities;
  final EtfBasketSearchAdapter _etfBasket;
  final BasketCatalogSearchAdapter _catalog;
  final HoldingsSearchAdapter _holdings;
  final Duration debounce;

  Timer? _timer;
  int _requestId = 0;

  /// Session recent symbols for empty-state suggestions.
  final List<String> recentSymbols = <String>[];

  /// Test / diagnostics: latest request id after [query].
  int get requestId => _requestId;

  @visibleForTesting
  BasketCatalogSearchAdapter get catalogAdapter => _catalog;

  void dispose() {
    _timer?.cancel();
  }

  void rememberSymbol(String symbol) {
    final s = symbol.trim().toUpperCase();
    if (s.isEmpty) return;
    recentSymbols.remove(s);
    recentSymbols.insert(0, s);
    if (recentSymbols.length > 8) {
      recentSymbols.removeRange(8, recentSymbols.length);
    }
  }

  /// Schedule a search; [onResult] only receives the latest request.
  /// Securities paint first; ETF/basket results merge in when ready.
  void query({
    required String rawQuery,
    required SearchContext context,
    required BuildContext navContext,
    required List<CommandItem> seedActions,
    ProviderContainer? container,
    required void Function(UnifiedSearchSnapshot snapshot) onResult,
  }) {
    _timer?.cancel();
    final query = rawQuery.trim();
    final id = ++_requestId;
    final wantBaskets = context == SearchContext.baskets ||
        context == SearchContext.portfolio;

    if (query.isEmpty) {
      onResult(
        UnifiedSearchSnapshot(
          items: _emptySuggestions(
            context: context,
            seedActions: seedActions,
            navContext: navContext,
            container: container,
          ),
          query: '',
          requestId: id,
        ),
      );
      if (wantBaskets) {
        _catalog.ensureLoaded().then((_) {
          if (id != _requestId) return;
          if (!navContext.mounted) return;
          onResult(
            UnifiedSearchSnapshot(
              items: _emptySuggestions(
                context: context,
                seedActions: seedActions,
                navContext: navContext,
                container: container,
              ),
              query: '',
              requestId: id,
            ),
          );
        });
      }
      return;
    }

    onResult(
      UnifiedSearchSnapshot(
        items: const [],
        query: query,
        requestId: id,
        isLoading: true,
      ),
    );

    _timer = Timer(debounce, () async {
      final nav = SearchNavigationHandler(navContext, container: container);
      final secCategory =
          (context == SearchContext.equityInsider ||
                  context == SearchContext.paper ||
                  context == SearchContext.portfolio)
              ? 'STOCKS'
              : 'ALL';

      var securitiesItems = <CommandItem>[];
      var basketItems = <CommandItem>[];
      var holdingItems = <CommandItem>[];
      var securitiesDone = false;
      var basketsDone = !wantBaskets;
      String? lastError;

      if (context == SearchContext.portfolio) {
        holdingItems = _holdings
            .matching(
              query: query,
              container: container,
              navContext: navContext,
            )
            .map(
              (h) => CommandItem(
                title: h.symbol,
                subtitle: h.companyName.trim().isEmpty
                    ? 'Holding'
                    : 'Holding · ${h.companyName}',
                icon: Icons.account_balance_wallet_outlined,
                category: 'Portfolio',
                onSelected: () {
                  rememberSymbol(h.symbol);
                  nav.openSecurity(h.symbol, context);
                },
              ),
            )
            .toList();
      }

      void emit({required bool loading, String? error}) {
        if (id != _requestId) return;
        final q = query.toLowerCase();
        final actions = seedActions
            .where(
              (i) =>
                  i.title.toLowerCase().contains(q) ||
                  i.subtitle.toLowerCase().contains(q) ||
                  i.category.toLowerCase().contains(q),
            )
            .toList();
        var journalItems = <CommandItem>[];
        if (query.length >= 2) {
          for (final hit in JournalSearchBridge.searchLocal(query)) {
            journalItems.add(
              CommandItem(
                title: hit.title,
                subtitle: hit.subtitle,
                icon: Icons.menu_book_outlined,
                category: 'Journal',
                onSelected: () {
                  JournalSearchBridge.tryApply(query);
                  JournalSearchBridge.focusEntry?.call(hit.id);
                },
              ),
            );
          }
        }

        final holdingSymbols = holdingItems
            .map((h) => h.title.trim().toUpperCase())
            .toSet();
        final marketDeduped = securitiesItems.where(
          (i) => !holdingSymbols.contains(i.title.trim().toUpperCase()),
        );
        final merged = <CommandItem>[
          ...journalItems,
          ...holdingItems,
          ...marketDeduped,
          ...basketItems,
          ...actions,
        ];
        final ranked = List<CommandItem>.generate(merged.length, (i) => merged[i]);
        ranked.sort((a, b) {
          return SearchRelevance.compare(
            context: context,
            query: query,
            aCategory: a.category,
            aTitle: a.title,
            aSubtitle: a.subtitle,
            aIndex: merged.indexOf(a),
            bCategory: b.category,
            bTitle: b.title,
            bSubtitle: b.subtitle,
            bIndex: merged.indexOf(b),
            recents: recentSymbols,
          );
        });
        onResult(
          UnifiedSearchSnapshot(
            items: ranked.take(SearchRelevance.resultCap).toList(),
            query: query,
            requestId: id,
            isLoading: loading,
            error: error ?? lastError,
          ),
        );
      }

      try {
        final securitiesFuture = () async {
          try {
            final hits =
                await _securities.search(query, category: secCategory);
            securitiesItems = hits
                .map(
                  (h) => CommandItem(
                    title: h.symbol,
                    subtitle: h.name,
                    icon: Icons.show_chart,
                    category: 'Market',
                    onSelected: () {
                      rememberSymbol(h.symbol);
                      nav.openSecurity(h.symbol, context);
                    },
                  ),
                )
                .toList();
          } catch (_) {
            securitiesItems = const [];
          } finally {
            securitiesDone = true;
            emit(loading: !(securitiesDone && basketsDone));
          }
        }();

        final basketsFuture = wantBaskets
            ? () async {
                try {
                  final themeHits = await _catalog.search(query);
                  final etfHits = await _etfBasket.search(query);
                  final themeItems = themeHits
                      .map(
                        (h) => CommandItem(
                          title: h.label,
                          subtitle: h.query.isEmpty
                              ? 'Basket theme'
                              : 'Theme · ${h.query}',
                          icon: Icons.category_outlined,
                          category: 'Baskets',
                          onSelected: () => nav.openBasketTheme(
                            etfQuery: h.query,
                            themeLabel: h.label,
                          ),
                        ),
                      )
                      .toList();
                  final usedQueries = themeHits
                      .map((t) => t.query.trim().toUpperCase())
                      .where((s) => s.isNotEmpty)
                      .toSet();
                  final etfItems = etfHits
                      .where(
                        (h) => !usedQueries.contains(
                          h.result.symbol.trim().toUpperCase(),
                        ),
                      )
                      .map(
                        (h) => CommandItem(
                          title: h.title,
                          subtitle: h.subtitle.isEmpty
                              ? 'ETF / Basket'
                              : h.subtitle,
                          icon: Icons.pie_chart_outline,
                          category: 'Baskets',
                          onSelected: () => nav.openEtfOrBasket(h.result),
                        ),
                      )
                      .toList();
                  basketItems = [...themeItems, ...etfItems];
                } catch (e) {
                  basketItems = const [];
                  lastError = 'Baskets search unavailable';
                } finally {
                  basketsDone = true;
                  emit(loading: !(securitiesDone && basketsDone));
                }
              }()
            : Future<void>.value();

        await Future.wait([securitiesFuture, basketsFuture]);
        if (id != _requestId) return;
        emit(loading: false);
      } catch (e) {
        if (id != _requestId) return;
        emit(loading: false, error: e.toString());
      }
    });
  }

  List<CommandItem> _emptySuggestions({
    required SearchContext context,
    required List<CommandItem> seedActions,
    required BuildContext navContext,
    ProviderContainer? container,
  }) {
    final nav = SearchNavigationHandler(navContext, container: container);
    final out = <CommandItem>[];

    if (context == SearchContext.chart) {
      final chartRecents = ChartSearchBridge.recentSymbols;
      for (final sym in chartRecents.take(8)) {
        out.add(
          CommandItem(
            title: sym,
            subtitle: 'Recent chart',
            icon: Icons.history,
            category: 'Market',
            onSelected: () => nav.openSecurity(sym, SearchContext.chart),
          ),
        );
      }
      if (chartRecents.isEmpty) {
        for (final sym in const ['NIFTY 50', 'BANKNIFTY', 'RELIANCE', 'TCS']) {
          out.add(
            CommandItem(
              title: sym,
              subtitle: 'Popular chart',
              icon: Icons.show_chart,
              category: 'Market',
              onSelected: () => nav.openSecurity(sym, SearchContext.chart),
            ),
          );
        }
      }
    } else {
      for (final sym in recentSymbols.take(4)) {
        out.add(
          CommandItem(
            title: sym,
            subtitle: 'Recent',
            icon: Icons.history,
            category: 'Market',
            onSelected: () => nav.openSecurity(sym, context),
          ),
        );
      }
    }

    if (context == SearchContext.baskets) {
      for (final theme in _catalog.featuredCached.take(6)) {
        out.add(
          CommandItem(
            title: theme.label,
            subtitle: theme.query.isEmpty
                ? 'Popular theme'
                : 'Theme · ${theme.query}',
            icon: Icons.category_outlined,
            category: 'Baskets',
            onSelected: () => nav.openBasketTheme(
              etfQuery: theme.query,
              themeLabel: theme.label,
            ),
          ),
        );
      }
      out.add(
        CommandItem(
          title: 'Create a new basket',
          subtitle: 'Open Baskets to build or discover',
          icon: Icons.add_circle_outline,
          category: 'Action',
          onSelected: nav.openCreateBasket,
        ),
      );
    }

    if (context == SearchContext.fo) {
      for (final sym in const ['NIFTY', 'BANKNIFTY', 'FINNIFTY']) {
        out.add(
          CommandItem(
            title: sym,
            subtitle: 'Index · F&O',
            icon: Icons.candlestick_chart,
            category: 'Market',
            onSelected: () => nav.openSecurity(sym, SearchContext.fo),
          ),
        );
      }
    }

    if (context == SearchContext.portfolio) {
      for (final h in _holdings
          .cached(container: container, navContext: navContext)
          .take(8)) {
        out.add(
          CommandItem(
            title: h.symbol,
            subtitle: h.companyName.trim().isEmpty
                ? 'Holding'
                : 'Holding · ${h.companyName}',
            icon: Icons.account_balance_wallet_outlined,
            category: 'Portfolio',
            onSelected: () => nav.openSecurity(h.symbol, context),
          ),
        );
      }
    }

    if (context == SearchContext.equityInsider ||
        context == SearchContext.paper) {
      for (final sym in const ['RELIANCE', 'TCS', 'HDFCBANK', 'INFY']) {
        out.add(
          CommandItem(
            title: sym,
            subtitle: context == SearchContext.paper
                ? 'Paper watchlist'
                : 'Popular stock',
            icon: context == SearchContext.paper
                ? Icons.science_outlined
                : Icons.insights,
            category: 'Market',
            onSelected: () => nav.openSecurity(sym, context),
          ),
        );
      }
    }

    final ranked = List<CommandItem>.from(seedActions)
      ..sort((a, b) {
        final ba = SearchContextRegistry.boost(context, a.category);
        final bb = SearchContextRegistry.boost(context, b.category);
        return bb.compareTo(ba);
      });
    out.addAll(ranked.take(6));

    final seen = <String>{};
    return out.where((i) => seen.add(i.title.toLowerCase())).take(12).toList();
  }
}
