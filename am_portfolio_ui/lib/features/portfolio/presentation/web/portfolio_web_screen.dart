import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_common/am_common.dart';


import '../../internal/domain/entities/portfolio_list.dart';
import '../../providers/portfolio_providers.dart';


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
  String? _currentPortfolioId;

  @override
  void initState() {
    super.initState();
    _currentPortfolioId = widget.selectedPortfolioId ?? widget.userId;
    _initializeSwipeController();
  }

  void _initializeSwipeController() {
    _swipeController = SwipeNavigationController(
      items: [
        NavigationItem(
          title: 'Overview',
          subtitle: 'Portfolio summary',
          icon: Icons.dashboard_outlined,
          page: _wrapPage(PortfolioOverviewWebPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId ?? widget.userId,
          )),
          accentColor: ModuleColors.portfolio,
        ),
        NavigationItem(
          title: 'Holdings',
          subtitle: 'Asset breakdown',
          icon: Icons.pie_chart,
          page: _wrapPage(PortfolioHoldingsWebPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId ?? widget.userId,
          )),
          accentColor: ModuleColors.portfolio,
        ),
        NavigationItem(
          title: 'Analysis',
          subtitle: 'Performance metrics',
          icon: Icons.analytics_outlined,
          page: _wrapPage(PortfolioAnalysisWebPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId ?? widget.userId,
          )),
          accentColor: ModuleColors.portfolio,
        ),
        NavigationItem(
          title: 'Heatmap',
          subtitle: 'Visual analysis',
          icon: Icons.grid_on_outlined,
          page: _wrapPage(PortfolioHeatmapWebPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId ?? widget.userId,
            portfolioName: widget.selectedPortfolioName,
          )),
          accentColor: ModuleColors.portfolio,
        ),
      ],
    );
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
        // Removed title/subtitle as requested
        title: null,
        subtitle: null,
        // CRITICAL: Pass an empty header to override default "Portfolio" header
        header: const SizedBox(height: 16),
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
        footer: Padding(
          padding: const EdgeInsets.all(16),
          child: SidebarPrimaryAction(
            title: 'New Trade',
            icon: Icons.add,
            accentColor: ModuleColors.portfolio,
            onTap: () {
              // Navigate to NEW TRADE
            },
          ),
        ),
        sections: [
            if (widget.portfolios != null && widget.portfolios!.isNotEmpty)
            SecondarySidebarSection(
              title: '', // No title as requested ("Institute of account") style
              customWidget: SharedPortfolioSelector<PortfolioItem>(
                currentPortfolioId: _currentPortfolioId,
                currentPortfolioName: widget.selectedPortfolioName,
                portfolios: widget.portfolios!,
                onPortfolioSelected: _onPortfolioChanged,
                idExtractor: (p) => p.portfolioId,
                nameExtractor: (p) => p.portfolioName,
                accentColor: ModuleColors.portfolio,
              ),
            ),
          
          // Navigation Section (No Title)
          SecondarySidebarSection(
            title: '',
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


}
