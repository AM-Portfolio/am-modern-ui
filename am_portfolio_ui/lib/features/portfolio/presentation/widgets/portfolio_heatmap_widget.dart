import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart'
    hide MarketCapType, MetricType, TimeFrame, SectorType;
import 'package:am_design_system/core/utils/string_utils.dart';
import '../cubit/portfolio_analytics_cubit.dart';
import '../cubit/portfolio_analytics_state.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_heatmap_cubit.dart';
import '../cubit/portfolio_heatmap_state.dart';
import '../cubit/portfolio_state.dart';
import '../mappers/sector_heatmap_converter.dart';
import 'portfolio_metric_card.dart';


/// Platform UI settings for the portfolio heatmap page widget
/// (distinct from presentation/config/portfolio_heatmap_config.dart).
class PortfolioHeatmapUiConfig {
  const PortfolioHeatmapUiConfig({
    required this.defaultLayout,
    required this.compactMode,
    required this.showSelectors,
    required this.templateType,
    required this.showSubCards,
    required this.padding,
    required this.title,
    required this.subtitle,
    this.logTag = 'PortfolioHeatmap',
  });

  final HeatmapLayoutType defaultLayout;
  final bool compactMode;
  final bool showSelectors;
  final UniversalTemplateType templateType;
  final bool showSubCards;
  final EdgeInsets padding;
  final String title;
  final String subtitle;
  final String logTag;

  /// Mobile configuration — List by default so every sector stays readable.
  static const mobile = PortfolioHeatmapUiConfig(
    defaultLayout: HeatmapLayoutType.list,
    compactMode: true,
    showSelectors: true,
    templateType: UniversalTemplateType.compact,
    showSubCards: false,
    padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
    title: 'Heatmap Overview',
    subtitle: '', // Completely removed the down side text
    logTag: 'PortfolioHeatmap.Mobile',
  );

  /// Web configuration
  static const web = PortfolioHeatmapUiConfig(
    defaultLayout: HeatmapLayoutType.treemap,
    compactMode: false,
    showSelectors: true,
    templateType: UniversalTemplateType.full,
    showSubCards: true,
    padding: EdgeInsets.all(16.0),
    title: 'Heatmap Overview',
    subtitle: '',
    logTag: 'PortfolioHeatmap.Web',
  );
}

/// Common Portfolio Heatmap Widget
/// Shared implementation between web and mobile with configurable behavior
class PortfolioHeatmapWidget extends ConsumerStatefulWidget {
  const PortfolioHeatmapWidget({
    required this.portfolioId,
    required this.config,
    super.key,
    this.portfolioName,
  });

  final String portfolioId;
  final String? portfolioName;
  final PortfolioHeatmapUiConfig config;

  @override
  ConsumerState<PortfolioHeatmapWidget> createState() =>
      _PortfolioHeatmapWidgetState();
}

class _PortfolioHeatmapWidgetState
    extends ConsumerState<PortfolioHeatmapWidget> {
  // Current selections with config-based defaults
  late MetricType _selectedMetric;
  SectorType? _selectedSector;
  MarketCapType? _selectedMarketCap;
  late HeatmapLayoutType _selectedLayout;
  HeatmapTileData? _drillDownTile;
  int _heatmapLoadGeneration = 0;

  @override
  void initState() {
    super.initState();

    // Initialize with config defaults
    _selectedMetric = MetricType.changePercent;
    _selectedLayout = widget.config.defaultLayout;

    CommonLogger.info(
      'PortfolioHeatmapWidget initialized',
      tag: '${widget.config.logTag}.Init',
    );
    CommonLogger.debug(
      'Parameters: portfolioId=${widget.portfolioId}, portfolioName=${widget.portfolioName ?? 'null'}',
      tag: '${widget.config.logTag}.Init',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadHeatmapData();
    });
  }

  @override
  void didUpdateWidget(PortfolioHeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.defaultLayout != widget.config.defaultLayout &&
        _selectedLayout == oldWidget.config.defaultLayout) {
      setState(() => _selectedLayout = widget.config.defaultLayout);
    }
  }

  void _loadHeatmapData() {
    final selectedTimeframe = ref.read(appTimeFrameProvider);
    final loadGen = ++_heatmapLoadGeneration;
    CommonLogger.methodEntry(
      '_loadHeatmapData',
      tag: '${widget.config.logTag}.Data',
      metadata: {
        'portfolioId': widget.portfolioId,
        'timeFrame': selectedTimeframe.name,
        'metric': _selectedMetric.name,
        'sector': _selectedSector?.name ?? 'all',
        'marketCap': _selectedMarketCap?.name ?? 'all',
        'loadGen': loadGen,
      },
    );

    final portfolioAnalyticsCubit = context.read<PortfolioAnalyticsCubit>();
    final portfolioHeatmapCubit = context.read<PortfolioHeatmapCubit>();

    // Load analytics data first
    portfolioAnalyticsCubit
        .loadAnalytics(widget.portfolioId, timeFrame: selectedTimeframe)
        .then((_) {
          if (!mounted || loadGen != _heatmapLoadGeneration) return;
          final analyticsState = portfolioAnalyticsCubit.state;
          if (analyticsState is PortfolioAnalyticsError) {
            CommonLogger.error(
              'Analytics failed, skipping heatmap data load',
              tag: '${widget.config.logTag}.Data',
            );
            portfolioHeatmapCubit.showError('Failed to load portfolio data. Please retry.');
            return;
          }

          CommonLogger.info(
            'Analytics loaded, proceeding with heatmap data',
            tag: '${widget.config.logTag}.Data',
          );

          portfolioHeatmapCubit.loadHeatmapData(
            portfolioId: widget.portfolioId,
            timeFrame: selectedTimeframe,
            metric: _selectedMetric,
            sector: _selectedSector ?? SectorType.all,
            marketCap: _selectedMarketCap ?? MarketCapType.all,
            analyticsCubit: portfolioAnalyticsCubit,
          );
        })
        .catchError((error) {
          if (!mounted || loadGen != _heatmapLoadGeneration) return;
          CommonLogger.error(
            'Analytics failed, using fallback',
            tag: '${widget.config.logTag}.Data',
            error: error,
          );

          portfolioHeatmapCubit.loadHeatmapData(
            portfolioId: widget.portfolioId,
            timeFrame: selectedTimeframe,
            metric: _selectedMetric,
            sector: _selectedSector ?? SectorType.all,
            marketCap: _selectedMarketCap ?? MarketCapType.all,
            analyticsCubit: portfolioAnalyticsCubit,
          );
        });

    CommonLogger.methodExit(
      '_loadHeatmapData',
      tag: '${widget.config.logTag}.Data',
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appTimeFrameProvider, (previous, next) {
      if (previous != next) _loadHeatmapData();
    });
    ref.watch(appTimeFrameProvider);

    // Wrap in LayoutBuilder so _buildLoadedWidget always receives a bounded
    // height constraint — without this, Expanded inside the Column gets 0.
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Padding(
          padding: widget.config.padding,
          child: _buildHeatmapContent(),
        );
        return widget.config.compactMode
            ? SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : MediaQuery.sizeOf(context).height,
                child: content,
              )
            : SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : double.infinity,
                child: content,
              );
      },
    );
  }

  /// Main heatmap content with state handling using dual cubit approach
  Widget _buildHeatmapContent() => MultiBlocListener(
    listeners: [
      BlocListener<PortfolioCubit, PortfolioState>(
        listenWhen: (previous, current) {
          if (previous is PortfolioLoaded && current is PortfolioLoaded) {
            // Only trigger if live data is active and todayChange has updated
            return current.isLiveDataActive && 
                   previous.summary.todayChangePercentage != current.summary.todayChangePercentage;
          }
          return false;
        },
        listener: (context, state) {
          if (state is PortfolioLoaded && state.isLiveDataActive) {
            // Live data updated, refresh the heatmap UI
            CommonLogger.info('Live data update detected, refreshing heatmap', tag: widget.config.logTag);
            // Re-trigger the heatmap load. We don't need to fetch new analytics,
            // we just need the cubit to emit a new state so the UI updates.
            final portfolioHeatmapCubit = context.read<PortfolioHeatmapCubit>();
            portfolioHeatmapCubit.refresh();
          }
        },
      ),
    ],
    child: BlocBuilder<PortfolioHeatmapCubit, PortfolioHeatmapState>(
      builder: (context, state) {
        CommonLogger.debug(
          'State update: ${state.runtimeType}',
          tag: '${widget.config.logTag}.State',
        );

        return _buildStateWidget(state);
      },
    ),
  );

  /// Routes to appropriate widget based on current state
  Widget _buildStateWidget(PortfolioHeatmapState state) {
    if (state is PortfolioHeatmapLoading) {
      return _buildLoadingWidget(state);
    }

    if (state is PortfolioHeatmapError) {
      return _buildErrorWidget(state);
    }

    if (state is PortfolioHeatmapLoaded) {
      return _buildLoadedWidget(state);
    }

    if (state is PortfolioHeatmapEmpty) {
      return _buildEmptyWidget(state);
    }

    return _buildDefaultWidget();
  }

  /// Builds loading state UI
  Widget _buildLoadingWidget(PortfolioHeatmapLoading state) {
    CommonLogger.info(
      'Showing loading: ${state.message ?? "Loading..."}',
      tag: '${widget.config.logTag}.UI',
    );

    return const Center(child: CircularProgressIndicator());
  }

  /// Builds error state UI
  Widget _buildErrorWidget(PortfolioHeatmapError state) {
    CommonLogger.warning(
      'Showing error: ${state.message}',
      tag: '${widget.config.logTag}.UI',
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            if (state.details != null) ...[
              const SizedBox(height: 8),
              Text(
                state.details!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHeatmapData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds loaded state UI with heatmap
  Widget _buildLoadedWidget(PortfolioHeatmapLoaded state) {
    final selectedTimeFrame = ref.watch(appTimeFrameProvider);
    CommonLogger.info(
      'Showing heatmap: ${state.heatmapData.tiles.length} tiles',
      tag: '${widget.config.logTag}.UI',
    );

    final convertedHeatmapData = state.heatmapData;

    // Create configuration with selected layout
    final baseSelectors = convertedHeatmapData.configuration.selectors ??
        const SelectorConfig();
    final baseLayout = convertedHeatmapData.configuration.layout ??
        const LayoutConfig();
    final customConfig = convertedHeatmapData.configuration.copyWith(
      display: convertedHeatmapData.configuration.display?.copyWith(
        showPerformance: false, // Hides old default legend
      ),
      layout: baseLayout.copyWith(
        layoutType: _selectedLayout,
        showLayoutSelector: widget.config.compactMode ? true : null,
      ),
      selectors: baseSelectors.copyWith(
        selectorLayout:
            widget.config.compactMode ? SelectorLayoutType.compact : null,
        showSectorSelector: widget.config.compactMode ? true : null,
        showMarketCapSelector: widget.config.compactMode ? true : null,
        showTimeFrameSelector: widget.config.compactMode ? false : null,
        showMetricSelector: widget.config.compactMode ? false : null,
      ),
    );

    // Drill-down filtering + treemap small-weight merge + per-tile tap
    var workingTiles = convertedHeatmapData.tiles
        .map((t) => t is HeatmapTileData ? t : HeatmapTileData.fromEntity(t))
        .toList();

    if (_drillDownTile != null && _drillDownTile!.children != null) {
      workingTiles = _drillDownTile!.children!
          .map((t) => t is HeatmapTileData ? t : HeatmapTileData.fromEntity(t))
          .toList();
    } else if (_selectedLayout == HeatmapLayoutType.treemap) {
      workingTiles =
          SectorHeatmapConverter.mergeSmallWeightTilesForTreemap(workingTiles);
    }

    workingTiles = workingTiles.map((tile) {
      final hasChildren = tile.children != null && tile.children!.isNotEmpty;
      if (!hasChildren) return tile;
      return HeatmapTileData(
        id: tile.id,
        name: tile.name,
        displayName: tile.displayName,
        weightage: tile.weightage,
        performance: tile.performance,
        value: tile.value,
        metadata: tile.metadata,
        children: tile.children,
        customColor: tile.customColor,
        icon: tile.icon,
        imageUrl: tile.imageUrl,
        onTap: () {
          CommonLogger.userAction(
            'Heatmap drill-down: ${tile.name}',
            tag: '${widget.config.logTag}.Action',
          );
          setState(() => _drillDownTile = tile);
        },
        customWidgets: tile.customWidgets,
      );
    }).toList();

    final displayData = convertedHeatmapData.copyWith(tiles: workingTiles);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SUMMARY CARDS ROW ──
        _buildSummaryCardsRow(),
        const SizedBox(height: 16),

        // ── EQUITY DISTRIBUTION HEADER (web/desktop only) ──
        if (!widget.config.compactMode) ...[
          _buildEquityDistributionHeader(context),
          const SizedBox(height: 12),
        ],

        // ── DRILLDOWN BREADCRUMB ──
        if (_drillDownTile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => setState(() => _drillDownTile = null),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16, color: ModuleColors.portfolio),
                  const SizedBox(width: 4),
                  Text(
                    'Portfolio > ${_drillDownTile!.displayName}',
                    style: TextStyle(
                      color: ModuleColors.portfolio,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── MAIN HEATMAP (fills remaining tab height on mobile) ──
        if (widget.config.compactMode)
          Expanded(
            child: UniversalHeatmapWidget(
              investmentType: InvestmentType.portfolio,
              heatmapData: displayData,
              title: 'Heatmap',
              subtitle: null,
              config: _mapToWidgetConfig(customConfig),
              showSelectors: true,
              compactMode: widget.config.compactMode,
              selectedTimeFrame: selectedTimeFrame,
              selectedMetric: _selectedMetric,
              selectedSector: _selectedSector,
              selectedMarketCap: _selectedMarketCap,
              selectedLayout: _selectedLayout,
              onTilePressed: () {
                CommonLogger.userAction(
                  'Heatmap stock tile pressed',
                  tag: '${widget.config.logTag}.Action',
                );
              },
              onFiltersChanged: ({timeFrame, metric, sector, marketCap, layout}) {
                _onFiltersChanged(
                  timeFrame: timeFrame,
                  metric: metric,
                  sector: sector,
                  marketCap: marketCap,
                  layout: layout,
                );
              },
              templateType: widget.config.templateType,
            ),
          )
        else
          // Web: fill all remaining vertical space dynamically to keep it single-page.
          Expanded(
            child: LayoutBuilder(
              builder: (context, heatmapConstraints) {
                final heatmapContent = SizedBox(
                  width: double.infinity,
                  height: heatmapConstraints.maxHeight,
                  child: UniversalHeatmapWidget(
                    investmentType: InvestmentType.portfolio,
                    heatmapData: displayData,
                    title: widget.config.title,
                    subtitle: widget.config.subtitle,
                    config: _mapToWidgetConfig(customConfig),
                    showSelectors: false,
                    compactMode: widget.config.compactMode,
                    selectedTimeFrame: selectedTimeFrame,
                    selectedMetric: _selectedMetric,
                    selectedSector: _selectedSector,
                    selectedMarketCap: _selectedMarketCap,
                    selectedLayout: _selectedLayout,
                    onTilePressed: () {
                      CommonLogger.userAction(
                        'Heatmap stock tile pressed',
                        tag: '${widget.config.logTag}.Action',
                      );
                    },
                    onFiltersChanged: ({timeFrame, metric, sector, marketCap, layout}) {
                      _onFiltersChanged(
                        timeFrame: timeFrame,
                        metric: metric,
                        sector: sector,
                        marketCap: marketCap,
                        layout: layout,
                      );
                    },
                    templateType: widget.config.templateType,
                  ),
                );
                
                return heatmapContent;
              },
            ),
          ),

      ],
    );
  }

  /// Builds the 4 summary stat cards row
  Widget _buildSummaryCardsRow() {
    return BlocBuilder<PortfolioCubit, PortfolioState>(
      builder: (context, portfolioState) {
        // Derive values from portfolio state (exact ₹ on Heatmap page only)
        String totalValue = '--';
        String todayChange = '--';
        double todayChangePct = 0;
        bool isTodayPositive = true;
        final selectedTf = ref.watch(appTimeFrameProvider);
        // Day P&L from overview until advanced attaches period P&L.
        final changeCardTitle = selectedTf == TimeFrame.oneDay
            ? 'TODAY'
            : 'TODAY (day)';

        if (portfolioState is PortfolioLoaded) {
          final summary = portfolioState.summary;
          totalValue = StringUtils.formatCurrencyExact(summary.totalValue);
          todayChange = StringUtils.formatCurrencyExact(summary.todayChange);
          todayChangePct = summary.todayChangePercentage;
          isTodayPositive = summary.isTodayPositive;
        }

        // Top/Weakest from visible filtered heatmap tiles
        return BlocBuilder<PortfolioHeatmapCubit, PortfolioHeatmapState>(
          builder: (context, heatmapState) {
            String topSector = '--';
            String topSectorChange = '';
            String worstSector = '--';
            String worstSectorChange = '';

            if (heatmapState is PortfolioHeatmapLoaded) {
              final summary = SectorHeatmapConverter.resolveSectorSummary(
                tiles: heatmapState.heatmapData.uiTiles,
              );
              topSector = summary.topSector;
              topSectorChange = summary.topSectorChange;
              worstSector = summary.worstSector;
              worstSectorChange = summary.worstSectorChange;
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final isSmallMobile = constraints.maxWidth < 600;
                final cards = [
                  PortfolioMetricCard(
                    title: 'TOTAL VALUE',
                    value: totalValue,
                    subtitle: '',
                    accentColor: context.marketPositive,
                    chromeColor: ModuleColors.portfolio,
                    compact: isSmallMobile,
                    glowBorder: true,
                  ),
                  PortfolioMetricCard(
                    title: changeCardTitle,
                    value: todayChange,
                    subtitle: todayChangePct.abs() < 0.005
                        ? '0.00%'
                        : '${isTodayPositive ? '+' : ''}${todayChangePct.toStringAsFixed(2)}%',
                    accentColor: isTodayPositive
                        ? context.marketPositive
                        : context.marketNegative,
                    chromeColor: ModuleColors.portfolio,
                    isPositive: isTodayPositive,
                    compact: isSmallMobile,
                    glowBorder: true,
                  ),
                  PortfolioMetricCard(
                    title: 'TOP SECTOR',
                    value: topSector,
                    subtitle: topSectorChange,
                    accentColor: topSectorChange.startsWith('-')
                        ? context.marketNegative
                        : context.marketPositive,
                    chromeColor: ModuleColors.portfolio,
                    isPositive: !topSectorChange.startsWith('-'),
                    compact: isSmallMobile,
                    glowBorder: true,
                  ),
                  PortfolioMetricCard(
                    title: 'WEAKEST SECTOR',
                    value: worstSector,
                    subtitle: worstSectorChange,
                    accentColor: worstSectorChange.isEmpty
                        ? ModuleColors.portfolio
                        : (worstSectorChange.startsWith('-')
                            ? context.marketNegative
                            : context.marketPositive),
                    chromeColor: ModuleColors.portfolio,
                    isPositive: worstSectorChange.isEmpty
                        ? null
                        : !worstSectorChange.startsWith('-'),
                    compact: isSmallMobile,
                    glowBorder: true,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: cards
                        .map((c) => Expanded(child: c))
                        .toList()
                        .expand((w) => [w, const SizedBox(width: 12)])
                        .toList()
                      ..removeLast(),
                  );
                } else {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: cards
                        .map(
                          (c) => SizedBox(
                            width: (constraints.maxWidth - 12) / 2,
                            child: c,
                          ),
                        )
                        .toList(),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  /// Builds the "Equity Distribution" header with perfectly aligned title, filters, and timeframe.
  Widget _buildEquityDistributionHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 950;

        final titleWidget = Container(
          height: 40,
          alignment: Alignment.centerLeft,
          child: Text(
            'Equity Distribution',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        );

        final filterRow = _buildFilterRow(context, isCompact: isNarrow);

        final timeframeBar = Container(
          height: 40,
          alignment: Alignment.centerRight,
          child: GlobalTimeFrameBar(
            variant: isNarrow
                ? GlobalTimeFrameVariant.dropdown
                : GlobalTimeFrameVariant.pills,
            primaryColor: ModuleColors.portfolio,
            availableTimeFrames: TimeFrame.heatmapTimeFrames,
          ),
        );

        if (isNarrow) {
          return Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              titleWidget,
              filterRow,
              timeframeBar,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Title
            titleWidget,
            
            const SizedBox(width: 20),
            
            // Center-left: Filters grouped beside title
            filterRow,
            
            const Spacer(),
            
            // Right: Timeframe Pills
            timeframeBar,
          ],
        );
      },
    );
  }

  Widget _buildFilterRow(BuildContext context, {bool isCompact = false}) {
    final dropWidth = isCompact ? 130.0 : 150.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sector Filter
        SizedBox(
          width: dropWidth,
          child: CustomDropdown<SectorType>(
            value: _selectedSector ?? SectorType.all,
            items: SectorType.values
                .map((item) => item.toDropdownItem(
                    text: item.displayName, icon: Icons.category_outlined))
                .toList(),
            onChanged: (val) {
              if (val != null) _onFiltersChanged(sector: val);
            },
            isExpanded: true,
            primaryColor: ModuleColors.portfolio,
          ),
        ),
        const SizedBox(width: 8),
        // Market Cap Filter
        SizedBox(
          width: dropWidth,
          child: CustomDropdown<MarketCapType>(
            value: _selectedMarketCap ?? MarketCapType.all,
            items: MarketCapType.values
                .map((item) => item.toDropdownItem(
                    text: item.displayName, icon: Icons.pie_chart_outline))
                .toList(),
            onChanged: (val) {
              if (val != null) _onFiltersChanged(marketCap: val);
            },
            isExpanded: true,
            primaryColor: ModuleColors.portfolio,
          ),
        ),
        const SizedBox(width: 8),
        // Layout Filter
        SizedBox(
          width: dropWidth,
          child: CustomDropdown<HeatmapLayoutType>(
            value: _selectedLayout,
            items: HeatmapLayoutType.values
                .map((item) => item.toDropdownItem(
                    text: item.displayName, icon: Icons.grid_view_outlined))
                .toList(),
            onChanged: (val) {
              if (val != null) _onFiltersChanged(layout: val);
            },
            isExpanded: true,
            primaryColor: ModuleColors.portfolio,
          ),
        ),
      ],
    );
  }



  /// Builds empty state UI
  Widget _buildEmptyWidget(PortfolioHeatmapEmpty state) {
    CommonLogger.info(
      'Showing empty state: ${state.message}',
      tag: '${widget.config.logTag}.UI',
    );

    final iconSize = widget.config.compactMode ? 64.0 : 80.0;
    final textSize = widget.config.compactMode ? 16.0 : 18.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: iconSize, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              state.message,
              style: TextStyle(fontSize: textSize, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some investments to see the ${widget.config.compactMode ? '' : 'portfolio '}heatmap',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds default/fallback state UI
  Widget _buildDefaultWidget() {
    CommonLogger.debug(
      'Showing default state (initial)',
      tag: '${widget.config.logTag}.UI',
    );

    final iconSize = widget.config.compactMode ? 48.0 : 64.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: iconSize, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Loading ${widget.config.compactMode ? '' : 'portfolio '}data...',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHeatmapData,
            child: Text(
              'Load ${widget.config.compactMode ? '' : 'Portfolio '}Heatmap',
            ),
          ),
        ],
      ),
    );
  }

  /// Handles filter changes from heatmap selectors
  void _onFiltersChanged({
    TimeFrame? timeFrame,
    MetricType? metric,
    SectorType? sector,
    MarketCapType? marketCap,
    HeatmapLayoutType? layout,
  }) {
    CommonLogger.debug(
      'Filters: timeFrame=${timeFrame?.code}, metric=${metric?.name}, sector=${sector?.name}, marketCap=${marketCap?.name}, layout=${layout?.name}',
      tag: '${widget.config.logTag}.Filter',
    );

    // Update local state
    if (timeFrame != null) {
      ref.read(appTimeFrameProvider.notifier).setTimeFrame(timeFrame);
    }
    if (metric != null) {
      setState(() {
        _selectedMetric = metric;
      });
    }
    if (sector != null) {
      setState(() {
        _selectedSector = sector;
      });
    }
    if (marketCap != null) {
      setState(() {
        _selectedMarketCap = marketCap;
      });
    }
    if (layout != null) {
      setState(() {
        _selectedLayout = layout;
      });
      CommonLogger.info(
        'Layout changed to: ${layout.name}',
        tag: '${widget.config.logTag}.Layout',
      );
    }

    // Sector/market-cap need client-side refilter. Layout/metric are UI-only.
    // Timeframe reloads via appTimeFrameProvider listen.
    if (sector != null || marketCap != null) {
      _loadHeatmapData();
    }
  }

  HeatmapConfig _mapToWidgetConfig(HeatmapConfig modelConfig) {
    return modelConfig; // Since types match now, just return it or adapt if needed
    /*
    return HeatmapConfig(
      display: DisplayConfig(
        showPerformance: modelConfig.display?.showPerformance ?? true,
        showValue: modelConfig.display?.showValue ?? true,
        showSubCards: modelConfig.display?.showSubCards ?? true,
        showWeightage: modelConfig.display?.showWeightage ?? true,
      ),
      layout: LayoutConfig(
        layoutType: modelConfig.layout?.layoutType ?? HeatmapLayoutType.treemap,
      ),
      visual: VisualConfig(
        // colorScheme: modelConfig.colorScheme,
      ),
    );
    */
  }
}
