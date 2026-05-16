import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';

import 'package:am_common/am_common.dart';
import '../../internal/domain/entities/metrics/metrics_filter_request.dart';
import '../../providers/trade_internal_providers.dart';
import '../../providers/trade_report_providers.dart';
import '../calendar/pages/trade_calendar_analytics_web_page.dart';
import '../components/templates/trade_portfolio_discovery_template.dart';
import '../components/portfolio_selection_prompt.dart';
import '../holdings/pages/trade_holdings_dashboard_web_page.dart';
import '../journal/pages/journal_web_page.dart';
import '../models/trade_portfolio_view_model.dart';
import '../trades/pages/trade_list_web_page.dart';
import '../metrics/trade_metrics_page.dart';
import '../report/pages/trade_report_page.dart';
import 'package:am_market_ui/shared/widgets/trading_view_chart_widget.dart';
import 'package:am_market_ui/am_market_ui.dart';
import '../pages/trade_market_page.dart';
import '../pages/trade_unified_view_page.dart';
import '../trade_navigation.dart';

/// Trade view types for navigation
enum TradeViewType { portfolios, holdings, calendar, analysis, report, trades, journal, marketAnalysis, unified }

/// Web-specific trade screen implementation with sidebar navigation
class TradeWebScreen extends ConsumerStatefulWidget {
  const TradeWebScreen({
    required this.userId,
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.initialView = TradeViewType.portfolios,
    this.isSidebarVisible = true,
    this.onToggleSidebar,
    this.onBack,
  });

  final String userId;
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final TradeViewType initialView;
  final bool isSidebarVisible;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onBack;

  @override
  ConsumerState<TradeWebScreen> createState() => _TradeWebScreenState();
}

class _TradeWebScreenState extends ConsumerState<TradeWebScreen> {
  late SwipeNavigationController _swipeController;
  String? _currentPortfolioId;
  String? _currentPortfolioName;
  late TextEditingController _symbolController;

  @override
  void initState() {
    super.initState();
    _currentPortfolioId = widget.selectedPortfolioId;
    _currentPortfolioName = widget.selectedPortfolioName;
    _symbolController = TextEditingController(text: '');

    _initializeSwipeController();

    if (widget.userId.isEmpty) {
      AppLogger.error(
        '🚨 CRITICAL: TradeWebScreen initialized with EMPTY userId! This should NOT happen!',
        tag: 'TradeWebScreen',
      );
    }
  }

  void _initializeSwipeController() {
    final initialIndex = _getInitialIndex();
    _swipeController = SwipeNavigationController(
      items: _buildNavigationItems(),
      initialIndex: initialIndex,
    );

    // Listen to controller changes to update sidebar selection
    _swipeController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  int _getInitialIndex() {
    switch (widget.initialView) {
      case TradeViewType.portfolios: return 0;
      case TradeViewType.holdings: return 1;
      case TradeViewType.calendar: return 2;
      case TradeViewType.trades: return 3;
      case TradeViewType.journal: return 4;
      case TradeViewType.analysis: return 5;
      case TradeViewType.marketAnalysis: return 6;
      case TradeViewType.report: return 7;
      case TradeViewType.unified: return 8;
    }
  }

  List<NavigationItem> _buildNavigationItems() {
    return [
      NavigationItem(
        title: 'Portfolios',
        subtitle: 'Portfolio Discovery',
        icon: Icons.folder_open_outlined,
        page: _buildPortfoliosView(),
        accentColor: ModuleColors.trade,
      ),
      NavigationItem(
        title: 'Holdings',
        subtitle: 'Asset breakdown',
        icon: Icons.dashboard_outlined,
        page: _currentPortfolioId == null 
            ? PortfolioSelectionPrompt(
                title: 'Holdings',
                icon: Icons.dashboard_outlined,
                onViewPortfolioList: () => _swipeController.navigateTo(0),
              )
            : TradeHoldingsDashboardWebPage(
                key: ValueKey('holdings_$_currentPortfolioId'),
                userId: widget.userId,
                portfolioId: _currentPortfolioId!,
                onNavigateToChart: (symbol) {
                  ref.read(marketAnalysisSymbolProvider.notifier).updateSymbol(symbol);
                  _swipeController.navigateTo(6); // Market Analysis index
                },
              ),
        accentColor: ModuleColors.trade,
      ),
      NavigationItem(
        title: 'Calendar',
        subtitle: 'Trading events',
        icon: Icons.calendar_today_outlined,
        page: _currentPortfolioId == null
            ? PortfolioSelectionPrompt(
                title: 'Calendar',
                icon: Icons.calendar_today_outlined,
                onViewPortfolioList: () => _swipeController.navigateTo(0),
              )
            : TradeCalendarAnalyticsWebPage(
                key: ValueKey('calendar_$_currentPortfolioId'),
                userId: widget.userId,
                portfolioId: _currentPortfolioId!,
              ),
        accentColor: ModuleColors.trade,
      ),
      NavigationItem(
        title: 'Trades',
        subtitle: 'Trade history',
        icon: Icons.list_alt_rounded,
        page: _currentPortfolioId == null
            ? PortfolioSelectionPrompt(
                title: 'Trades',
                icon: Icons.list_alt_rounded,
                onViewPortfolioList: () => _swipeController.navigateTo(0),
              )
            : TradeListWebPage(
                key: ValueKey('trades_$_currentPortfolioId'),
                userId: widget.userId,
                portfolioId: _currentPortfolioId!,
                onNavigateToChart: (symbol) {
                  ref.read(marketAnalysisSymbolProvider.notifier).updateSymbol(symbol);
                  _swipeController.navigateTo(6); // Market Analysis index
                },
              ),
        accentColor: ModuleColors.trade,
      ),
      NavigationItem(
        title: 'Journal',
        subtitle: 'Trade journal',
        icon: Icons.book_outlined,
        page: JournalWebPage(userId: widget.userId, portfolioId: _currentPortfolioId),
        accentColor: ModuleColors.trade,
      ),
      NavigationItem(
        title: 'Analysis',
        subtitle: 'Performance metrics',
        icon: Icons.analytics_outlined,
        page: _currentPortfolioId == null
            ? PortfolioSelectionPrompt(
                title: 'Analysis',
                icon: Icons.analytics_outlined,
                onViewPortfolioList: () => _swipeController.navigateTo(0),
              )
            : TradeMetricsPage(
                key: ValueKey('metrics_$_currentPortfolioId'),
                userId: widget.userId,
                portfolioId: _currentPortfolioId!,
              ),
        accentColor: ModuleColors.trade,
      ),
      NavigationItem(
        title: 'Market',
        subtitle: 'Market Analysis',
        icon: Icons.trending_up_rounded,
        page: const TradeMarketPage(),
        accentColor: ModuleColors.trade,
      ),
      NavigationItem(
        title: 'Report',
        subtitle: 'Generate reports',
        icon: Icons.summarize_outlined,
        page: _currentPortfolioId == null
            ? PortfolioSelectionPrompt(
                title: 'Report',
                icon: Icons.summarize_outlined,
                onViewPortfolioList: () => _swipeController.navigateTo(0),
              )
            : TradeReportPage(
                key: ValueKey('report_$_currentPortfolioId'),
                userId: widget.userId,
                portfolioId: _currentPortfolioId!,
              ),
        accentColor: ModuleColors.trade,
      ),
      NavigationItem(
        title: 'Unified',
        subtitle: 'Trade Dashboard',
        icon: Icons.view_quilt_outlined,
        page: TradeUnifiedViewPage(userId: widget.userId),
        accentColor: ModuleColors.trade,
      ),
    ];
  }

  void _onPortfolioSelected(String portfolioId, String portfolioName) {
    final previousPortfolioId = _currentPortfolioId;
    final currentIndex = _swipeController.currentIndex;
    final wasOnPortfolioSpecificPage = [1, 2, 3, 5, 7].contains(currentIndex); // Holdings, Calendar, Trades, Analysis, Report

    setState(() {
      _currentPortfolioId = portfolioId;
      _currentPortfolioName = portfolioName;
      
      // Update items to inject new portfolio ID
      _swipeController.updateItems(_buildNavigationItems());

      // If we were on a portfolio-specific page but had no portfolio selected (prompt shown),
      // we stay on the same page index, but now it shows data.
      // If we were on Portfolios list (index 0) and selected one, go to Holdings (index 1).
      if (currentIndex == 0) {
        _swipeController.navigateTo(1);
      }
    });

    AppLogger.info('Portfolio selected: $portfolioName ($portfolioId)', tag: 'TradeWebScreen');
  }

  @override
  Widget build(BuildContext context) {
    // Watch portfolios stream
    final portfoliosAsyncValue = ref.watch(tradePortfoliosStreamProvider(widget.userId));
    final portfolios = portfoliosAsyncValue.asData?.value ?? const [];

      return UnifiedSidebarScaffold(
        module: ModuleType.trade,
        // Removed title/subtitle as requested
        title: null, 
        subtitle: null,
        // CRITICAL: Pass an empty header to override the default "Trade Analysis" header
        header: const SizedBox(height: 16), 
        onBackToGlobal: widget.onBack,
        onThemeToggle: () {
          context.read<ThemeCubit>().toggleTheme();
        },
        // Footer: Add Trade Button (Synced with Green Theme)
        footer: Padding(
          padding: const EdgeInsets.all(16),
          child: SidebarPrimaryAction(
            title: 'Add Trade',
            icon: Icons.add,
            accentColor: ModuleColors.trade,
            onTap: () {
              if (_currentPortfolioId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a portfolio first')),
                );
                return;
              }
              openAddTradeWebPage(
                context,
                portfolioId: _currentPortfolioId!,
                portfolioName: _currentPortfolioName,
              );
            },
          ),
        ),
        body: SwipeablePageView(
          controller: _swipeController,
          showIndicator: !portfoliosAsyncValue.isLoading,
          indicatorPosition: IndicatorPosition.bottom,
        ),
        sections: [
          // Portfolio Selector (Top Item, No Title)
          if (portfolios.isNotEmpty)
            SecondarySidebarSection(
              title: '',
              customWidget: SharedPortfolioSelector<TradePortfolioViewModel>(
                currentPortfolioId: _currentPortfolioId,
                currentPortfolioName: _currentPortfolioName,
                portfolios: portfolios,
                onPortfolioSelected: _onPortfolioSelected,
                idExtractor: (p) => p.id,
                nameExtractor: (p) => p.name,
                accentColor: ModuleColors.trade,
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
              );
            }).toList(),
          ),
        ],
      );
  }

  /// Build portfolios view with integrated navigation
  Widget _buildPortfoliosView() {
    if (widget.userId.isEmpty) {
      return Center(child: Text('User ID missing'));
    }

    return Consumer(
      builder: (context, ref, child) {
        final portfoliosAsync = ref.watch(tradePortfoliosStreamProvider(widget.userId));

        return portfoliosAsync.when(
          data: (portfolios) {
            if (_currentPortfolioId == null && portfolios.isNotEmpty && _swipeController.currentIndex == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _onPortfolioSelected(portfolios.first.id, portfolios.first.name);
                }
              });
            }

            return TradePortfolioDiscoveryTemplate(
              portfolios: portfolios,
              isLoading: false,
              onPortfolioSelected: (portfolio) {
                _onPortfolioSelected(portfolio.id, portfolio.name);
              },
              onRefresh: () {
                ref.invalidate(tradePortfoliosStreamProvider(widget.userId));
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }
}

