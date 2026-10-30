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

  /// Mobile configuration — treemap by default (matches web).
  static const mobile = PortfolioHeatmapUiConfig(
    defaultLayout: HeatmapLayoutType.treemap,
    compactMode: true,
    showSelectors: true,
    templateType: UniversalTemplateType.compact,
    showSubCards: false,
    padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
    title: 'Heatmap Overview',
    subtitle: '', // Completely removed the down side text
    logTag: 'PortfolioHeatmap.Mobile',
  );

  /// Space so the treemap sits above the floating global bottom nav.
  static double mobileBottomInset(
    BuildContext context, {
    double navFactor = 1,
  }) {
    final reserve = PlatformConstants.globalBottomNavReserve(context);
    return 8.0 + reserve * navFactor.clamp(0.0, 1.0);
  }

  /// Web configuration — tight padding so the treemap uses the page width/height.
  static const web = PortfolioHeatmapUiConfig(
    defaultLayout: HeatmapLayoutType.treemap,
    compactMode: false,
    showSelectors: true,
    templateType: UniversalTemplateType.full,
    showSubCards: true,
    padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
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
  HeatmapTileData? _inspectedTile;
  int _heatmapLoadGeneration = 0;
  /// Tab viewport height — mobile heatmap block matches one full screen.
  double _mobileViewportH = 0;

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

    // Web: fill the tab. Mobile: scroll page; heatmap block = one screen tall.
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        if (widget.config.compactMode) {
          _mobileViewportH = viewportH;
        }
        final content = Padding(
          padding: widget.config.padding,
          child: _buildHeatmapContent(),
        );
        if (widget.config.compactMode) {
          return SizedBox(
            width: constraints.maxWidth,
            height: viewportH,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: content,
            ),
          );
        }
        return SizedBox(
          width: constraints.maxWidth,
          height: viewportH,
          child: content,
        );
      },
    );
  }

  /// Main heatmap content with state handling using dual cubit approach.
  /// Live summary ticks update KPI strip via PortfolioCubit; do not full-reload tiles.
  Widget _buildHeatmapContent() =>
      BlocBuilder<PortfolioHeatmapCubit, PortfolioHeatmapState>(
        builder: (context, state) {
          CommonLogger.debug(
            'State update: ${state.runtimeType}',
            tag: '${widget.config.logTag}.State',
          );

          return _buildStateWidget(state);
        },
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

    return const HeatmapSkeletonLoader();
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
            Icon(Icons.error_outline, size: 64, color: context.statusError),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              style: TextStyle(color: context.statusError),
              textAlign: TextAlign.center,
            ),
            if (state.details != null) ...[
              const SizedBox(height: 8),
              Text(
                state.details!,
                style: TextStyle(color: context.textTertiary, fontSize: 12),
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
    final useNested =
        _drillDownTile == null && _selectedLayout == HeatmapLayoutType.treemap;
    final customConfig = convertedHeatmapData.configuration.copyWith(
      display: (convertedHeatmapData.configuration.display ??
              const DisplayConfig())
          .copyWith(
        showPerformance: true,
        showLegend: true,
      ),
      layout: baseLayout.copyWith(
        layoutType: _selectedLayout,
        showLayoutSelector: widget.config.compactMode ? true : null,
        nestedSectors: useNested,
        // Glass / liquid tiles (translucent fills + soft edge).
        solidFills: false,
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

    // Drill-down: flat children. Overview nested mosaic: keep all sectors
    // (no Other-merge) so TradingView-style bands stay complete.
    var workingTiles = convertedHeatmapData.tiles
        .map((t) => t is HeatmapTileData ? t : HeatmapTileData.fromEntity(t))
        .toList();

    if (_drillDownTile != null && _drillDownTile!.children != null) {
      workingTiles = _drillDownTile!.children!
          .map((t) => t is HeatmapTileData ? t : HeatmapTileData.fromEntity(t))
          .toList();
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
          setState(() {
            _drillDownTile = tile;
            _inspectedTile = null;
          });
        },
        customWidgets: tile.customWidgets,
      );
    }).toList();

    final displayData = convertedHeatmapData.copyWith(
      tiles: workingTiles,
      configuration: customConfig,
    );

    Widget heatmapBody({required bool showSelectors}) => HeatmapInteractionScope(
          onTileHover: (tile) {
            if (!mounted) return;
            // Only stocks drive the docked inspector; null clears on mouse leave.
            if (tile == null) {
              if (_inspectedTile != null) {
                setState(() => _inspectedTile = null);
              }
              return;
            }
            if (tile.metadata?['type'] != 'stock') return;
            setState(() => _inspectedTile = tile);
          },
          onTileSelect: (tile) {
            if (!mounted) return;
            if (tile.metadata?['type'] != 'stock') return;
            setState(() => _inspectedTile = tile);
          },
          onSectorDrill: (tile) {
            if (!mounted) return;
            final hasChildren =
                tile.children != null && tile.children!.isNotEmpty;
            if (!hasChildren) return;
            CommonLogger.userAction(
              'Heatmap sector drill: ${tile.name}',
              tag: '${widget.config.logTag}.Action',
            );
            setState(() {
              _drillDownTile = tile;
              _inspectedTile = null;
            });
          },
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: UniversalHeatmapWidget(
                  investmentType: InvestmentType.portfolio,
                  heatmapData: displayData,
                  title: widget.config.compactMode
                      ? 'Heatmap'
                      : widget.config.title,
                  subtitle: widget.config.compactMode
                      ? null
                      : widget.config.subtitle,
                  customHeader: _drillDownTile != null
                      ? _buildDrillInCardHeader(context)
                      : null,
                  config: _mapToWidgetConfig(customConfig),
                  showSelectors: showSelectors,
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
                  onFiltersChanged: ({
                    timeFrame,
                    metric,
                    sector,
                    marketCap,
                    layout,
                  }) {
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
              ),
              if (_inspectedTile != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: widget.config.compactMode ? 8 : 12,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 460,
                        maxHeight: 44,
                      ),
                      child: HeatmapTileInspector(
                        tile: _inspectedTile!,
                        onDismiss: () =>
                            setState(() => _inspectedTile = null),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );

    // Mobile: scroll past KPIs; heatmap block height = one full tab screen.
    if (widget.config.compactMode) {
      final mapH = _mobileViewportH > 0
          ? _mobileViewportH
          : MediaQuery.sizeOf(context).height;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCardsRow(),
          const SizedBox(height: 8),
          SizedBox(
            height: mapH,
            width: double.infinity,
            child: _padAboveBottomNav(
              context,
              child: heatmapBody(showSelectors: true),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryCardsRow(),
        const SizedBox(height: 8),
        _buildEquityDistributionHeader(context),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, heatmapConstraints) => SizedBox(
              width: double.infinity,
              height: heatmapConstraints.maxHeight,
              child: heatmapBody(showSelectors: false),
            ),
          ),
        ),
      ],
    );
  }

  /// Drill chrome inside the Heatmap Overview card (back + sector + stats).
  Widget _buildDrillInCardHeader(BuildContext context) {
    final tile = _drillDownTile!;
    final sectorLabel =
        tile.name.trim().isNotEmpty ? tile.name : tile.displayName;
    final meta = tile.metadata ?? const <String, dynamic>{};
    final holdings = meta['holdingsCount'] ?? meta['stockCount'];
    final compact = widget.config.compactMode;
    final scheme = Theme.of(context).colorScheme;

    // Compact meta so the drill header stays short.
    final metaBits = <String>[];
    if (tile.value != null && tile.value! > 0) {
      metaBits.add(StringUtils.formatCurrency(tile.value!));
    }
    if (holdings is num && holdings > 0) {
      metaBits.add('${holdings.toInt()} hld');
    }
    final pct = tile.performance;
    final pctColor = pct > 0
        ? context.marketPositive
        : (pct < 0 ? context.marketNegative : scheme.onSurfaceVariant);
    final metaStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w500,
        );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sectorLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (compact
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.titleLarge)
              ?.copyWith(fontWeight: FontWeight.w700, fontSize: compact ? 15 : 17),
        ),
        if (metaBits.isNotEmpty || pct != 0) ...[
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              style: metaStyle,
              children: [
                if (metaBits.isNotEmpty)
                  TextSpan(text: metaBits.join(' · ')),
                if (metaBits.isNotEmpty)
                  TextSpan(text: ' · ', style: metaStyle),
                TextSpan(
                  text: StringUtils.formatSignedPercent(pct),
                  style: metaStyle?.copyWith(
                    color: pctColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => setState(() {
            _drillDownTile = null;
            _inspectedTile = null;
          }),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 6, 4),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: compact ? 16 : 18,
              color: ModuleColors.portfolio,
            ),
          ),
        ),
        Expanded(child: titleBlock),
        if (!compact) ...[
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: _buildDrillPerformanceLegend(context),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDrillPerformanceLegend(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Performance: ', style: Theme.of(context).textTheme.bodySmall),
        _drillLegendSwatch(context, 'Loss', context.marketNegative),
        const SizedBox(width: 16),
        _drillLegendSwatch(
          context,
          'Neutral',
          context.colors.statusNeutral,
        ),
        const SizedBox(width: 16),
        _drillLegendSwatch(context, 'Gain', context.marketPositive),
      ],
    );
  }

  Widget _drillLegendSwatch(
    BuildContext context,
    String label,
    Color color,
  ) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );

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
          if (summary.hasTodayChange) {
            todayChange = StringUtils.formatCurrencyExact(summary.todayChange!);
            todayChangePct = summary.todayChangePercentage ?? 0;
            isTodayPositive = summary.isTodayPositive;
          } else {
            todayChange = '—';
            todayChangePct = 0;
            isTodayPositive = true;
          }
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
                    subtitle: todayChange == '—'
                        ? 'Unavailable'
                        : (todayChangePct.abs() < 0.005
                            ? '0.00%'
                            : '${isTodayPositive ? '+' : ''}${todayChangePct.toStringAsFixed(2)}%'),
                    accentColor: todayChange == '—'
                        ? context.statusNeutral
                        : (isTodayPositive
                            ? context.marketPositive
                            : context.marketNegative),
                    chromeColor: ModuleColors.portfolio,
                    isPositive: todayChange == '—' ? null : isTodayPositive,
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
            Icon(Icons.folder_open, size: iconSize, color: context.statusNeutral),
            const SizedBox(height: 24),
            Text(
              state.message,
              style: TextStyle(fontSize: textSize, color: context.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some investments to see the ${widget.config.compactMode ? '' : 'portfolio '}heatmap',
              style: TextStyle(color: context.textTertiary),
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
          Icon(Icons.bar_chart_outlined, size: iconSize, color: context.statusNeutral),
          const SizedBox(height: 16),
          Text(
            'Loading ${widget.config.compactMode ? '' : 'portfolio '}data...',
            style: TextStyle(color: context.textTertiary),
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

  Widget _padAboveBottomNav(BuildContext context, {required Widget child}) {
    return ValueListenableBuilder<double>(
      valueListenable: GlobalBottomNavVisibility.factor,
      builder: (context, navFactor, _) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: PortfolioHeatmapUiConfig.mobileBottomInset(
              context,
              navFactor: navFactor,
            ),
          ),
          child: child,
        );
      },
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

    // Update local state; clear drill/inspector so mosaic stays consistent.
    setState(() {
      _drillDownTile = null;
      _inspectedTile = null;
      if (metric != null) _selectedMetric = metric;
      if (sector != null) _selectedSector = sector;
      if (marketCap != null) _selectedMarketCap = marketCap;
      if (layout != null) _selectedLayout = layout;
    });
    if (timeFrame != null) {
      ref.read(appTimeFrameProvider.notifier).setTimeFrame(timeFrame);
    }
    if (layout != null) {
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
