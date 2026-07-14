import 'app_routes.dart';

/// Builds and parses shareable deep-link paths for portfolio-scoped modules.
class ShareUrlBuilder {
  ShareUrlBuilder._();

  static String portfolio(String portfolioId, [String tab = 'overview']) =>
      AppRoutes.portfolioPath(portfolioId, tab);

  static String trade(String portfolioId, [String tab = 'portfolios']) =>
      AppRoutes.tradePath(portfolioId, tab);

  static String market([String tab = 'all-indices']) => AppRoutes.marketPath(tab);

  /// Tab slug from market URL (`/app/market/:tab`).
  static String? marketTabFromLocation(String location) {
    final segments = _pathSegments(location);
    if (segments.length < 3 || segments[0] != 'app' || segments[1] != 'market') {
      return null;
    }
    return segments[2];
  }

  /// Tab slug from doc-intel URL (`/app/doc-intel` or `/app/doc-intel/:tab`).
  static String? docIntelTabFromLocation(String location) {
    final segments = _pathSegments(location);
    if (segments.length < 2 || segments[0] != 'app' || segments[1] != 'doc-intel') {
      return null;
    }
    if (segments.length >= 3) return segments[2];
    return 'doc-processor';
  }

  /// Returns portfolio ID from a 3-segment portfolio or trade path, else null.
  static String? portfolioIdFromLocation(String location) {
    final segments = _pathSegments(location);
    if (segments.length < 3 || segments[0] != 'app') return null;

    final module = segments[1];
    if (module == 'portfolio' && segments.length >= 4) {
      return segments[2];
    }
    if (module == 'trade' && segments.length >= 4) {
      final candidate = segments[2];
      if (candidate == 'portfolios') return null;
      return candidate;
    }
    return null;
  }

  /// Tab slug from portfolio URL (3-segment or legacy 2-segment tab-only).
  static String? portfolioTabFromLocation(String location) {
    final segments = _pathSegments(location);
    if (segments.length < 3 || segments[0] != 'app' || segments[1] != 'portfolio') {
      return null;
    }
    if (segments.length >= 4) return segments[3];
    if (segments.length == 3 && AppRoutes.isPortfolioTab(segments[2])) {
      return segments[2];
    }
    return null;
  }

  /// Tab slug from trade URL (3-segment, discovery, or legacy 2-segment).
  static String? tradeTabFromLocation(String location) {
    final segments = _pathSegments(location);
    if (segments.length < 3 || segments[0] != 'app' || segments[1] != 'trade') {
      return null;
    }
    if (location == AppRoutes.tradeDiscovery) return 'portfolios';
    if (segments.length >= 4) return segments[3];
    if (segments.length == 3 && AppRoutes.isTradeTab(segments[2])) {
      return segments[2];
    }
    return null;
  }

  /// True when URL already encodes portfolio + tab (share-ready).
  static bool isDeepPortfolioLink(String location) {
    final segments = _pathSegments(location);
    return segments.length >= 4 &&
        segments[0] == 'app' &&
        segments[1] == 'portfolio' &&
        !AppRoutes.isPortfolioTab(segments[2]);
  }

  static bool isDeepTradeLink(String location) {
    if (location == AppRoutes.tradeDiscovery) return false;
    final segments = _pathSegments(location);
    return segments.length >= 4 &&
        segments[0] == 'app' &&
        segments[1] == 'trade' &&
        !AppRoutes.isTradeTab(segments[2]);
  }

  static bool isExplicitDeepLink(String location) =>
      isDeepPortfolioLink(location) || isDeepTradeLink(location);

  /// Validates redirect target from login query param.
  static String? sanitizeRedirect(String? redirect) {
    if (redirect == null || redirect.isEmpty) return null;

    var candidate = redirect;
    if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
      try {
        candidate = Uri.parse(candidate).path;
        final query = Uri.parse(redirect).hasQuery
            ? '?${Uri.parse(redirect).query}'
            : '';
        candidate = '$candidate$query';
      } catch (_) {
        return null;
      }
    }

    if (!candidate.startsWith('/app')) return null;
    return candidate;
  }

  /// True when reload should keep the browser URL (any /app/* route with path).
  static bool isReloadableAppRoute(String location) {
    if (!AppRoutes.isAuthenticatedAppRoute(location)) return false;
    if (location == AppRoutes.dashboard) return false;
    return true;
  }

  static List<String> _pathSegments(String location) {
    final path = Uri.parse(location).path;
    return path.split('/').where((s) => s.isNotEmpty).toList();
  }
}
