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
    super.key,
    this.config,
    this.onTilePressed,
    this.onFiltersChanged,
    this.showSelectors,
    this.compactMode,
    this.isLoading = false,
    this.error,
    this.templateType = UniversalTemplateType.adaptive,
    this.selectedSector,
  });

  /// Investment type (portfolio, index, mutual funds, ETF)
  final InvestmentType investmentType;

  /// Heatmap data to be displayed
  final HeatmapData heatmapData;

  /// Configuration overrides (optional, uses basic config if not provided)
  final ui_config.HeatmapConfig? config;

  /// Custom title (required)
  final String title;

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

  /// Currently selected sector for filtering
  final SectorType? selectedSector;

  @override
  Widget build(BuildContext context) {
    final buildStartTime = DateTime.now();

    // Log widget initialization
    CommonLogger.info(
      'UniversalHeatmapWidget build started for ${investmentType.toString()}',
      tag: 'UniversalHeatmapWidget',
    );

    CommonLogger.debug(
      'Widget config: showSelectors=$showSelectors, '
      'title=$title, compactMode=$compactMode, isLoading=$isLoading, '
      'hasError=${error != null}, templateType=${templateType.name}',
      tag: 'UniversalHeatmapWidget',
    );

    // Log complete heatmap data as JSON string
    CommonLogger.debug(
      'Complete HeatmapData JSON: ${heatmapData.toJsonString()}',
      tag: 'UniversalHeatmapWidget.HeatmapData',
    );

    // Get effective config (use provided config or basic fallback)
    final effectiveConfig =
        config ??
        UniversalHeatmapConfigManager.getBasicConfig(
          title: title,
          compactMode: compactMode ?? false,
        );

    // Build the universal template by composing the 3 separate components
    final widget = _buildUniversalTemplate(
      context,
      effectiveConfig,
      heatmapData,
    );

    // Log build completion with performance metrics
    final buildDuration = DateTime.now().difference(buildStartTime);
    CommonLogger.info(
      'UniversalHeatmapWidget build completed in ${buildDuration.inMilliseconds}ms - '
      'Investment: ${investmentType.name}, Template: ${templateType.name}, '
      'Tiles: ${heatmapData.tiles.length}, Config: ${effectiveConfig.layoutType}',
      tag: 'UniversalHeatmapWidget.Performance',
    );

    return widget;
  }

  /// Build the universal template by composing the 3 separate components
  Widget _buildUniversalTemplate(
    BuildContext context,
    ui_config.HeatmapConfig effectiveConfig,
    HeatmapData heatmapData,
  ) {
    CommonLogger.debug(
      'Building universal template: layout=${effectiveConfig.layoutType}, '
      'tiles=${heatmapData.tiles.length}, isLoading=$isLoading',
      tag: 'UniversalHeatmapWidget.Template',
    );

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
        );

    CommonLogger.debug(
      'Display template created with layout=${effectiveConfig.layoutType}',
      tag: 'UniversalHeatmapWidget.Template',
    );

    // 2. Create Selector Template (handles filter UI)
    final selectorTemplate =
        UniversalHeatmapTemplateFactory.createSelectorTemplate(
          config: effectiveConfig,
          investmentType: investmentType,
          onFiltersChanged: onFiltersChanged,
        );

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
    );
  }
}
