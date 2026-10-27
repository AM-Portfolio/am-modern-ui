part of 'app_shell.dart';

/// Command palette + mobile fullscreen search wiring.
mixin ShellSearchOps on State<AppShell> {
  // Satisfied by [ShellNav] / [ShellBottomNavChrome] on the same State.
  String get _currentLocation;
  ValueNotifier<bool> get _mobileSearchOpen;

  final UnifiedSearchEngine _searchEngine = UnifiedSearchEngine();

  /// Static module actions / tools (live securities come from [UnifiedSearchEngine]).
  List<common.CommandItem> _seedActionItems(BuildContext context) {
    final portfolioId =
        ShareUrlBuilder.portfolioIdFromLocation(_currentLocation) ?? 'all';
    return [
      common.CommandItem(
        title: 'Trade Journal',
        subtitle: 'Review your past performance',
        category: 'Trade',
        icon: Icons.book,
        onSelected: () => context.go('/app/trade/journal'),
      ),
      common.CommandItem(
        title: 'Equity Insider',
        subtitle: 'Fundamental analysis',
        category: 'Action',
        icon: Icons.insights,
        onSelected: () =>
            context.go(AppRoutes.marketPath('equity-insider')),
      ),
      common.CommandItem(
        title: 'Futures & Options',
        subtitle: 'Option chain and derivatives',
        category: 'Action',
        icon: Icons.candlestick_chart,
        onSelected: () =>
            context.go(AppRoutes.marketPath('futures-options')),
      ),
      common.CommandItem(
        title: 'Baskets',
        subtitle: 'Discover ETFs and basket ideas',
        category: 'Baskets',
        icon: Icons.pie_chart,
        onSelected: () =>
            context.go(AppRoutes.portfolioPath(portfolioId, 'baskets')),
      ),
      common.CommandItem(
        title: 'Place New Order',
        subtitle: 'Open the trading desk',
        category: 'Action',
        icon: Icons.add_shopping_cart,
        onSelected: () => context.go('/app/trade'),
      ),
      common.CommandItem(
        title: 'News',
        subtitle: 'Market headlines',
        category: 'News',
        icon: Icons.article,
        onSelected: () => context.go(AppRoutes.dashboard),
      ),
    ];
  }

  SearchContext get _searchContext =>
      SearchContextResolver.fromLocation(_currentLocation);

  bool get _highlightSearchHint => SearchDiscoveryHint.shouldHighlight(
        _searchContext,
        searchOpen: _mobileSearchOpen.value,
      );

  Future<void> _liveSearchQuery(
    String query,
    void Function(List<common.CommandItem> items, {bool isLoading}) emit,
  ) async {
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } catch (_) {}

    final done = Completer<void>();
    _searchEngine.query(
      rawQuery: query,
      context: _searchContext,
      navContext: context,
      seedActions: _seedActionItems(context),
      container: container,
      onResult: (snap) {
        emit(snap.items, isLoading: snap.isLoading);
        if (!snap.isLoading && !done.isCompleted) {
          done.complete();
        }
        if (snap.error != null && !done.isCompleted) {
          done.complete();
        }
      },
    );
    await done.future;
  }

  List<common.CommandItem> _emptySearchSuggestions() {
    final searchCtx = _searchContext;
    final seed = _seedActionItems(context);
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } catch (_) {}
    List<common.CommandItem> items = seed;
    _searchEngine.query(
      rawQuery: '',
      context: searchCtx,
      navContext: context,
      seedActions: seed,
      container: container,
      onResult: (snap) {
        if (!snap.isLoading) items = snap.items;
      },
    );
    return items;
  }

  void _openMobileFullscreenSearch() {
    final searchCtx = _searchContext;
    SearchDiscoveryHint.dismiss(searchCtx);
    if (_mobileSearchOpen.value != true) {
      _mobileSearchOpen.value = true;
    }
    if (mounted) setState(() {});
  }

  void _showSearch() {
    final searchCtx = _searchContext;
    SearchDiscoveryHint.dismiss(searchCtx);
    if (mounted) setState(() {});

    final isMobile =
        MediaQuery.sizeOf(context).width < UIConstants.mobileBreakpoint;

    if (isMobile) {
      _openMobileFullscreenSearch();
      return;
    }

    final copy = SearchContextRegistry.copyFor(searchCtx);
    common.AmCommandPalette.show(
      context,
      items: _seedActionItems(context),
      bannerTitle: copy.bannerTitle,
      bannerSubtitle: copy.bannerSubtitle,
      liveSearch: _liveSearchQuery,
      emptySuggestions: _emptySearchSuggestions,
    );
  }

  void _disposeSearch() {
    if (identical(common.GlobalSearchBridge.open, _showSearch)) {
      common.GlobalSearchBridge.open = null;
    }
    _searchEngine.dispose();
  }
}
