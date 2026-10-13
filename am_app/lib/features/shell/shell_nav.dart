part of 'app_shell.dart';

/// Global nav titles, accents, swipe, and streaming-tab coordination.
mixin ShellNav on State<AppShell> {
  // Satisfied by [ShellBottomNavChrome] on the same State.
  void _showBottomNavWithIdleHide();

  String get _currentLocation => GoRouterState.of(context).matchedLocation;

  String get _activeNavItem {
    final location = GoRouterState.of(context).matchedLocation;
    return AppRoutes.activeNavTitleForLocation(location);
  }

  List<SidebarItem> _sidebarItemsFor({required bool isAdmin}) => [
        const SidebarItem(
            title: 'Dashboard', icon: Icons.dashboard_rounded),
        const SidebarItem(
            title: 'Portfolio',
            icon: Icons.account_balance_wallet_rounded),
        const SidebarItem(title: 'Trade', icon: Icons.swap_horiz_rounded),
        const SidebarItem(title: 'Market', icon: Icons.show_chart_rounded),
        const SidebarItem(
            title: 'AI Chat', icon: Icons.auto_awesome_rounded),
        if (isAdmin)
          const SidebarItem(
              title: 'Analysis', icon: Icons.analytics_outlined),
      ];

  Color _moduleAccentFor(String title) {
    switch (title.toLowerCase()) {
      case 'dashboard':
        return ModuleColors.dashboard;
      case 'portfolio':
        return ModuleColors.portfolio;
      case 'trade':
        return ModuleColors.trade;
      case 'market':
        return ModuleColors.market;
      case 'ai chat':
        return ModuleColors.aiChat;
      case 'analysis':
      case 'doc intel':
        return ModuleColors.analytics;
      default:
        return ModuleColors.dashboard;
    }
  }

  ModuleType _moduleTypeFor(String title) {
    switch (title.toLowerCase()) {
      case 'dashboard':
        return ModuleType.dashboard;
      case 'portfolio':
        return ModuleType.portfolio;
      case 'trade':
        return ModuleType.trade;
      case 'market':
        return ModuleType.market;
      case 'analysis':
      case 'doc intel':
        return ModuleType.admin;
      case 'ai chat':
        return ModuleType.dashboard;
      default:
        return ModuleType.other;
    }
  }

  void _applyStreamingTabCoordinator(String tabTitle) {
    if (!GetIt.instance.isRegistered<common.AmStompClient>()) return;
    if (tabTitle.isEmpty) return;
    common.StreamingTabCoordinator(GetIt.instance<common.AmStompClient>())
        .onTabSelected(tabTitle);
  }

  void _onGlobalNavigate(String title, String userId) {
    final path = AppRoutes.pathForNavTitle(title);
    if (path == null) return;

    ProductTelemetry.instance.featureAction(
      'global_nav',
      tag: 'shell',
      metadata: {'title': title},
    );
    _showBottomNavWithIdleHide();
    _applyStreamingTabCoordinator(title);
    context.go(path);
    common.SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(globalNav: title, clearBasket: title != 'Portfolio'),
    );
  }

  String? _resolveSwipePortfolioId() {
    final fromUrl =
        ShareUrlBuilder.portfolioIdFromLocation(_currentLocation);
    if (fromUrl != null && fromUrl.isNotEmpty) return fromUrl;
    final cached = common.SessionPersistenceService.instance.cached?.portfolioId;
    if (cached != null &&
        cached.isNotEmpty &&
        !_isDevMockPortfolioId(cached)) {
      return cached;
    }
    return null;
  }

  void _goSwipePath(String path, String userId) {
    _showBottomNavWithIdleHide();
    final navTitle = AppRoutes.activeNavTitleForLocation(path);
    _applyStreamingTabCoordinator(navTitle);
    context.go(path);
    common.SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(
        globalNav: navTitle,
        clearBasket: navTitle != 'Portfolio',
      ),
    );
  }

  void _onCrossSectionNext(String userId) {
    // Doc Intel is a shortcut destination (not in the swipe sequence).
    if (_currentLocation.startsWith(AppRoutes.docIntel)) return;
    final next = CrossModuleSectionSequence.nextPath(
      _currentLocation,
      portfolioId: _resolveSwipePortfolioId(),
    );
    if (next == null) return;
    _goSwipePath(next, userId);
  }

  void _onCrossSectionPrevious(String userId) {
    if (_currentLocation.startsWith(AppRoutes.docIntel)) return;
    final prev = CrossModuleSectionSequence.previousPath(
      _currentLocation,
      portfolioId: _resolveSwipePortfolioId(),
    );
    if (prev == null) return;
    _goSwipePath(prev, userId);
  }

  StreamSubscription<bool>? _marketGateSubscription;

  Future<void> _startMarketStreamingGate() async {
    if (!GetIt.instance.isRegistered<common.MarketStreamingGate>()) return;
    final gate = GetIt.instance<common.MarketStreamingGate>();
    await gate.start();
    _marketGateSubscription?.cancel();
    _marketGateSubscription = gate.isOpenStream.listen((open) {
      if (!mounted) return;
      if (open) {
        _applyStreamingTabCoordinator(_activeNavItem);
      } else {
        _applyStreamingTabCoordinator(_activeNavItem);
      }
    });
  }

  void _resetMarketStreamingGate() {
    _marketGateSubscription?.cancel();
    _marketGateSubscription = null;
    if (GetIt.instance.isRegistered<common.MarketStreamingGate>()) {
      GetIt.instance<common.MarketStreamingGate>().reset();
    }
  }

  Future<void> _syncFeatureFlagAttributes(String userId) async {
    if (!GetIt.instance.isRegistered<common.FeatureFlagService>()) return;
    await GetIt.instance<common.FeatureFlagService>().updateAttributes({
      'id': userId,
      'platform': common.featureFlagPlatform(),
      'environment': common.ConfigService.resolvedEnv,
    });
  }

  Future<void> _clearFeatureFlagAttributes() async {
    if (!GetIt.instance.isRegistered<common.FeatureFlagService>()) return;
    await GetIt.instance<common.FeatureFlagService>().updateAttributes({
      'platform': common.featureFlagPlatform(),
      'environment': common.ConfigService.resolvedEnv,
    });
  }
}
