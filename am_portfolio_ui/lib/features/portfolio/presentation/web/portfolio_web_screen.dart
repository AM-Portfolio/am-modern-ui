import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_common/am_common.dart';

import '../../internal/domain/entities/portfolio_list.dart';
import '../../providers/portfolio_providers.dart';
import '../cubit/portfolio_cubit.dart';

import 'package:am_design_system/am_design_system.dart';
import 'pages/portfolio_overview_web_page.dart';
import 'pages/portfolio_holdings_web_page.dart';
import 'pages/portfolio_heatmap_web_page.dart';
import 'pages/portfolio_baskets_web_page.dart';
import 'package:am_user_ui/am_user_ui.dart';

/// Web-specific portfolio screen implementation
class PortfolioWebScreen extends ConsumerStatefulWidget {
  const PortfolioWebScreen({
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.portfolios,
    this.initialTab = 'overview',
    this.onTabChanged,
    this.onPortfolioChanged,
    this.isSidebarVisible = true,
    this.onToggleSidebar,
    this.onBack,
    this.addTradeBuilder,
  });
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final List<PortfolioItem>? portfolios;
  final String initialTab;
  final ValueChanged<String>? onTabChanged;
  final Function(String portfolioId, String portfolioName)? onPortfolioChanged;
  final bool isSidebarVisible;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onBack;
  final Widget Function(BuildContext context, String portfolioId, String? portfolioName, VoidCallback onComplete)? addTradeBuilder;

  @override
  ConsumerState<PortfolioWebScreen> createState() => _PortfolioWebScreenState();
}

class _PortfolioWebScreenState extends ConsumerState<PortfolioWebScreen> {
  static const _tabSlugs = [
    'overview',
    'holdings',
    'heatmap',
    'baskets',
  ];

  SwipeNavigationController? _swipeController;
  String? _currentPortfolioId;
  String? _currentPortfolioName;
  bool _isAddingTrade = false;

  @override
  void initState() {
    super.initState();
    _syncPortfolioSelection();
    _initializeSwipeController();
  }

  @override
  void dispose() {
    _swipeController?.removeListener(_onSwipeControllerChanged);
    _swipeController?.dispose();
    super.dispose();
  }

  void _syncPortfolioSelection() {
    _currentPortfolioId = widget.selectedPortfolioId ??
        widget.portfolios?.firstOrNull?.portfolioId;
    _currentPortfolioName = widget.selectedPortfolioName ??
        widget.portfolios?.firstOrNull?.portfolioName;
  }

  @override
  void didUpdateWidget(PortfolioWebScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPortfolioId != oldWidget.selectedPortfolioId ||
        widget.selectedPortfolioName != oldWidget.selectedPortfolioName ||
        widget.portfolios != oldWidget.portfolios) {
      _syncPortfolioSelection();
      _swipeController?.updateItems(_buildNavigationItems());
    } else if (widget.initialTab != oldWidget.initialTab) {
      _navigateToTabSlug(widget.initialTab, notify: false);
    }
  }

  int _tabIndexFromSlug(String slug) {
    final index = _tabSlugs.indexOf(slug);
    return index >= 0 ? index : 0;
  }

  String _slugFromIndex(int index) =>
      _tabSlugs[index.clamp(0, _tabSlugs.length - 1)];

  void _navigateToTabSlug(String slug, {bool notify = true}) {
    final index = _tabIndexFromSlug(slug);
    _swipeController?.navigateTo(index);
    if (notify) widget.onTabChanged?.call(_slugFromIndex(index));
  }

  String? get _resolvedPortfolioId {
    if (_currentPortfolioId != null) return _currentPortfolioId;
    if (widget.selectedPortfolioId != null) return widget.selectedPortfolioId;
    final portfolios = widget.portfolios;
    if (portfolios != null && portfolios.isNotEmpty) {
      return portfolios.first.portfolioId;
    }
    return null;
  }

  void _initializeSwipeController() {
    final items = _buildNavigationItems();
    final initialIndex = _tabIndexFromSlug(widget.initialTab);
    if (_swipeController == null) {
      _swipeController = SwipeNavigationController(
        items: items,
        initialIndex: initialIndex,
      );
      _swipeController!.addListener(_onSwipeControllerChanged);
    } else {
      _swipeController!.updateItems(items);
      _swipeController!.navigateTo(initialIndex);
    }
  }

  void _onSwipeControllerChanged() {
    if (mounted) {
      setState(() {});
      final index = _swipeController?.currentIndex;
      if (index != null) {
        widget.onTabChanged?.call(_slugFromIndex(index));
      }
    }
  }

  List<NavigationItem> _buildNavigationItems() {
    final portfolioId = _resolvedPortfolioId;
    if (portfolioId == null) {
      return [
        NavigationItem(
          title: 'Overview',
          subtitle: 'Dashboard',
          icon: Icons.dashboard_outlined,
          accentColor: Colors.blue,
          page: _wrapPage(
            const Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    return [
      NavigationItem(
        title: 'Overview',
        subtitle: 'Dashboard',
        icon: Icons.dashboard_outlined,
        accentColor: Colors.blue,
        page: _wrapPage(
          PortfolioOverviewWebPage(
            portfolioId: portfolioId,
            portfolioName: _currentPortfolioName ?? widget.selectedPortfolioName,
          ),
        ),
      ),
      NavigationItem(
        title: 'Holdings',
        subtitle: 'Assets',
        icon: Icons.account_balance_wallet_outlined,
        accentColor: Colors.green,
        page: _wrapPage(
          PortfolioHoldingsWebPage(
            portfolioId: portfolioId,
          ),
        ),
      ),
      NavigationItem(
        title: 'Heatmap',
        subtitle: 'Performance',
        icon: Icons.grid_view_outlined,
        accentColor: Colors.orange,
        page: _wrapPage(
          PortfolioHeatmapWebPage(
            portfolioId: portfolioId,
            portfolioName: _currentPortfolioName ?? widget.selectedPortfolioName,
          ),
        ),
      ),
      NavigationItem(
        title: 'Baskets',
        subtitle: 'Basket replication',
        icon: Icons.shopping_basket_outlined,
        accentColor: Colors.teal,
        page: _wrapPage(
          PortfolioBasketsWebPage(
            portfolioId: portfolioId,
          ),
        ),
      ),
    ];
  }

  void _navigateToNext() {
    // Only navigate if not at the last item
    if (_swipeController != null && _swipeController!.currentIndex < _swipeController!.items.length - 1) {
      _swipeController!.navigateTo(_swipeController!.currentIndex + 1);
    }
  }

  void _navigateToPrev() {
    // Only navigate if not at the first item
    if (_swipeController != null && _swipeController!.currentIndex > 0) {
      _swipeController!.navigateTo(_swipeController!.currentIndex - 1);
    }
  }

  Widget _wrapPage(Widget page) {
    return VerticalScrollNavigator(
      child: page,
      onNextPage: _navigateToNext,
      onPreviousPage: _navigateToPrev,
    );
  }

  void _onPortfolioChanged(String portfolioId, String portfolioName) {
    setState(() {
      _currentPortfolioId = portfolioId;
      _currentPortfolioName = portfolioName;
      _initializeSwipeController();
    });

    try {
      // Use the global wrapper extension to sync URL if it exists
      context.selectPortfolio(portfolioId, portfolioName);
    } catch (_) {
      // Fallback if not inside the wrapper
      context.read<PortfolioCubit>().loadPortfolioById(portfolioId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OpenAddTradeNotification>(
      onNotification: (notification) {
        if (widget.addTradeBuilder != null) {
          setState(() {
            _isAddingTrade = true;
          });
          notification.handled = true;
          return true;
        }
        return false;
      },
      child: UnifiedSidebarScaffold(
      module: ModuleType.portfolio,
      title: null,
      subtitle: null,
      showModuleBottomNavigation: false,
      headerActions: const [ShareLinkButton()],
      header: const SizedBox(height: 16),
      onBackToGlobal: widget.onBack,
      onThemeToggle: () {
        context.read<ThemeCubit>().toggleTheme();
      },
      onProfileTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              final authState = context.read<AuthCubit>().state;
              if (authState is Authenticated) {
                return ProfileSettingsPage(
                  userId: authState.user.id,
                  email: authState.user.email,
                  displayName: authState.user.displayName,
                );
              }
              return const ProfileSettingsPage(userId: '');
            },
          ),
        );
      },
      onLogout: () {
        context.read<AuthCubit>().logout();
        widget.onBack?.call();
      },
      body: (_isAddingTrade && widget.addTradeBuilder != null && _currentPortfolioId != null)
          ? widget.addTradeBuilder!(
              context,
              _currentPortfolioId!,
              _currentPortfolioName ?? widget.selectedPortfolioName,
              () {
                setState(() {
                  _isAddingTrade = false;
                });
              }
            )
          : (_swipeController == null 
              ? const Center(child: CircularProgressIndicator())
              : SwipeablePageView(
                  controller: _swipeController!,
                  showIndicator: true,
                  indicatorPosition: IndicatorPosition.bottom,
                )),
      footer: (_currentPortfolioId == null || _currentPortfolioId == 'all')
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SidebarPrimaryAction(
                title: 'New Trade',
                icon: Icons.add,
                accentColor: ModuleColors.portfolio,

                onTap: () {
                  if (widget.addTradeBuilder != null) {
                    setState(() {
                      _isAddingTrade = true;
                    });
                  }
                },
              ),
            ),
      sections: [
        if (widget.portfolios != null && widget.portfolios!.isNotEmpty)
          SecondarySidebarSection(
            title: '', // No title as requested ("Institute of account") style
            customWidget: SharedPortfolioSelector<PortfolioItem>(
              currentPortfolioId: _currentPortfolioId,
              currentPortfolioName:
                  _currentPortfolioName ?? widget.selectedPortfolioName,
              portfolios: [
                const PortfolioItem(
                  portfolioId: 'all',
                  portfolioName: 'All Portfolios',
                ),
                ...widget.portfolios!,
              ],
              onPortfolioSelected: _onPortfolioChanged,
              idExtractor: (p) => p.portfolioId,
              nameExtractor: (p) => p.portfolioName,
              accentColor: ModuleColors.portfolio,
            ),
          ),

        // Navigation Section (No Title)
        SecondarySidebarSection(
          title: '',
          items: _swipeController == null ? [] : _swipeController!.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return SecondarySidebarItem(
              title: item.title,
              icon: item.icon,
              isSelected: _swipeController!.currentIndex == index,
              onTap: () => _navigateToTabSlug(_slugFromIndex(index)),
              accentColor: item.accentColor,
            );
          }).toList(),
        ),
      ],
      ),
    );
  }
}
