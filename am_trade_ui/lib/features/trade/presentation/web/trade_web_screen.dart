import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_list.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/cubit/portfolio_cubit.dart';

import 'package:am_common/am_common.dart';
import '../../internal/domain/entities/trade_controller_entities.dart';
import '../../providers/portfolio_overview_providers.dart';
import '../../providers/trade_internal_providers.dart';
import '../calendar/pages/trade_calendar_analytics_web_page.dart';
import '../components/templates/trade_portfolio_discovery_template.dart';
import '../components/portfolio_selection_prompt.dart';
import '../holdings/pages/trade_holdings_dashboard_web_page.dart';
import '../../journal_providers.dart';
import '../journal/pages/journal_web_page.dart';
import '../journal/utils/journal_this_trade.dart';
import '../models/trade_portfolio_view_model.dart';
import '../models/visible_trade_portfolios.dart';
import '../trades/pages/trade_list_web_page.dart';
import '../analysis/trade_analysis_page.dart';
import 'package:am_market_ui/shared/widgets/trading_view_chart_widget.dart';
import 'package:am_market_ui/am_market_ui.dart';
import '../pages/trade_market_page.dart';
import '../pages/trade_unified_view_page.dart';
import '../trade_navigation.dart';
import '../../providers/trade_controller_providers.dart';
import '../../trade_calendar_providers.dart';
import '../cubit/trade_controller_cubit.dart';
import '../cubit/trade_controller_state.dart';
import '../models/trade_holding_view_model.dart';
import '../models/trade_holding_edit_mapper.dart';
import '../add_trade/pages/add_trade_web_page.dart';
import '../paper/paper_wallet_banner.dart';
import '../paper/paper_portfolio.dart';
import '../paper/place_order_web_page.dart';
import '../cubit/oms_cubit.dart';
import '../cubit/oms_state.dart';
import '../../providers/oms_providers.dart';
import '../../internal/data/dtos/oms_dto.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/mobile/widgets/portfolio_form_modal.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/data/dtos/portfolio_update_request_dto.dart';
import 'package:am_portfolio_ui/features/portfolio/providers/portfolio_providers.dart';

/// Trade view types for navigation
enum TradeViewType {
  portfolios,
  holdings,
  calendar,
  trades,
  journal,
  analysis,
  unified
}

/// Web-specific trade screen implementation with sidebar navigation
class TradeWebScreen extends ConsumerStatefulWidget {
  const TradeWebScreen({
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.initialView = TradeViewType.portfolios,
    this.initialTabIndex,
    this.isSidebarVisible = true,
    this.onToggleSidebar,
    this.onBack,
    this.onTabChanged,
    this.onPortfolioChanged,
  });

  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final TradeViewType initialView;
  final int? initialTabIndex;
  final bool isSidebarVisible;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onBack;

  /// Called whenever the active tab index changes (for cross-layout state sync)
  final void Function(int index)? onTabChanged;

  /// Called whenever a portfolio is selected (for cross-layout state sync)
  final void Function(String id, String name)? onPortfolioChanged;

  @override
  ConsumerState<TradeWebScreen> createState() => TradeWebScreenState();
}

class TradeWebScreenState extends ConsumerState<TradeWebScreen> {
  static const String addTradeTitle = 'Add Trade';
  static const String placeOrderTitle = 'Place order';
  late SwipeNavigationController _swipeController;
  String? _currentPortfolioId;
  String? _currentPortfolioName;
  String? _selectedTradeIdForTrades;

  /// When true, Journal loads across all portfolios (other tabs still need a book).
  bool _journalAllPortfolios = false;
  late TextEditingController _symbolController;
  TradeDetails? _existingTradeToEdit;
  int? _lastNotifiedTabIndex;
  String? _handledGhostPortfolioId;
  bool _hasAutoSelectedFirstPortfolio = false;

  void _onHoldingSelected(TradeHoldingViewModel holding) {
    setState(() {
      _selectedTradeIdForTrades = holding.tradeId;
      _swipeController.updateItems(_buildNavigationItems());
    });
    final tradesIndex = _swipeController.items
        .indexWhere((item) => item.title == 'Trades');
    if (tradesIndex != -1) {
      _swipeController.navigateTo(tradesIndex);
    }
  }

  /// Create/open journal for [holding], then jump to Journal tab with that entry focused.
  Future<void> _onJournalHolding(TradeHoldingViewModel holding) async {
    if (_journalNavigating) return;
    _journalNavigating = true;
    try {
      final cubit = await ref.read(journalCubitProvider.future);
      if (!mounted) return;
      final entry = await journalThisTrade(
        cubit: cubit,
        tradeId: holding.tradeId,
        portfolioId: _currentPortfolioId ?? holding.portfolioId,
        holding: holding,
      );
      if (!mounted) return;
      // Do not set _journalInitialTab — keeps Journal ValueKey stable so focus
      // survives onInitialTabApplied clearing the pending focus id.
      setState(() {
        _journalFocusEntryId = entry.id;
        _swipeController.updateItems(_buildNavigationItems());
      });
      final journalIndex =
          _swipeController.items.indexWhere((item) => item.title == 'Journal');
      if (journalIndex != -1) {
        _swipeController.navigateTo(journalIndex);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open journal: $e')),
      );
    } finally {
      _journalNavigating = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPortfolioId = widget.selectedPortfolioId;
    _currentPortfolioName = widget.selectedPortfolioName;
    _symbolController = TextEditingController(text: '');

    _initializeSwipeController();
    GlobalAddActionsBus.instance.addListener(_onGlobalAddAction);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onGlobalAddAction());
  }

  void _onGlobalAddAction() {
    if (!mounted) return;
    final bus = GlobalAddActionsBus.instance;
    if (!bus.tryConsume(GlobalAddActionKind.addTrade)) return;
    openAddTrade();
  }

  @override
  void dispose() {
    GlobalAddActionsBus.instance.removeListener(_onGlobalAddAction);
    _symbolController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TradeWebScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep local selection in sync with route props (portfolio switch).
    final idChanged = widget.selectedPortfolioId != oldWidget.selectedPortfolioId &&
        widget.selectedPortfolioId != null;
    final nameChanged = widget.selectedPortfolioName != oldWidget.selectedPortfolioName &&
        widget.selectedPortfolioName != null &&
        widget.selectedPortfolioName!.isNotEmpty;
    if (idChanged || nameChanged) {
      if (widget.selectedPortfolioId != _handledGhostPortfolioId) {
        _handledGhostPortfolioId = null;
      }
      setState(() {
        if (widget.selectedPortfolioId != null) {
          _currentPortfolioId = widget.selectedPortfolioId;
        }
        if (widget.selectedPortfolioName != null &&
            widget.selectedPortfolioName!.isNotEmpty) {
          _currentPortfolioName = widget.selectedPortfolioName;
        }
      });
      if (idChanged) {
        // Holdings, Calendar, Analysis, Trades, and Journal read this id.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _swipeController.updateItems(_buildNavigationItems());
        });
      }
    }
    if (widget.initialTabIndex != null &&
        widget.initialTabIndex != oldWidget.initialTabIndex &&
        widget.initialTabIndex != _swipeController.currentIndex) {
      _lastNotifiedTabIndex = widget.initialTabIndex;
      _swipeController.navigateTo(widget.initialTabIndex!);
    }
  }

  void _initializeSwipeController() {
    final initialIndex = _getInitialIndex();
    _lastNotifiedTabIndex = initialIndex;
    _swipeController = SwipeNavigationController(
      items: _buildNavigationItems(),
      initialIndex: initialIndex,
    );

    // Listen to controller changes to update sidebar selection
    _swipeController.addListener(() {
      if (mounted) {
        final currentIndex = _swipeController.currentIndex;
        if (currentIndex != _lastNotifiedTabIndex) {
          _lastNotifiedTabIndex = currentIndex;
          setState(() {});
          widget.onTabChanged?.call(currentIndex);
        } else {
          setState(() {});
        }
      }
    });
  }

  void openAddTrade() {
    final addTradeIndex = _swipeController.items
        .indexWhere((item) => item.title == addTradeTitle);
    if (addTradeIndex != -1) {
      _swipeController.navigateTo(addTradeIndex);
    }
  }

  void openPlaceOrder() {
    final index = _swipeController.items
        .indexWhere((item) => item.title == placeOrderTitle);
    if (index != -1) {
      _swipeController.navigateTo(index);
    }
  }

  /// Journal hub sub-tab requested by Analysis context strip (Insights).
  String? _journalInitialTab;

  /// Pending journal entry id to select after navigating to Journal tab.
  String? _journalFocusEntryId;

  /// Guards against double-taps on Holdings → Journal.
  bool _journalNavigating = false;

  void _openJournalInsights() {
    setState(() {
      _journalInitialTab = 'insights';
      _swipeController.updateItems(_buildNavigationItems());
    });
    _swipeController.navigateTo(4);
  }

  void _openAnalysis() {
    _swipeController.navigateTo(5);
  }

  int _getInitialIndex() {
    if (widget.initialTabIndex != null) return widget.initialTabIndex!;
    switch (widget.initialView) {
      case TradeViewType.portfolios:
        return 0;
      case TradeViewType.holdings:
        return 1;
      case TradeViewType.calendar:
        return 2;
      case TradeViewType.trades:
        return 3;
      case TradeViewType.journal:
        return 4;
      case TradeViewType.analysis:
        return 5;
      case TradeViewType.unified:
        return 6;
    }
  }

  List<NavigationItem> _buildNavigationItems() {
    return [
      NavigationItem(
        title: 'Portfolios',
        subtitle: 'Portfolio Discovery',
        icon: Icons.folder_open_outlined,
        page: _buildPortfoliosView(context),
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
                onNavigateToChart: null,
                onSelectTrade: _onHoldingSelected,
                onJournalThis: _onJournalHolding,
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
                key: ValueKey(
                    'trades_${_currentPortfolioId}_$_selectedTradeIdForTrades'),
                portfolioId: _currentPortfolioId!,
                initialTradeId: _selectedTradeIdForTrades,
                onNavigateToChart: null,
              ),
        accentColor: ModuleColors.trade,
      ),
      NavigationItem(
        title: 'Journal',
        subtitle: 'Trade journal',
        icon: Icons.book_outlined,
        page: _currentPortfolioId == null && !_journalAllPortfolios
            ? PortfolioSelectionPrompt(
                title: 'Journal',
                icon: Icons.book_outlined,
                onViewPortfolioList: () => _swipeController.navigateTo(0),
                secondaryLabel: 'All portfolios',
                onSecondary: () {
                  setState(() {
                    _journalAllPortfolios = true;
                    _swipeController.updateItems(_buildNavigationItems());
                  });
                },
              )
            : JournalWebPage(
                key: ValueKey(
                    'journal_${_journalAllPortfolios ? 'all' : _currentPortfolioId}_$_journalInitialTab'),
                portfolioId:
                    _journalAllPortfolios ? null : _currentPortfolioId,
                initialTab: _journalInitialTab ?? 'entries',
                initialFocusEntryId: _journalFocusEntryId,
                onOpenAnalysis: _openAnalysis,
                onInitialTabApplied: () {
                  if (_journalInitialTab != null ||
                      _journalFocusEntryId != null) {
                    setState(() {
                      _journalInitialTab = null;
                      _journalFocusEntryId = null;
                    });
                  }
                },
              ),
        accentColor: ModuleColors.trade,
      ),

      NavigationItem(
        title: 'Analysis',
        subtitle: 'Edge analytics',
        icon: Icons.insights_outlined,
        page: _currentPortfolioId == null
            ? PortfolioSelectionPrompt(
                title: 'Analysis',
                icon: Icons.insights_outlined,
                onViewPortfolioList: () => _swipeController.navigateTo(0),
              )
            : TradeAnalysisPage(
                key: ValueKey('analysis_$_currentPortfolioId'),
                portfolioId: _currentPortfolioId!,
                onOpenCalendar: () => _swipeController.navigateTo(2),
                onOpenJournalInsights: _openJournalInsights,
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
        title: addTradeTitle,
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
                        existingTrade: _existingTradeToEdit,
                        onTradeAdded: () {
                          setState(() => _existingTradeToEdit = null);

                          // Refresh calendar data so it reflects the new trade
                          if (_currentPortfolioId != null) {
                            ref
                                .read(tradeCalendarCubitProvider(
                                        _currentPortfolioId!)
                                    .future)
                                .then((cubit) => cubit.loadTradeCalendar(
                                      portfolioId: _currentPortfolioId!,
                                      forceReload: true,
                                    ));

                            // Refresh trade list so it reflects the new trade
                            ref.invalidate(tradeHoldingsStreamProvider(
                                _currentPortfolioId!));
                          }

                          _swipeController
                              .navigateTo(3); // Navigate to trades on success
                        },
                        onCancel: () {
                          setState(() => _existingTradeToEdit = null);
                          _swipeController
                              .navigateTo(3); // Navigate to trades on cancel
                        },
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                        child: Text('Error loading trade service: $error')),
                  );
                },
              ),
        accentColor: ModuleColors.trade,
      ),
    ];
  }

  Future<void> _openEditOrAddTrade(Object? existingTrade) async {
    List<TradeDetails>? knownTrades;
    final cubitAsync = ref.read(tradeControllerCubitProvider);
    if (cubitAsync is AsyncData<TradeControllerCubit>) {
      cubitAsync.value.state.mapOrNull(
        loaded: (state) => knownTrades = state.trades,
      );
    }

    TradeDetails? tradeToEdit;
    TradeHoldingViewModel? holding;
    String? tradeIdForFetch;

    if (existingTrade is TradeDetails) {
      tradeToEdit = existingTrade;
      tradeIdForFetch = existingTrade.tradeId;
    } else if (existingTrade is TradeHoldingViewModel) {
      holding = existingTrade;
      tradeIdForFetch = holding.tradeId;
    } else if (existingTrade is String) {
      tradeIdForFetch = existingTrade;
      try {
        tradeToEdit = knownTrades?.firstWhere((t) => t.tradeId == existingTrade);
      } catch (_) {
        AppLogger.warning('Trade $existingTrade not found in cubit list',
            tag: 'TradeWebScreen');
      }
    }

    TradeDetails? fetched;
    if (tradeIdForFetch != null && tradeIdForFetch.isNotEmpty) {
      try {
        final repo =
            await ref.read(tradeControllerRepositoryProvider.future);
        final list =
            await repo.getTradeDetailsByTradeIds([tradeIdForFetch]);
        if (list.isNotEmpty) fetched = list.first;
      } catch (e, st) {
        AppLogger.warning(
          'Failed to fetch trade $tradeIdForFetch for edit — using local merge',
          tag: 'TradeWebScreen',
          error: e,
          stackTrace: st,
        );
      }
    }

    if (holding != null) {
      tradeToEdit = resolveTradeForEdit(
        holding: holding,
        knownTrades: knownTrades,
        fetchedTrade: fetched,
        portfolioNameHint: _currentPortfolioName,
      );
    } else if (fetched != null) {
      tradeToEdit = fetched;
    }

    if (!mounted) return;
    setState(() => _existingTradeToEdit = tradeToEdit);

    final addTradeIndex = _swipeController.items
        .indexWhere((item) => item.title == addTradeTitle);
    if (addTradeIndex != -1) {
      _swipeController.navigateTo(addTradeIndex);
    }
  }

  void _onPortfolioSelected(String portfolioId, String portfolioName,
      {bool autoSelect = false}) {
    final currentIndex = _swipeController.currentIndex;

    setState(() {
      _currentPortfolioId = portfolioId;
      _currentPortfolioName = portfolioName;
      _journalAllPortfolios = false;

      // Update items to inject new portfolio ID
      _swipeController.updateItems(_buildNavigationItems());

      // If we were on a portfolio-specific page but had no portfolio selected (prompt shown),
      // we stay on the same page index, but now it shows data.
      // If we were on Portfolios list (index 0) and selected one manually, go to Holdings (index 1).
      if (currentIndex == 0 && !autoSelect) {
        _swipeController.navigateTo(1);
      }
    });

    // Notify parent for cross-layout state sync
    widget.onPortfolioChanged?.call(portfolioId, portfolioName);

    AppLogger.info('Portfolio selected: $portfolioName ($portfolioId)',
        tag: 'TradeWebScreen');
  }

  List<PortfolioItem> _shellPortfolios(BuildContext context) {
    try {
      return context.watch<PortfolioCubit>().state.portfolioList?.portfolios ??
          const [];
    } catch (_) {
      return const [];
    }
  }

  List<TradePortfolioViewModel> _visiblePortfolios(
    BuildContext context,
    List<TradePortfolioViewModel> trade,
  ) {
    return mergeVisibleTradePortfolios(
      trade: trade,
      shell: _shellPortfolios(context),
      selectedId: _currentPortfolioId,
      selectedName: _currentPortfolioName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brokerPortfolios = _visiblePortfolios(
      context,
      ref.watch(tradePortfoliosStreamProvider).asData?.value ?? const [],
    );
    final omsCubit = ref.watch(omsCubitProvider).asData?.value;

    Widget tree(List<TradePortfolioViewModel> portfolios, OmsWallet? paper) {
    final isPaperSelected =
        paper != null && _currentPortfolioId == paper.portfolioUuid;

    // Drop shell selection that Trade does not own (e.g. deleted Portfolio-only ghost).
    if (portfolios.isNotEmpty &&
        _currentPortfolioId != null &&
        _currentPortfolioId != 'all' &&
        !portfolios.any((p) => p.id == _currentPortfolioId)) {
      final ghostId = _currentPortfolioId!;
      if (_handledGhostPortfolioId != ghostId) {
        _handledGhostPortfolioId = ghostId;
        final fallback = portfolios.first;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.clearPortfolioSelectionIf(ghostId);
          _onPortfolioSelected(fallback.id, fallback.name, autoSelect: true);
        });
      }
    }

    // Automatically select the first portfolio if none is selected
    if (portfolios.isNotEmpty && _currentPortfolioId == null && !_hasAutoSelectedFirstPortfolio) {
      _hasAutoSelectedFirstPortfolio = true;
      final defaultPortfolio = portfolios.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onPortfolioSelected(defaultPortfolio.id, defaultPortfolio.name,
              autoSelect: true);
        }
      });
    }

    return NotificationListener<OpenAddTradeNotification>(
      onNotification: (notification) {
        notification.handled = true;
        _openEditOrAddTrade(notification.existingTrade);
        return true;
      },
      child: UnifiedSidebarScaffold(
        module: ModuleType.trade,
        title: null,
        subtitle: null,
        showModuleBottomNavigation: false,
        // Add / Sync lives on GlobalSidebar only (above theme).
        headerActions: const [ShareLinkButton()],
        onBackToGlobal: widget.onBack,
        onThemeToggle: () {
          context.read<ThemeCubit>().toggleTheme();
        },
        footer: const SizedBox.shrink(),
        body: Column(
          children: [
            if (isPaperSelected && paper != null) PaperWalletBanner(wallet: paper),
            Expanded(
              child: SwipeablePageView(
                // Stable identity so OMS/stream rebuilds do not dispose
                // AnimatedBuilder dependents mid-notify (InheritedNotifier assert).
                key: const ValueKey('trade-swipeable-pages'),
                controller: _swipeController,
                showIndicator: false,
                indicatorPosition: IndicatorPosition.bottom,
              ),
            ),
          ],
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
            items: _swipeController.items.asMap().entries.where((entry) {
              final title = entry.value.title;
              return title != addTradeTitle &&
                  title != placeOrderTitle &&
                  title != 'Market' &&
                  title != 'Unified';
            }).map((entry) {
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

    if (omsCubit == null) {
      return tree(brokerPortfolios, null);
    }
    return BlocProvider<OmsCubit>.value(
      value: omsCubit,
      child: BlocListener<OmsCubit, OmsState>(
        listenWhen: (prev, next) => next.toast != null && next.toast != prev.toast,
        listener: (context, state) {
          final toast = state.toast;
          if (toast == null) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(toast)));
        },
        child: BlocBuilder<OmsCubit, OmsState>(
          buildWhen: (prev, next) => prev.paperWallet != next.paperWallet,
          builder: (context, oms) => tree(
            mergePaperWallet(brokerPortfolios, oms.paperWallet),
            oms.paperWallet,
          ),
        ),
      ),
    );
  }

  /// Build portfolios view with integrated navigation
  Widget _buildPortfoliosView(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final portfoliosAsyncValue = ref.watch(enrichedTradePortfoliosProvider);
        // Progressive: stream often has realized cards before enrichment finishes.
        final streamPortfolios = _visiblePortfolios(
          context,
          ref.watch(tradePortfoliosStreamProvider).asData?.value ?? const [],
        );

        return portfoliosAsyncValue.when(
          data: (portfolios) {
            final omsCubit = ref.watch(omsCubitProvider).asData?.value;
            Widget template(List<TradePortfolioViewModel> list, OmsWallet? paper) {
              return TradePortfolioDiscoveryTemplate(
            portfolios: mergePaperWallet(list, paper),
            isLoading: false,
            hasPaperWallet: paper != null,
            onPortfolioSelected: (portfolio) {
              _onPortfolioSelected(portfolio.id, portfolio.name);
            },
            onCreatePaperWallet: null,
            onCreatePortfolio: null,
            // ─── EDIT PORTFOLIO ──────────────────────────────────────────
            onEditPortfolio: (portfolio) {
              if (portfolio.isPaper) return;
              final portfolioItem = PortfolioItem(
                portfolioId: portfolio.id,
                portfolioName: portfolio.name,
              );
              PortfolioFormModal.show(
                context: context,
                portfolio: portfolioItem,
                onSubmit: (name, desc) async {
                  final service = ref.read(portfolioServiceProvider).value;
                  if (service == null) {
                    throw Exception('Portfolio service not ready');
                  }
                  final request = PortfolioUpdateRequestDto(
                    name: name,
                    description: desc,
                    currency: 'USD',
                  );
                  await service.updatePortfolio(portfolio.id, request);
                  // Optimistically update local cache to bypass backend cache
                  final repository = ref.read(tradeRepositoryProvider).value;
                  repository?.updateCachedPortfolio(
                      portfolio.id, request.name, request.description);
                  // We explicitly DO NOT call ref.invalidate here
                },
              );
            },
            // ─── DELETE PORTFOLIO ────────────────────────────────────────
            onDeletePortfolio: (portfolio) async {
              if (portfolio.isPaper) return;
              // Use a StatefulBuilder so the checkbox inside the dialog can
              // rebuild without closing it — standard Flutter pattern.
              bool deleteTrades = false;
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  final colors = dialogContext.colors;
                  final textTheme = Theme.of(dialogContext).textTheme;
                  return StatefulBuilder(
                    builder: (ctx, setDialogState) => AlertDialog(
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  colors.statusError.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.delete_outline_rounded,
                                color: colors.statusError, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text('Delete Portfolio'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Are you sure you want to delete "${portfolio.name}"?',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This action cannot be undone.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            value: deleteTrades,
                            onChanged: (v) => setDialogState(
                                () => deleteTrades = v ?? false),
                            title: Text(
                              'Also delete all associated trades',
                              style: textTheme.bodyMedium,
                            ),
                            subtitle: Text(
                              'If unchecked, trades remain in the database but will be unassigned.',
                              style: textTheme.bodySmall,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: colors.statusError,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          icon: const Icon(Icons.delete_rounded, size: 18),
                          label: const Text('Delete'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.statusError,
                            foregroundColor: colors.actionPrimaryFg,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
              if (confirm == true && mounted) {
                final service = ref.read(portfolioServiceProvider).value;
                if (service == null) return;
                try {
                  await service.deletePortfolio(
                    portfolio.id,
                    deleteTrades: deleteTrades,
                  );
                  if (!mounted) return;
                  // Optimistically remove from local cache, then refresh streams
                  // so a failed/partial backend delete cannot leave a ghost card.
                  final repository = ref.read(tradeRepositoryProvider).value;
                  repository?.removeCachedPortfolio(portfolio.id);
                  invalidateTradePortfolios(ref);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Portfolio deleted successfully'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete portfolio: $e'),
                      backgroundColor: context.colors.statusError,
                    ),
                  );
                }
              }
            },
            onRefresh: () => invalidateTradePortfolios(ref),
              );
            }

            final visible = _visiblePortfolios(context, portfolios);
            if (omsCubit == null) {
              return template(visible, null);
            }
            return BlocProvider<OmsCubit>.value(
              value: omsCubit,
              child: BlocBuilder<OmsCubit, OmsState>(
                builder: (context, oms) =>
                    template(visible, oms.paperWallet),
              ),
            );
          },
          loading: () {
            if (streamPortfolios.isNotEmpty) {
              return TradePortfolioDiscoveryTemplate(
                portfolios: streamPortfolios,
                isLoading: false,
                onPortfolioSelected: (portfolio) {
                  _onPortfolioSelected(portfolio.id, portfolio.name);
                },
                onRefresh: () => invalidateTradePortfolios(ref),
              );
            }
            return TradePortfolioDiscoveryTemplate(
              portfolios: const [],
              isLoading: true,
              onPortfolioSelected: (_) {},
            );
          },
          error: (error, _) => TradePortfolioDiscoveryTemplate(
            portfolios: streamPortfolios,
            isLoading: false,
            errorMessage: streamPortfolios.isEmpty
                ? 'Failed to load portfolios: $error'
                : null,
            onPortfolioSelected: (portfolio) {
              _onPortfolioSelected(portfolio.id, portfolio.name);
            },
            onRefresh: () => invalidateTradePortfolios(ref),
          ),
        );
      },
    );
  }

  Future<void> _createPaperWallet(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create paper wallet'),
        content: const Text(
          'Practice with ₹10,00,000 virtual cash — not a live broker order. '
          'You can have one paper wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final cubit = ref.read(omsCubitProvider).asData?.value;
    if (cubit == null) return;
    await cubit.createPaperWallet();
    final wallet = cubit.state.paperWallet;
    if (wallet != null) {
      _onPortfolioSelected(wallet.portfolioUuid, 'Paper');
    }
  }
}
