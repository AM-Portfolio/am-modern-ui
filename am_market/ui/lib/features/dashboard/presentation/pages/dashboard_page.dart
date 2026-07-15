import 'package:am_market_ui/core/providers/view_mode_provider.dart' as view_mode;
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_market_ui/features/market_analysis/presentation/pages/analysis_page.dart';
import 'package:am_market_common/providers/market_provider.dart';


import 'package:am_market_ui/features/etf/etf_explorer_page.dart';
import 'package:am_market_ui/features/instrument/instrument_explorer_page.dart';

import 'package:am_market_ui/features/security/security_explorer_page.dart';
import 'package:am_market_dev/am_market_dev.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/indices_performance_view_v2.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:am_common/core/di/price_providers.dart';
import 'package:am_common/core/services/price_service.dart';

import 'package:am_market_ui/features/market_analysis/presentation/widgets/market_index_detail_view.dart';

import 'package:am_market_ui/core/providers/view_mode_provider.dart';
import 'package:am_market_ui/shared/widgets/mode_toggle_widget.dart';
import 'user_dashboard_page.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/heatmap_explorer_view.dart';
import 'package:am_market_ui/features/market/widgets/market_header.dart';
import 'package:am_common/am_common.dart';

/// Market feature page with Swipe Navigation
class MarketPage extends StatelessWidget {
  const MarketPage({
    required this.userId,
    super.key,
    this.initialTab = 'all-indices',
    this.onTabChanged,
    this.onBack,
  });

  final String userId;
  final String initialTab;
  final ValueChanged<String>? onTabChanged;
  final VoidCallback? onBack;

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
  });

  final String userId;
  final String initialTab;
  final bool isAdmin;
  final ValueChanged<String>? onTabChanged;
  final VoidCallback? onBack;

  @override
  ConsumerState<MarketContent> createState() => _MarketContentState();
}

class _MarketContentState extends ConsumerState<MarketContent> {
  late SwipeNavigationController _swipeController;
  final GlobalKey<UserDashboardPageState> _dashboardKey =
      GlobalKey<UserDashboardPageState>();

  static const _staticTitleToSlug = {
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

  void _syncTabFromUrl({bool notify = false}) {
    final items = _swipeController.items;
    if (items.isEmpty) return;
    final index = _indexForSlug(widget.initialTab, items);
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
    _swipeController = SwipeNavigationController(
      items: _buildNavigationItems(
        context.read<MarketProvider>(),
        context.read<view_mode.ViewModeProvider>(),
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
      // Update controller items when provider updates (e.g. indices loaded)
      final newItems = _buildNavigationItems(provider, viewModeProvider);
      if (_hasItemsChanged(newItems)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _swipeController.updateItems(newItems);
            _syncTabFromUrl();
          }
        });
      }

      final isMobile = MediaQuery.sizeOf(context).width < 900;

      void openAllIndices() {
        final dash = _dashboardKey.currentState;
        if (dash != null) {
          dash.openAllIndicesPanel();
          return;
        }
        if (_swipeController.currentIndex != 0) {
          _swipeController.navigateTo(0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _dashboardKey.currentState?.openAllIndicesPanel();
          });
        }
      }

      return UnifiedSidebarScaffold(
        module: ModuleType.market,
        onBackToGlobal: widget.onBack,
        showModuleBottomNavigation: false,
        // Keep Dashboard / Market Analysis pills always visible so users can
        // switch back from Analysis without relying on hidden scroll chrome.
        autoHideMobileTabsOnScroll: false,
        showMobileMenuButton: false,
        // Compact grid icon left of "Market Data".
        mobileLeading: isMobile
            ? Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Center(
                  child: AllIndicesChip(
                    iconOnly: true,
                    onPressed: openAllIndices,
                  ),
                ),
              )
            : null,
        mobileLeadingWidth: isMobile ? 44 : null,
        headerActions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: GlobalTimeFrameBar(
              variant: GlobalTimeFrameVariant.dropdown,
              dropdownWidth: 72,
            ),
          ),
        ],
        // Dashboard / Market Analysis pills for switching sections.
        sections: _buildSidebarSections(provider, viewModeProvider),
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
    view_mode.ViewModeProvider viewModeProvider,
  ) {
    // If User mode, show simplified navigation
    if (viewModeProvider.isUserMode) {
      return _buildUserModeSections(provider);
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

    const accentColor = ModuleColors.market;
    final currentIndex = _swipeController.currentIndex;

    final mainItems = [
      _createSidebarItem(
        0,
        'All Indices',
        Icons.dashboard_rounded,
        'Market Overview',
      ),
      _createSidebarItem(1, 'Streamer', Icons.waves_rounded, 'Real-time data'),
      _createSidebarItem(
        2,
        'Instrument Explorer',
        Icons.manage_search_rounded,
        'Search instruments',
      ),
      _createSidebarItem(
        3,
        'Security Explorer',
        Icons.security_rounded,
        'Security details',
      ),
      _createSidebarItem(
        4,
        'ETF Explorer',
        Icons.dashboard_customize_rounded,
        'ETF insights',
      ),
      _createSidebarItem(
        5,
        'Price Test',
        Icons.price_check_rounded,
        'Price validation',
      ),
      _createSidebarItem(
        6,
        'Market Analysis',
        Icons.analytics_rounded,
        'Detailed charts',
      ),
    ];

    // Dynamic Indices
    final dynamicIndicesCount =
        provider.availableIndices?.broad.take(5).length ?? 0;
    final indexItems = <SecondarySidebarItem>[];
    if (provider.availableIndices != null) {
      var baseIndex = 7;
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

    final adminIndex = 7 + dynamicIndicesCount;
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

  // User Mode - Simplified Navigation (Dashboard, Overview, Heatmap)
  List<SecondarySidebarSection> _buildUserModeSections(MarketProvider provider) {
    const accentColor = ModuleColors.market;
    final currentIndex = _swipeController.currentIndex;

    final userItems = [
      _createSidebarItem(0, 'Dashboard', Icons.home_rounded, 'Overview'),
      _createSidebarItem(1, 'Market Analysis', Icons.analytics_rounded, 'Detailed charts'),
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
      _swipeController.navigateTo(index);
      context.read<MarketProvider>().selectIndex(title);
      widget.onTabChanged?.call(_slugForTitle(title));
    },
  );

  List<NavigationItem> _buildNavigationItems(
    MarketProvider provider,
    view_mode.ViewModeProvider viewModeProvider,
  ) {
    // If User mode, show only 3 pages: Dashboard, Market Analysis, Heatmap
    if (viewModeProvider.isUserMode) {
      return _buildUserModeNavigationItems(provider);
    }
    
    // Developer mode - show all items
    const accentColor = ModuleColors.market;

    final items = [
      NavigationItem(
        title: 'All Indices',
        subtitle: 'Market Overview',
        icon: Icons.dashboard_rounded,
        page: _wrapPage(const IndicesPerformanceViewV2()),
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
    ];

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

  List<NavigationItem> _buildUserModeNavigationItems(MarketProvider provider) {
    const accentColor = ModuleColors.market;

    return [
      NavigationItem(
        title: 'Dashboard',
        subtitle: 'Overview',
        icon: Icons.home_rounded,
        page: _wrapPage(UserDashboardPage(key: _dashboardKey)), // User Dashboard with cards + chart
        accentColor: accentColor,
      ),
      NavigationItem(
        title: 'Market Analysis',
        subtitle: 'Heatmap & Details',
        icon: Icons.analytics_rounded,
        page: _wrapPage(const HeatmapExplorerView()), // Was AnalysisPage(), now consolidated
        accentColor: accentColor,
      ),
      // Heatmap Explorer removed as it's now Market Analysis
    ];
  }
}


