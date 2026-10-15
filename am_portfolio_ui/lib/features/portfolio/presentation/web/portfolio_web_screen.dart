import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_common/am_common.dart';

import '../../internal/domain/entities/portfolio_list.dart';
import '../cubit/portfolio_cubit.dart';

import 'package:am_design_system/am_design_system.dart';
import 'pages/portfolio_overview_web_page.dart';
import 'pages/portfolio_holdings_web_page.dart';
import 'pages/portfolio_heatmap_web_page.dart';
import 'pages/portfolio_baskets_web_page.dart';
import 'package:am_user_ui/am_user_ui.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/xray_class_add_sheet.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/asset_class/add_asset_class_workspace.dart';
import 'package:am_portfolio_ui/features/basket/presentation/basket_navigation.dart';
import 'package:am_portfolio_ui/features/basket/presentation/widgets/discover/discover_view_mode.dart';

/// Web-specific portfolio screen implementation
class PortfolioWebScreen extends ConsumerStatefulWidget {
  const PortfolioWebScreen({
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.portfolios,
    this.initialTab = 'overview',
    this.onTabChanged,
    this.onPortfolioChanged,
    this.isSidebarVisible = true,
    this.onToggleSidebar,
    this.onBack,
    this.addTradeBuilder,
    this.holdingsPageBuilder,
    this.onOpenDocIntel,
    this.uploadPortfolioBuilder,
    this.addAssetClassBuilder,
    this.onQuickAdd,
  });
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final List<PortfolioItem>? portfolios;
  final String initialTab;
  final ValueChanged<String>? onTabChanged;
  final Function(String portfolioId, String portfolioName)? onPortfolioChanged;
  final bool isSidebarVisible;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onBack;
  final Widget Function(BuildContext context, String portfolioId, String? portfolioName, VoidCallback onComplete)? addTradeBuilder;
  /// Optional web Holdings tab body (e.g. Trade holdings dashboard from am_app).
  final Widget Function(BuildContext context, String portfolioId)? holdingsPageBuilder;
  final VoidCallback? onOpenDocIntel;
  final Widget Function(String portfolioId, String? portfolioName, VoidCallback onCancel)? uploadPortfolioBuilder;
  final Widget Function(BuildContext context, String portfolioId, String? portfolioName, VoidCallback onComplete)? addAssetClassBuilder;
  final ValueChanged<GlobalAddActionKind>? onQuickAdd;

  @override
  ConsumerState<PortfolioWebScreen> createState() => _PortfolioWebScreenState();
}

class _PortfolioWebScreenState extends ConsumerState<PortfolioWebScreen> {
  static const _tabSlugs = [
    'overview',
    'holdings',
    'heatmap',
    'baskets',
  ];

  String? _currentPortfolioId;
  String? _currentPortfolioName;
  bool _isAddingTrade = false;
  bool _isAddingAssetClass = false;
  bool _isUploadingPortfolio = false;
  /// True only after the user edits/selects something on an in-shell form.
  bool _operationDirty = false;

  @override
  void initState() {
    super.initState();
    _syncPortfolioSelection();
    GlobalAddActionsBus.instance.addListener(_onGlobalAddAction);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onGlobalAddAction());
  }

  @override
  void dispose() {
    GlobalAddActionsBus.instance.removeListener(_onGlobalAddAction);
    super.dispose();
  }

  bool get _isAddAssetClassRoute =>
      widget.initialTab.toLowerCase() == 'add-asset-class';

  void _leaveFocusedFlow() {
    setState(_clearActiveOperation);
    widget.onTabChanged?.call('overview');
  }

  Future<void> _onGlobalAddAction() async {
    if (!mounted) return;
    final bus = GlobalAddActionsBus.instance;
    // Upload / Add Trade / Add Asset Class use dedicated URLs via onQuickAdd.
    // Only Add Basket still lands on this module via the bus.
    if (!bus.tryConsume(GlobalAddActionKind.addBasket)) return;
    if (!await _promptDiscardChanges()) return;
    if (!mounted) return;
    widget.onTabChanged?.call('baskets');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BasketNavigation.setViewMode(BasketViewMode.discover);
    });
  }

  void _syncPortfolioSelection() {
    _currentPortfolioId = widget.selectedPortfolioId ??
        widget.portfolios?.firstOrNull?.portfolioId;
    _currentPortfolioName = widget.selectedPortfolioName ??
        widget.portfolios?.firstOrNull?.portfolioName;
  }

  @override
  void didUpdateWidget(PortfolioWebScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPortfolioId != oldWidget.selectedPortfolioId ||
        widget.selectedPortfolioName != oldWidget.selectedPortfolioName ||
        widget.portfolios != oldWidget.portfolios) {
      _syncPortfolioSelection();
      WidgetsBinding.instance.addPostFrameCallback((_) => _onGlobalAddAction());
    }
    if (oldWidget.initialTab == 'baskets' &&
        widget.initialTab != 'baskets') {
      final portfolioId = _resolvedPortfolioId;
      if (portfolioId != null) {
        context.read<PortfolioCubit>().loadPortfolioById(portfolioId);
      }
    }
  }

  String? get _resolvedPortfolioId {
    if (_currentPortfolioId != null) return _currentPortfolioId;
    if (widget.selectedPortfolioId != null) return widget.selectedPortfolioId;
    final portfolios = widget.portfolios;
    if (portfolios != null && portfolios.isNotEmpty) {
      return portfolios.first.portfolioId;
    }
    return null;
  }

  int get _currentIndex {
    final index = _tabSlugs.indexOf(widget.initialTab);
    return index >= 0 ? index : 0;
  }

  void _clearActiveOperation() {
    _isAddingTrade = false;
    _isAddingAssetClass = false;
    _isUploadingPortfolio = false;
    _operationDirty = false;
  }

  void _markOperationDirty() {
    if (!mounted || _operationDirty) return;
    setState(() => _operationDirty = true);
  }

  /// Marks dirty on any pointer interaction inside add-trade / upload /
  /// asset-class. Notification bubbling alone is unreliable for those panes.
  Widget _wrapActiveOperation(Widget child) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _markOperationDirty(),
      child: child,
    );
  }

  Future<bool> _promptDiscardChanges() async {
    final inFocusedFlow = _isAddingTrade ||
        _isUploadingPortfolio ||
        _isAddingAssetClass ||
        _isAddAssetClassRoute;
    if (!inFocusedFlow) {
      return true;
    }

    // Exploring an empty form — leave without a discard prompt.
    if (!_operationDirty) {
      setState(_clearActiveOperation);
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Discard Unsaved Changes?'),
        content: const Text(
          'You have unsaved edits. Are you sure you want to discard them and navigate away?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Discard',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDiscard == true) {
      setState(_clearActiveOperation);
      return true;
    }
    return false;
  }

  Future<void> _navigateToTabSlug(String slug) async {
    if (await _promptDiscardChanges()) {
      widget.onTabChanged?.call(slug);
    }
  }

  Future<void> _onPortfolioChanged(
    String portfolioId,
    String portfolioName,
  ) async {
    if (!await _promptDiscardChanges()) return;
    if (!mounted) return;

    setState(() {
      _currentPortfolioId = portfolioId;
      _currentPortfolioName = portfolioName;
    });

    try {
      context.selectPortfolio(portfolioId, portfolioName);
    } catch (_) {
      if (widget.initialTab != 'baskets') {
        context.read<PortfolioCubit>().loadPortfolioById(portfolioId);
      }
    }
    widget.onPortfolioChanged?.call(portfolioId, portfolioName);
  }

  List<NavigationItem> _buildNavigationItems() {
    final portfolioId = _resolvedPortfolioId;
    if (portfolioId == null) {
      return [
        NavigationItem(
          title: 'Overview',
          subtitle: 'Dashboard',
          icon: Icons.dashboard_outlined,
          accentColor: ModuleColors.portfolio,
          page: Center(
            child: Text(
              'No portfolios found. Please create a new portfolio.',
              style: TextStyle(fontSize: 16, color: context.textTertiary),
            ),
          ),
        ),
      ];
    }

    return [
      NavigationItem(
        title: 'Overview',
        subtitle: 'Dashboard',
        icon: Icons.dashboard_outlined,
        accentColor: ModuleColors.portfolio,
        page: PortfolioOverviewWebPage(
          portfolioId: portfolioId,
          portfolioName: _currentPortfolioName ?? widget.selectedPortfolioName,
        ),
      ),
      NavigationItem(
        title: 'Holdings',
        subtitle: 'Assets',
        icon: Icons.account_balance_wallet_outlined,
        accentColor: ModuleColors.portfolio,
        page: widget.holdingsPageBuilder?.call(context, portfolioId) ??
            PortfolioHoldingsWebPage(
              portfolioId: portfolioId,
            ),
      ),
      NavigationItem(
        title: 'Heatmap',
        subtitle: 'Performance',
        icon: Icons.grid_view_outlined,
        accentColor: ModuleColors.portfolio,
        page: PortfolioHeatmapWebPage(
          portfolioId: portfolioId,
          portfolioName: _currentPortfolioName ?? widget.selectedPortfolioName,
        ),
      ),
      NavigationItem(
        title: 'Baskets',
        subtitle: 'Basket replication',
        icon: Icons.shopping_basket_outlined,
        accentColor: ModuleColors.portfolio,
        page: PortfolioBasketsWebPage(
          portfolioId: portfolioId,
        ),
      ),
    ];
  }

  Widget _buildAddAssetClassBody() {
    final id = _currentPortfolioId ?? widget.selectedPortfolioId;
    if (id == null || id.isEmpty || id == 'all') {
      return const Center(child: Text('Select a portfolio to continue'));
    }
    final name = _currentPortfolioName ?? widget.selectedPortfolioName;
    return _wrapActiveOperation(
      widget.addAssetClassBuilder != null
          ? widget.addAssetClassBuilder!(
              context,
              id,
              name,
              _leaveFocusedFlow,
            )
          : AddAssetClassWorkspace(
              portfolioId: id,
              portfolioName: name,
              onOpenDocIntel: widget.onOpenDocIntel,
              onCancel: () {
                _promptDiscardChanges().then((ok) {
                  if (ok && mounted) _leaveFocusedFlow();
                });
              },
              onComplete: _leaveFocusedFlow,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildNavigationItems();
    final currentIndex = _currentIndex;
    final activePage =
        currentIndex < items.length ? items[currentIndex].page : items.first.page;
    final focusedAssetClass = _isAddAssetClassRoute;

    return NotificationListener<ShellOperationDirtyNotification>(
      onNotification: (notification) {
        if (_operationDirty != notification.isDirty) {
          setState(() => _operationDirty = notification.isDirty);
        }
        return true;
      },
      child: NotificationListener<OpenAddTradeNotification>(
        onNotification: (notification) {
          // Prefer Trade module URL for new trades.
          if (widget.onQuickAdd != null) {
            widget.onQuickAdd!(GlobalAddActionKind.addTrade);
            notification.handled = true;
            return true;
          }
          if (widget.initialTab == 'holdings') {
            notification.handled = true;
            return true;
          }
          return false;
        },
        child: UnifiedSidebarScaffold(
          module: ModuleType.portfolio,
          title: null,
          subtitle: null,
          showModuleBottomNavigation: false,
          headerActions: const [],
          onBackToGlobal: () {
            _promptDiscardChanges().then((ok) {
              if (ok && mounted) {
                if (focusedAssetClass) {
                  _leaveFocusedFlow();
                } else {
                  widget.onBack?.call();
                }
              }
            });
          },
          onThemeToggle: () {
            context.read<ThemeCubit>().toggleTheme();
          },
          onProfileTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is Authenticated) {
                    return ProfileSettingsPage(
                      userId: authState.user.id,
                      email: authState.user.email,
                      displayName: authState.user.displayName,
                    );
                  }
                  return const ProfileSettingsPage(userId: '');
                },
              ),
            );
          },
          onLogout: () {
            context.read<AuthCubit>().logout();
            widget.onBack?.call();
          },
          body: focusedAssetClass
              ? _buildAddAssetClassBody()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          if (widget.portfolios != null &&
                              widget.portfolios!.any((p) => p.isDummy))
                            Expanded(
                              child: DemoAccountInlineBanner(
                                onUploadPortfolio: widget.onOpenDocIntel,
                              ),
                            )
                          else
                            const Spacer(),
                          if (currentIndex == 0) ...[
                            const SizedBox(width: 12),
                            Consumer(
                              builder: (context, ref, _) {
                                final selected = ref.watch(appTimeFrameProvider);
                                final screenWidth =
                                    MediaQuery.of(context).size.width;

                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: screenWidth > 800
                                        ? 400
                                        : screenWidth * 0.45,
                                  ),
                                  child: TimeFrameSelector(
                                    compact: true,
                                    primaryColor: ModuleColors.portfolio,
                                    selectedTimeFrame: selected,
                                    onTimeFrameChanged: (tf) => ref
                                        .read(appTimeFrameProvider.notifier)
                                        .setTimeFrame(tf),
                                    availableTimeFrames: const [
                                      TimeFrame.oneDay,
                                      TimeFrame.oneWeek,
                                      TimeFrame.oneMonth,
                                      TimeFrame.threeMonths,
                                      TimeFrame.sixMonths,
                                      TimeFrame.oneYear,
                                      TimeFrame.fiveYears,
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(child: activePage),
                  ],
                ),
          footer: const SizedBox.shrink(),
          // Keep full portfolio rail on Add Asset Class (selector + tabs).
          sections: [
            if (widget.portfolios != null && widget.portfolios!.isNotEmpty)
              SecondarySidebarSection(
                title: '',
                customWidget: SharedPortfolioSelector<PortfolioItem>(
                  currentPortfolioId: _currentPortfolioId,
                  currentPortfolioName:
                      _currentPortfolioName ?? widget.selectedPortfolioName,
                  portfolios: [
                    const PortfolioItem(
                      portfolioId: 'all',
                      portfolioName: 'All Portfolios',
                    ),
                    ...widget.portfolios!,
                  ],
                  onPortfolioSelected: _onPortfolioChanged,
                  idExtractor: (p) => p.portfolioId,
                  nameExtractor: (p) => p.portfolioName,
                  accentColor: ModuleColors.portfolio,
                ),
              ),
            SecondarySidebarSection(
              title: '',
              items: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return SecondarySidebarItem(
                  title: item.title,
                  icon: item.icon,
                  // No Overview/Holdings highlight while on add-asset-class URL.
                  isSelected: !focusedAssetClass && currentIndex == index,
                  onTap: () => _navigateToTabSlug(_tabSlugs[index]),
                  accentColor: item.accentColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
