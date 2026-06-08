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
import '../../providers/trade_controller_providers.dart';
import '../cubit/trade_controller_cubit.dart';
import '../add_trade/pages/add_trade_web_page.dart';

/// Trade view types for navigation
enum TradeViewType { portfolios, holdings, calendar, analysis, report, trades, journal, marketAnalysis, unified }

/// Web-specific trade screen implementation with sidebar navigation
class TradeWebScreen extends ConsumerStatefulWidget {
  const TradeWebScreen({
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.initialView = TradeViewType.portfolios,
    this.isSidebarVisible = true,
    this.onToggleSidebar,
    this.onBack,
    this.onTabChanged,
    this.onPortfolioChanged,
  });

  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final TradeViewType initialView;
  final bool isSidebarVisible;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onBack;

  /// Called whenever the active tab index changes (for cross-layout state sync)
  final void Function(int index)? onTabChanged;

  /// Called whenever a portfolio is selected (for cross-layout state sync)
  final void Function(String id, String name)? onPortfolioChanged;

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
  }

  void _initializeSwipeController() {
    final initialIndex = _getInitialIndex();
    _swipeController = SwipeNavigationController(
      items: _buildNavigationItems(),
      initialIndex: initialIndex,
    );

    // Listen to controller changes to update sidebar selection
    _swipeController.addListener(() {
      if (mounted) {
        setState(() {});
        // Notify parent about tab changes for cross-layout state sync
        widget.onTabChanged?.call(_swipeController.currentIndex);
      }
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
        page: JournalWebPage( portfolioId: _currentPortfolioId),
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
                portfolioId: _currentPortfolioId!,
              ),
        accentColor: ModuleColors.trade,
      ),
      NavigationItem(
        title: 'Unified',
        subtitle: 'Trade Dashboard',
        icon: Icons.view_quilt_outlined,
        page: const TradeUnifiedViewPage(),
        accentColor: ModuleColors.trade,
      ),
      NavigationItem(
        title: 'Add Trade',
        subtitle: 'New Trade Entry',
        icon: Icons.add,
        page: _currentPortfolioId == null
            ? PortfolioSelectionPrompt(
                title: 'Add Trade',
                icon: Icons.add_circle_outline,
                onViewPortfolioList: () => _swipeController.navigateTo(0),
              )
            : Consumer(
                builder: (context, ref, _) {
                  final cubitAsync = ref.watch(tradeControllerCubitProvider);

                  return cubitAsync.when(
                    data: (cubit) => BlocProvider<TradeControllerCubit>.value(
                      value: cubit,
                      child: AddTradeWebPage(
                        portfolioId: _currentPortfolioId!,
                        portfolioName: _currentPortfolioName,
                        onTradeAdded: () {
                           _swipeController.navigateTo(3); // Navigate to trades on success
                        },
                        onCancel: () {
                           _swipeController.navigateTo(3); // Navigate to trades on cancel
                        },
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Error loading trade service: $error')),
                  );
                },
              ),
        accentColor: ModuleColors.trade,
      ),
    ];
  }

  void _onPortfolioSelected(String portfolioId, String portfolioName) {
    final currentIndex = _swipeController.currentIndex;

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

    // Notify parent for cross-layout state sync
    widget.onPortfolioChanged?.call(portfolioId, portfolioName);

    AppLogger.info('Portfolio selected: $portfolioName ($portfolioId)', tag: 'TradeWebScreen');
  }

  @override
  Widget build(BuildContext context) {
    // Watch portfolios stream
    final portfoliosAsyncValue = ref.watch(tradePortfoliosStreamProvider);
    final portfolios = portfoliosAsyncValue.asData?.value ?? const [];

    return NotificationListener<OpenAddTradeNotification>(
      onNotification: (notification) {
        notification.handled = true;
        final addTradeIndex = _swipeController.items.indexWhere((item) => item.title == 'Add Trade');
        if (addTradeIndex != -1) {
          _swipeController.navigateTo(addTradeIndex);
        }
        return true;
      },
      child: UnifiedSidebarScaffold(
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
              // Dispatch directly via _swipeController since NotificationListener is below this context
              final addTradeIndex = _swipeController.items.indexWhere((item) => item.title == 'Add Trade');
              if (addTradeIndex != -1) {
                _swipeController.navigateTo(addTradeIndex);
              }
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
            items: _swipeController.items.asMap().entries
              .where((entry) {
                final title = entry.value.title;
                return title != 'Add Trade' && 
                       title != 'Market' && 
                       title != 'Report' && 
                       title != 'Unified';
              })
              .map((entry) {
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
      ),
    );
  }

  /// Build portfolios view with integrated navigation
  Widget _buildPortfoliosView() {
    return Consumer(
      builder: (context, ref, child) {
        final portfoliosAsync = ref.watch(tradePortfoliosStreamProvider);

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
                ref.invalidate(tradePortfoliosStreamProvider);
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

