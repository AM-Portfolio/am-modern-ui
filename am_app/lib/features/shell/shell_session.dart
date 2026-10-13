part of 'app_shell.dart';

/// Dev mock portfolio IDs (trade mock JSON) must not be restored from session.
bool _isDevMockPortfolioId(String portfolioId) =>
    portfolioId.startsWith('mock-');

/// Session restore, portfolio seed, and in-shell history stack.
mixin ShellSessionOps on State<AppShell> {
  // Satisfied by other shell mixins on the same State.
  void _showBottomNavWithIdleHide();
  void _applyStreamingTabCoordinator(String tabTitle);

  bool _sessionRestored = false;
  bool _portfolioSeeded = false;
  String _lastRecordedLocation = '';
  final List<String> _history = [];

  void _updateHistory(String currentLocation) {
    if (currentLocation != _lastRecordedLocation) {
      _lastRecordedLocation = currentLocation;
      // Reveal bottom nav whenever the route changes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showBottomNavWithIdleHide();
      });
      if (_history.contains(currentLocation)) {
        final index = _history.indexOf(currentLocation);
        _history.removeRange(index + 1, _history.length);
      } else {
        _history.add(currentLocation);
      }
    }
  }

  Future<void> _seedPortfolioSelectionFromSession() async {
    if (_portfolioSeeded) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    _portfolioSeeded = true;

    final session =
        await common.SessionPersistenceService.instance.load(authState.user.id);
    if (session?.portfolioId == null || !mounted) return;

    final portfolioId = session!.portfolioId!;
    if (_isDevMockPortfolioId(portfolioId)) return;

    common.PortfolioSelectionScope.maybeStateOf(context)?.seedSelection(
      portfolioId,
      session.portfolioName,
    );
  }

  Future<void> _restoreSessionNav() async {
    if (_sessionRestored) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final userId = authState.user.id;
    final current = GoRouterState.of(context).matchedLocation;

    if (ShareUrlBuilder.isReloadableAppRoute(current) ||
        ShareUrlBuilder.isExplicitDeepLink(current)) {
      _sessionRestored = true;
      _syncSessionFromLocation(userId, current);
      return;
    }

    _sessionRestored = true;

    final session =
        await common.SessionPersistenceService.instance.load(userId);
    if (session == null || !mounted) return;

    if (ShareUrlBuilder.isExplicitDeepLink(current)) return;

    var savedPath = AppRoutes.pathForNavTitle(session.globalNav);
    if (savedPath == null) return;

    // Doc Intel is no longer a primary nav destination.
    if (session.globalNav == 'Doc Intel') {
      savedPath = AppRoutes.dashboard;
    }
    // Paper is now a Market tab (legacy sessions used primary "Paper").
    if (session.globalNav == 'Paper') {
      savedPath = AppRoutes.marketPath('paper');
    }

    final portfolioId = session.portfolioId;
    final restoredPortfolioId =
        portfolioId != null && _isDevMockPortfolioId(portfolioId)
            ? null
            : portfolioId;

    if (restoredPortfolioId != null) {
      if (session.globalNav == 'Portfolio') {
        savedPath = AppRoutes.portfolioPath(
          restoredPortfolioId,
          AppRoutes.portfolioTab(session.portfolioTabIndex),
        );
      } else if (session.globalNav == 'Trade') {
        savedPath = AppRoutes.tradePath(restoredPortfolioId, 'portfolios');
      }
    } else if (portfolioId != null && restoredPortfolioId == null) {
      common.SessionPersistenceService.instance.patch(
        userId,
        (s) => s.copyWith(clearPortfolio: true),
      );
    }

    if (current == AppRoutes.dashboard && savedPath != AppRoutes.dashboard) {
      final streamingNav =
          session.globalNav == 'Paper' ? 'Market' : session.globalNav;
      _applyStreamingTabCoordinator(streamingNav);
      context.go(savedPath);
    }
  }

  void _syncSessionFromLocation(String userId, String location) {
    final nav = AppRoutes.activeNavTitleForLocation(location);
    final portfolioId = ShareUrlBuilder.portfolioIdFromLocation(location);
    final portfolioTab = ShareUrlBuilder.portfolioTabFromLocation(location);

    if (portfolioId != null) {
      common.PortfolioSelectionScope.maybeStateOf(context)
          ?.seedSelection(portfolioId, null);
    }

    common.SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(
        globalNav: nav,
        portfolioId: portfolioId,
        portfolioTabIndex: portfolioTab != null
            ? AppRoutes.portfolioTabIndex(portfolioTab)
            : s.portfolioTabIndex,
        clearPortfolio: portfolioId == null,
      ),
    );
  }
}
