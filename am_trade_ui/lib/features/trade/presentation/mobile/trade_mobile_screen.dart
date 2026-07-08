import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';

import 'package:am_common/am_common.dart';
import '../../providers/trade_controller_providers.dart';
import '../../providers/trade_internal_providers.dart';
import '../../trade_calendar_providers.dart';
import '../components/templates/trade_portfolio_discovery_template.dart';
import '../cubit/trade_controller_cubit.dart';
import '../models/trade_portfolio_view_model.dart';
import 'pages/add_trade_mobile_page.dart';
import 'pages/trade_calendar_analytics_mobile_page.dart';
import 'pages/trade_holdings_dashboard_mobile_page.dart';
import 'journal_mobile_page.dart';
import '../metrics/trade_metrics_page.dart';
import '../journal_template/pages/template_browser_page.dart';

/// Trade view types for mobile navigation
enum MobileTradeViewType { portfolios, holdings, calendar, addTrade }

/// Mobile-specific trade screen with bottom tab navigation
class TradeMobileScreen extends ConsumerStatefulWidget {
  const TradeMobileScreen({
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.initialView = MobileTradeViewType.portfolios,
    this.initialTabIndex,
    this.onBack,
    this.onTabChanged,
    this.onPortfolioChanged,
  });

  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final MobileTradeViewType initialView;

  /// Override initial view via a raw tab index (for cross-layout sync)
  final int? initialTabIndex;

  final VoidCallback? onBack;

  /// Called when the active view changes (for cross-layout state sync)
  final void Function(int index)? onTabChanged;

  /// Called when a portfolio is selected (for cross-layout state sync)
  final void Function(String id, String name)? onPortfolioChanged;

  @override
  ConsumerState<TradeMobileScreen> createState() => _TradeMobileScreenState();
}

class _TradeMobileScreenState extends ConsumerState<TradeMobileScreen> {
  late MobileTradeViewType _selectedView;
  String? _currentPortfolioId;
  String? _currentPortfolioName;

  @override
  void initState() {
    super.initState();

    // Safely map from Web index to Mobile index
    if (widget.initialTabIndex != null) {
      if (widget.initialTabIndex == 9) {
        _selectedView = MobileTradeViewType.addTrade;
      } else if (widget.initialTabIndex == 0) {
        _selectedView = MobileTradeViewType.portfolios;
      } else if (widget.initialTabIndex == 1) {
        _selectedView = MobileTradeViewType.holdings;
      } else if (widget.initialTabIndex == 2) {
        _selectedView = MobileTradeViewType.calendar;
      } else {
        // If coming from another desktop tab (Trades, Journal, etc.), fallback to holdings/portfolios
        _selectedView = widget.selectedPortfolioId != null
            ? MobileTradeViewType.holdings
            : MobileTradeViewType.portfolios;
      }
    } else {
      _selectedView = widget.initialView;
    }

    _currentPortfolioId = widget.selectedPortfolioId;
    _currentPortfolioName = widget.selectedPortfolioName;

    AppLogger.info('TradeMobileScreen initialized with view: $_selectedView', tag: 'TradeMobileScreen');
  }

  void _onViewChanged(MobileTradeViewType viewType) {
    // Don't allow switching to holdings/calendar if no portfolio is selected
    if ((viewType == MobileTradeViewType.holdings || viewType == MobileTradeViewType.calendar) && _currentPortfolioId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a portfolio first'), duration: Duration(seconds: 2)));
      return;
    }

    setState(() {
      _selectedView = viewType;
    });

    // Notify parent for cross-layout sync
    widget.onTabChanged?.call(viewType.index);

    AppLogger.info('Trade view changed to: $viewType', tag: 'TradeMobileScreen');
  }

  void _onPortfolioSelected(String portfolioId, String portfolioName) {
    setState(() {
      _currentPortfolioId = portfolioId;
      _currentPortfolioName = portfolioName;
      // Automatically switch to holdings view when portfolio is selected
      _selectedView = MobileTradeViewType.holdings;
    });

    // Notify parent for cross-layout sync
    widget.onPortfolioChanged?.call(portfolioId, portfolioName);
    widget.onTabChanged?.call(MobileTradeViewType.holdings.index);

    AppLogger.info('Portfolio selected: $portfolioName ($portfolioId)', tag: 'TradeMobileScreen');
  }

  void _clearPortfolioSelection() {
    setState(() {
      _currentPortfolioId = null;
      _currentPortfolioName = null;
      _selectedView = MobileTradeViewType.portfolios;
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Trade';
    switch (_selectedView) {
      case MobileTradeViewType.portfolios:
        title = 'Trade Portfolios';
        break;
      case MobileTradeViewType.holdings:
        title = _currentPortfolioName != null ? 'Holdings - $_currentPortfolioName' : 'Holdings';
        break;
      case MobileTradeViewType.calendar:
        title = _currentPortfolioName != null ? 'Calendar - $_currentPortfolioName' : 'Calendar';
        break;
      case MobileTradeViewType.addTrade:
        title = _currentPortfolioName != null ? 'Add Trade - $_currentPortfolioName' : 'Add Trade';
        break;
    }

    final showAppBar = _selectedView != MobileTradeViewType.addTrade &&
        _selectedView != MobileTradeViewType.calendar;

    return UnifiedSidebarScaffold(
      module: ModuleType.trade,
      title: title,
      showAppBarOnMobile: showAppBar,
      showModuleBottomNavigation: false,
      onBackToGlobal: widget.onBack,
      onMobileMenuTap: () => _showMoreMenu(context),
      floatingActionButton: _buildFloatingActionButton(context),
      items: [
        SecondarySidebarItem(
          title: 'Portfolios',
          icon: Icons.account_balance_wallet,
          isSelected: _selectedView == MobileTradeViewType.portfolios,
          onTap: () => _onViewChanged(MobileTradeViewType.portfolios),
        ),
        SecondarySidebarItem(
          title: 'Holdings',
          icon: Icons.dashboard_outlined,
          isSelected: _selectedView == MobileTradeViewType.holdings,
          onTap: () => _onViewChanged(MobileTradeViewType.holdings),
        ),
        SecondarySidebarItem(
          title: 'Calendar',
          icon: Icons.calendar_today_outlined,
          isSelected: _selectedView == MobileTradeViewType.calendar,
          onTap: () => _onViewChanged(MobileTradeViewType.calendar),
        ),
        SecondarySidebarItem(
          title: 'Add Trade',
          icon: Icons.add_circle_outline,
          isSelected: _selectedView == MobileTradeViewType.addTrade,
          onTap: () => _onViewChanged(MobileTradeViewType.addTrade),
        ),
      ],
      body: _buildMainContent(context),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'More Options',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.book, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: const Text('Journal', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('View and manage your trade journal'),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JournalMobilePage(portfolioId: _currentPortfolioId),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics, color: Colors.purple),
                  ),
                  title: const Text('Metrics & Analysis', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Deep dive into your performance'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(title: const Text('Metrics & Analysis')),
                          body: TradeMetricsPage(portfolioId: _currentPortfolioId),
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.style, color: Colors.orange),
                  ),
                  title: const Text('Templates', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Manage trade journal templates'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TemplateBrowserPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }



  /// Build main content based on selected view
  Widget _buildMainContent(BuildContext context) {
    switch (_selectedView) {
      case MobileTradeViewType.portfolios:
        return _buildPortfoliosView();

      case MobileTradeViewType.holdings:
        if (_currentPortfolioId == null) {
          return _buildSelectPortfolioPrompt(MobileTradeViewType.holdings);
        }
        return TradeHoldingsDashboardMobilePage(portfolioId: _currentPortfolioId!);

      case MobileTradeViewType.calendar:
        if (_currentPortfolioId == null) {
          return _buildSelectPortfolioPrompt(MobileTradeViewType.calendar);
        }
        return TradeCalendarAnalyticsMobilePage(portfolioId: _currentPortfolioId!);

      case MobileTradeViewType.addTrade:
        if (_currentPortfolioId == null) {
          return _buildSelectPortfolioPrompt(MobileTradeViewType.addTrade);
        }
        // Get TradeControllerCubit from Riverpod provider
        final tradeControllerCubitAsync = ref.watch(tradeControllerCubitProvider);
        
        return tradeControllerCubitAsync.when(
          data: (tradeControllerCubit) => BlocProvider<TradeControllerCubit>.value(
            value: tradeControllerCubit,
            child: AddTradeMobilePage(
              portfolioId: _currentPortfolioId!,
              portfolioName: _currentPortfolioName,
              onTradeAdded: () {
                // Refresh holdings when trade is added
                if (_currentPortfolioId != null) {
                  ref.invalidate(tradeHoldingsStreamProvider(_currentPortfolioId!));
                  
                  // Refresh calendar data so it reflects the new trade
                  ref.read(tradeCalendarCubitProvider(_currentPortfolioId!).future)
                      .then((cubit) => cubit.loadTradeCalendar(
                         portfolioId: _currentPortfolioId!, 
                         forceReload: true,
                      ));
                }
                // Switch back to holdings view after adding trade
                setState(() => _selectedView = MobileTradeViewType.holdings);
                widget.onTabChanged?.call(MobileTradeViewType.holdings.index);
              },
              onCancel: () {
                // Switch back to holdings view when cancelled
                setState(() => _selectedView = MobileTradeViewType.holdings);
                widget.onTabChanged?.call(MobileTradeViewType.holdings.index);
              },
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error initializing trade controller: $error')),
        );
    }
  }

  /// Build portfolios view
  Widget _buildPortfoliosView() => Consumer(
    builder: (context, ref, child) {
      final portfoliosAsync = ref.watch(tradePortfoliosStreamProvider);

      return portfoliosAsync.when(
        data: (portfolios) => TradePortfolioDiscoveryTemplate(
          portfolios: portfolios,
          isLoading: false,
          onPortfolioSelected: (portfolio) {
            _onPortfolioSelected(portfolio.id, portfolio.name);
          },
          onRefresh: () {
            ref.invalidate(tradePortfoliosStreamProvider);
          },
          isWebView: false,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => TradePortfolioDiscoveryTemplate(
          portfolios: const <TradePortfolioViewModel>[],
          isLoading: false,
          errorMessage: error.toString(),
          onPortfolioSelected: (_) {},
          onRefresh: () {
            ref.invalidate(tradePortfoliosStreamProvider);
          },
          isWebView: false,
        ),
      );
    },
  );

  /// Build prompt to select a portfolio
  Widget _buildSelectPortfolioPrompt(MobileTradeViewType viewType) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            viewType == MobileTradeViewType.holdings ? Icons.dashboard_outlined : Icons.calendar_today_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Portfolio Selected',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            viewType == MobileTradeViewType.holdings
                ? 'Select a portfolio from the Portfolios tab to view detailed holdings and analytics'
                : 'Select a portfolio from the Portfolios tab to explore calendar analytics and trade events',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('Browse Portfolios'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: () {
              setState(() {
                _selectedView = MobileTradeViewType.portfolios;
              });
            },
          ),
        ],
      ),
    ),
  );

  /// Build floating action button for adding new trade
  Widget? _buildFloatingActionButton(BuildContext context) {
    // FAB removed - Add Trade now in bottom navigation
    return null;
  }
}

