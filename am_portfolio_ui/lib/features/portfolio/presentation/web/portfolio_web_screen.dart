import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart' hide SharedPortfolioSelector;
import 'package:am_auth_ui/am_auth_ui.dart';

import 'package:am_common/core/utils/logger.dart';
import '../../internal/domain/entities/portfolio_list.dart';
import '../../providers/portfolio_providers.dart';
import '../cubit/portfolio_analytics_cubit.dart';
import '../cubit/portfolio_heatmap_cubit.dart';
import '../cubit/portfolio_state.dart';
import 'package:am_design_system/am_design_system.dart';
import 'pages/portfolio_overview_web_page.dart';
import 'pages/portfolio_holdings_web_page.dart';
import 'pages/portfolio_analysis_web_page.dart';
import 'pages/portfolio_heatmap_web_page.dart';
import 'package:am_user_ui/am_user_ui.dart';

/// Web-specific portfolio screen implementation
class PortfolioWebScreen extends ConsumerStatefulWidget {
  const PortfolioWebScreen({
    required this.userId,
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.portfolios,
    this.onPortfolioChanged,
    this.isSidebarVisible = true,
    this.onToggleSidebar,
    this.onBack,
  });
  final String userId;
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final List<PortfolioItem>? portfolios;
  final Function(String portfolioId, String portfolioName)? onPortfolioChanged;
  final bool isSidebarVisible;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onBack;

  @override
  ConsumerState<PortfolioWebScreen> createState() => _PortfolioWebScreenState();
}

class _PortfolioWebScreenState extends ConsumerState<PortfolioWebScreen> {
  late SwipeNavigationController _swipeController;
  late CacheService _cacheService;
  String? _currentPortfolioId;

  @override
  void initState() {
    super.initState();
    _currentPortfolioId = widget.selectedPortfolioId ?? widget.userId;
    _cacheService = ref.read(cacheServiceProvider);
    _initializeSwipeController();
  }

  void _initializeSwipeController() {
    _swipeController = SwipeNavigationController(
      items: [
        NavigationItem(
          title: 'Overview',
          subtitle: 'Portfolio summary',
          icon: Icons.dashboard_outlined,
          page: PortfolioOverviewWebPage(
            userId: widget.userId,
          ),
          accentColor: ModuleColors.portfolio,
        ),
        NavigationItem(
          title: 'Holdings',
          subtitle: 'Asset breakdown',
          icon: Icons.pie_chart,
          page: PortfolioHoldingsWebPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId ?? widget.userId,
          ),
          accentColor: ModuleColors.portfolio,
        ),
        NavigationItem(
          title: 'Analysis',
          subtitle: 'Performance metrics',
          icon: Icons.analytics_outlined,
          page: PortfolioAnalysisWebPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId ?? widget.userId,
          ),
          accentColor: ModuleColors.portfolio,
        ),
        NavigationItem(
          title: 'Heatmap',
          subtitle: 'Visual analysis',
          icon: Icons.grid_on_outlined,
          page: PortfolioHeatmapWebPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId ?? widget.userId,
          ),
          accentColor: ModuleColors.portfolio,
        ),
      ],
    );
  }

  void _onPortfolioChanged(String portfolioId, String portfolioName) {
    setState(() {
      _currentPortfolioId = portfolioId;
    });

    // Invalidate providers to refresh data - use userId for API calls
    ref.invalidate(portfolioSummaryProvider(widget.userId));
    ref.invalidate(portfolioHoldingsProvider(widget.userId));

    // Notify parent if callback is provided
    widget.onPortfolioChanged?.call(portfolioId, portfolioName);
  }


  @override
  Widget build(BuildContext context) { 

      return UnifiedSidebarScaffold(
        module: ModuleType.portfolio,
        title: 'WORKSPACE',
        subtitle: 'Personal Account',
        onBackToGlobal: widget.onBack,
        onThemeToggle: () {
          context.read<ThemeCubit>().toggleTheme();
        },
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileSettingsPage(userId: widget.userId),
            ),
          );
        },
        onLogout: () {
          context.read<AuthCubit>().logout();
          widget.onBack?.call();
        },
        body: SwipeablePageView(
          controller: _swipeController,
          showIndicator: true,
          indicatorPosition: IndicatorPosition.bottom,
        ),
        footer: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1F222B), // Dark background for contrast
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Navigate to NEW TRADE
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'New Trade',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        sections: [
          // Portfolio Selector Section
          if (widget.portfolios != null && widget.portfolios!.isNotEmpty)
            SecondarySidebarSection(
              title: 'PORTFOLIO',
              customWidget: SharedPortfolioSelector<PortfolioItem>(
                currentPortfolioId: _currentPortfolioId,
                currentPortfolioName: widget.selectedPortfolioName,
                portfolios: widget.portfolios!,
                onPortfolioSelected: _onPortfolioChanged,
                idExtractor: (p) => p.portfolioId,
                nameExtractor: (p) => p.portfolioName,
                // Accent color will be handled by module theme
              ),
            ),
          
          // Navigation Section
          SecondarySidebarSection(
            title: 'NAVIGATION',
            items: _swipeController.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return SecondarySidebarItem(
                title: item.title,
                icon: item.icon,
                isSelected: _swipeController.currentIndex == index,
                onTap: () => _swipeController.navigateTo(index),
                accentColor: item.accentColor,
              );
            }).toList(),
          ),
        ],
      );
  }





  /// Build overview content using dedicated overview page
  Widget _buildOverviewContent(BuildContext context) {
    return PortfolioOverviewWebPage(
      userId: widget.userId,
      portfolioName: widget.selectedPortfolioName,
    );
  }

  /// Build holdings content using dedicated holdings page
  Widget _buildHoldingsContent(BuildContext context) {
    return PortfolioHoldingsWebPage(
      userId: widget.userId,
      portfolioId: _currentPortfolioId!,
      portfolioName: widget.selectedPortfolioName,
    );
  }

  /// Build analysis content using dedicated analysis page
  Widget _buildAnalysisContent(BuildContext context) {
    return PortfolioAnalysisWebPage(
      userId: widget.userId,
      portfolioId: _currentPortfolioId!,
      portfolioName: widget.selectedPortfolioName,
    );
  }

  /// Build heatmap content using dedicated heatmap page
  Widget _buildHeatmapContent(BuildContext context) {
    CommonLogger.debug(
      'Building heatmap content with analytics and heatmap cubits',
      tag: 'PortfolioWebScreen',
    );

    final analyticsServiceAsync = ref.watch(portfolioAnalyticsServiceProvider);

    return analyticsServiceAsync.when(
      data: (analyticsService) {
        CommonLogger.info(
          'Analytics service loaded, creating cubits',
          tag: 'PortfolioWebScreen',
        );

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) {
                CommonLogger.info(
                  'Creating PortfolioAnalyticsCubit',
                  tag: 'PortfolioWebScreen',
                );
                return PortfolioAnalyticsCubit(analyticsService);
              },
            ),
            BlocProvider(
              create: (context) {
                CommonLogger.info(
                  'Creating PortfolioHeatmapCubit',
                  tag: 'PortfolioWebScreen',
                );
                return PortfolioHeatmapCubit();
              },
            ),
          ],
          child: PortfolioHeatmapWebPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId!,
            portfolioName: widget.selectedPortfolioName,
          ),
        );
      },
      loading: () {
        CommonLogger.debug(
          'Analytics service loading...',
          tag: 'PortfolioWebScreen',
        );
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        CommonLogger.error(
          'Failed to load analytics service',
          tag: 'PortfolioWebScreen',
          error: error,
          stackTrace: stack,
        );
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load analytics service: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(portfolioAnalyticsServiceProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }
}
