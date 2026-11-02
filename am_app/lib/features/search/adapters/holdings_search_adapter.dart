import 'package:am_common/am_common.dart';
import 'package:am_portfolio_ui/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/share_url_builder.dart';
import '../search_context.dart';
import '../search_relevance.dart';

class HoldingsHit {
  const HoldingsHit({
    required this.symbol,
    required this.name,
    required this.companyName,
  });

  final String symbol;
  final String name;
  final String companyName;
}

/// Cached portfolio holdings for Global Search. Never fetches on its own.
class HoldingsSearchAdapter {
  HoldingsSearchAdapter({List<HoldingsHit> Function()? debugHoldings})
      : _debugHoldings = debugHoldings;

  final List<HoldingsHit> Function()? _debugHoldings;

  List<HoldingsHit> cached({
    ProviderContainer? container,
    BuildContext? navContext,
  }) {
    if (_debugHoldings != null) return _debugHoldings();
    if (container == null) return const [];

    for (final id in _candidatePortfolioIds(navContext)) {
      try {
        final value =
            container.read(portfolioHoldingsProvider(id)).asData?.value;
        if (value == null) continue;
        return value.holdings
            .map(
              (h) => HoldingsHit(
                symbol: h.symbol.trim().toUpperCase(),
                name: h.name,
                companyName: h.companyName,
              ),
            )
            .where((h) => h.symbol.isNotEmpty)
            .toList();
      } catch (_) {
        continue;
      }
    }
    return const [];
  }

  /// `/app/portfolio/holdings` has no id in the URL — use the selected
  /// portfolio (same key the holdings page watches), then `all`.
  List<String> _candidatePortfolioIds(BuildContext? navContext) {
    final ids = <String>[];
    void add(String? id) {
      final v = id?.trim() ?? '';
      if (v.isEmpty || ids.contains(v)) return;
      ids.add(v);
    }

    if (navContext != null) {
      try {
        add(
          ShareUrlBuilder.portfolioIdFromLocation(
            GoRouterState.of(navContext).matchedLocation,
          ),
        );
      } catch (_) {}
      add(navContext.selectedPortfolioId);
    }
    add('all');
    return ids;
  }

  List<HoldingsHit> matching({
    required String query,
    ProviderContainer? container,
    BuildContext? navContext,
  }) {
    final q = query.trim();
    if (q.length < SearchRelevance.minHoldingsQueryLength) return const [];
    return cached(container: container, navContext: navContext).where((h) {
      return SearchRelevance.matchScore(
            query: q,
            title: h.symbol,
            subtitle: '${h.name} ${h.companyName}',
            context: SearchContext.portfolio,
          ) >
          0;
    }).toList();
  }

  /// Searches the user's aggregate holdings so Global Search works from every
  /// app section, not only after the Portfolio page has loaded its cache.
  Future<List<HoldingsHit>> search({
    required String query,
    ProviderContainer? container,
    BuildContext? navContext,
  }) async {
    if (query.trim().length < SearchRelevance.minHoldingsQueryLength) {
      return const [];
    }
    if (_debugHoldings != null || container == null) {
      return matching(
        query: query,
        container: container,
        navContext: navContext,
      );
    }

    try {
      final holdings = await container.read(
        portfolioHoldingsProvider('all').future,
      );
      return holdings.holdings
          .map(
            (h) => HoldingsHit(
              symbol: h.symbol.trim().toUpperCase(),
              name: h.name,
              companyName: h.companyName,
            ),
          )
          .where(
            (h) =>
                h.symbol.isNotEmpty &&
                SearchRelevance.matchScore(
                      query: query,
                      title: h.symbol,
                      subtitle: '${h.name} ${h.companyName}',
                      context: SearchContext.portfolio,
                    ) >
                    0,
          )
          .toList();
    } catch (_) {
      // A transient API failure should not hide holdings already in cache.
      return matching(
        query: query,
        container: container,
        navContext: navContext,
      );
    }
  }
}
