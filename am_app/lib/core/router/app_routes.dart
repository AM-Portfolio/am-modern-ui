/// URL paths and tab slug helpers for [GoRouter] navigation.
class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const verifyEmail = '/verify-email';

  static const dashboard = '/app/dashboard';
  static const portfolio = '/app/portfolio';
  static const trade = '/app/trade';
  static const tradeDiscovery = '/app/trade/portfolios';
  static const market = '/app/market';
  static const aiChat = '/app/ai-chat';
  static const lab = '/app/lab';
  static const analysis = '/app/analysis';
  static const docIntel = '/app/doc-intel';
  static const profile = '/app/profile';
  static const privacyPolicy = '/app/privacy-policy';
  static const termsOfService = '/app/terms-of-service';
  static const subscription = '/app/subscription';

  static const docIntelTabs = [
    'doc-processor',
    'email-extractor',
  ];

  static const portfolioTabs = [
    'overview',
    'holdings',
    'analysis',
    'heatmap',
    'baskets',
  ];

  static const tradeTabs = [
    'portfolios',
    'holdings',
    'calendar',
    'trades',
    'journal',
    'analysis',
    'market-analysis',
    'report',
    'unified',
    'metrics',
    'templates',
  ];

  static const marketStaticSlugs = {
    'All Indices': 'all-indices',
    'Streamer': 'streamer',
    'Instrument Explorer': 'instrument-explorer',
    'Security Explorer': 'security-explorer',
    'ETF Explorer': 'etf-explorer',
    'Price Test': 'price-test',
    'Market Analysis': 'market-analysis',
    'Admin Dashboard': 'admin',
    'Developer Dashboard': 'developer-dashboard',
    'Dashboard': 'dashboard',
    'Heatmap Explorer': 'heatmap-explorer',
  };

  static bool isPortfolioTab(String slug) => portfolioTabs.contains(slug);

  static bool isTradeTab(String slug) => tradeTabs.contains(slug);

  static String portfolioTab(int index) =>
      portfolioTabs[index.clamp(0, portfolioTabs.length - 1)];

  static int portfolioTabIndex(String tab) {
    final index = portfolioTabs.indexOf(tab);
    return index >= 0 ? index : 0;
  }

  static String tradeTab(int index) =>
      tradeTabs[index.clamp(0, tradeTabs.length - 1)];

  static int tradeTabIndex(String tab) {
    final index = tradeTabs.indexOf(tab);
    return index >= 0 ? index : 0;
  }

  static String marketSlugForTitle(String title) {
    return marketStaticSlugs[title] ??
        title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }

  static String marketTitleForSlug(String slug, {List<String> dynamicTitles = const []}) {
    for (final entry in marketStaticSlugs.entries) {
      if (entry.value == slug) return entry.key;
    }
    for (final title in dynamicTitles) {
      if (marketSlugForTitle(title) == slug) return title;
    }
    return 'All Indices';
  }

  static int marketTabIndexForSlug(
    String slug, {
    required List<String> itemTitles,
  }) {
    for (var i = 0; i < itemTitles.length; i++) {
      if (marketSlugForTitle(itemTitles[i]) == slug) return i;
    }
    return 0;
  }

  /// Canonical 3-segment portfolio path.
  static String portfolioPath(String portfolioId, [String tab = 'overview']) =>
      '/app/portfolio/$portfolioId/$tab';

  /// Canonical 3-segment trade path (except discovery).
  static String tradePath(String portfolioId, [String tab = 'portfolios']) =>
      '/app/trade/$portfolioId/$tab';

  static String marketPath([String tab = 'all-indices']) => '/app/market/$tab';

  static String docIntelPath([String tab = 'doc-processor']) =>
      '$docIntel/$tab';

  static bool isDocIntelTab(String slug) => docIntelTabs.contains(slug);

  /// Legacy 2-segment tab-only paths (redirected to 3-segment after portfolio load).
  static String portfolioLegacyTabPath(String tab) => '/app/portfolio/$tab';

  static String tradeLegacyTabPath(String tab) => '/app/trade/$tab';

  static const Map<String, String> navTitleToDefaultPath = {
    'Dashboard': dashboard,
    'Portfolio': '/app/portfolio/overview',
    'Trade': tradeDiscovery,
    'Market': '/app/market/all-indices',
    'AI Chat': aiChat,
    'Lab': lab,
    'Analysis': analysis,
    'Doc Intel': '${AppRoutes.docIntel}/doc-processor',
    'Profile': profile,
    'Subscription': subscription,
  };

  static String? pathForNavTitle(String title) => navTitleToDefaultPath[title];

  static String activeNavTitleForLocation(String location) {
    if (location.startsWith(portfolio)) return 'Portfolio';
    if (location.startsWith(trade)) return 'Trade';
    if (location.startsWith(market)) return 'Market';
    if (location.startsWith(aiChat)) return 'AI Chat';
    if (location.startsWith(lab)) return 'Lab';
    if (location.startsWith(analysis)) return 'Analysis';
    if (location.startsWith(docIntel)) return 'Doc Intel';
    if (location.startsWith(profile) ||
        location.startsWith(privacyPolicy) ||
        location.startsWith(termsOfService)) {
      return 'Profile';
    }
    if (location.startsWith(subscription)) return 'Subscription';
    return 'Dashboard';
  }

  static bool isAuthenticatedAppRoute(String location) =>
      location.startsWith('/app');

  /// Public auth pages that must survive cold start / refresh without a session.
  static const publicAuthRoutes = {
    login,
    register,
    forgotPassword,
    resetPassword,
    verifyEmail,
  };

  /// Strip a trailing slash (except root) so `/reset-password/` matches allowlists.
  static String normalizePath(String path) {
    if (path.isEmpty) return '/';
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }

  static bool isPublicAuthRoute(String location) =>
      publicAuthRoutes.contains(normalizePath(location));
}
