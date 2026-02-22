import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart' hide MarketCapType, MetricType, TimeFrame, SectorType;
import '../cubit/portfolio_analytics_cubit.dart';
import '../cubit/portfolio_analytics_state.dart';
import '../cubit/portfolio_heatmap_cubit.dart';
import '../cubit/portfolio_heatmap_state.dart';
import '../mappers/sector_heatmap_converter.dart';

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
    showSelectors: false,
    templateType: UniversalTemplateType.compact,
    showSubCards: false,
    padding: EdgeInsets.all(12.0),
    title: 'Mobile: Portfolio Heatmap',
    subtitle: 'Performance by sector',
    logTag: 'PortfolioHeatmap.Mobile',
  );

  /// Web configuration
  static const web = PortfolioHeatmapConfig(
    defaultLayout: HeatmapLayoutType.grid,
    compactMode: false,
    showSelectors: true,
    templateType: UniversalTemplateType.full,
    showSubCards: true,
    padding: EdgeInsets.all(16.0),
    title: 'Web: Portfolio Heatmap',
    subtitle: 'Performance by sector',
    logTag: 'PortfolioHeatmap.Web',
  );
}

/// Common Portfolio Heatmap Widget
/// Shared implementation between web and mobile with configurable behavior
class PortfolioHeatmapWidget extends ConsumerStatefulWidget {
  const PortfolioHeatmapWidget({
    required this.userId,
    required this.portfolioId,
    required this.config,
    super.key,
    this.portfolioName,
  });

  final String userId;
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
  late TimeFrame _selectedTimeframe;
  SectorType? _selectedSector;
  MarketCapType? _selectedMarketCap;
  late HeatmapLayoutType _selectedLayout;

  @override
  void initState() {
    super.initState();

    // Initialize with config defaults
    _selectedMetric = MetricType.changePercent;
    _selectedTimeframe = TimeFrame.oneYear;
    _selectedLayout = widget.config.defaultLayout;

    CommonLogger.info(
      'PortfolioHeatmapWidget initialized',
      tag: '${widget.config.logTag}.Init',
    );
    CommonLogger.debug(
      'Parameters: userId=${widget.userId}, portfolioId=${widget.portfolioId}, portfolioName=${widget.portfolioName ?? 'null'}',
      tag: '${widget.config.logTag}.Init',
    );
    _loadHeatmapData();
  }

  void _loadHeatmapData() {
    CommonLogger.methodEntry(
      '_loadHeatmapData',
      tag: '${widget.config.logTag}.Data',
      metadata: {
        'portfolioId': widget.portfolioId,
        'timeFrame': _selectedTimeframe.name,
        'metric': _selectedMetric.name,
        'sector': _selectedSector?.name ?? 'all',
        'marketCap': _selectedMarketCap?.name ?? 'all',
      },
    );

    final portfolioAnalyticsCubit = context.read<PortfolioAnalyticsCubit>();
    final portfolioHeatmapCubit = context.read<PortfolioHeatmapCubit>();

    // Load analytics data first
    portfolioAnalyticsCubit
        .loadAnalytics(widget.portfolioId)
        .then((_) {
          CommonLogger.info(
            'Analytics loaded, proceeding with heatmap data',
            tag: '${widget.config.logTag}.Data',
          );

          portfolioHeatmapCubit.loadHeatmapData(
            portfolioId: widget.portfolioId,
            timeFrame: _selectedTimeframe,
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
            timeFrame: _selectedTimeframe,
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
  Widget build(BuildContext context) =>
      Padding(padding: widget.config.padding, child: _buildHeatmapContent());

  /// Main heatmap content with state handling using dual cubit approach
  Widget _buildHeatmapContent() => StreamBuilder<PortfolioHeatmapState>(
    stream: context.read<PortfolioHeatmapCubit>().stream,
    initialData: PortfolioHeatmapInitial(),
    builder: (context, snapshot) {
      final state = snapshot.data ?? PortfolioHeatmapInitial();

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
    CommonLogger.info(
      'Showing heatmap: ${state.heatmapData.tiles.length} tiles',
      tag: '${widget.config.logTag}.UI',
    );

    // Get analytics data from the cubit
    final portfolioAnalyticsCubit = context.read<PortfolioAnalyticsCubit>();
    final analyticsState = portfolioAnalyticsCubit.state;

    // Check if analytics data is available
    if (analyticsState is! PortfolioAnalyticsLoaded ||
        analyticsState.heatmap == null) {
      CommonLogger.warning(
        'Analytics data not available for heatmap display',
        tag: '${widget.config.logTag}.UI',
      );
      return const Center(child: Text('Analytics data is loading...'));
    }

    // Use sector heatmap converter to convert analytics data
    final convertedHeatmapData = SectorHeatmapConverter.convertToHeatmapData(
      heatmap: analyticsState.heatmap,
      showSubCards: widget.config.showSubCards,
      title: widget.config.title,
      subtitle: widget.config.subtitle,
      accentColor: Theme.of(context).primaryColor,
    );

    CommonLogger.debug(
      'Converted heatmap data: ${convertedHeatmapData.tiles.length} tiles',
      tag: '${widget.config.logTag}.UI',
    );

    // Create configuration with selected layout
    final customConfig = convertedHeatmapData.configuration.copyWith(
      layout: convertedHeatmapData.configuration.layout?.copyWith(
        layoutType: _selectedLayout,
      ),
    );

    // Return UniversalHeatmapWidget with configuration
    return SizedBox(
      width: double.infinity,
      child: UniversalHeatmapWidget(
        investmentType: InvestmentType.portfolio,
        heatmapData: convertedHeatmapData,
        config: _mapToWidgetConfig(customConfig),
        title: widget.config.title,
        showSelectors: widget.config.showSelectors,
        compactMode: widget.config.compactMode,
        selectedSector: _selectedSector,
        onTilePressed: () {
          CommonLogger.userAction(
            'Heatmap tile pressed',
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
      _selectedTimeframe = timeFrame;
    }
    if (metric != null) {
      _selectedMetric = metric;
    }
    if (sector != null) {
      _selectedSector = sector;
    }
    if (marketCap != null) {
      _selectedMarketCap = marketCap;
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

    // Reload heatmap data with new selections
    _loadHeatmapData();
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

