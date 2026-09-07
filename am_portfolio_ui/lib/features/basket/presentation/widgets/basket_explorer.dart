import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_library/am_library.dart';

import '../providers/basket_providers.dart';
import '../utils/basket_api_errors.dart';
import '../utils/discover_view_state.dart';
import '../basket_navigation.dart';
import '../../domain/models/basket_opportunity.dart';
import '../pages/my_baskets_view.dart';
import 'etf_search_bar.dart';
import 'discover/discover_baskets_table.dart';
import 'discover/discover_filter_bar.dart';
import 'discover/discover_layout.dart';
import 'discover/discover_mode_toggle.dart';
import 'discover/discover_opportunity_card.dart';
import 'discover/discover_section_headers.dart';
import 'discover/discover_states.dart';

export 'discover/discover_mode_toggle.dart';
export 'discover/discover_view_mode.dart';

class BasketExplorer extends ConsumerStatefulWidget {
  final String userId;
  final String portfolioId;

  /// When false, Discover/My Baskets lives in the portfolio sticky header.
  final bool showInlineToggle;

  const BasketExplorer({
    super.key,
    required this.userId,
    required this.portfolioId,
    this.showInlineToggle = true,
  });

  @override
  ConsumerState<BasketExplorer> createState() => _BasketExplorerState();
}

class _BasketExplorerState extends ConsumerState<BasketExplorer> {
  String? _query;
  String? _lastEmptyTelemetryQuery;
  String? _selectedThemeId;
  DiscoverViewState _discoverState = const DiscoverViewState();
  final ScrollController _discoverScroll = ScrollController();
  final GlobalKey _allBasketsKey = GlobalKey();
  final GlobalKey<EtfSearchBarState> _searchKey = GlobalKey<EtfSearchBarState>();

  bool get _watchOpportunities {
    final nested = BasketNavigation.navigatorKey.currentState;
    return nested == null || !nested.canPop();
  }

  @override
  void initState() {
    super.initState();
    BasketNavigation.registerMyBasketsListener(_showMyBasketsTab);
    BasketNavigation.viewMode.addListener(_onViewModeChanged);
  }

  @override
  void dispose() {
    _discoverScroll.dispose();
    BasketNavigation.viewMode.removeListener(_onViewModeChanged);
    BasketNavigation.unregisterMyBasketsListener();
    super.dispose();
  }

  void _onViewModeChanged() {
    if (mounted) setState(() {});
  }

  void _showMyBasketsTab() {
    if (mounted) setState(() {});
  }

  void _updateQuery({String? query, String? themeId}) {
    setState(() {
      _query = query;
      _selectedThemeId = themeId;
      _lastEmptyTelemetryQuery = null;
    });
  }

  void _clearAll() {
    _searchKey.currentState?.clear(notify: false);
    setState(() {
      _query = null;
      _selectedThemeId = null;
      _lastEmptyTelemetryQuery = null;
      _discoverState = const DiscoverViewState();
    });
  }

  void _scrollToAllBaskets() {
    final ctx = _allBasketsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }

  void _openPreview(BasketOpportunity opp) {
    ProductTelemetry.instance.featureAction(
      'basket_open_preview',
      tag: 'basket',
      metadata: {'etf_isin': opp.etfIsin},
    );
    BasketNavigation.openPreview(
      context,
      etfIsin: opp.etfIsin,
      userId: widget.userId,
      portfolioId: widget.portfolioId,
      opportunity: opp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(basketCatalogProvider);

    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => DiscoverErrorState(
        title: 'Couldn’t load baskets',
        message: basketApiErrorMessage(err),
        onRetry: () => ref.invalidate(basketCatalogProvider),
      ),
      data: (catalog) {
        final activeQuery = (_query != null && _query!.isNotEmpty)
            ? _query!
            : catalog.defaultQuery;
        if (activeQuery.isEmpty) {
          return DiscoverErrorState(
            title: 'Couldn’t load baskets',
            message: 'No default basket query is configured yet.',
            onRetry: () => ref.invalidate(basketCatalogProvider),
          );
        }

        final opportunitiesProvider = basketOpportunitiesProvider(
          userId: widget.userId,
          portfolioId: widget.portfolioId,
          query: activeQuery,
        );

        ref.listen<AsyncValue<List<BasketOpportunity>>>(
          opportunitiesProvider,
          (previous, next) {
            if (!_watchOpportunities) return;
            next.whenOrNull(
              data: (opportunities) {
                if (opportunities.isEmpty &&
                    _lastEmptyTelemetryQuery != activeQuery) {
                  _lastEmptyTelemetryQuery = activeQuery;
                  ProductTelemetry.instance
                      .emptyState('basket_opportunities_empty');
                } else if (opportunities.isNotEmpty) {
                  _lastEmptyTelemetryQuery = null;
                }
              },
            );
          },
        );

        final opportunitiesAsync = _watchOpportunities
            ? ref.watch(opportunitiesProvider)
            : ref.read(opportunitiesProvider);

        final themes = catalog.themes
            .where((t) => t.featured && t.query.isNotEmpty)
            .toList();
        final viewMode = BasketNavigation.viewMode.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showInlineToggle)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobileWidth =
                      constraints.maxWidth < AmBreakpoints.mobile;
                  // Mobile shell owns sticky toggle. Narrow web still needs
                  // exactly one toggle here (no sticky).
                  if (isMobileWidth) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BasketModeToggle(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Baskets',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Discover pre-built ETF portfolios and invest in market themes with one click.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Baskets',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Discover pre-built ETF portfolios and invest in market themes with one click.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const BasketModeToggle(compact: false),
                      ],
                    ),
                  );
                },
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Baskets',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discover pre-built ETF portfolios and invest in market themes with one click.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            if (viewMode == BasketViewMode.myBaskets)
              Expanded(
                child: MyBasketsView(
                  userId: widget.userId,
                  portfolioId: widget.portfolioId,
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: EtfSearchBar(
                  key: _searchKey,
                  onEtfSelected: (selection) {
                    if (selection.isin != null) {
                      if (selection.isin!.contains(',')) {
                        _updateQuery(query: selection.isin!, themeId: null);
                      } else {
                        BasketNavigation.openPreview(
                          context,
                          etfIsin: selection.isin!,
                          userId: widget.userId,
                          portfolioId: widget.portfolioId,
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selected ETF has no ISIN'),
                        ),
                      );
                    }
                  },
                  onCleared: () {
                    _updateQuery(query: catalog.defaultQuery, themeId: null);
                  },
                ),
              ),
              DiscoverFilterBar(
                themes: themes,
                defaultQuery: catalog.defaultQuery,
                selectedThemeId: _selectedThemeId,
                discoverState: _discoverState,
                onThemeSelect: ({query, themeId}) =>
                    _updateQuery(query: query, themeId: themeId),
                onPeriodChanged: (p) {
                  setState(() {
                    _discoverState = _discoverState.copyWith(period: p);
                  });
                },
                onSortChanged: (mode) {
                  setState(() {
                    _discoverState = _discoverState.copyWith(sort: mode);
                  });
                },
                onClearAll: _clearAll,
              ),
              const SizedBox(height: DiscoverLayout.filtersToContentGap),
              Expanded(
                child: opportunitiesAsync.when(
                  data: (opportunities) {
                    if (opportunities.isEmpty) {
                      return DiscoverEmptyState(
                        themeSelected: _selectedThemeId != null,
                        onReset: () {
                          _updateQuery(
                            query: catalog.defaultQuery,
                            themeId: null,
                          );
                        },
                        onRetry: () => ref.invalidate(opportunitiesProvider),
                      );
                    }
                    final displayList = _discoverState.apply(opportunities);
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile =
                            constraints.maxWidth < AmBreakpoints.mobile;
                        if (isMobile) {
                          final bottomInset =
                              PlatformConstants.globalBottomNavReserve(
                                    context,
                                  ) +
                                  AppSpacing.sm;
                          return ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              bottomInset,
                            ),
                            itemCount: displayList.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: DiscoverLayout.mobileListGap,
                                  ),
                                  child: Text(
                                    '${displayList.length} baskets',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                );
                              }
                              final opp = displayList[index - 1];
                              return DiscoverOpportunityCard(
                                opportunity: opp,
                                period: _discoverState.period,
                                compactList: true,
                                onTap: () => _openPreview(opp),
                              );
                            },
                          );
                        }

                        // Single Top picks row: 3 by default, 5 on wide desktop.
                        final topCount =
                            constraints.maxWidth >= AmBreakpoints.wideDesktop
                                ? 5
                                : 3;
                        final top = _discoverState.topPicks(
                          displayList,
                          limit: topCount,
                        );

                        return CustomScrollView(
                          controller: _discoverScroll,
                          slivers: [
                            SliverToBoxAdapter(
                              child: DiscoverTopPicksHeader(
                                onViewAll: _scrollToAllBaskets,
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: top.length.clamp(1, topCount),
                                  mainAxisExtent: DiscoverLayout.cardHeight,
                                  crossAxisSpacing: DiscoverLayout.gridGap,
                                  mainAxisSpacing: DiscoverLayout.gridGap,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final opp = top[index];
                                    return DiscoverOpportunityCard(
                                      opportunity: opp,
                                      period: _discoverState.period,
                                      onTap: () => _openPreview(opp),
                                    );
                                  },
                                  childCount: top.length,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: SizedBox(height: DiscoverLayout.sectionGap),
                            ),
                            SliverToBoxAdapter(
                              child: KeyedSubtree(
                                key: _allBasketsKey,
                                child: DiscoverAllBasketsHeader(
                                  count: displayList.length,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  0,
                                  AppSpacing.md,
                                  AppSpacing.lg,
                                ),
                                child: DiscoverBasketsTable(
                                  opportunities: displayList,
                                  period: _discoverState.period,
                                  periodColumnLabel:
                                      _discoverState.periodReturnColumnLabel,
                                  onPreview: _openPreview,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const DiscoverSkeletonGrid(),
                  error: (err, stack) => DiscoverErrorState(
                    title: 'Couldn’t load opportunities',
                    message: basketApiErrorMessage(err),
                    onRetry: () => ref.invalidate(opportunitiesProvider),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
