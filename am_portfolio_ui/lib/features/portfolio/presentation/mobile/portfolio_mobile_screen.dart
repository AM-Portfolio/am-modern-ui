import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/portfolio_actions_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../cubit/portfolio_analytics_cubit.dart';
import '../../providers/portfolio_providers.dart';
import '../../internal/domain/entities/portfolio_list.dart';
import '../../internal/data/dtos/portfolio_create_request_dto.dart';
import '../../internal/data/dtos/portfolio_update_request_dto.dart';
import 'widgets/portfolio_tab_content_widget.dart';
import 'widgets/portfolio_form_modal.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/xray_class_add_sheet.dart';

/// Mobile-optimized portfolio screen with bottom navigation and portfolio selection
class PortfolioMobileScreen extends ConsumerStatefulWidget {
  const PortfolioMobileScreen({
    super.key,
    this.selectedPortfolioId,
    this.selectedPortfolioName,
    this.portfolios,
    this.onPortfolioChanged,
    this.onBack,
    this.initialTab,
    this.onTabChanged,
    this.addTradeBuilder,
    this.uploadPortfolioBuilder,
    this.onOpenDocIntel,
  });
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final List<PortfolioItem>? portfolios;
  final Function(String portfolioId, String portfolioName)? onPortfolioChanged;
  final VoidCallback? onBack;
  final String? initialTab;
  final ValueChanged<String>? onTabChanged;
  final Widget Function(BuildContext context, String portfolioId, String? portfolioName, VoidCallback onComplete)? addTradeBuilder;
  final Widget Function(String portfolioId, String? portfolioName, VoidCallback onCancel)? uploadPortfolioBuilder;
  final VoidCallback? onOpenDocIntel;

  @override
  ConsumerState<PortfolioMobileScreen> createState() =>
      _PortfolioMobileScreenState();
}

class _PortfolioMobileScreenState extends ConsumerState<PortfolioMobileScreen> {
  @override
  Widget build(BuildContext context) {
    final portfolioServiceAsync = ref.watch(portfolioServiceProvider);

    return portfolioServiceAsync.when(
      data: (portfolioService) {
        final analyticsServiceAsync = ref.watch(
          portfolioAnalyticsServiceProvider,
        );

        return analyticsServiceAsync.when(
          data: (analyticsService) => BlocProvider(
            create: (context) => PortfolioAnalyticsCubit(analyticsService),
            child: PortfolioMobileView(
              selectedPortfolioId: widget.selectedPortfolioId,
              selectedPortfolioName: widget.selectedPortfolioName,
              portfolios: widget.portfolios,
              onPortfolioChanged: widget.onPortfolioChanged,
              onBack: widget.onBack,
              initialTab: widget.initialTab,
              onTabChanged: widget.onTabChanged,
              addTradeBuilder: widget.addTradeBuilder,
              uploadPortfolioBuilder: widget.uploadPortfolioBuilder,
              onOpenDocIntel: widget.onOpenDocIntel,
            ),
          ),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: context.statusError),
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
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: context.statusError),
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
      ),
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
    this.initialTab,
    this.onTabChanged,
    this.addTradeBuilder,
    this.uploadPortfolioBuilder,
    this.onOpenDocIntel,
  });
  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final List<PortfolioItem>? portfolios;
  final Function(String portfolioId, String portfolioName)? onPortfolioChanged;
  final VoidCallback? onBack;
  final String? initialTab;
  final ValueChanged<String>? onTabChanged;
  final Widget Function(BuildContext context, String portfolioId, String? portfolioName, VoidCallback onComplete)? addTradeBuilder;
  final Widget Function(String portfolioId, String? portfolioName, VoidCallback onCancel)? uploadPortfolioBuilder;
  final VoidCallback? onOpenDocIntel;

  @override
  State<PortfolioMobileView> createState() => _PortfolioMobileViewState();
}

class _PortfolioMobileViewState extends State<PortfolioMobileView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _currentPortfolioId;
  bool _isAddingTrade = false;
  bool _isUploadingPortfolio = false;
  bool _wasOnBasketsTab = false;

  bool _isBasketsTab(String? slug) => slug?.toLowerCase() == 'baskets';

  int _tabIndexFromSlug(String? slug) {
    switch (slug?.toLowerCase()) {
      case 'overview':
        return 0;
      case 'holdings':
        return 1;
      case 'heatmap':
        return 2;
      case 'baskets':
        return 3;
      case 'add-trade':
        return 3;
      default:
        return 0;
    }
  }

  String _tabSlugFromIndex(int index) {
    switch (index) {
      case 0:
        return 'overview';
      case 1:
        return 'holdings';
      case 2:
        return 'heatmap';
      case 3:
        return 'baskets';
      default:
        return 'overview';
    }
  }

  bool _isAddTradeSlug(String? slug) => slug?.toLowerCase() == 'add-trade';

  void _loadPortfolioDetailIfNeeded(PortfolioCubit cubit) {
    if (_currentPortfolioId == null) return;
    final currentState = cubit.state;
    if (currentState is PortfolioLoaded &&
        currentState.portfolioId == _currentPortfolioId) {
      return;
    }
    cubit.loadPortfolioById(_currentPortfolioId!);
  }

  @override
  void initState() {
    super.initState();
    final initialIndex = _tabIndexFromSlug(widget.initialTab);
    _isAddingTrade = _isAddTradeSlug(widget.initialTab);
    _wasOnBasketsTab = _isBasketsTab(widget.initialTab);
    _tabController = TabController(length: 4, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {});
        if (!_isAddingTrade) {
          final slug = _tabSlugFromIndex(_tabController.index);
          if (_wasOnBasketsTab && !_isBasketsTab(slug)) {
            _loadPortfolioDetailIfNeeded(context.read<PortfolioCubit>());
          }
          _wasOnBasketsTab = _isBasketsTab(slug);
          widget.onTabChanged?.call(slug);
        }
      }
    });
    _currentPortfolioId = widget.selectedPortfolioId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentPortfolioId != null && mounted) {
        final cubit = context.read<PortfolioCubit>();
        cubit.subscribeToPortfolioUpdates(
          portfolioId: _currentPortfolioId,
          forceResubscribe: true,
        );
        if (!_isBasketsTab(widget.initialTab)) {
          _loadPortfolioDetailIfNeeded(cubit);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant PortfolioMobileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPortfolioId != null &&
        widget.selectedPortfolioId != _currentPortfolioId) {
      setState(() => _currentPortfolioId = widget.selectedPortfolioId);
      final cubit = context.read<PortfolioCubit>()
        ..subscribeToPortfolioUpdates(
          portfolioId: widget.selectedPortfolioId,
          forceResubscribe: true,
        );
      if (!_isBasketsTab(widget.initialTab) && !_wasOnBasketsTab) {
        cubit.loadPortfolioById(widget.selectedPortfolioId!);
      }
    }

    if (widget.initialTab != oldWidget.initialTab) {
      final addTrade = _isAddTradeSlug(widget.initialTab);
      if (addTrade != _isAddingTrade) {
        setState(() => _isAddingTrade = addTrade);
      }
      if (!addTrade) {
        final newIndex = _tabIndexFromSlug(widget.initialTab);
        if (newIndex != _tabController.index) {
          _tabController.animateTo(newIndex);
        }
      }
      if (_isBasketsTab(oldWidget.initialTab) &&
          !_isBasketsTab(widget.initialTab)) {
        final id = _currentPortfolioId;
        if (id != null) {
          context.read<PortfolioCubit>().loadPortfolioById(id);
        }
      }
      _wasOnBasketsTab = _isBasketsTab(widget.initialTab);
    }
  }

  void _openAddTrade() {
    setState(() => _isAddingTrade = true);
    widget.onTabChanged?.call('add-trade');
  }

  void _selectTab(int index) {
    setState(() {
      _tabController.index = index;
      _isAddingTrade = false;
      _isUploadingPortfolio = false;
    });
    final slug = _tabSlugFromIndex(index);
    if (_wasOnBasketsTab && !_isBasketsTab(slug)) {
      _loadPortfolioDetailIfNeeded(context.read<PortfolioCubit>());
    }
    _wasOnBasketsTab = _isBasketsTab(slug);
    widget.onTabChanged?.call(slug);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPortfolioChanged(String portfolioId, String portfolioName) {
    setState(() => _currentPortfolioId = portfolioId);
    if (!_isBasketsTab(widget.initialTab) && !_wasOnBasketsTab) {
      context.read<PortfolioCubit>().loadPortfolioById(portfolioId);
    }
    widget.onPortfolioChanged?.call(portfolioId, portfolioName);
  }

  void _showAddPortfolioModal() {
    PortfolioFormModal.show(
      context: context,
      onSubmit: (name, desc) async {
        final request = PortfolioCreateRequestDto(
          name: name,
          description: desc,
          currency: 'INR',
          initialCapital: 0,
        );
        await context.read<PortfolioCubit>().createPortfolio(request);
      },
    );
  }

  void _showEditPortfolioModal(PortfolioItem portfolio) {
    PortfolioFormModal.show(
      context: context,
      portfolio: portfolio,
      onSubmit: (name, desc) async {
        final request = PortfolioUpdateRequestDto(
          name: name,
          description: desc,
          currency: 'INR',
        );
        await context.read<PortfolioCubit>().updatePortfolio(
              portfolio.portfolioId,
              request,
            );
      },
    );
  }

  void _deletePortfolio(PortfolioItem portfolio) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Portfolio'),
        content: Text(
          'Are you sure you want to delete "${portfolio.portfolioName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.statusError),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<PortfolioCubit>().deletePortfolio(portfolio.portfolioId);
    }
  }

  /// Mobile FAB — shows a bottom sheet with quick portfolio actions.
  /// Only rendered when a specific portfolio (not 'all') is selected.
  Widget _buildMobileFab() {
    if (_currentPortfolioId == null || _currentPortfolioId == 'all') {
      return const SizedBox.shrink();
    }
    return FloatingActionButton(
      backgroundColor: ModuleColors.portfolio,
      foregroundColor: Colors.white,
      tooltip: 'Quick Actions',
      onPressed: () {
        showPortfolioActionsSheet(
          context: context,
          triggerColor: ModuleColors.portfolio,
          actions: [
            FloatingMenuAction(
              icon: Icons.upload_file_rounded,
              title: 'Upload Portfolio',
              subtitle: 'Import from file or broker',
              iconColor: ModuleColors.portfolio,
              onTap: () {
                if (_isUploadingPortfolio) return;
                if (widget.uploadPortfolioBuilder != null) {
                  setState(() {
                    _isUploadingPortfolio = true;
                    _isAddingTrade = false;
                  });
                } else if (widget.onOpenDocIntel != null) {
                  widget.onOpenDocIntel!();
                }
              },
            ),
            FloatingMenuAction(
              icon: Icons.add_circle_outline_rounded,
              title: 'Add Trade',
              subtitle: 'Buy or sell an asset',
              iconColor: ModuleColors.trade,
              onTap: () {
                if (!_isAddingTrade) _openAddTrade();
              },
            ),
            FloatingMenuAction(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Add Asset Class',
              subtitle: 'Create a new asset class',
              iconColor: ModuleColors.market,
              onTap: () {
                showXrayClassAddSheet(
                  context: context,
                  portfolioId: _currentPortfolioId!,
                  onSaved: () {},
                );
              },
            ),
            FloatingMenuAction(
              icon: Icons.shopping_basket_outlined,
              title: 'Add Basket',
              subtitle: 'Create a new basket',
              iconColor: ModuleColors.reports,
              onTap: () {
                _selectTab(3);
              },
            ),
          ],
        );
      },
      child: const Icon(Icons.add_rounded),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPortfolioId == null) {
      return const Scaffold(
        body: Center(child: Text('Select a portfolio to continue')),
      );
    }

    String currentName = 'Select Portfolio';
    if (_currentPortfolioId == 'all') {
      currentName = 'All Portfolios';
    } else if (_currentPortfolioId != null && widget.portfolios != null) {
      final match = widget.portfolios!.where(
        (p) => p.portfolioId == _currentPortfolioId,
      );
      if (match.isNotEmpty) {
        currentName = match.first.portfolioName;
      }
    }

    return BlocListener<PortfolioCubit, PortfolioState>(
      listener: (context, state) {
        if (state is PortfolioError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: context.statusError,
            ),
          );
        }
      },
      child: UnifiedSidebarScaffold(
        module: ModuleType.portfolio,
        title: currentName,
        showModuleBottomNavigation: false,
        showAppBarOnMobile: false,
        showMobileMenuButton: false,
        autoHideMobileTabsOnScroll: true,
        onBackToGlobal: widget.onBack,
        mobileStickyHeader: _tabController.index == 3
            ? null // BasketExplorer owns Discover / My Baskets (avoid duplicate)
            : _buildStickyControlsRow(context, currentName),
        items: [
          SecondarySidebarItem(
            title: 'Overview',
            icon: Icons.dashboard_outlined,
            isSelected: _tabController.index == 0 && !_isAddingTrade && !_isUploadingPortfolio,
            onTap: () => _selectTab(0),
          ),
          SecondarySidebarItem(
            title: 'Holdings',
            icon: Icons.wallet,
            isSelected: _tabController.index == 1 && !_isAddingTrade && !_isUploadingPortfolio,
            onTap: () => _selectTab(1),
          ),
          SecondarySidebarItem(
            title: 'Heatmap',
            icon: Icons.grid_view,
            isSelected: _tabController.index == 2 && !_isAddingTrade && !_isUploadingPortfolio,
            onTap: () => _selectTab(2),
          ),
          SecondarySidebarItem(
            title: 'Baskets',
            icon: Icons.shopping_basket_outlined,
            isSelected: _tabController.index == 3 && !_isAddingTrade && !_isUploadingPortfolio,
            onTap: () => _selectTab(3),
          ),
        ],
        body: (_isAddingTrade &&
                widget.addTradeBuilder != null &&
                _currentPortfolioId != null)
            ? widget.addTradeBuilder!(
                context,
                _currentPortfolioId!,
                currentName,
                () {
                  setState(() {
                    _isAddingTrade = false;
                  });
                },
              )
            : (_isUploadingPortfolio &&
                widget.uploadPortfolioBuilder != null &&
                _currentPortfolioId != null)
                ? widget.uploadPortfolioBuilder!(
                    _currentPortfolioId!,
                    currentName,
                    () {
                      setState(() {
                        _isUploadingPortfolio = false;
                      });
                    },
                  )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.portfolios != null &&
                        widget.portfolios!.any((p) => p.isDummy))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        // Sticky row already has Doc Intel / Add — no second Upload.
                        child: const DemoAccountInlineBanner(),
                      ),
                    Expanded(
                      child: PortfolioTabContentWidget(
                        tabController: _tabController,
                        currentPortfolioId: _currentPortfolioId!,
                      ),
                    ),
                  ],
                ),
        floatingActionButton: _buildMobileFab(),
      ),
    );
  }

  Widget _buildStickyControlsRow(BuildContext context, String currentName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = context.textPrimary;
    final chipBg = isDark
        ? context.glassOverlay(0.08)
        : const Color(0xFFEDE9FE);
    final chipBorder = isDark
        ? context.glassOverlay(0.12)
        : const Color(0xFFDDD6FE);

    Widget actionChip({
      required VoidCallback onTap,
      required IconData icon,
      required String label,
      Color? iconColor,
      bool iconOnly = false,
    }) {
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: iconOnly ? 8 : 8),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: chipBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: iconColor ?? onSurface),
                if (!iconOnly) ...[
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
        child: Row(
          children: [
            // Shrinks first when space is tight — never nest Flexible+min Rows.
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 128),
                  child: _buildPortfolioSwitcher(context, currentName),
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (widget.onOpenDocIntel != null) ...[
              actionChip(
                onTap: widget.onOpenDocIntel!,
                icon: Icons.psychology_outlined,
                iconColor: const Color(0xFF00D2D3),
                label: 'Doc Intel',
                iconOnly: true,
              ),
              const SizedBox(width: 6),
            ],
            if (_currentPortfolioId != null && _currentPortfolioId != 'all')
              _buildPortfolioMenu(context),
            GlobalTimeFrameBar(
              variant: GlobalTimeFrameVariant.dropdown,
              primaryColor: ModuleColors.portfolio,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioSwitcher(BuildContext context, String currentName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final portfolios = widget.portfolios ?? const [];
    final selectedId = _currentPortfolioId ?? 'all';

    final items = <DropdownMenuItem<String>>[
      'all'.toSimpleDropdownItem(text: 'All Portfolios', fontSize: 12),
      ...portfolios.map(
        (p) => p.portfolioId.toSimpleDropdownItem(
          text: p.portfolioName,
          fontSize: 12,
        ),
      ),
    ];

    final hasSelection = items.any((item) => item.value == selectedId);

    return CustomDropdown<String>(
      value: hasSelection ? selectedId : 'all',
      height: 36,
      isExpanded: true,
      fontSize: 12,
      iconSize: 16,
      borderRadius: 10,
      menuMaxHeight: 148,
      primaryColor: ModuleColors.portfolio,
      backgroundColor: isDark ? context.glassOverlay(0.06) : null,
      borderColor: isDark ? context.glassOverlay(0.1) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      items: items,
      onChanged: (id) {
        if (id == null) return;
        var name = currentName;
        if (id == 'all') {
          name = 'All Portfolios';
        } else {
          for (final p in portfolios) {
            if (p.portfolioId == id) {
              name = p.portfolioName;
              break;
            }
          }
        }
        _onPortfolioChanged(id, name);
      },
    );
  }

  Widget _buildPortfolioMenu(BuildContext context) {
    final portfolios = widget.portfolios ?? const [];
    final portfolio = portfolios
        .where((p) => p.portfolioId == _currentPortfolioId)
        .firstOrNull;

    if (portfolio == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        if (value == 'edit') {
          _showEditPortfolioModal(portfolio);
        } else if (value == 'delete') {
          _deletePortfolio(portfolio);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit Portfolio'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: context.statusError),
              const SizedBox(width: 8),
              Text('Delete Portfolio', style: TextStyle(color: context.statusError)),
            ],
          ),
        ),
      ],
    );
  }
}
