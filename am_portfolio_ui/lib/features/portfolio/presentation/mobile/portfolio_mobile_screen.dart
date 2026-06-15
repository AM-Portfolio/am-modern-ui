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
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.portfolios,
    this.onPortfolioChanged,
    this.onBack,
  });
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final List<PortfolioItem>? portfolios;
  final Function(String portfolioId, String portfolioName)? onPortfolioChanged;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.portfolios,
    this.onPortfolioChanged,
    this.onBack,
  });
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
    _currentPortfolioId = widget.selectedPortfolioId;

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
      context.read<PortfolioCubit>().loadPortfolioById(widget.selectedPortfolioId!);
    }
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
    context.read<PortfolioCubit>().loadPortfolioById(portfolioId);

    // Notify parent if callback is provided
    widget.onPortfolioChanged?.call(portfolioId, portfolioName);
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).primaryColor;

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
              // ── Top Header Row ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded,
                        color: accentColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.selectedPortfolioName ?? 'Portfolio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showMenuBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.menu_rounded,
                            size: 20,
                            color: isDark ? Colors.white70 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Top Tab Bar (scrollable pills) ─────────────────
              _buildTopTabBar(context, isDark, accentColor),

              const SizedBox(height: 4),

              // ── Main Content ────────────────────────────────────
              Expanded(
                child: PortfolioTabContentWidget(
                  tabController: _tabController,
                  currentPortfolioId: _currentPortfolioId!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopTabBar(BuildContext context, bool isDark, Color accentColor) {
    final tabs = [
      _TabDef(Icons.dashboard_outlined, 'Overview'),
      _TabDef(Icons.wallet, 'Holdings'),
      _TabDef(Icons.analytics_outlined, 'Analysis'),
      _TabDef(Icons.grid_view, 'Heatmap'),
      _TabDef(Icons.show_chart, 'Trade'),
    ];

    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Container(
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final tab = tabs[index];
              final isActive = _tabController.index == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _tabController.animateTo(index);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accentColor.withValues(alpha: isDark ? 0.2 : 0.12)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? accentColor.withValues(alpha: 0.4)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 16,
                        color: isActive
                            ? accentColor
                            : (isDark ? Colors.white54 : Colors.grey.shade500),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? accentColor
                              : (isDark ? Colors.white54 : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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

/// Simple data holder for top tab definitions
class _TabDef {
  const _TabDef(this.icon, this.label);
  final IconData icon;
  final String label;
}
