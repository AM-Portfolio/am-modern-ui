import '../router/app_routes.dart';
import '../router/share_url_builder.dart';

/// Ordered mobile swipe sequence across primary modules and their sub-pages.
///
/// Finger swipe **left** advances forward through this list (wraps at the end).
class CrossModuleSectionSequence {
  CrossModuleSectionSequence._();

  /// Portfolio tabs that participate in mobile swipe (plus add-trade).
  static const portfolioSwipeTabs = [
    'overview',
    'holdings',
    'heatmap',
    'baskets',
    'add-trade',
  ];

  /// Trade mobile swipe tabs (URL-backed where possible).
  static const tradeSwipeTabs = [
    'portfolios',
    'holdings',
    'calendar',
    'journal',
    'metrics',
    'templates',
  ];

  /// Market user-mode pages in swipe order.
  static const marketSwipeTabs = [
    'dashboard',
    'market-analysis',
  ];

  /// Doc Intel pages in swipe order.
  static const docIntelSwipeTabs = [
    'doc-processor',
    'email-extractor',
  ];

  /// Build a full deep link for a portfolio tab, falling back to legacy 2-segment.
  static String portfolioStepPath(String? portfolioId, String tab) {
    if (portfolioId != null && portfolioId.isNotEmpty) {
      return AppRoutes.portfolioPath(portfolioId, tab);
    }
    return AppRoutes.portfolioLegacyTabPath(
      tab == 'add-trade' ? 'overview' : tab,
    );
  }

  static String tradeStepPath(String? portfolioId, String tab) {
    if (tab == 'portfolios') return AppRoutes.tradeDiscovery;
    if (portfolioId != null && portfolioId.isNotEmpty) {
      return AppRoutes.tradePath(portfolioId, tab);
    }
    return AppRoutes.tradeLegacyTabPath(tab);
  }

  static String marketStepPath(String tab) => AppRoutes.marketPath(tab);

  static String docIntelStepPath(String tab) => AppRoutes.docIntelPath(tab);

  /// Next path from [location]. Wraps Profile → Dashboard.
  static String? nextPath(
    String location, {
    String? portfolioId,
  }) {
    final id = portfolioId ?? ShareUrlBuilder.portfolioIdFromLocation(location);
    final steps = _steps(id);
    if (steps.isEmpty) return null;
    final index = indexOfLocation(location, portfolioId: id);
    if (index < 0) return null;
    return steps[(index + 1) % steps.length];
  }

  /// Previous path from [location]. Wraps Dashboard → Profile.
  static String? previousPath(
    String location, {
    String? portfolioId,
  }) {
    final id = portfolioId ?? ShareUrlBuilder.portfolioIdFromLocation(location);
    final steps = _steps(id);
    if (steps.isEmpty) return null;
    final index = indexOfLocation(location, portfolioId: id);
    if (index < 0) return null;
    return steps[(index - 1 + steps.length) % steps.length];
  }

  /// Index of [location] in the swipe sequence, or nearest module root.
  static int indexOfLocation(String location, {String? portfolioId}) {
    final id = portfolioId ?? ShareUrlBuilder.portfolioIdFromLocation(location);
    final steps = _steps(id);
    final normalized = _normalize(location);

    final exact = steps.indexWhere((s) => _normalize(s) == normalized);
    if (exact >= 0) return exact;

    // Soft match: same module + closest tab.
    if (normalized.startsWith('/app/dashboard') ||
        normalized == AppRoutes.dashboard) {
      return steps.indexWhere((s) => s == AppRoutes.dashboard);
    }
    if (normalized.startsWith(AppRoutes.portfolio)) {
      final tab =
          ShareUrlBuilder.portfolioTabFromLocation(location) ?? 'overview';
      final target =
          portfolioStepPath(id, tab == 'analysis' ? 'overview' : tab);
      final i = steps.indexWhere((s) => _normalize(s) == _normalize(target));
      if (i >= 0) return i;
      return steps.indexWhere((s) => s.contains('/portfolio/'));
    }
    if (normalized.startsWith(AppRoutes.trade)) {
      final tab =
          ShareUrlBuilder.tradeTabFromLocation(location) ?? 'portfolios';
      final target = tradeStepPath(id, tab);
      final i = steps.indexWhere((s) => _normalize(s) == _normalize(target));
      if (i >= 0) return i;
      return steps.indexWhere((s) => s.contains('/trade'));
    }
    if (normalized.startsWith(AppRoutes.market)) {
      final tab = ShareUrlBuilder.marketTabFromLocation(location) ?? 'dashboard';
      // Map legacy / alternate user landings onto the first market swipe step.
      final resolved = (tab == 'all-indices' || tab == 'heatmap-explorer')
          ? (tab == 'heatmap-explorer' ? 'market-analysis' : 'dashboard')
          : tab;
      final target = marketStepPath(
        marketSwipeTabs.contains(resolved) ? resolved : 'dashboard',
      );
      final i = steps.indexWhere((s) => _normalize(s) == _normalize(target));
      if (i >= 0) return i;
      return steps.indexWhere((s) => s.startsWith(AppRoutes.market));
    }
    if (normalized.startsWith(AppRoutes.docIntel)) {
      final tab =
          ShareUrlBuilder.docIntelTabFromLocation(location) ?? 'doc-processor';
      final target = docIntelStepPath(
        docIntelSwipeTabs.contains(tab) ? tab : 'doc-processor',
      );
      final i = steps.indexWhere((s) => _normalize(s) == _normalize(target));
      if (i >= 0) return i;
      return steps.indexWhere((s) => s.startsWith(AppRoutes.docIntel));
    }
    if (normalized.startsWith(AppRoutes.subscription)) {
      return steps.indexWhere((s) => s == AppRoutes.subscription);
    }
    if (normalized.startsWith(AppRoutes.profile) ||
        normalized.startsWith(AppRoutes.privacyPolicy) ||
        normalized.startsWith(AppRoutes.termsOfService)) {
      return steps.indexWhere((s) => s == AppRoutes.profile);
    }
    return 0;
  }

  static List<String> _steps(String? portfolioId) => [
        AppRoutes.dashboard,
        for (final tab in portfolioSwipeTabs)
          portfolioStepPath(portfolioId, tab),
        for (final tab in tradeSwipeTabs) tradeStepPath(portfolioId, tab),
        for (final tab in marketSwipeTabs) marketStepPath(tab),
        for (final tab in docIntelSwipeTabs) docIntelStepPath(tab),
        AppRoutes.subscription,
        AppRoutes.profile,
      ];

  static String _normalize(String location) {
    final path = Uri.parse(location).path;
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }
}
