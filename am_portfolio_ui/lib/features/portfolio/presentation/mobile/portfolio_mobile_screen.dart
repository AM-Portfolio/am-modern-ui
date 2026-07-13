import 'dart:async';
import 'dart:ui';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../cubit/portfolio_analytics_cubit.dart';
import '../../providers/portfolio_providers.dart';
import '../../internal/domain/entities/portfolio_list.dart';
import 'widgets/portfolio_header_widget.dart';
import 'widgets/portfolio_tab_content_widget.dart';
import 'widgets/portfolio_logout_handler.dart';
import 'package:am_common/am_common.dart';

/// Mobile-optimized portfolio screen with bottom navigation and portfolio selection
class PortfolioMobileScreen extends ConsumerStatefulWidget {
  const PortfolioMobileScreen({
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.portfolios,
    this.onPortfolioChanged,
    this.onBack,
    this.initialTab,
    this.onTabChanged,
    this.addTradeBuilder,
  });
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final List<PortfolioItem>? portfolios;
  final Function(String portfolioId, String portfolioName)? onPortfolioChanged;
  final VoidCallback? onBack;
  final String? initialTab;
  final ValueChanged<String>? onTabChanged;
  final Widget Function(BuildContext context, String portfolioId, String? portfolioName, VoidCallback onComplete)? addTradeBuilder;

  @override
  ConsumerState<PortfolioMobileScreen> createState() => _PortfolioMobileScreenState();
}

class _PortfolioMobileScreenState extends ConsumerState<PortfolioMobileScreen> {
  @override
  Widget build(BuildContext context) {
    CommonLogger.info(
      'Building PortfolioMobileScreen',
      tag: 'PortfolioMobileScreen',
    );
    CommonLogger.userAction(
      'Navigate to Mobile Portfolio',
      tag: 'PortfolioMobileScreen',
    );

    // Watch the portfolio service provider
    final portfolioServiceAsync = ref.watch(portfolioServiceProvider);

    return portfolioServiceAsync.when(
      data: (portfolioService) {
        CommonLogger.debug(
          'Portfolio service loaded, creating mobile cubit',
          tag: 'PortfolioMobileScreen',
        );
        // Watch analytics service as well
        final analyticsServiceAsync = ref.watch(
          portfolioAnalyticsServiceProvider,
        );

        return analyticsServiceAsync.when(
          data: (analyticsService) => BlocProvider(
            create: (context) => PortfolioAnalyticsCubit(analyticsService),
            child: PortfolioMobileView(
              selectedPortfolioId: widget.selectedPortfolioId,
              selectedPortfolioName: widget.selectedPortfolioName,
              portfolios: widget.portfolios,
              onPortfolioChanged: widget.onPortfolioChanged,
              onBack: widget.onBack,
              initialTab: widget.initialTab,
              onTabChanged: widget.onTabChanged,
              addTradeBuilder: widget.addTradeBuilder,
            ),
          ),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) {
            CommonLogger.error(
              'Failed to load analytics service',
              tag: 'PortfolioMobileScreen',
              error: error,
            );
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Failed to load analytics: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(portfolioAnalyticsServiceProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () {
        CommonLogger.debug(
          'Portfolio service loading',
          tag: 'PortfolioMobileScreen',
        );
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stack) {
        CommonLogger.error(
          'Failed to load portfolio service',
          tag: 'PortfolioMobileScreen',
          error: error,
        );
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load portfolio: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(portfolioServiceProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Internal mobile portfolio view with tab-based navigation and portfolio selection
class PortfolioMobileView extends StatefulWidget {
  const PortfolioMobileView({
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.portfolios,
    this.onPortfolioChanged,
    this.onBack,
    this.initialTab,
    this.onTabChanged,
    this.addTradeBuilder,
  });
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final List<PortfolioItem>? portfolios;
  final Function(String portfolioId, String portfolioName)? onPortfolioChanged;
  final VoidCallback? onBack;
  final String? initialTab;
  final ValueChanged<String>? onTabChanged;
  final Widget Function(BuildContext context, String portfolioId, String? portfolioName, VoidCallback onComplete)? addTradeBuilder;

  @override
  State<PortfolioMobileView> createState() => _PortfolioMobileViewState();
}

class _PortfolioMobileViewState extends State<PortfolioMobileView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _currentPortfolioId;
  bool _isAddingTrade = false;
  bool _showScrollFab = false;
  Timer? _scrollHideTimer;

  int _tabIndexFromSlug(String? slug) {
    switch (slug?.toLowerCase()) {
      case 'overview':
        return 0;
      case 'holdings':
        return 1;
      case 'heatmap':
        return 2;
      case 'baskets':
        return 3;
      default:
        return 0;
    }
  }

  String _tabSlugFromIndex(int index) {
    switch (index) {
      case 0:
        return 'overview';
      case 1:
        return 'holdings';
      case 2:
        return 'heatmap';
      case 3:
        return 'baskets';
      default:
        return 'overview';
    }
  }

  @override
  void initState() {
    super.initState();
    final initialIndex = _tabIndexFromSlug(widget.initialTab);
    _tabController = TabController(length: 4, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {});
        widget.onTabChanged?.call(_tabSlugFromIndex(_tabController.index));
      }
    });
    _currentPortfolioId = widget.selectedPortfolioId;

    // Load portfolio data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentPortfolioId != null && mounted) {
        final cubit = context.read<PortfolioCubit>();
        cubit.subscribeToPortfolioUpdates(
          portfolioId: _currentPortfolioId,
          forceResubscribe: true,
        );

        final currentState = cubit.state;

        if (currentState is PortfolioLoaded &&
            currentState.portfolioId == _currentPortfolioId) {
          // Data is already loaded for this portfolio, skip reloading
          return;
        }

        cubit.loadPortfolioById(_currentPortfolioId!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant PortfolioMobileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPortfolioId != null &&
        widget.selectedPortfolioId != _currentPortfolioId) {
      setState(() => _currentPortfolioId = widget.selectedPortfolioId);
      context.read<PortfolioCubit>()
        ..subscribeToPortfolioUpdates(
          portfolioId: widget.selectedPortfolioId,
          forceResubscribe: true,
        )
        ..loadPortfolioById(widget.selectedPortfolioId!);
    }

    if (widget.initialTab != oldWidget.initialTab) {
      final newIndex = _tabIndexFromSlug(widget.initialTab);
      if (newIndex != _tabController.index) {
        _tabController.animateTo(newIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollHideTimer?.cancel();
    super.dispose();
  }

  /// Handles portfolio selection change
  void _onPortfolioChanged(String portfolioId, String portfolioName) {
    setState(() {
      _currentPortfolioId = portfolioId;
    });

    // Load new portfolio data
    context.read<PortfolioCubit>().loadPortfolioById(portfolioId);

    // Notify parent if callback is provided
    widget.onPortfolioChanged?.call(portfolioId, portfolioName);
  }

  void _onScrollDetected() {
    _scrollHideTimer?.cancel();
    if (!_showScrollFab) setState(() => _showScrollFab = true);
    _scrollHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showScrollFab = false);
    });
  }

  Widget _buildGlassFab() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: GestureDetector(
          onTap: () => setState(() => _isAddingTrade = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: ModuleColors.portfolio.withOpacity(0.25),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: ModuleColors.portfolio.withOpacity(0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Add Trade',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CommonLogger.debug(
      'Building PortfolioMobileView - portfolioId: $_currentPortfolioId',
      tag: 'PortfolioMobileView',
    );

    if (_currentPortfolioId == null) {
      return const Scaffold(
        body: Center(child: Text('Select a portfolio to continue')),
      );
    }

    String currentName = 'Select Portfolio';
    if (_currentPortfolioId == 'all') {
      currentName = 'All Portfolios';
    } else if (_currentPortfolioId != null && widget.portfolios != null) {
      final match = widget.portfolios!.where(
        (p) => p.portfolioId == _currentPortfolioId,
      );
      if (match.isNotEmpty) {
        currentName = match.first.portfolioName;
      }
    }

    return BlocListener<PortfolioCubit, PortfolioState>(
      listener: (context, state) {
        if (state is PortfolioError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: UnifiedSidebarScaffold(
        module: ModuleType.portfolio,
        title: currentName,
        showModuleBottomNavigation: false,
        onBackToGlobal: widget.onBack,
        onMobileMenuTap: () => _showMenuBottomSheet(context),
        items: [
          SecondarySidebarItem(
            title: 'Overview',
            icon: Icons.dashboard_outlined,
            isSelected: _tabController.index == 0 && !_isAddingTrade,
            onTap: () => setState(() {
              _tabController.index = 0;
              _isAddingTrade = false;
            }),
          ),
          SecondarySidebarItem(
            title: 'Holdings',
            icon: Icons.wallet,
            isSelected: _tabController.index == 1 && !_isAddingTrade,
            onTap: () => setState(() {
              _tabController.index = 1;
              _isAddingTrade = false;
            }),
          ),
          SecondarySidebarItem(
            title: 'Heatmap',
            icon: Icons.grid_view,
            isSelected: _tabController.index == 2 && !_isAddingTrade,
            onTap: () => setState(() {
              _tabController.index = 2;
              _isAddingTrade = false;
            }),
          ),
          SecondarySidebarItem(
            title: 'Baskets',
            icon: Icons.shopping_basket_outlined,
            isSelected: _tabController.index == 3 && !_isAddingTrade,
            onTap: () => setState(() {
              _tabController.index = 3;
              _isAddingTrade = false;
            }),
          ),
          SecondarySidebarItem(
            title: 'Add Trade',
            icon: Icons.add,
            isSelected: _isAddingTrade,
            onTap: () => setState(() {
              _isAddingTrade = true;
            }),
          ),
        ],
        body: (_isAddingTrade && widget.addTradeBuilder != null && _currentPortfolioId != null)
            ? widget.addTradeBuilder!(
                context,
                _currentPortfolioId!,
                currentName,
                () {
                  setState(() {
                    _isAddingTrade = false;
                  });
                },
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (_tabController.index == 0 &&
                      notification is ScrollUpdateNotification &&
                      (notification.scrollDelta ?? 0).abs() > 0) {
                    _onScrollDetected();
                  }
                  return false;
                },
                child: Stack(
                  children: [
                    PortfolioTabContentWidget(
                      tabController: _tabController,
                      currentPortfolioId: _currentPortfolioId!,
                    ),
                    if (widget.addTradeBuilder != null && _tabController.index == 0)
                      Positioned(
                        bottom: 24,
                        right: 16,
                        child: AnimatedOpacity(
                          opacity: _showScrollFab ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: IgnorePointer(
                            ignoring: !_showScrollFab,
                            child: _buildGlassFab(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        floatingActionButton: null,
      ),
    );
  }

  void _showMenuBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Portfolio Menu',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Portfolio List Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'SWITCH PORTFOLIO',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.portfolios != null)
              ...[
                const PortfolioItem(
                  portfolioId: 'all',
                  portfolioName: 'All Portfolios',
                ),
                ...widget.portfolios!
              ].map(
                (p) => ListTile(
                  leading: Icon(
                    Icons.account_balance_wallet,
                    color: p.portfolioId == _currentPortfolioId
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  title: Text(
                    p.portfolioName,
                    style: TextStyle(
                      fontWeight: p.portfolioId == _currentPortfolioId
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: p.portfolioId == _currentPortfolioId
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                  ),
                  trailing: p.portfolioId == _currentPortfolioId
                      ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _onPortfolioChanged(p.portfolioId, p.portfolioName);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  dense: true,
                ),
              ),

            const Divider(height: 32),

            // Navigation Actions
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Back to Dashboard'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () {
                Navigator.pop(context);
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Use system back to return')),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () {
                Navigator.pop(context);
                PortfolioLogoutHandler.showLogoutDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
