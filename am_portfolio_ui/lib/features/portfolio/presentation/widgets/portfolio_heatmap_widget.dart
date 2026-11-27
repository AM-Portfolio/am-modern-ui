import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart'
    hide MarketCapType, MetricType, TimeFrame, SectorType;
import 'package:am_design_system/core/utils/string_utils.dart';
import '../../providers/portfolio_providers.dart';
import '../cubit/portfolio_analytics_cubit.dart';
import '../cubit/portfolio_analytics_state.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_heatmap_cubit.dart';
import '../cubit/portfolio_heatmap_state.dart';
import '../cubit/portfolio_state.dart';
import '../mappers/sector_heatmap_converter.dart';
import '../models/heatmap_asset_filter.dart';
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
  ///
  /// Scales reserve by [navFactor] (e.g. [GlobalBottomNavVisibility.factor]) so
  /// tiles are not painted under the bar when the nav returns after scroll-hide.
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
  HeatmapAssetFilter _selectedAssetFilter = HeatmapAssetFilter.allAssets;
  HeatmapMfCategory _selectedMfCategory = HeatmapMfCategory.all;
  HeatmapPerformanceFilter _selectedPerformanceFilter =
      HeatmapPerformanceFilter.all;
  /// Drill path: overview → Other → Commodities → … Back pops one level.
  final List<HeatmapTileData> _drillStack = <HeatmapTileData>[];
  HeatmapTileData? get _drillDownTile =>
      _drillStack.isEmpty ? null : _drillStack.last;
  final ValueNotifier<HeatmapTileData?> _inspectedTile =
      ValueNotifier<HeatmapTileData?>(null);
  Timer? _hoverClearTimer;
  Timer? _liveRefreshTimer;
  int _heatmapLoadGeneration = 0;
  int _lookthroughGeneration = 0;
  bool _lookthroughLoading = false;
  /// Full nested tiles before compact budget — used for sector drill-down.
  List<HeatmapTileData> _fullOverviewTiles = const [];

  void _pushDrill(HeatmapTileData tile) {
    if (_drillStack.isNotEmpty && _drillStack.last.id == tile.id) return;
    setState(() {
      _drillStack.add(tile);
      _inspectedTile.value = null;
    });
  }

  void _popDrill() {
    if (_drillStack.isEmpty) return;
    setState(() {
      _drillStack.removeLast();
      _inspectedTile.value = null;
    });
  }

  void _clearDrill() {
    if (_drillStack.isEmpty && _inspectedTile.value == null) return;
    _drillStack.clear();
    _inspectedTile.value = null;
  }

  late final ValueChanged<HeatmapTileData?> _onTileHover;
  late final ValueChanged<HeatmapTileData> _onTileSelect;
  late final ValueChanged<HeatmapTileData> _onSectorDrill;

  @override
  void initState() {
    super.initState();

    // Initialize with config defaults
    _selectedMetric = MetricType.changePercent;
    _selectedLayout = widget.config.defaultLayout;
    _onTileHover = _handleTileHover;
    _onTileSelect = _handleTileSelect;
    _onSectorDrill = _handleSectorDrill;

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
    _startLiveRefreshTimer();
  }

  @override
  void dispose() {
    _hoverClearTimer?.cancel();
    _liveRefreshTimer?.cancel();
    _inspectedTile.dispose();
    super.dispose();
  }

  void _startLiveRefreshTimer() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      if (_selectedAssetFilter == HeatmapAssetFilter.mutualFunds) return;
      _loadHeatmapData(quiet: true);
    });
  }

  void _handleTileHover(HeatmapTileData? tile) {
    if (!mounted) return;
    if (tile == null) {
      _hoverClearTimer?.cancel();
      _hoverClearTimer = Timer(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        if (_inspectedTile.value != null) _inspectedTile.value = null;
      });
      return;
    }
    if (tile.metadata?['type'] != 'stock') return;
    _hoverClearTimer?.cancel();
    _hoverClearTimer = null;
    if (_inspectedTile.value?.id == tile.id) return;
    _inspectedTile.value = tile;
  }

  void _handleTileSelect(HeatmapTileData tile) {
    if (!mounted) return;
    // Sector shells painted as flat leaves (e.g. inside Other) still expand.
    if (_tileHasHoldings(tile) && !_isSchemeLookthroughTile(tile)) {
      _handleSectorDrill(tile);
      return;
    }
    if (tile.metadata?['type'] != 'stock') return;
    if (_isSchemeLookthroughTile(tile)) {
      unawaited(_openSchemeLookthrough(tile));
      return;
    }
    _inspectedTile.value = tile;
  }

  void _handleSectorDrill(HeatmapTileData tile) {
    if (!mounted) return;
    final full = _lookupFullSectorTile(tile);
    final hasChildren = full.children != null && full.children!.isNotEmpty;
    if (!hasChildren) {
      if (_isSchemeLookthroughTile(full)) {
        unawaited(_openSchemeLookthrough(full));
        return;
      }
      _inspectedTile.value = full;
      return;
    }
    CommonLogger.userAction(
      'Heatmap sector drill: ${full.name}',
      tag: '${widget.config.logTag}.Action',
    );
    _pushDrill(full);
  }

  bool _tileHasHoldings(HeatmapTileData tile) {
    final kids = tile.children;
    if (kids != null && kids.isNotEmpty) return true;
    final full = _lookupFullSectorTile(tile);
    return full.children != null && full.children!.isNotEmpty;
  }

  static final RegExp _mfIsin = RegExp(r'^INF[A-Z0-9]{9}$');

  String? _schemeKeyOf(HeatmapTileData tile) {
    final isin = tile.metadata?['isin']?.toString().trim();
    if (isin != null && isin.isNotEmpty) {
      return isin.toUpperCase();
    }
    final symbol =
        (tile.metadata?['symbol'] ?? tile.name).toString().trim().toUpperCase();
    if (_mfIsin.hasMatch(symbol)) return symbol;
    // ETF display tickers (NIFTYBEES, etc.) still resolve via parser.
    if (symbol.isNotEmpty && symbol != 'UNKNOWN') return symbol;
    return null;
  }

  bool _isSchemeLookthroughTile(HeatmapTileData tile) {
    if (tile.metadata?['lookthroughLeaf'] == true) return false;
    if (tile.metadata?['type'] != 'stock') return false;
    final parent = (tile.metadata?['parentSector'] ?? tile.metadata?['sector'] ?? '')
        .toString()
        .toLowerCase();
    if (parent.contains('mutual fund') || parent.contains('etf')) {
      return true;
    }
    final symbol =
        (tile.metadata?['symbol'] ?? tile.name).toString().trim().toUpperCase();
    final isin = tile.metadata?['isin']?.toString().trim().toUpperCase();
    if (isin != null && _mfIsin.hasMatch(isin)) return true;
    if (_mfIsin.hasMatch(symbol)) return true;
    return HeatmapAssetFilterX.isMutualFundTile(
      name: tile.name,
      displayName: tile.displayName,
      symbol: symbol,
      parentSector: parent,
      sector: parent,
    );
  }

  Future<void> _openSchemeLookthrough(HeatmapTileData tile) async {
    final key = _schemeKeyOf(tile);
    if (key == null) {
      _inspectedTile.value = tile;
      return;
    }
    final gen = ++_lookthroughGeneration;
    setState(() => _lookthroughLoading = true);
    CommonLogger.userAction(
      'Heatmap lookthrough: $key',
      tag: '${widget.config.logTag}.Action',
    );
    try {
      final ds = await ref.read(portfolioRemoteDataSourceProvider.future);
      final result = await ds.getHeatmapLookthrough(
        widget.portfolioId,
        schemeIsin: key,
        schemeValue: tile.value,
      );
      if (!mounted || gen != _lookthroughGeneration) return;
      if (!result.available || result.sectors.isEmpty) {
        // Expected when catalog has no holdingsJson — pin inspector, no page toast.
        _inspectedTile.value = tile.copyWith(
          metadata: {
            ...?tile.metadata,
            'lookthroughNote': 'Underlying holdings not in catalog yet',
          },
        );
        return;
      }
      _pushDrill(result.toDrillTile(tile));
    } catch (e, st) {
      CommonLogger.error(
        'Heatmap lookthrough failed for $key',
        tag: widget.config.logTag,
        error: e,
        stackTrace: st,
      );
      if (!mounted || gen != _lookthroughGeneration) return;
      _inspectedTile.value = tile.copyWith(
        metadata: {
          ...?tile.metadata,
          'lookthroughNote': 'Could not load fund holdings',
        },
      );
    } finally {
      if (mounted && gen == _lookthroughGeneration) {
        setState(() => _lookthroughLoading = false);
      }
    }
  }

  HeatmapTileData _lookupFullSectorTile(HeatmapTileData tile) {
    HeatmapTileData? find(List<HeatmapTileData> tiles) {
      for (final t in tiles) {
        if (t.id == tile.id || t.name == tile.name) return t;
        final kids = t.children;
        if (kids == null || kids.isEmpty) continue;
        final nested = find(
          kids
              .map(
                (c) => c is HeatmapTileData ? c : HeatmapTileData.fromEntity(c),
              )
              .toList(),
        );
        if (nested != null) return nested;
      }
      return null;
    }

    return find(_fullOverviewTiles) ?? tile;
  }

  @override
  void didUpdateWidget(PortfolioHeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.defaultLayout != widget.config.defaultLayout &&
        _selectedLayout == oldWidget.config.defaultLayout) {
      setState(() => _selectedLayout = widget.config.defaultLayout);
    }
    if (oldWidget.portfolioId != widget.portfolioId) {
      _clearDrill();
      _loadHeatmapData();
    }
  }

  void _loadHeatmapData({bool quiet = false}) {
    const timeFrame = TimeFrame.oneDay;
    final loadGen = ++_heatmapLoadGeneration;
    CommonLogger.methodEntry(
      '_loadHeatmapData',
      tag: '${widget.config.logTag}.Data',
      metadata: {
        'portfolioId': widget.portfolioId,
        'timeFrame': timeFrame.name,
        'metric': _selectedMetric.name,
        'sector': _selectedSector?.name ?? 'all',
        'marketCap': _selectedMarketCap?.name ?? 'all',
        'assetFilter': _selectedAssetFilter.name,
        'mfCategory': _selectedMfCategory.name,
        'loadGen': loadGen,
        'quiet': quiet,
      },
    );

    final portfolioAnalyticsCubit = context.read<PortfolioAnalyticsCubit>();
    final portfolioHeatmapCubit = context.read<PortfolioHeatmapCubit>();

    // Leave Initial immediately so UI shows real Loading, not the manual CTA.
    if (!quiet) {
      portfolioHeatmapCubit.beginLoading();
    }

    // Always fetch ALL mosaic once; Equity/ETF/MF tabs filter client-side.
    final filterKey = ref.read(familyPortfolioFilterProvider);
    portfolioAnalyticsCubit
        .loadAnalytics(
          widget.portfolioId,
          timeFrame: timeFrame,
          persona: widget.portfolioId == 'all'
              ? holdingsPersonaParam(filterKey)
              : null,
          assetScope: HeatmapAssetFilter.allAssets.apiAssetScope,
          forceRefresh: quiet,
          heatmapFirst: true,
        )
        .then((_) {
          if (!mounted || loadGen != _heatmapLoadGeneration) return;
          final analyticsState = portfolioAnalyticsCubit.state;
          if (analyticsState is PortfolioAnalyticsError) {
            CommonLogger.error(
              'Analytics failed, skipping heatmap data load',
              tag: '${widget.config.logTag}.Data',
            );
            if (!quiet) {
              portfolioHeatmapCubit.showError(
                'Failed to load portfolio data. Please retry.',
              );
            }
            return;
          }

          CommonLogger.info(
            'Analytics loaded, proceeding with heatmap data',
            tag: '${widget.config.logTag}.Data',
          );

          portfolioHeatmapCubit.loadHeatmapData(
            portfolioId: widget.portfolioId,
            timeFrame: timeFrame,
            metric: _selectedMetric,
            sector: _selectedSector ?? SectorType.all,
            marketCap: _selectedMarketCap ?? MarketCapType.all,
            assetFilter: _selectedAssetFilter,
            mfCategory: _selectedMfCategory,
            analyticsCubit: portfolioAnalyticsCubit,
            quiet: quiet,
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
            timeFrame: timeFrame,
            metric: _selectedMetric,
            sector: _selectedSector ?? SectorType.all,
            marketCap: _selectedMarketCap ?? MarketCapType.all,
            assetFilter: _selectedAssetFilter,
            mfCategory: _selectedMfCategory,
            analyticsCubit: portfolioAnalyticsCubit,
            quiet: quiet,
          );
        });

    CommonLogger.methodExit(
      '_loadHeatmapData',
      tag: '${widget.config.logTag}.Data',
    );
  }

  /// Re-slice cached ALL heatmap — no analytics API round-trip.
  void _applyClientHeatmapFilters({bool quiet = true}) {
    const timeFrame = TimeFrame.oneDay;
    context.read<PortfolioHeatmapCubit>().loadHeatmapData(
          portfolioId: widget.portfolioId,
          timeFrame: timeFrame,
          metric: _selectedMetric,
          sector: _selectedSector ?? SectorType.all,
          marketCap: _selectedMarketCap ?? MarketCapType.all,
          assetFilter: _selectedAssetFilter,
          mfCategory: _selectedMfCategory,
          analyticsCubit: context.read<PortfolioAnalyticsCubit>(),
          quiet: quiet,
        );
  }

  bool _hasCachedHeatmapMosaic() {
    final analytics = context.read<PortfolioAnalyticsCubit>().state;
    if (analytics is! PortfolioAnalyticsLoaded) return false;
    final hasHeatmap =
        analytics.heatmap != null && analytics.heatmap!.sectors.isNotEmpty;
    final hasAllocation =
        analytics.sectorAllocation?.sectorWeights.isNotEmpty ?? false;
    return hasHeatmap || hasAllocation;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(familyPortfolioFilterProvider, (previous, next) {
      if (previous != next && widget.portfolioId == 'all') _loadHeatmapData();
    });

    // Heatmap-first often converts before allocation lands; reconvert when sectors arrive.
    return BlocListener<PortfolioAnalyticsCubit, PortfolioAnalyticsState>(
      listenWhen: (previous, current) {
        if (current is! PortfolioAnalyticsLoaded) return false;
        final prevAlloc = previous is PortfolioAnalyticsLoaded
            ? previous.sectorAllocation
            : null;
        final nextAlloc = current.sectorAllocation;
        final prevEmpty = prevAlloc == null || prevAlloc.sectorWeights.isEmpty;
        final nextReady = nextAlloc != null && nextAlloc.sectorWeights.isNotEmpty;
        return prevEmpty && nextReady;
      },
      listener: (context, state) {
        final heatmapCubit = context.read<PortfolioHeatmapCubit>();
        if (heatmapCubit.state is! PortfolioHeatmapLoaded) return;
        heatmapCubit.loadHeatmapData(
          portfolioId: widget.portfolioId,
          timeFrame: TimeFrame.oneDay,
          metric: _selectedMetric,
          sector: _selectedSector ?? SectorType.all,
          marketCap: _selectedMarketCap ?? MarketCapType.all,
          assetFilter: _selectedAssetFilter,
          mfCategory: _selectedMfCategory,
          analyticsCubit: context.read<PortfolioAnalyticsCubit>(),
          quiet: true,
        );
      },
      child: LayoutBuilder(
      builder: (context, constraints) {
        final viewportH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        return SizedBox(
          width: constraints.maxWidth,
          height: viewportH,
          child: Stack(
            children: [
              Padding(
                padding: widget.config.padding,
                child: _buildHeatmapContent(mobileViewportH: viewportH),
              ),
              // Corner spinner only — never dim / block the whole mosaic.
              if (_lookthroughLoading)
                const Positioned(
                  right: 16,
                  bottom: 16,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      ),
    );
  }

  /// Main heatmap content with state handling using dual cubit approach.
  /// Live summary ticks update KPI strip via PortfolioCubit; do not full-reload tiles.
  Widget _buildHeatmapContent({required double mobileViewportH}) =>
      BlocBuilder<PortfolioHeatmapCubit, PortfolioHeatmapState>(
        builder: (context, state) {
          CommonLogger.debug(
            'State update: ${state.runtimeType}',
            tag: '${widget.config.logTag}.State',
          );

          return _buildStateWidget(state, mobileViewportH: mobileViewportH);
        },
      );

  /// Routes to appropriate widget based on current state
  Widget _buildStateWidget(
    PortfolioHeatmapState state, {
    required double mobileViewportH,
  }) {
    if (state is PortfolioHeatmapLoading) {
      return _buildLoadingWidget(state);
    }

    if (state is PortfolioHeatmapError) {
      return _buildErrorWidget(state);
    }

    if (state is PortfolioHeatmapLoaded) {
      return _buildLoadedWidget(state, mobileViewportH: mobileViewportH);
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
  Widget _buildLoadedWidget(
    PortfolioHeatmapLoaded state, {
    required double mobileViewportH,
  }) {
    CommonLogger.info(
      'Showing heatmap: ${state.heatmapData.tiles.length} tiles',
      tag: '${widget.config.logTag}.UI',
    );

    final convertedHeatmapData = state.heatmapData;

    // Create configuration with selected layout
    final baseSelectors =
        convertedHeatmapData.configuration.selectors ?? const SelectorConfig();
    final baseLayout =
        convertedHeatmapData.configuration.layout ?? const LayoutConfig();
    final baseInteractions =
        convertedHeatmapData.configuration.interactions ??
        const InteractionConfig();

    // Overview tiles (before drill). Keep a full copy for sector lookup.
    var workingTiles = convertedHeatmapData.tiles
        .map((t) => t is HeatmapTileData ? t : HeatmapTileData.fromEntity(t))
        .toList();
    _fullOverviewTiles = workingTiles;

    if (_drillDownTile != null && _drillDownTile!.children != null) {
      workingTiles = _drillDownTile!.children!
          .map((t) => t is HeatmapTileData ? t : HeatmapTileData.fromEntity(t))
          .toList();
    }

    // Keep nested sector chrome whenever tiles still have children (MF → Equity
    // → Flexi Cap → schemes). Flat-only drill hid category headers and funds.
    final useNested = _selectedLayout == HeatmapLayoutType.treemap &&
        (_drillDownTile == null ||
            workingTiles.any(
              (t) => t.children != null && t.children!.isNotEmpty,
            ));

    final customConfig = convertedHeatmapData.configuration.copyWith(
      display:
          (convertedHeatmapData.configuration.display ?? const DisplayConfig())
              .copyWith(showPerformance: true, showLegend: false),
      layout: baseLayout.copyWith(
        layoutType: _selectedLayout,
        showLayoutSelector: widget.config.compactMode ? true : null,
        nestedSectors: useNested,
        // Nested overview always uses solid fills — glass/blur per leaf freezes
        // Flutter Web on large books. Drill-down / flat layouts can stay richer.
        solidFills: widget.config.compactMode || useNested,
      ),
      interactions: baseInteractions.copyWith(
        // Web: hover opens docked inspector via ValueNotifier (no mosaic rebuild).
        // Compact/mobile: tap / long-press pin only.
        enableHoverEffects: !widget.config.compactMode,
      ),
      selectors: baseSelectors.copyWith(
        selectorLayout: widget.config.compactMode
            ? SelectorLayoutType.compact
            : null,
        showSectorSelector: widget.config.compactMode ? true : null,
        showMarketCapSelector: widget.config.compactMode ? true : null,
        showTimeFrameSelector: widget.config.compactMode ? false : null,
        showMetricSelector: widget.config.compactMode ? false : null,
      ),
    );

    // Nested mosaic (overview or mid-level drill): budget leaves so web stays responsive.
    if (useNested) {
      workingTiles = SectorHeatmapConverter.applyCompactTreemapBudget(
        workingTiles,
        maxStocksPerSector: widget.config.compactMode
            ? SectorHeatmapConverter.compactMaxStocksPerSector
            : SectorHeatmapConverter.webMaxStocksPerSector,
      );
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
          _pushDrill(_lookupFullSectorTile(tile));
        },
        customWidgets: tile.customWidgets,
      );
    }).toList();

    // Gainers / Losers — overview sectors or drilled-in stocks/schemes.
    workingTiles = filterHeatmapTilesByPerformance(
      workingTiles,
      _selectedPerformanceFilter,
    );

    final displayData = convertedHeatmapData.copyWith(
      tiles: workingTiles,
      configuration: customConfig,
    );

    Widget heatmapBody({required bool showSelectors}) {
      // Keep filters visible even when the mosaic is empty so the user can reset.
      if (workingTiles.isEmpty) {
        final compact = widget.config.compactMode;
        return Card(
          elevation: compact ? 2 : 4,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: compact
                ? const EdgeInsets.fromLTRB(6, 6, 6, 6)
                : const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeatmapCardHeader(context),
                SizedBox(height: compact ? 6 : 8),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No holdings match these filters.\nTry All Assets or All Sectors.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return HeatmapInteractionScope(
          onTileHover: _onTileHover,
          onTileSelect: _onTileSelect,
          onSectorDrill: _onSectorDrill,
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
                      : _buildHeatmapCardHeader(context),
                  config: _mapToWidgetConfig(customConfig),
                  showSelectors: showSelectors,
                  compactMode: widget.config.compactMode,
                  selectedTimeFrame: TimeFrame.oneDay,
                  selectedMetric: _selectedMetric,
                  // Cubit already applied sector / asset / cap filters. Passing
                  // Banking here made the treemap look for the literal name
                  // "Banking" and hide "Financial Services" → blank mosaic.
                  selectedSector: SectorType.all,
                  selectedMarketCap: _selectedMarketCap,
                  selectedLayout: _selectedLayout,
                  onTilePressed: () {
                    CommonLogger.userAction(
                      'Heatmap stock tile pressed',
                      tag: '${widget.config.logTag}.Action',
                    );
                  },
                  onFiltersChanged:
                      ({timeFrame, metric, sector, marketCap, layout}) {
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
              Positioned(
                left: 12,
                right: 12,
                bottom: widget.config.compactMode ? 8 : 12,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ValueListenableBuilder<HeatmapTileData?>(
                    valueListenable: _inspectedTile,
                    builder: (context, tile, _) {
                      if (tile == null) return const SizedBox.shrink();
                      final screenW = MediaQuery.sizeOf(context).width;
                      // Compact pill: phone ~92% width capped 360; web capped 420.
                      final maxW = widget.config.compactMode
                          ? (screenW - 24).clamp(240.0, 360.0)
                          : (screenW * 0.42).clamp(280.0, 420.0);
                      return IgnorePointer(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxW,
                            maxHeight: 44,
                          ),
                          child: HeatmapTileInspector(tile: tile),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
    }

    // Mobile only: scroll past KPIs → filters pin → mosaic fills the rest of
    // the tab. Taps inside filters/mosaic must not reveal the floating bottom nav.
    if (widget.config.compactMode) {
      final screenH = MediaQuery.sizeOf(context).height;
      final topSafe = MediaQuery.paddingOf(context).top;
      final bottomSafe = MediaQuery.paddingOf(context).bottom;
      final navReserve = PlatformConstants.globalBottomNavReserve(context);
      const stickyHeaderH = 44.0;
      final topChromeWhenPinned = topSafe + stickyHeaderH;
      final bottomMargin =
          (bottomSafe > 0 ? bottomSafe : 8.0) +
          (navReserve > 0 ? navReserve : 20.0);
      final fullMobileScreenH = screenH - topChromeWhenPinned - bottomMargin;
      final mapH = (fullMobileScreenH > mobileViewportH
              ? fullMobileScreenH
              : mobileViewportH)
          .clamp(540.0, 4000.0);

      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCardsRow(),
                const SizedBox(height: 8),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: mapH,
              width: double.infinity,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _suppressBottomNavOnHeatmapTap(),
                child: _padAboveBottomNav(
                  context,
                  child: heatmapBody(showSelectors: false),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: bottomMargin)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryCardsRow(),
        const SizedBox(height: 8),
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

  String _drillSectorLabel(HeatmapTileData tile) {
    final name = tile.name.trim();
    if (name.isNotEmpty) return name;
    return tile.displayName.trim();
  }

  /// Drill chrome inside the Heatmap Overview card (back + sector path + stats).
  Widget _buildDrillInCardHeader(BuildContext context) {
    final tile = _drillDownTile!;
    // Breadcrumb so Mutual Funds › Equity keeps category context in the header.
    final sectorLabel = _drillStack
        .map(_drillSectorLabel)
        .where((s) => s.isNotEmpty)
        .join(' › ');
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
          sectorLabel.isNotEmpty ? sectorLabel : _drillSectorLabel(tile),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (compact
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 15 : 17,
                  ),
        ),
        if (metaBits.isNotEmpty || pct != 0) ...[
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              style: metaStyle,
              children: [
                if (metaBits.isNotEmpty) TextSpan(text: metaBits.join(' · ')),
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

    final showMfCategory = _selectedAssetFilter == HeatmapAssetFilter.mutualFunds ||
        HeatmapAssetFilterX.isMutualFundTile(
          name: tile.name,
          displayName: tile.displayName,
          symbol: meta['symbol']?.toString(),
          sector: meta['sector']?.toString() ?? meta['parentSector']?.toString(),
          assetClass: meta['assetClass']?.toString(),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: _popDrill,
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
        _buildPerformanceFilterControl(context, compact: compact),
        if (showMfCategory) ...[
          const SizedBox(width: 8),
          CustomDropdown<HeatmapMfCategory>(
            value: _selectedMfCategory,
            items: HeatmapMfCategory.values
                .map(
                  (item) => item.toDropdownItem(
                    text: item.displayName,
                    icon: item.icon,
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) _onFiltersChanged(mfCategory: val);
            },
            isExpanded: false,
            primaryColor: ModuleColors.portfolio,
          ),
        ],
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
          if (summary.hasTodayChange) {
            todayChange = StringUtils.formatCurrencyExact(summary.todayChange!);
            final dayInr = summary.todayChange!;
            final priorValue = summary.totalValue - dayInr;
            // Prefer implied % from Total + Today ₹ so stale socket % cannot show 40% on 0.2%.
            todayChangePct = priorValue > 0
                ? (dayInr / priorValue) * 100
                : (summary.todayChangePercentage ?? 0);
            isTodayPositive = dayInr >= 0;
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
              final analyticsState = context.read<PortfolioAnalyticsCubit>().state;
              final allocation = analyticsState is PortfolioAnalyticsLoaded
                  ? analyticsState.sectorAllocation
                  : null;
              final summary = SectorHeatmapConverter.resolveSectorSummary(
                tiles: heatmapState.heatmapData.uiTiles,
                sectorAllocation: allocation,
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
                    children:
                        cards
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

  /// Header controls on one row, grouped by function:
  /// title → asset scope → view dropdowns → day movers.
  Widget _buildHeatmapCardHeader(BuildContext context) {
    final compact = widget.config.compactMode;
    final showMfCategory =
        _selectedAssetFilter == HeatmapAssetFilter.mutualFunds;
    final scheme = Theme.of(context).colorScheme;

    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.grid_view_rounded,
          color: ModuleColors.portfolio,
          size: compact ? 16 : 18,
        ),
        const SizedBox(width: 6),
        Text(
          compact ? 'Heatmap' : 'Heatmap Overview',
          style: (compact
                  ? Theme.of(context).textTheme.titleSmall
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );

    Widget groupGap() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(
            height: 18,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
        );

    CustomDropdown<T> denseDropdown<T>({
      required T value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
    }) {
      return CustomDropdown<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: false,
        height: 30,
        fontSize: 11,
        iconSize: 14,
        borderRadius: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        primaryColor: ModuleColors.portfolio,
      );
    }

    // View / layout dropdowns only (not mixed with pill toggles).
    final viewDropdowns = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        denseDropdown<SectorType>(
          value: _selectedSector ?? SectorType.all,
          items: SectorType.values
              .map(
                (item) => item.toDropdownItem(
                  text: item.displayName,
                  icon: Icons.category_outlined,
                  fontSize: 11,
                  iconSize: 13,
                  expandText: false,
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) _onFiltersChanged(sector: val);
          },
        ),
        const SizedBox(width: 4),
        denseDropdown<MarketCapType>(
          value: _selectedMarketCap ?? MarketCapType.all,
          items: MarketCapType.values
              .map(
                (item) => item.toDropdownItem(
                  text: item.displayName,
                  icon: Icons.pie_chart_outline,
                  fontSize: 11,
                  iconSize: 13,
                  expandText: false,
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) _onFiltersChanged(marketCap: val);
          },
        ),
        if (showMfCategory) ...[
          const SizedBox(width: 4),
          denseDropdown<HeatmapMfCategory>(
            value: _selectedMfCategory,
            items: HeatmapMfCategory.values
                .map(
                  (item) => item.toDropdownItem(
                    text: item.displayName,
                    icon: item.icon,
                    fontSize: 11,
                    iconSize: 13,
                    expandText: false,
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) _onFiltersChanged(mfCategory: val);
            },
          ),
        ],
        const SizedBox(width: 4),
        denseDropdown<HeatmapLayoutType>(
          value: _selectedLayout,
          items: HeatmapLayoutType.values
              .map(
                (item) => item.toDropdownItem(
                  text: item.displayName,
                  icon: Icons.visibility_outlined,
                  fontSize: 11,
                  iconSize: 13,
                  expandText: false,
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) _onFiltersChanged(layout: val);
          },
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              title,
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAssetScopeControl(context, compact: true),
                        const SizedBox(width: 6),
                        _buildPerformanceFilterControl(
                          context,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: viewDropdowns,
          ),
        ],
      );
    }

    // Web: one row — scale controls down so Equity is never clipped.
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAssetScopeControl(context, compact: false),
        groupGap(),
        viewDropdowns,
        groupGap(),
        _buildPerformanceFilterControl(context, compact: false),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        title,
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: controls,
            ),
          ),
        ),
      ],
    );
  }

  String _mobileAssetLabel(HeatmapAssetFilter filter) {
    switch (filter) {
      case HeatmapAssetFilter.equity:
        return 'Equity';
      case HeatmapAssetFilter.etfs:
        return 'ETFs';
      case HeatmapAssetFilter.mutualFunds:
        return 'Funds';
      case HeatmapAssetFilter.allAssets:
        return 'All';
    }
  }

  /// Web: pill tabs. Mobile ([compact]): dropdown — avoids horizontal overflow.
  Widget _buildAssetScopeControl(
    BuildContext context, {
    required bool compact,
  }) {
    if (compact) {
      return CustomDropdown<HeatmapAssetFilter>(
        value: _selectedAssetFilter,
        items: HeatmapAssetFilter.values
            .map(
              (item) => item.toDropdownItem(
                text: _mobileAssetLabel(item),
                icon: item.icon,
                fontSize: 12,
                iconSize: 14,
                expandText: false,
              ),
            )
            .toList(),
        onChanged: (val) {
          if (val != null) _onFiltersChanged(assetFilter: val);
        },
        isExpanded: false,
        height: 36,
        fontSize: 12,
        iconSize: 16,
        borderRadius: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        primaryColor: ModuleColors.portfolio,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: HeatmapAssetFilter.values.map((filter) {
        final selected = filter == _selectedAssetFilter;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Material(
            color: selected
                ? ModuleColors.portfolio
                : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _onFiltersChanged(assetFilter: filter),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter.icon,
                      size: 12,
                      color: selected ? Colors.white : scheme.onSurface,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      filter.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// All / Gainers / Losers — same dense dropdown as other header filters.
  Widget _buildPerformanceFilterControl(
    BuildContext context, {
    required bool compact,
  }) {
    final dense = !compact;
    return CustomDropdown<HeatmapPerformanceFilter>(
      value: _selectedPerformanceFilter,
      items: HeatmapPerformanceFilter.values
          .map(
            (item) => item.toDropdownItem(
              text: item.displayName,
              icon: item.icon,
              fontSize: dense ? 11 : 12,
              iconSize: dense ? 13 : 14,
              expandText: false,
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val == null || val == _selectedPerformanceFilter) return;
        setState(() => _selectedPerformanceFilter = val);
      },
      isExpanded: false,
      height: dense ? 30 : 36,
      fontSize: dense ? 11 : 12,
      iconSize: dense ? 14 : 16,
      borderRadius: dense ? 8 : 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      primaryColor: ModuleColors.portfolio,
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
            Icon(
              Icons.folder_open,
              size: iconSize,
              color: context.statusNeutral,
            ),
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
          Icon(
            Icons.bar_chart_outlined,
            size: iconSize,
            color: context.statusNeutral,
          ),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: PortfolioHeatmapUiConfig.mobileBottomInset(context),
      ),
      child: child,
    );
  }

  /// Heatmap taps must not flash the floating company bottom nav.
  void _suppressBottomNavOnHeatmapTap() {
    GlobalBottomNavVisibility.suppressChromeTapReveal = true;
    GlobalBottomNavVisibility.requestHide();
  }

  /// Handles filter changes from heatmap selectors
  void _onFiltersChanged({
    TimeFrame? timeFrame,
    MetricType? metric,
    SectorType? sector,
    MarketCapType? marketCap,
    HeatmapLayoutType? layout,
    HeatmapAssetFilter? assetFilter,
    HeatmapMfCategory? mfCategory,
  }) {
    CommonLogger.debug(
      'Filters: metric=${metric?.name}, sector=${sector?.name}, marketCap=${marketCap?.name}, view=${layout?.name}, asset=${assetFilter?.name}, mfCat=${mfCategory?.name}',
      tag: '${widget.config.logTag}.Filter',
    );

    setState(() {
      _clearDrill();
      if (metric != null) _selectedMetric = metric;
      if (sector != null) _selectedSector = sector;
      if (marketCap != null) _selectedMarketCap = marketCap;
      if (layout != null) _selectedLayout = layout;
      if (assetFilter != null) {
        _selectedAssetFilter = assetFilter;
        if (assetFilter != HeatmapAssetFilter.mutualFunds) {
          _selectedMfCategory = HeatmapMfCategory.all;
        }
      }
      if (mfCategory != null) _selectedMfCategory = mfCategory;
    });
    if (layout != null) {
      CommonLogger.info(
        'View changed to: ${layout.name}',
        tag: '${widget.config.logTag}.View',
      );
    }

    if (sector != null ||
        marketCap != null ||
        assetFilter != null ||
        mfCategory != null) {
      if (_hasCachedHeatmapMosaic()) {
        _applyClientHeatmapFilters(quiet: true);
      } else {
        _loadHeatmapData();
      }
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
