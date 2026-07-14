import 'dart:async';
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

/// Trade view types for mobile navigation.
///
/// Indices 0–3 stay aligned with [TradeResponsiveLayout] / web mapping
/// (`addTrade` remains index 3). Journal / metrics / templates follow after.
enum MobileTradeViewType {
  portfolios,
  holdings,
  calendar,
  addTrade,
  journal,
  metrics,
  templates,
}

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
  Timer? _fabHideTimer;
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _resetFabHideTimer();

    // Prefer explicit mobile view; fall back to web-index mapping.
    if (widget.initialView != MobileTradeViewType.portfolios ||
        widget.initialTabIndex == null) {
      _selectedView = widget.initialView;
    } else {
      final index = widget.initialTabIndex!;
      if (index == 9) {
        _selectedView = MobileTradeViewType.addTrade;
      } else if (index == 0) {
        _selectedView = MobileTradeViewType.portfolios;
      } else if (index == 1) {
        _selectedView = MobileTradeViewType.holdings;
      } else if (index == 2) {
        _selectedView = MobileTradeViewType.calendar;
      } else if (index == 4) {
        _selectedView = MobileTradeViewType.journal;
      } else if (index == 5 || index == MobileTradeViewType.metrics.index) {
        _selectedView = MobileTradeViewType.metrics;
      } else if (index == MobileTradeViewType.templates.index) {
        _selectedView = MobileTradeViewType.templates;
      } else {
        _selectedView = widget.selectedPortfolioId != null
            ? MobileTradeViewType.holdings
            : MobileTradeViewType.portfolios;
      }
    }

    _currentPortfolioId = widget.selectedPortfolioId;
    _currentPortfolioName = widget.selectedPortfolioName;

    AppLogger.info(
      'TradeMobileScreen initialized with view: $_selectedView',
      tag: 'TradeMobileScreen',
    );
  }

  @override
  void didUpdateWidget(covariant TradeMobileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialView != oldWidget.initialView &&
        widget.initialView != _selectedView) {
      setState(() => _selectedView = widget.initialView);
    }
    if (widget.selectedPortfolioId != oldWidget.selectedPortfolioId &&
        widget.selectedPortfolioId != null) {
      _currentPortfolioId = widget.selectedPortfolioId;
      _currentPortfolioName = widget.selectedPortfolioName;
    }
  }

  @override
  void dispose() {
    _fabHideTimer?.cancel();
    super.dispose();
  }

  void _resetFabHideTimer() {
    _fabHideTimer?.cancel();
    if (!_showFab) {
      setState(() => _showFab = true);
    }
    _fabHideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showFab = false);
      }
    });
  }

  void _onViewChanged(MobileTradeViewType viewType) {
    // Don't allow switching to holdings/calendar/addTrade if no portfolio is selected
    if ((viewType == MobileTradeViewType.holdings ||
            viewType == MobileTradeViewType.calendar ||
            viewType == MobileTradeViewType.addTrade) &&
        _currentPortfolioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a portfolio first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedView = viewType;
    });

    // Notify parent for cross-layout sync
    widget.onTabChanged?.call(viewType.index);

    AppLogger.info(
      'Trade view changed to: $viewType',
      tag: 'TradeMobileScreen',
    );
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

    AppLogger.info(
      'Portfolio selected: $portfolioName ($portfolioId)',
      tag: 'TradeMobileScreen',
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = _selectedView == MobileTradeViewType.addTrade;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetFabHideTimer(),
      onPointerMove: (_) => _resetFabHideTimer(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            _resetFabHideTimer();
          }
          return false;
        },
        child: UnifiedSidebarScaffold(
          module: ModuleType.trade,
          title: 'Trade',
          showAppBarOnMobile: showAppBar,
          showMobileMenuButton: false,
          showModuleBottomNavigation: false,
          autoHideMobileTabsOnScroll: true,
          onBackToGlobal: widget.onBack,
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
          title: 'Journal',
          icon: Icons.book_outlined,
          isSelected: _selectedView == MobileTradeViewType.journal,
          onTap: () => _onViewChanged(MobileTradeViewType.journal),
        ),
        SecondarySidebarItem(
          title: 'Metrics',
          icon: Icons.analytics_outlined,
          isSelected: _selectedView == MobileTradeViewType.metrics,
          onTap: () => _onViewChanged(MobileTradeViewType.metrics),
        ),
        SecondarySidebarItem(
          title: 'Templates',
          icon: Icons.style_outlined,
          isSelected: _selectedView == MobileTradeViewType.templates,
          onTap: () => _onViewChanged(MobileTradeViewType.templates),
        ),
      ],
      body: _buildMainContent(context),
    ),
    ),
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
        return TradeHoldingsDashboardMobilePage(
          portfolioId: _currentPortfolioId!,
        );

      case MobileTradeViewType.calendar:
        if (_currentPortfolioId == null) {
          return _buildSelectPortfolioPrompt(MobileTradeViewType.calendar);
        }
        return TradeCalendarAnalyticsMobilePage(
          portfolioId: _currentPortfolioId!,
        );

      case MobileTradeViewType.journal:
        return JournalMobilePage(
          portfolioId: _currentPortfolioId,
          embedded: true,
        );

      case MobileTradeViewType.metrics:
        return TradeMetricsPage(portfolioId: _currentPortfolioId);

      case MobileTradeViewType.templates:
        return const TemplateBrowserPage(embedded: true);

      case MobileTradeViewType.addTrade:
        if (_currentPortfolioId == null) {
          return _buildSelectPortfolioPrompt(MobileTradeViewType.addTrade);
        }
        final tradeControllerCubitAsync = ref.watch(tradeControllerCubitProvider);

        return tradeControllerCubitAsync.when(
          data: (tradeControllerCubit) =>
              BlocProvider<TradeControllerCubit>.value(
            value: tradeControllerCubit,
            child: AddTradeMobilePage(
              portfolioId: _currentPortfolioId!,
              portfolioName: _currentPortfolioName,
              onTradeAdded: () {
                if (_currentPortfolioId != null) {
                  ref.invalidate(
                    tradeHoldingsStreamProvider(_currentPortfolioId!),
                  );

                  ref
                      .read(
                        tradeCalendarCubitProvider(_currentPortfolioId!).future,
                      )
                      .then(
                        (cubit) => cubit.loadTradeCalendar(
                          portfolioId: _currentPortfolioId!,
                          forceReload: true,
                        ),
                      );
                }
                setState(() => _selectedView = MobileTradeViewType.holdings);
                widget.onTabChanged?.call(MobileTradeViewType.holdings.index);
              },
              onCancel: () {
                setState(() => _selectedView = MobileTradeViewType.holdings);
                widget.onTabChanged?.call(MobileTradeViewType.holdings.index);
              },
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error initializing trade controller: $error'),
          ),
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
                viewType == MobileTradeViewType.holdings
                    ? Icons.dashboard_outlined
                    : Icons.calendar_today_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No Portfolio Selected',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                viewType == MobileTradeViewType.holdings
                    ? 'Select a portfolio from the Portfolios tab to view detailed holdings and analytics'
                    : 'Select a portfolio from the Portfolios tab to explore calendar analytics and trade events',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Browse Portfolios'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
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

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (_selectedView == MobileTradeViewType.addTrade ||
        _selectedView == MobileTradeViewType.journal ||
        _selectedView == MobileTradeViewType.metrics ||
        _selectedView == MobileTradeViewType.templates) {
      return null;
    }

    return AnimatedScale(
      duration: const Duration(milliseconds: 400),
      scale: _showFab ? 1.0 : 0.0,
      curve: _showFab ? Curves.elasticOut : Curves.easeInBack,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showFab ? 1.0 : 0.0,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 96.0),
          child: FloatingActionButton(
            onPressed: () => _onViewChanged(MobileTradeViewType.addTrade),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
