import 'package:am_market_ui/core/providers/view_mode_provider.dart' as view_mode;
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_market_common/providers/market_provider.dart';


import 'package:am_market_ui/features/etf/etf_explorer_page.dart';
import 'package:am_market_ui/features/instrument/instrument_explorer_page.dart';

import 'package:am_market_ui/features/security/security_explorer_page.dart';
import 'package:am_market_dev/am_market_dev.dart';
import 'package:am_market_ui/features/watchlists/presentation/pages/watchlists_page.dart';
import 'package:am_market_ui/features/market/widgets/all_indices_page.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:am_common/core/di/price_providers.dart';
import 'package:am_common/core/services/price_service.dart';

import 'package:am_market_ui/features/market_analysis/presentation/widgets/market_index_detail_view.dart';

import 'package:am_market_ui/shared/widgets/mode_toggle_widget.dart';
import 'user_dashboard_page.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/heatmap_explorer_view.dart';
import 'package:am_common/am_common.dart';
import 'package:am_market_ui/features/equity_insider/presentation/pages/equity_insider_page.dart';

/// Market feature page with Swipe Navigation
class MarketPage extends StatelessWidget {
  const MarketPage({
    required this.userId,
    super.key,
    this.initialTab = 'all-indices',
    this.onTabChanged,
    this.onBack,
    this.paperDesk,
  });

  final String userId;
  final String initialTab;
  final ValueChanged<String>? onTabChanged;
  final VoidCallback? onBack;

  /// Host-injected paper trading desk (avoids am_market_ui → am_paper_ui cycle).
  final Widget? paperDesk;

  @override
  Widget build(BuildContext context) {
    CommonLogger.methodEntry('build', tag: 'MarketPage');

    final authState = context.watch<AuthCubit>().state;
    final isAdmin = authState is Authenticated && authState.user.isAdmin;
    final tab = _effectiveMarketTab(initialTab, isAdmin: isAdmin);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            CommonLogger.info(
              'Initializing MarketProvider for MarketPage',
              tag: 'MarketPage',
            );
            final provider = MarketProvider();
            // Trigger initial load
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (provider.availableIndices == null) {
                provider.loadIndices();
              }
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => view_mode.ViewModeProvider(lockToUserMode: !isAdmin),
        ),
      ],
      child: MarketContent(
        userId: userId,
        initialTab: tab,
        isAdmin: isAdmin,
        onTabChanged: onTabChanged,
        onBack: onBack,
        paperDesk: paperDesk,
      ),
    );
  }
}

String _effectiveMarketTab(String tab, {required bool isAdmin}) {
  if (isAdmin) return tab;
  const developerOnly = {
    'streamer',
    'price-test',
    'admin',
    'developer-dashboard',
    'instrument-explorer',
    'security-explorer',
    'etf-explorer',
  };
  if (developerOnly.contains(tab)) return 'dashboard';
  return tab;
}

class MarketContent extends ConsumerStatefulWidget {
  const MarketContent({
    required this.userId,
    super.key,
    this.initialTab = 'all-indices',
    this.isAdmin = false,
    this.onTabChanged,
    this.onBack,
    this.paperDesk,
  });

  final String userId;
  final String initialTab;
  final bool isAdmin;
  final ValueChanged<String>? onTabChanged;
  final VoidCallback? onBack;
  final Widget? paperDesk;

  @override
  ConsumerState<MarketContent> createState() => _MarketContentState();
}

class _MarketContentState extends ConsumerState<MarketContent> {
  late SwipeNavigationController _swipeController;
  final GlobalKey<UserDashboardPageState> _dashboardKey =
      GlobalKey<UserDashboardPageState>();
  final GlobalKey<EquityInsiderPageState> _equityInsiderKey =
      GlobalKey<EquityInsiderPageState>();

  static const _staticTitleToSlug = {
    'Paper': 'paper',
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
    'Equity Insider': 'equity-insider',
    'Watch List': 'watch-list',
  };

  String _slugForTitle(String title) {
    return _staticTitleToSlug[title] ??
        title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }

  int _indexForSlug(String slug, List<NavigationItem> items) {
    for (var i = 0; i < items.length; i++) {
      if (_slugForTitle(items[i].title) == slug) return i;
    }
    return 0;
  }

  void _syncTabFromUrl({bool notify = false, bool? isMobile}) {
    final items = _swipeController.items;
    if (items.isEmpty) return;
    var tab = widget.initialTab;
    final mobile = isMobile ?? MediaQuery.sizeOf(context).width < 1100;
    // Web has no All Indices secondary tab — land on Dashboard instead.
    if (!mobile && tab == 'all-indices') {
      tab = 'dashboard';
    }
    final index = _indexForSlug(tab, items);
    if (_swipeController.currentIndex != index) {
      _swipeController.navigateTo(index);
    }
    if (notify) {
      widget.onTabChanged?.call(_slugForTitle(items[index].title));
    }
  }

  void _notifyTabChanged() {
    final items = _swipeController.items;
    if (items.isEmpty) return;
    final title = items[_swipeController.currentIndex].title;
    widget.onTabChanged?.call(_slugForTitle(title));
  }

  @override
  void initState() {
    super.initState();
    _initializeSwipeController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindPriceService());
  }

  Future<void> _bindPriceService() async {
    if (!mounted) return;
    try {
      final service = await ref.read(priceServiceProvider.future);
      if (!mounted) return;
      context.read<MarketProvider>().setPriceService(service);
    } catch (e) {
      AppLogger.warning('MarketPage: Failed to bind PriceService', error: e);
    }
  }

  void _initializeSwipeController() {
    // Avoid MediaQuery in initState (InheritedWidget not ready yet).
    // First build() recalculates includeAllIndices from width.
    _swipeController = SwipeNavigationController(
      items: _buildNavigationItems(
        context.read<MarketProvider>(),
        context.read<view_mode.ViewModeProvider>(),
        includeAllIndices: true,
      ),
    );

    _swipeController.addListener(() {
      if (!mounted) return;
      setState(() {});

      final currentTitle = _swipeController.currentItem.title;
      final provider = context.read<MarketProvider>();
      if (provider.selectedIndex != currentTitle) {
        provider.selectIndex(currentTitle);
      }
      _notifyTabChanged();
    });
  }

  @override
  void didUpdateWidget(MarketContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncTabFromUrl();
      });
    }
  }

  void _navigateToNext() {
    // Only navigate if not at the last item
    if (_swipeController.currentIndex < _swipeController.items.length - 1) {
      _swipeController.navigateTo(_swipeController.currentIndex + 1);
    }
  }

  void _navigateToPrev() {
    // Only navigate if not at the first item
    if (_swipeController.currentIndex > 0) {
      _swipeController.navigateTo(_swipeController.currentIndex - 1);
    }
  }

  Widget _wrapPage(Widget page) {
    return VerticalScrollNavigator(
      child: page,
      onNextPage: _navigateToNext,
      onPreviousPage: _navigateToPrev,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PriceService>>(priceServiceProvider, (previous, next) {
      next.whenData((service) {
        if (!context.mounted) return;
        context.read<MarketProvider>().setPriceService(service);
      });
    });

    return Consumer2<MarketProvider, view_mode.ViewModeProvider>(
    builder: (context, provider, viewModeProvider, _) {
      final isMobile = MediaQuery.sizeOf(context).width < 1100;
      // Update controller items when provider updates (e.g. indices loaded)
      final newItems = _buildNavigationItems(
        provider,
        viewModeProvider,
        includeAllIndices: isMobile,
      );
      if (_hasItemsChanged(newItems)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _swipeController.updateItems(newItems);
            _syncTabFromUrl(isMobile: isMobile);
          }
        });
      }

      return UnifiedSidebarScaffold(
        module: ModuleType.market,
        onBackToGlobal: widget.onBack,
        showModuleBottomNavigation: false,
        // Portfolio-style: pills at top, no Market Data title / grid AppBar.
        showAppBarOnMobile: false,
        // Keep pills always visible so users can switch sections without
        // relying on hidden scroll chrome.
        autoHideMobileTabsOnScroll: false,
        showMobileMenuButton: false,
        sections: _buildSidebarSections(
          provider,
          viewModeProvider,
          includeAllIndices: isMobile,
        ),
        body: SwipeablePageView(
          key: const PageStorageKey('market_page_info'),
          scrollDirection: Axis.vertical,
          controller: _swipeController,
          showIndicator: false,
        ),
      );
    },
    );
  }

  bool _hasItemsChanged(List<NavigationItem> newItems) {
    if (_swipeController.items.length != newItems.length) return true;
    // Simple check on titles or structure
    for (var i = 0; i < newItems.length; i++) {
      if (_swipeController.items[i].title != newItems[i].title) return true;
    }
    return false;
  }

  List<SecondarySidebarSection> _buildSidebarSections(
    MarketProvider provider,
    view_mode.ViewModeProvider viewModeProvider, {
    required bool includeAllIndices,
  }) {
    // If User mode, show simplified navigation
    if (viewModeProvider.isUserMode) {
      return _buildUserModeSections(
        provider,
        includeAllIndices: includeAllIndices,
      );
    }
    
    // Developer mode - show all sections (existing behavior)
    // Map controller items back to sections
    // Indices:
    // 0: All Indices
    // 1: Streamer
    // 2: Instrument Explorer
    // 3: Security Explorer
    // 4: ETF Explorer
    // 5: Price Test
    // 6: Market Analysis
    // 7..(7+N): Dynamic Indices
    // Last: Admin

    final accentColor = ModuleColors.market;
    final currentIndex = _swipeController.currentIndex;

    final mainItems = <SecondarySidebarItem>[
      if (includeAllIndices)
        _createSidebarItem(
          0,
          'All Indices',
          Icons.dashboard_rounded,
          'Market Overview',
        ),
      _createSidebarItem(
        includeAllIndices ? 1 : 0,
        'Streamer',
        Icons.waves_rounded,
        'Real-time data',
      ),
      _createSidebarItem(
        includeAllIndices ? 2 : 1,
        'Instrument Explorer',
        Icons.manage_search_rounded,
        'Search instruments',
      ),
      _createSidebarItem(
        includeAllIndices ? 3 : 2,
        'Security Explorer',
        Icons.security_rounded,
        'Security details',
      ),
      _createSidebarItem(
        includeAllIndices ? 4 : 3,
        'ETF Explorer',
        Icons.dashboard_customize_rounded,
        'ETF insights',
      ),
      _createSidebarItem(
        includeAllIndices ? 5 : 4,
        'Price Test',
        Icons.price_check_rounded,
        'Price validation',
      ),
      _createSidebarItem(
        includeAllIndices ? 6 : 5,
        'Market Analysis',
        Icons.analytics_rounded,
        'Detailed charts',
      ),
      _createSidebarItem(
        includeAllIndices ? 7 : 6,
        'Equity Insider',
        Icons.insights_rounded,
        'Fundamental analysis',
      ),
      if (widget.paperDesk != null)
        _createSidebarItem(
          includeAllIndices ? 8 : 7,
          'Paper',
          Icons.science_outlined,
          'Paper trading desk',
        ),
    ];

    // Dynamic Indices (shift when Paper tab / All Indices present)
    final paperOffset = widget.paperDesk != null ? 1 : 0;
    final allIndicesOffset = includeAllIndices ? 1 : 0;
    final dynamicIndicesCount =
        provider.availableIndices?.broad.take(5).length ?? 0;
    final indexItems = <SecondarySidebarItem>[];
    if (provider.availableIndices != null) {
      var baseIndex = 7 + allIndicesOffset + paperOffset;
      for (final indexName in provider.availableIndices!.broad.take(5)) {
        final i = baseIndex;
        indexItems.add(
          SecondarySidebarItem(
            title: indexName,
            icon: Icons.trending_up_rounded,
            subtitle: 'Live Index Data',
            isSelected: currentIndex == i,
            accentColor: accentColor,
            onTap: () {
              _swipeController.navigateTo(i);
              provider.selectIndex(
                indexName,
              ); // Keep provider in sync if needed
            },
          ),
        );
        baseIndex++;
      }
    }

    final adminIndex = 7 + allIndicesOffset + paperOffset + dynamicIndicesCount;
    final developerIndex = adminIndex + 1;

    final adminItem = SecondarySidebarItem(
      title: 'Admin Dashboard',
      icon: Icons.admin_panel_settings_rounded,
      isSelected: currentIndex == adminIndex,
      accentColor: const Color(0xFFFF6B6B),
      onTap: () {
        _swipeController.navigateTo(adminIndex.toInt());
        provider.selectIndex('Admin Dashboard');
      },
    );

    final developerItem = SecondarySidebarItem(
      title: 'Developer Dashboard',
      icon: Icons.developer_mode_rounded,
      isSelected: currentIndex == developerIndex,
      accentColor: Colors.deepPurple,
      onTap: () {
        _swipeController.navigateTo(developerIndex.toInt());
        provider.selectIndex('Developer Dashboard');
      },
    );

    // Add mode toggle as first section (admin only)
    final sections = <SecondarySidebarSection>[
      if (widget.isAdmin)
        SecondarySidebarSection(
          title: '',
          items: const [],
          customWidget: const ModeToggleWidget(),
        ),
      SecondarySidebarSection(title: 'Data', items: mainItems),
      if (indexItems.isNotEmpty)
        SecondarySidebarSection(title: 'Major Indices', items: indexItems),
      SecondarySidebarSection(title: 'System Tools', items: [adminItem, developerItem]),
    ];

    return sections;
  }

  // User Mode - All Indices first on mobile only; web starts at Paper/Dashboard
  List<SecondarySidebarSection> _buildUserModeSections(
    MarketProvider provider, {
    required bool includeAllIndices,
  }) {
    final hasPaper = widget.paperDesk != null;
    var i = 0;
    final userItems = <SecondarySidebarItem>[
      if (includeAllIndices)
        _createSidebarItem(
          i++,
          'All Indices',
          Icons.grid_view_rounded,
          'Market Overview',
        ),
      if (hasPaper)
        _createSidebarItem(i++, 'Paper', Icons.science_outlined, 'Paper trading desk'),
      _createSidebarItem(i++, 'Dashboard', Icons.home_rounded, 'Overview'),
      _createSidebarItem(i++, 'Market Analysis', Icons.analytics_rounded, 'Detailed charts'),
      _createSidebarItem(i++, 'Equity Insider', Icons.insights_rounded, 'Fundamental analysis'),
      _createSidebarItem(i++, 'Watch List', Icons.star_border_rounded, 'Custom tracking'),
    ];

    return [
      if (widget.isAdmin)
        SecondarySidebarSection(
          title: '',
          items: const [],
          customWidget: const ModeToggleWidget(),
        ),
      SecondarySidebarSection(title: 'Navigation', items: userItems),
    ];
  }

  SecondarySidebarItem _createSidebarItem(
    int index,
    String title,
    IconData icon,
    String subtitle,
  ) => SecondarySidebarItem(
    title: title,
    icon: icon,
    subtitle: subtitle,
    isSelected: _swipeController.currentIndex == index,
    accentColor: ModuleColors.market,
    onTap: () {
      if (title == 'Equity Insider') {
        _equityInsiderKey.currentState?.resetToLanding();
      }
      _swipeController.navigateTo(index);
      context.read<MarketProvider>().selectIndex(title);
      widget.onTabChanged?.call(_slugForTitle(title));
    },
  );

  List<NavigationItem> _buildNavigationItems(
    MarketProvider provider,
    view_mode.ViewModeProvider viewModeProvider, {
    required bool includeAllIndices,
  }) {
    // If User mode, show only 3 pages: Dashboard, Market Analysis, Heatmap
    if (viewModeProvider.isUserMode) {
      return _buildUserModeNavigationItems(
        provider,
        includeAllIndices: includeAllIndices,
      );
    }
    
    // Developer mode - show all items
    final accentColor = ModuleColors.market;

    final items = <NavigationItem>[
      if (includeAllIndices)
        NavigationItem(
          title: 'All Indices',
          subtitle: 'Market Overview',
          icon: Icons.dashboard_rounded,
          page: _wrapPage(const AllIndicesPage()),
          accentColor: accentColor,
        ),
      NavigationItem(
        title: 'Streamer',
        subtitle: 'Real-time data',
        icon: Icons.waves_rounded,
        page: _wrapPage(const StreamerPage()),
        accentColor: accentColor,
      ),
      NavigationItem(
        title: 'Instrument Explorer',
        subtitle: 'Search instruments',
        icon: Icons.manage_search_rounded,
        page: _wrapPage(const InstrumentExplorerPage()),
        accentColor: accentColor,
      ),
      NavigationItem(
        title: 'Security Explorer',
        subtitle: 'Security details',
        icon: Icons.security_rounded,
        page: _wrapPage(const SecurityExplorerPage()),
        accentColor: accentColor,
      ),
      NavigationItem(
        title: 'ETF Explorer',
        subtitle: 'ETF insights',
        icon: Icons.dashboard_customize_rounded,
        page: _wrapPage(const EtfExplorerPage()),
        accentColor: accentColor,
      ),
      NavigationItem(
        title: 'Price Test',
        subtitle: 'Price validation',
        icon: Icons.price_check_rounded,
        page: _wrapPage(const PriceTestPage()),
        accentColor: accentColor,
      ),
      NavigationItem(
        title: 'Market Analysis',
        subtitle: 'Detailed charts',
        icon: Icons.analytics_rounded,
        page: _wrapPage(const HeatmapExplorerView()),
        accentColor: accentColor,
      ),
      NavigationItem(
        title: 'Equity Insider',
        subtitle: 'Fundamental analysis',
        icon: Icons.insights_rounded,
        page: _wrapPage(EquityInsiderPage(key: _equityInsiderKey)),
        accentColor: accentColor,
      ),
    ];

    final paperDesk = widget.paperDesk;
    if (paperDesk != null) {
      items.add(
        NavigationItem(
          title: 'Paper',
          subtitle: 'Paper trading desk',
          icon: Icons.science_outlined,
          page: paperDesk,
          accentColor: accentColor,
        ),
      );
    }

    // Dynamic Indices
    if (provider.availableIndices != null) {
      for (final indexName in provider.availableIndices!.broad.take(5)) {
        items.add(
          NavigationItem(
            title: indexName,
            subtitle: 'Live Index Data',
            icon: Icons.trending_up_rounded,
            page: _wrapPage(MarketIndexDetailView(
              provider: provider,
              indexSymbol: indexName,
            )),
            accentColor: accentColor,
          ),
        );
      }
    }

    // Admin
    items.add(
      NavigationItem(
        title: 'Admin Dashboard',
        subtitle: 'System Tools',
        icon: Icons.admin_panel_settings_rounded,
        page: _wrapPage(const AdminDashboardPage()),
        accentColor: Color(0xFFFF6B6B),
      ),
    );

    items.add(
      NavigationItem(
        title: 'Developer Dashboard',
        subtitle: 'Dev Tools & Scheduler',
        icon: Icons.developer_mode_rounded,
        page: _wrapPage(const DeveloperDashboard()),
        accentColor: Colors.deepPurple,
      ),
    );

    return items;
  }

  List<NavigationItem> _buildUserModeNavigationItems(
    MarketProvider provider, {
    required bool includeAllIndices,
  }) {
    final accentColor = ModuleColors.market;
    final paperDesk = widget.paperDesk;

    return [
      if (includeAllIndices)
        NavigationItem(
          title: 'All Indices',
          subtitle: 'Market Overview',
          icon: Icons.grid_view_rounded,
          page: _wrapPage(const AllIndicesPage()),
          accentColor: accentColor,
        ),
      if (paperDesk != null)
        NavigationItem(
          title: 'Paper',
          subtitle: 'Paper trading desk',
          icon: Icons.science_outlined,
          // Do not wrap — desk owns its scroll/layout.
          page: paperDesk,
          accentColor: accentColor,
        ),
      NavigationItem(
        title: 'Dashboard',
        subtitle: 'Overview',
        icon: Icons.home_rounded,
        page: _wrapPage(UserDashboardPage(key: _dashboardKey)),
        accentColor: accentColor,
      ),
      NavigationItem(
        title: 'Market Analysis',
        subtitle: 'Heatmap & Details',
        icon: Icons.analytics_rounded,
        page: _wrapPage(const HeatmapExplorerView()),
        accentColor: accentColor,
      ),
      NavigationItem(
        title: 'Equity Insider',
        subtitle: 'Fundamental analysis',
        icon: Icons.insights_rounded,
        page: _wrapPage(EquityInsiderPage(key: _equityInsiderKey)),
        accentColor: accentColor,
      ),
      NavigationItem(
        title: 'Watch List',
        subtitle: 'Custom tracking',
        icon: Icons.star_border_rounded,
        page: _wrapPage(WatchlistsPage(
          onStockSelected: (symbol) {
            final items = _swipeController.items;
            final index = _indexForSlug('equity-insider', items);
            _swipeController.navigateTo(index);
            // Delay slightly to ensure page is built if it was not in view
            Future.delayed(const Duration(milliseconds: 100), () {
              _equityInsiderKey.currentState?.navigateToSymbol(symbol);
            });
          },
        )),
        accentColor: accentColor,
      ),
    ];
  }
}
