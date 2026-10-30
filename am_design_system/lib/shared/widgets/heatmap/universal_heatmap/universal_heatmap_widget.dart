import 'package:flutter/material.dart';

import 'package:am_design_system/core/utils/common_logger.dart';
import '../../../models/heatmap.dart';
import '../../selectors/selectors.dart';
import '../heatmap_config.dart' as ui_config;
import 'config_manager.dart';
import 'template_factory.dart';
import 'types.dart';

/// Universal heatmap widget template that orchestrates 3 separate components based on config
/// This is the main widget that should be used for displaying heatmaps across the app
/// Creates: DisplayTemplate + SelectorTemplate + LayoutTemplate based on configuration
class UniversalHeatmapWidget extends StatelessWidget {
  const UniversalHeatmapWidget({
    required this.investmentType,
    required this.heatmapData,
    required this.title,
    this.subtitle,
    super.key,
    this.config,
    this.onTilePressed,
    this.onFiltersChanged,
    this.showSelectors,
    this.compactMode,
    this.isLoading = false,
    this.error,
    this.templateType = UniversalTemplateType.adaptive,
    this.selectedTimeFrame,
    this.selectedMetric,
    this.selectedSector,
    this.selectedMarketCap,
    this.selectedLayout,
    this.customHeader,
  });

  /// Investment type (portfolio, index, mutual funds, ETF)
  final InvestmentType investmentType;

  /// Heatmap data to be displayed
  final HeatmapData heatmapData;

  /// Configuration overrides (optional, uses basic config if not provided)
  final ui_config.HeatmapConfig? config;

  /// Custom title (required)
  final String title;

  /// Custom subtitle (optional)
  final String? subtitle;

  /// Callback when a tile is pressed
  final VoidCallback? onTilePressed;

  /// Callback when filters change
  final Function({
    TimeFrame? timeFrame,
    MetricType? metric,
    SectorType? sector,
    MarketCapType? marketCap,
    HeatmapLayoutType? layout,
  })?
  onFiltersChanged;

  /// Whether to show selectors (can override config)
  final bool? showSelectors;

  /// Whether to use compact mode (can override config)
  final bool? compactMode;

  /// Loading state
  final bool isLoading;

  /// Error message
  final String? error;

  /// Template composition type
  final UniversalTemplateType templateType;

  /// Currently selected timeframe for filtering
  final TimeFrame? selectedTimeFrame;

  /// Currently selected metric for filtering
  final MetricType? selectedMetric;

  /// Currently selected sector for filtering
  final SectorType? selectedSector;

  /// Currently selected market cap for filtering
  final MarketCapType? selectedMarketCap;
  /// Currently selected layout
  final HeatmapLayoutType? selectedLayout;

  /// When set, replaces the default card title/subtitle header.
  final Widget? customHeader;

  @override
  Widget build(BuildContext context) {
    final buildStartTime = DateTime.now();

    var effectiveConfig =
        config ??
        UniversalHeatmapConfigManager.getBasicConfig(
          title: title,
          compactMode: compactMode ?? false,
        );

    if (selectedLayout != null) {
      effectiveConfig = effectiveConfig.withLayout(type: selectedLayout);
    }

    // Build the universal template by composing the 3 separate components
    final widget = _buildUniversalTemplate(
      context,
      effectiveConfig,
      heatmapData,
    );

    assert(() {
      final buildDuration = DateTime.now().difference(buildStartTime);
      CommonLogger.debug(
        'UniversalHeatmapWidget build ${buildDuration.inMilliseconds}ms '
        'tiles=${heatmapData.tiles.length} layout=${effectiveConfig.layoutType}',
        tag: 'UniversalHeatmapWidget.Performance',
      );
      return true;
    }());

    return widget;
  }

  /// Build the universal template by composing the 3 separate components
  Widget _buildUniversalTemplate(
    BuildContext context,
    ui_config.HeatmapConfig effectiveConfig,
    HeatmapData heatmapData,
  ) {
    final data = heatmapData;

    // 1. Create Display Template (handles tile rendering)
    final displayTemplate =
        UniversalHeatmapTemplateFactory.createDisplayTemplate(
          heatmapData: data,
          config: effectiveConfig,
          isLoading: isLoading,
          error: error,
          onTilePressed: onTilePressed,
          selectedSector: selectedSector,
          selectedMetric: selectedMetric,
        );

    // 2. Create Selector Template (handles filter UI)
    final selectorTemplate = (showSelectors ?? true)
        ? UniversalHeatmapTemplateFactory.createSelectorTemplate(
            config: effectiveConfig,
            investmentType: investmentType,
            onFiltersChanged: onFiltersChanged,
            selectedTimeFrame: selectedTimeFrame,
            selectedMetric: selectedMetric,
            selectedSector: selectedSector,
            selectedMarketCap: selectedMarketCap,
            selectedLayout: selectedLayout,
          )
        : null;

    // 3. Create Layout Template (handles overall structure)
    return UniversalHeatmapTemplateFactory.createLayoutTemplate(
      context: context,
      templateType: templateType,
      config: effectiveConfig,
      data: data,
      investmentType: investmentType,
      displayWidget: displayTemplate,
      selectorWidget: selectorTemplate,
      customTitle: title,
      customSubtitle: subtitle,
      customHeader: customHeader,
    );
  }
}
