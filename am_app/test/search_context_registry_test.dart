import 'package:flutter_test/flutter_test.dart';

import 'package:am_app/features/search/search_context.dart';
import 'package:am_app/features/search/search_context_registry.dart';
import 'package:am_app/features/search/search_inventory.dart';

void main() {
  group('SearchContextResolver', () {
    test('resolves baskets from portfolio tab', () {
      expect(
        SearchContextResolver.fromLocation('/app/portfolio/p1/baskets'),
        SearchContext.baskets,
      );
    });

    test('resolves equity insider and F&O market tabs', () {
      expect(
        SearchContextResolver.fromLocation('/app/market/equity-insider'),
        SearchContext.equityInsider,
      );
      expect(
        SearchContextResolver.fromLocation('/app/market/futures-options'),
        SearchContext.fo,
      );
    });

    test('resolves portfolio, trade, dashboard', () {
      expect(
        SearchContextResolver.fromLocation('/app/portfolio/p1/holdings'),
        SearchContext.portfolio,
      );
      expect(
        SearchContextResolver.fromLocation('/app/trade/p1/orders'),
        SearchContext.trade,
      );
      expect(
        SearchContextResolver.fromLocation('/app/dashboard'),
        SearchContext.dashboard,
      );
    });

    test('discovery contexts match Baskets / EI / F&O', () {
      expect(
        SearchContextResolver.isDiscoveryContext(SearchContext.baskets),
        isTrue,
      );
      expect(
        SearchContextResolver.isDiscoveryContext(SearchContext.equityInsider),
        isTrue,
      );
      expect(
        SearchContextResolver.isDiscoveryContext(SearchContext.fo),
        isTrue,
      );
      expect(
        SearchContextResolver.isDiscoveryContext(SearchContext.trade),
        isFalse,
      );
    });
  });

  group('SearchContextRegistry', () {
    test('boosts baskets category highest in baskets context', () {
      final copy = SearchContextRegistry.copyFor(SearchContext.baskets);
      expect(copy.bannerTitle, contains('Baskets'));
      expect(
        SearchContextRegistry.boost(SearchContext.baskets, 'Baskets'),
        greaterThan(
          SearchContextRegistry.boost(SearchContext.baskets, 'Market'),
        ),
      );
    });

    test('boosts Market first for Equity Insider and F&O', () {
      expect(
        SearchContextRegistry.boost(SearchContext.equityInsider, 'Market'),
        greaterThan(
          SearchContextRegistry.boost(SearchContext.equityInsider, 'Action'),
        ),
      );
      expect(
        SearchContextRegistry.boost(SearchContext.fo, 'Market'),
        greaterThan(SearchContextRegistry.boost(SearchContext.fo, 'Trade')),
      );
    });

    test('hintFor baskets matches product copy', () {
      expect(
        SearchContextRegistry.hintFor(SearchContext.baskets),
        'Search ETFs & baskets',
      );
      expect(
        SearchContextRegistry.hintFor(SearchContext.equityInsider),
        'Search a stock…',
      );
      expect(
        SearchContextRegistry.hintFor(SearchContext.fo),
        'Search indices & contracts…',
      );
    });
  });

  group('SearchInventory', () {
    test('documents removed discovery surfaces', () {
      expect(SearchInventory.removedDiscoverySurfaces, isNotEmpty);
      expect(
        SearchInventory.removedDiscoverySurfaces,
        containsAll([
          'heatmap_explorer.TextFieldGo',
          'watchlists_page.SearchWatchlists',
          'ipo_filter_toolbar.SearchBox',
          'equity_insider_hero.ChangeStockCapsule',
          'fo_header_card.searchIcon',
        ]),
      );
      expect(
        SearchInventory.keptSpecializedSurfaces,
        containsAll([
          'trade.InstrumentCard',
          'watchlist_detail.SearchStocksFilter',
          'heatmap_index_chips',
        ]),
      );
      expect(
        SearchInventory.keptSpecializedSurfaces,
        isNot(contains('heatmap_symbol_go')),
      );
    });
  });
}
