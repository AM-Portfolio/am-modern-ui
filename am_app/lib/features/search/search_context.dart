import '../../core/router/app_routes.dart';
import '../../core/router/share_url_builder.dart';

/// Where Global Search was opened from (affects ranking / banner, not category access).
enum SearchContext {
  baskets,
  equityInsider,
  fo,
  paper,
  market,
  portfolio,
  trade,
  dashboard,
  other,
}

class SearchContextResolver {
  SearchContextResolver._();

  static SearchContext fromLocation(String location) {
    final path = _normalize(location);
    final marketTab = ShareUrlBuilder.marketTabFromLocation(path);
    if (marketTab == 'equity-insider') return SearchContext.equityInsider;
    if (marketTab == 'futures-options') return SearchContext.fo;
    if (marketTab == 'paper') return SearchContext.paper;
    if (path.startsWith(AppRoutes.market)) return SearchContext.market;

    final portfolioTab = ShareUrlBuilder.portfolioTabFromLocation(path);
    if (portfolioTab == 'baskets') return SearchContext.baskets;
    if (path.startsWith(AppRoutes.portfolio)) return SearchContext.portfolio;

    if (path.startsWith(AppRoutes.trade)) return SearchContext.trade;
    if (path.startsWith(AppRoutes.dashboard) || path == AppRoutes.dashboard) {
      return SearchContext.dashboard;
    }
    return SearchContext.other;
  }

  /// Pages that used to own discovery search — show a subtle Global Search hint.
  static bool isDiscoveryContext(SearchContext ctx) =>
      ctx == SearchContext.baskets ||
      ctx == SearchContext.equityInsider ||
      ctx == SearchContext.fo ||
      ctx == SearchContext.paper;

  static String _normalize(String location) {
    final path = Uri.parse(location).path;
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }
}
