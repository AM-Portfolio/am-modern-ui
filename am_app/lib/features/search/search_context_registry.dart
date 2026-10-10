import 'search_context.dart';

class SearchContextCopy {
  const SearchContextCopy({
    required this.bannerTitle,
    required this.bannerSubtitle,
    required this.categoryBoost,
  });

  final String bannerTitle;
  final String bannerSubtitle;

  /// Higher = shown earlier when merging live + static results.
  final Map<String, int> categoryBoost;
}

/// Banner text and ranking weights for Global Search contexts.
class SearchContextRegistry {
  SearchContextRegistry._();

  static SearchContextCopy copyFor(SearchContext ctx) {
    switch (ctx) {
      case SearchContext.baskets:
        return const SearchContextCopy(
          bannerTitle: 'Searching in Baskets',
          bannerSubtitle: 'Showing baskets, ETFs and themes first.',
          categoryBoost: {
            'Baskets': 100,
            'Portfolio': 80,
            'Market': 40,
            'Action': 20,
          },
        );
      case SearchContext.equityInsider:
        return const SearchContextCopy(
          bannerTitle: 'Searching in Equity Insider',
          bannerSubtitle: 'Showing stocks and fundamentals first.',
          categoryBoost: {
            'Market': 100,
            'Action': 30,
            'Portfolio': 20,
          },
        );
      case SearchContext.fo:
        return const SearchContextCopy(
          bannerTitle: 'Searching in Market (F&O)',
          bannerSubtitle: 'Showing indices, derivatives and tools first.',
          categoryBoost: {
            'Market': 100,
            'Action': 50,
            'Trade': 30,
          },
        );
      case SearchContext.paper:
        return const SearchContextCopy(
          bannerTitle: 'Searching in Paper Trading',
          bannerSubtitle: 'Stocks for watchlist and orders first.',
          categoryBoost: {
            'Market': 100,
            'Action': 40,
          },
        );
      case SearchContext.market:
        return const SearchContextCopy(
          bannerTitle: 'Searching in Market',
          bannerSubtitle: 'Indices, stocks and market tools first.',
          categoryBoost: {'Market': 90, 'Action': 40},
        );
      case SearchContext.portfolio:
        return const SearchContextCopy(
          bannerTitle: 'Searching in Portfolio',
          bannerSubtitle: 'Portfolios, baskets and holdings first.',
          categoryBoost: {'Portfolio': 90, 'Baskets': 80, 'Market': 40},
        );
      case SearchContext.trade:
        return const SearchContextCopy(
          bannerTitle: 'Searching in Trade',
          bannerSubtitle: 'Trading tools and instruments first.',
          categoryBoost: {'Trade': 90, 'Action': 60, 'Market': 40},
        );
      case SearchContext.dashboard:
      case SearchContext.other:
        return const SearchContextCopy(
          bannerTitle: 'Searching in AM',
          bannerSubtitle: 'Results across markets, portfolios and tools.',
          categoryBoost: {'Action': 50, 'Market': 40, 'Portfolio': 40, 'Trade': 30},
        );
    }
  }

  /// Sort key for a result category under [ctx] (higher first).
  static int boost(SearchContext ctx, String category) =>
      copyFor(ctx).categoryBoost[category] ?? 0;

  /// Placeholder text for the mobile fullscreen search field.
  static String hintFor(SearchContext ctx) {
    switch (ctx) {
      case SearchContext.baskets:
        return 'Search ETFs & baskets';
      case SearchContext.equityInsider:
        return 'Search a stock…';
      case SearchContext.fo:
        return 'Search indices & contracts…';
      case SearchContext.paper:
        return 'Search stocks for paper…';
      case SearchContext.portfolio:
        return 'Search portfolios & baskets…';
      case SearchContext.market:
        return 'Search markets & symbols…';
      case SearchContext.trade:
        return 'Search trades & instruments…';
      case SearchContext.dashboard:
      case SearchContext.other:
        return 'Search markets, portfolios, trades…';
    }
  }
}
