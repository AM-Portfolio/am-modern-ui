import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
class PortfolioMobileScreen extends ConsumerWidget {
  const PortfolioMobileScreen({
    required this.userId,
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.portfolios,
    this.onPortfolioChanged,
    this.onBack,
  });
  final String userId;
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final List<PortfolioItem>? portfolios;
  final Function(String portfolioId, String portfolioName)? onPortfolioChanged;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    CommonLogger.info(
      'Building PortfolioMobileScreen for userId: $userId',
      tag: 'PortfolioMobileScreen',
    );
    CommonLogger.userAction(
      'Navigate to Mobile Portfolio',
      tag: 'PortfolioMobileScreen',
      metadata: {'userId': userId},
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
          data: (analyticsService) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => PortfolioCubit(portfolioService),
              ),
              BlocProvider(
                create: (context) => PortfolioAnalyticsCubit(analyticsService),
              ),
            ],
            child: PortfolioMobileView(
              userId: userId,
              selectedPortfolioId: selectedPortfolioId,
              selectedPortfolioName: selectedPortfolioName,
              portfolios: portfolios,
              onPortfolioChanged: onPortfolioChanged,
              onBack: onBack,
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
    required this.userId,
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.portfolios,
    this.onPortfolioChanged,
    this.onBack,
  });
  final String userId;
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final List<PortfolioItem>? portfolios;
  final Function(String portfolioId, String portfolioName)? onPortfolioChanged;
  final VoidCallback? onBack;

  @override
  State<PortfolioMobileView> createState() => _PortfolioMobileViewState();
}

class _PortfolioMobileViewState extends State<PortfolioMobileView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _currentPortfolioId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _currentPortfolioId = widget.selectedPortfolioId ?? widget.userId;

    // Load portfolio data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentPortfolioId != null && mounted) {
        final cubit = context.read<PortfolioCubit>();
        final currentState = cubit.state;
        
        if (currentState is PortfolioLoaded && 
            currentState.portfolioId == _currentPortfolioId) {
          // Data is already loaded for this portfolio, skip reloading
          return;
        }
        
        cubit.loadPortfolioById(
          widget.userId,
          _currentPortfolioId!,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Handles portfolio selection change
  void _onPortfolioChanged(String portfolioId, String portfolioName) {
    setState(() {
      _currentPortfolioId = portfolioId;
    });

    // Load new portfolio data
    context.read<PortfolioCubit>().loadPortfolioById(
      widget.userId,
      portfolioId,
    );

    // Notify parent if callback is provided
    widget.onPortfolioChanged?.call(portfolioId, portfolioName);
  }

  @override
  Widget build(BuildContext context) {
    CommonLogger.debug(
      'Building PortfolioMobileView - userId: ${widget.userId}',
      tag: 'PortfolioMobileView',
    );

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
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Content Area
              Expanded(
                child: PortfolioTabContentWidget(
                  tabController: _tabController,
                  currentPortfolioId: _currentPortfolioId!,
                  userId: widget.userId,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    // Standard Portfolio Tabs
    final tabs = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        label: 'Overview',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.wallet),
        label: 'Holdings',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.analytics_outlined),
        label: 'Analysis',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.grid_view),
        label: 'Heatmap',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.show_chart),
        label: 'Trade',
      ),
      // We add 'Menu' as the last functional item
      const BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
    ];

    return ModuleBottomNavigation(
      items: tabs,
      currentIndex: _tabController.index,
      accentColor: Theme.of(context).primaryColor,
      onBackToGlobal: widget.onBack,
      onTap: (index) {
        if (index < 5) {
          // Tab Switch
          setState(() {
            _tabController.animateTo(index);
          });
        } else {
          // Menu
          _showMenuBottomSheet(context);
        }
      },
      // Using generic styling, no special FAB here strictly needed unless we want 'Trade' to be FAB?
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
              ...widget.portfolios!.map(
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
