import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart'
    hide MarketCapType, MetricType, TimeFrame, SectorType;
import '../cubit/portfolio_analytics_cubit.dart';
import '../cubit/portfolio_analytics_state.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_heatmap_cubit.dart';
import '../cubit/portfolio_heatmap_state.dart';
import '../cubit/portfolio_state.dart';
import '../../internal/domain/entities/portfolio_analytics.dart' as analytics_entities;
import 'portfolio_metric_card.dart';


/// Configuration class for platform-specific heatmap settings
class PortfolioHeatmapConfig {
  const PortfolioHeatmapConfig({
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

  /// Mobile configuration
  static const mobile = PortfolioHeatmapConfig(
    defaultLayout: HeatmapLayoutType.list,
    compactMode: true,
    showSelectors: true,
    templateType: UniversalTemplateType.compact,
    showSubCards: false,
    padding: EdgeInsets.all(8.0),
    title: 'Heatmap Overview',
    subtitle: '', // Completely removed the down side text
    logTag: 'PortfolioHeatmap.Mobile',
  );

  /// Web configuration
  static const web = PortfolioHeatmapConfig(
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
  final PortfolioHeatmapConfig config;

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

  void _loadHeatmapData() {
    final selectedTimeframe = ref.read(appTimeFrameProvider);
    CommonLogger.methodEntry(
      '_loadHeatmapData',
      tag: '${widget.config.logTag}.Data',
      metadata: {
        'portfolioId': widget.portfolioId,
        'timeFrame': selectedTimeframe.name,
        'metric': _selectedMetric.name,
        'sector': _selectedSector?.name ?? 'all',
        'marketCap': _selectedMarketCap?.name ?? 'all',
      },
    );

    final portfolioAnalyticsCubit = context.read<PortfolioAnalyticsCubit>();
    final portfolioHeatmapCubit = context.read<PortfolioHeatmapCubit>();

    // Load analytics data first
    portfolioAnalyticsCubit
        .loadAnalytics(widget.portfolioId, timeFrame: selectedTimeframe)
        .then((_) {
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
            ? SingleChildScrollView(child: content)
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
    final customConfig = convertedHeatmapData.configuration.copyWith(
      display: convertedHeatmapData.configuration.display?.copyWith(
        showPerformance: false, // Hides old default legend
      ),
      layout: convertedHeatmapData.configuration.layout?.copyWith(
        layoutType: _selectedLayout,
      ),
    );

    // Drill-down filtering
    HeatmapData displayData = convertedHeatmapData;
    if (_drillDownTile != null && _drillDownTile!.children != null) {
      displayData = convertedHeatmapData.copyWith(
        tiles: _drillDownTile!.children,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SUMMARY CARDS ROW ──
        _buildSummaryCardsRow(),
        const SizedBox(height: 16),

        // ── EQUITY DISTRIBUTION HEADER ──
        _buildEquityDistributionHeader(context),
        const SizedBox(height: 12),

        // ── DRILLDOWN BREADCRUMB ──
        if (_drillDownTile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => setState(() => _drillDownTile = null),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Portfolio > ${_drillDownTile!.displayName}',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        // ── MAIN HEATMAP ──
        if (widget.config.compactMode)
          SizedBox(
            width: double.infinity,
            // Adaptive height: 45% of screen height, clamped between 320–600px.
            height: (MediaQuery.of(context).size.height * 0.45)
                .clamp(320.0, 600.0),
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
        // Derive values from portfolio state
        String totalValue = '--';
        String todayChange = '--';
        double todayChangePct = 0;
        bool isTodayPositive = true;

        if (portfolioState is PortfolioLoaded) {
          final summary = portfolioState.summary;
          totalValue = summary.formattedTotalValue;
          todayChange = summary.formattedTodayChange;
          todayChangePct = summary.todayChangePercentage;
          isTodayPositive = summary.isTodayPositive;
        }

        // Derive top/worst sectors from analytics
        return BlocBuilder<PortfolioAnalyticsCubit, PortfolioAnalyticsState>(
          builder: (context, analyticsState) {
            String topSector = '--';
            String topSectorChange = '';
            String worstSector = '--';
            String worstSectorChange = '';

            if (analyticsState is PortfolioAnalyticsLoaded &&
                analyticsState.heatmap != null &&
                analyticsState.heatmap!.sectors.isNotEmpty) {
              final sectors = List<analytics_entities.Sector>.from(
                analyticsState.heatmap!.sectors,
              )
                ..removeWhere((s) {
                  final name = s.sectorName.trim();
                  return name.isEmpty || name == '-' || name.toLowerCase() == 'unknown';
                })
                ..sort((a, b) => b.changePercent.compareTo(a.changePercent));
              topSector = sectors.first.sectorName;
              topSectorChange = sectors.first.formattedChangePercent;
              worstSector = sectors.last.sectorName;
              worstSectorChange = sectors.last.formattedChangePercent;
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
                    accentColor: const Color(0xFF0BA95B),
                    compact: isSmallMobile,
                    glowBorder: true,
                  ),
                  PortfolioMetricCard(
                    title: '24H CHANGE',
                    value: todayChange,
                    subtitle: '${isTodayPositive ? '+' : ''}${todayChangePct.toStringAsFixed(2)}%',
                    accentColor: isTodayPositive
                        ? const Color(0xFF0BA95B)
                        : const Color(0xFFB22222),
                    isPositive: isTodayPositive,
                    compact: isSmallMobile,
                    glowBorder: true,
                  ),
                  PortfolioMetricCard(
                    title: 'TOP SECTOR',
                    value: topSector,
                    subtitle: topSectorChange,
                    accentColor: const Color(0xFF0BA95B),
                    isPositive: !topSectorChange.startsWith('-'),
                    compact: isSmallMobile,
                    glowBorder: true,
                  ),
                  PortfolioMetricCard(
                    title: 'WEAKEST SECTOR',
                    value: worstSector,
                    subtitle: worstSectorChange,
                    accentColor: const Color(0xFFB22222),
                    isPositive: !worstSectorChange.startsWith('-'),
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

  /// Builds the "Equity Distribution" header with pill tag, status, and legend
  Widget _buildEquityDistributionHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;

        final titleRow = Row(
          children: [
            Text(
              'Equity Distribution',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'MARKET CAP WEIGHTED',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        );

        final legendRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendDot(context, const Color(0xFF0BA95B), 'Outperform'),
            const SizedBox(width: 12),
            _buildLegendDot(context, const Color(0xFF6B7280), 'Neutral'),
            const SizedBox(width: 12),
            _buildLegendDot(context, const Color(0xFFB22222), 'Underperform'),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleRow,
                  legendRow,
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const GlobalTimeFrameBar(),
                  _buildInlineStatusBar(context),
                ],
              ),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              titleRow,
              const Spacer(),
              const GlobalTimeFrameBar(),
              const SizedBox(width: 16),
              _buildInlineStatusBar(context),
              const SizedBox(width: 16),
              legendRow,
            ],
          );
        }
      },
    );
  }

  Widget _buildLegendDot(BuildContext context, Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          fontSize: 11,
        ),
      ),
    ],
  );

  Widget _buildInlineStatusBar(BuildContext context) {
    return BlocBuilder<PortfolioCubit, PortfolioState>(
      builder: (context, state) {
        bool isConnected = false;
        double todayChangePct = 0.0;
        if (state is PortfolioLoaded) {
          isConnected = state.isLiveDataActive;
          todayChangePct = state.summary.todayChangePercentage;
        }

        Color statusColor = state is! PortfolioLoaded
            ? const Color(0xFFF39C12)
            : isConnected
                ? const Color(0xFF0BA95B)
                : const Color(0xFFF39C12);
        String statusText = state is! PortfolioLoaded
            ? 'LOADING...'
            : isConnected
                ? 'LIVE FEED ACTIVE'
                : 'SYNCING...';

        final isPositive = todayChangePct >= 0;
        final sentimentColor =
            isPositive ? const Color(0xFF0BA95B) : const Color(0xFFB22222);
        final sentimentText =
            isPositive ? 'BULLISH' : 'BEARISH';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.access_time, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7), size: 12),
            const SizedBox(width: 4),
            BlocBuilder<PortfolioHeatmapCubit, PortfolioHeatmapState>(
              builder: (context, heatmapState) {
                String timeText = 'Just now';
                if (heatmapState is PortfolioHeatmapLoaded) {
                  final diff = DateTime.now().difference(heatmapState.lastUpdated);
                  if (diff.inMinutes > 0) {
                    timeText = '${diff.inMinutes}m ago';
                  } else if (diff.inSeconds > 0) {
                    timeText = '${diff.inSeconds}s ago';
                  }
                }
                return Text(
                  'Updated: $timeText',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10),
                );
              },
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: sentimentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sentimentColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                sentimentText,
                style: TextStyle(
                  color: sentimentColor, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        );
      },
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

    // Reload heatmap data with new selections (timeframe reloads via provider listen)
    if (timeFrame == null) {
      _loadHeatmapData();
    } else if (metric != null || sector != null || marketCap != null || layout != null) {
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
