import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_common/am_common.dart';

import '../../internal/domain/entities/portfolio_list.dart';
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

  String? _currentPortfolioId;
  String? _currentPortfolioName;
  bool _isAddingTrade = false;

  @override
  void initState() {
    super.initState();
    _syncPortfolioSelection();
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
    }
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

  int get _currentIndex {
    final index = _tabSlugs.indexOf(widget.initialTab);
    return index >= 0 ? index : 0;
  }

  void _navigateToTabSlug(String slug) {
    widget.onTabChanged?.call(slug);
  }

  void _onPortfolioChanged(String portfolioId, String portfolioName) {
    setState(() {
      _currentPortfolioId = portfolioId;
      _currentPortfolioName = portfolioName;
    });

    try {
      // Use the global wrapper extension to sync URL if it exists
      context.selectPortfolio(portfolioId, portfolioName);
    } catch (_) {
      // Fallback if not inside the wrapper
      context.read<PortfolioCubit>().loadPortfolioById(portfolioId);
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
          accentColor: ModuleColors.portfolio,
          page: const Center(
            child: Text(
              'No portfolios found. Please create a new portfolio.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      ];
    }

    return [
      NavigationItem(
        title: 'Overview',
        subtitle: 'Dashboard',
        icon: Icons.dashboard_outlined,
        accentColor: ModuleColors.portfolio,
        page: PortfolioOverviewWebPage(
          portfolioId: portfolioId,
          portfolioName: _currentPortfolioName ?? widget.selectedPortfolioName,
        ),
      ),
      NavigationItem(
        title: 'Holdings',
        subtitle: 'Assets',
        icon: Icons.account_balance_wallet_outlined,
        accentColor: ModuleColors.portfolio,
        page: PortfolioHoldingsWebPage(
          portfolioId: portfolioId,
        ),
      ),
      NavigationItem(
        title: 'Heatmap',
        subtitle: 'Performance',
        icon: Icons.grid_view_outlined,
        accentColor: ModuleColors.portfolio,
        page: PortfolioHeatmapWebPage(
          portfolioId: portfolioId,
          portfolioName: _currentPortfolioName ?? widget.selectedPortfolioName,
        ),
      ),
      NavigationItem(
        title: 'Baskets',
        subtitle: 'Basket replication',
        icon: Icons.shopping_basket_outlined,
        accentColor: ModuleColors.portfolio,
        page: PortfolioBasketsWebPage(
          portfolioId: portfolioId,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildNavigationItems();
    final currentIndex = _currentIndex;
    final activePage = currentIndex < items.length ? items[currentIndex].page : items.first.page;

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
        headerActions: const [],
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentIndex == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final selected = ref.watch(appTimeFrameProvider);
                        final screenWidth = MediaQuery.of(context).size.width;
                        
                        // Limit width to 40% of screen on large screens, up to a max of 400 pixels
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth > 800 ? 400 : screenWidth * 0.45,
                          ),
                          child: TimeFrameSelector(
                            compact: true,
                            selectedTimeFrame: selected,
                            onTimeFrameChanged: (tf) => ref.read(appTimeFrameProvider.notifier).setTimeFrame(tf),
                            availableTimeFrames: const [
                              TimeFrame.oneDay,
                              TimeFrame.oneWeek,
                              TimeFrame.oneMonth,
                              TimeFrame.threeMonths,
                              TimeFrame.sixMonths,
                              TimeFrame.oneYear,
                              TimeFrame.fiveYears,
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: (_isAddingTrade && widget.addTradeBuilder != null && _currentPortfolioId != null)
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
                  : activePage,
            ),
          ],
        ),
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
          SecondarySidebarSection(
            title: '',
            items: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return SecondarySidebarItem(
                title: item.title,
                icon: item.icon,
                isSelected: currentIndex == index,
                onTap: () => _navigateToTabSlug(_tabSlugs[index]),
                accentColor: item.accentColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
