import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_common/core/utils/logger.dart';
import '../../providers/trade_controller_providers.dart';
import '../../providers/trade_internal_providers.dart';
import '../components/templates/trade_portfolio_discovery_template.dart';
import '../cubit/trade_controller_cubit.dart';
import '../models/trade_portfolio_view_model.dart';
import 'pages/add_trade_mobile_page.dart';
import 'pages/trade_calendar_analytics_mobile_page.dart';
import 'pages/trade_holdings_dashboard_mobile_page.dart';

/// Trade view types for navigation
enum TradeViewType { portfolios, holdings, calendar, addTrade }

/// Mobile-specific trade screen with bottom tab navigation
class TradeMobileScreen extends ConsumerStatefulWidget {
  const TradeMobileScreen({
    required this.userId,
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.initialView = TradeViewType.portfolios,
    this.onBack,
  });

  final String userId;
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final TradeViewType initialView;
  final VoidCallback? onBack;

  @override
  ConsumerState<TradeMobileScreen> createState() => _TradeMobileScreenState();
}

class _TradeMobileScreenState extends ConsumerState<TradeMobileScreen> {
  late TradeViewType _selectedView;
  String? _currentPortfolioId;
  String? _currentPortfolioName;

  @override
  void initState() {
    super.initState();
    _selectedView = widget.initialView;
    _currentPortfolioId = widget.selectedPortfolioId;
    _currentPortfolioName = widget.selectedPortfolioName;

    AppLogger.info('TradeMobileScreen initialized with view: $_selectedView', tag: 'TradeMobileScreen');
  }

  void _onViewChanged(TradeViewType viewType) {
    // Don't allow switching to holdings/calendar if no portfolio is selected
    if ((viewType == TradeViewType.holdings || viewType == TradeViewType.calendar) && _currentPortfolioId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a portfolio first'), duration: Duration(seconds: 2)));
      return;
    }

    setState(() {
      _selectedView = viewType;
    });

    AppLogger.info('Trade view changed to: $viewType', tag: 'TradeMobileScreen');
  }

  void _onPortfolioSelected(String portfolioId, String portfolioName) {
    setState(() {
      _currentPortfolioId = portfolioId;
      _currentPortfolioName = portfolioName;
      // Automatically switch to holdings view when portfolio is selected
      _selectedView = TradeViewType.holdings;
    });

    AppLogger.info('Portfolio selected: $portfolioName ($portfolioId)', tag: 'TradeMobileScreen');
  }

  void _clearPortfolioSelection() {
    setState(() {
      _currentPortfolioId = null;
      _currentPortfolioName = null;
      _selectedView = TradeViewType.portfolios;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _buildAppBar(context),
    body: _buildMainContent(context),
    bottomNavigationBar: _buildBottomNavigationBar(context),
    floatingActionButton: _buildFloatingActionButton(context),
  );

  /// Build app bar with context-aware title and actions
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    String title;
    var actions = <Widget>[];

    switch (_selectedView) {
      case TradeViewType.portfolios:
        title = 'Trade Portfolios';
        actions = [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(tradePortfoliosStreamProvider(widget.userId));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Refreshing portfolios...'), duration: Duration(seconds: 1)));
            },
          ),
        ];
        break;
      case TradeViewType.holdings:
        title = _currentPortfolioName != null ? 'Holdings - $_currentPortfolioName' : 'Holdings';
        actions = [
          if (_currentPortfolioId != null)
            IconButton(icon: const Icon(Icons.close), tooltip: 'Close Portfolio', onPressed: _clearPortfolioSelection),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (_currentPortfolioId != null) {
                final params = (userId: widget.userId, portfolioId: _currentPortfolioId!);
                ref.invalidate(tradeHoldingsStreamProvider(params));
                ref.invalidate(tradeSummaryStreamProvider(params));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Refreshing holdings...'), duration: Duration(seconds: 1)));
              }
            },
          ),
        ];
        break;
      case TradeViewType.calendar:
        title = _currentPortfolioName != null ? 'Calendar - $_currentPortfolioName' : 'Calendar';
        actions = [
          if (_currentPortfolioId != null)
            IconButton(icon: const Icon(Icons.close), tooltip: 'Close Portfolio', onPressed: _clearPortfolioSelection),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (_currentPortfolioId != null) {
                final params = (userId: widget.userId, portfolioId: _currentPortfolioId!);
                ref.invalidate(tradeCalendarStreamProvider(params));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Refreshing calendar...'), duration: Duration(seconds: 1)));
              }
            },
          ),
        ];
        break;
      case TradeViewType.addTrade:
        title = _currentPortfolioName != null ? 'Add Trade - $_currentPortfolioName' : 'Add Trade';
        actions = [];
        break;
    }

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back to Main',
        onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
      ),
      actions: actions,
      elevation: 1,
    );
  }

  /// Build bottom navigation bar for trade views
  Widget _buildBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final hasPortfolio = _currentPortfolioId != null;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedView.index,
        onTap: (index) => _onViewChanged(TradeViewType.values[index]),
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: theme.cardColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Portfolios',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.dashboard_outlined,
              color: hasPortfolio ? null : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            activeIcon: const Icon(Icons.dashboard),
            label: 'Holdings',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_today_outlined,
              color: hasPortfolio ? null : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            activeIcon: const Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle_outline,
              color: hasPortfolio ? null : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            activeIcon: const Icon(Icons.add_circle),
            label: 'Add Trade',
          ),
        ],
      ),
    );
  }

  /// Build main content based on selected view
  Widget _buildMainContent(BuildContext context) {
    switch (_selectedView) {
      case TradeViewType.portfolios:
        return _buildPortfoliosView();

      case TradeViewType.holdings:
        if (_currentPortfolioId == null) {
          return _buildSelectPortfolioPrompt(TradeViewType.holdings);
        }
        return TradeHoldingsDashboardMobilePage(userId: widget.userId, portfolioId: _currentPortfolioId!);

      case TradeViewType.calendar:
        if (_currentPortfolioId == null) {
          return _buildSelectPortfolioPrompt(TradeViewType.calendar);
        }
        return TradeCalendarAnalyticsMobilePage(userId: widget.userId, portfolioId: _currentPortfolioId!);

      case TradeViewType.addTrade:
        if (_currentPortfolioId == null) {
          return _buildSelectPortfolioPrompt(TradeViewType.addTrade);
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
                  ref.invalidate(tradeHoldingsStreamProvider((userId: widget.userId, portfolioId: _currentPortfolioId!)));
                }
                // Switch back to holdings view after adding trade
                setState(() => _selectedView = TradeViewType.holdings);
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
      final portfoliosAsync = ref.watch(tradePortfoliosStreamProvider(widget.userId));

      return portfoliosAsync.when(
        data: (portfolios) => TradePortfolioDiscoveryTemplate(
          portfolios: portfolios,
          isLoading: false,
          onPortfolioSelected: (portfolio) {
            _onPortfolioSelected(portfolio.id, portfolio.name);
          },
          onRefresh: () {
            ref.invalidate(tradePortfoliosStreamProvider(widget.userId));
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
            ref.invalidate(tradePortfoliosStreamProvider(widget.userId));
          },
          isWebView: false,
        ),
      );
    },
  );

  /// Build prompt to select a portfolio
  Widget _buildSelectPortfolioPrompt(TradeViewType viewType) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            viewType == TradeViewType.holdings ? Icons.dashboard_outlined : Icons.calendar_today_outlined,
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
            viewType == TradeViewType.holdings
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
                _selectedView = TradeViewType.portfolios;
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
