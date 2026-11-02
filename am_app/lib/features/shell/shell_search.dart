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
        title: 'Portfolio Overview',
        subtitle: 'Portfolio · Overview',
        category: 'Portfolio',
        icon: Icons.account_balance_wallet_outlined,
        onSelected: () => context.go(AppRoutes.portfolioPath(portfolioId)),
      ),
      common.CommandItem(
        title: 'Portfolio Holdings',
        subtitle: 'Portfolio · Holdings',
        category: 'Portfolio',
        icon: Icons.wallet_outlined,
        onSelected: () => context.go(
          AppRoutes.portfolioPath(portfolioId, 'holdings'),
        ),
      ),
      common.CommandItem(
        title: 'Portfolio Analysis',
        subtitle: 'Portfolio · Analysis',
        category: 'Portfolio',
        icon: Icons.analytics_outlined,
        onSelected: () => context.go(
          AppRoutes.portfolioPath(portfolioId, 'analysis'),
        ),
      ),
      common.CommandItem(
        title: 'Portfolio Heatmap',
        subtitle: 'Portfolio · Heatmap',
        category: 'Portfolio',
        icon: Icons.grid_view_outlined,
        onSelected: () => context.go(
          AppRoutes.portfolioPath(portfolioId, 'heatmap'),
        ),
      ),
      common.CommandItem(
        title: 'Portfolio Baskets',
        subtitle: 'Portfolio · Baskets',
        category: 'Portfolio',
        icon: Icons.pie_chart_outline,
        onSelected: () => context.go(
          AppRoutes.portfolioPath(portfolioId, 'baskets'),
        ),
      ),
      common.CommandItem(
        title: 'Add Asset Class',
        subtitle: 'Portfolio · Add an asset class',
        category: 'Portfolio',
        icon: Icons.add_box_outlined,
        onSelected: () => context.go(
          AppRoutes.portfolioPath(portfolioId, 'add-asset-class'),
        ),
      ),
      common.CommandItem(
        title: 'Trade Portfolios',
        subtitle: 'Trade · Portfolios',
        category: 'Trade',
        icon: Icons.folder_outlined,
        onSelected: () => context.go(
          AppRoutes.tradePath(portfolioId, 'portfolios'),
        ),
      ),
      common.CommandItem(
        title: 'Trade Holdings',
        subtitle: 'Trade · Holdings',
        category: 'Trade',
        icon: Icons.wallet_outlined,
        onSelected: () => context.go(
          AppRoutes.tradePath(portfolioId, 'holdings'),
        ),
      ),
      common.CommandItem(
        title: 'Trade Calendar',
        subtitle: 'Trade · Calendar',
        category: 'Trade',
        icon: Icons.calendar_month_outlined,
        onSelected: () => context.go(
          AppRoutes.tradePath(portfolioId, 'calendar'),
        ),
      ),
      common.CommandItem(
        title: 'Trades',
        subtitle: 'Trade · Trades',
        category: 'Trade',
        icon: Icons.swap_horiz,
        onSelected: () => context.go(
          AppRoutes.tradePath(portfolioId, 'trades'),
        ),
      ),
      common.CommandItem(
        title: 'Trade Journal',
        subtitle: 'Trade · Journal',
        category: 'Trade',
        icon: Icons.book_outlined,
        onSelected: () => context.go(
          AppRoutes.tradePath(portfolioId, 'journal'),
        ),
      ),
      common.CommandItem(
        title: 'Trade Analysis',
        subtitle: 'Trade · Analysis',
        category: 'Trade',
        icon: Icons.analytics_outlined,
        onSelected: () => context.go(
          AppRoutes.tradePath(portfolioId, 'analysis'),
        ),
      ),
      common.CommandItem(
        title: 'Unified Trade View',
        subtitle: 'Trade · Unified',
        category: 'Trade',
        icon: Icons.view_agenda_outlined,
        onSelected: () => context.go(
          AppRoutes.tradePath(portfolioId, 'unified'),
        ),
      ),
      common.CommandItem(
        title: 'Trade Templates',
        subtitle: 'Trade · Templates',
        category: 'Trade',
        icon: Icons.library_books_outlined,
        onSelected: () => context.go(
          AppRoutes.tradePath(portfolioId, 'templates'),
        ),
      ),
      common.CommandItem(
        title: 'Add Trade',
        subtitle: 'Trade · Record a trade',
        category: 'Trade',
        icon: Icons.add_circle_outline,
        onSelected: () => context.go(
          AppRoutes.tradePath(portfolioId, 'add-trade'),
        ),
      ),
      common.CommandItem(
        title: 'Place New Order',
        subtitle: 'Action · Open the trading desk',
        category: 'Action',
        icon: Icons.add_shopping_cart,
        onSelected: () => context.go(AppRoutes.tradePath(portfolioId)),
      ),
      common.CommandItem(
        title: 'Market Dashboard',
        subtitle: 'Market · Dashboard',
        category: 'Market',
        icon: Icons.dashboard_outlined,
        onSelected: () => context.go(AppRoutes.marketPath('dashboard')),
      ),
      common.CommandItem(
        title: 'Paper Trading',
        subtitle: 'Market · Paper',
        category: 'Market',
        icon: Icons.science_outlined,
        onSelected: () => context.go(AppRoutes.marketPath('paper')),
      ),
      common.CommandItem(
        title: 'Market Analysis',
        subtitle: 'Market · Detailed charts and analysis',
        category: 'Market',
        icon: Icons.insights_outlined,
        onSelected: () => context.go(AppRoutes.marketPath('market-analysis')),
      ),
      common.CommandItem(
        title: 'Chart',
        subtitle: 'Market · Advanced chart terminal',
        category: 'Market',
        icon: Icons.show_chart,
        onSelected: () => context.go(AppRoutes.marketPath('chart')),
      ),
      common.CommandItem(
        title: 'Equity Insider',
        subtitle: 'Market · Fundamental analysis',
        category: 'Market',
        icon: Icons.insights,
        onSelected: () => context.go(AppRoutes.marketPath('equity-insider')),
      ),
      common.CommandItem(
        title: 'Futures & Options',
        subtitle: 'Market · Option chain and derivatives',
        category: 'Market',
        icon: Icons.candlestick_chart,
        onSelected: () => context.go(AppRoutes.marketPath('futures-options')),
      ),
      common.CommandItem(
        title: 'Watch List',
        subtitle: 'Market · Track securities',
        category: 'Market',
        icon: Icons.star_border,
        onSelected: () => context.go(AppRoutes.marketPath('watch-list')),
      ),
      common.CommandItem(
        title: 'All Indices',
        subtitle: 'Market · Market overview',
        category: 'Market',
        icon: Icons.show_chart_outlined,
        onSelected: () => context.go(AppRoutes.marketPath('all-indices')),
      ),
      common.CommandItem(
        title: 'Market News',
        subtitle: 'Open market headlines on Dashboard',
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
    final path = Uri.parse(_currentLocation).path;
    if (path.contains('/journal') && common.JournalSearchBridge.isBound) {
      common.JournalSearchBridge.tryApply(query);
    }

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
