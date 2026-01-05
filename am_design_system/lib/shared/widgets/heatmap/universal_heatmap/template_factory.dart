import 'package:flutter/material.dart';
import 'package:am_design_system/core/utils/common_logger.dart';


import '../../../models/heatmap.dart';
import '../../selectors/selectors.dart';
import '../configs/selector_config.dart';
import '../heatmap_config.dart' as ui_config;
import '../heatmap_display_template.dart';
import '../heatmap_layout_template.dart';
import '../heatmap_selector_template.dart';
import 'config_manager.dart';
import 'types.dart';

/// Factory for creating heatmap template components
/// Handles the creation of display, selector, and layout templates
class UniversalHeatmapTemplateFactory {
  /// Create display template for heatmap visualization
  static Widget createDisplayTemplate({
    required HeatmapData heatmapData,
    required ui_config.HeatmapConfig config,
    required bool isLoading,
    String? error,
    VoidCallback? onTilePressed,
    SectorType? selectedSector,
  }) {
    CommonLogger.debug(
      'Creating display template with layout=${config.layoutType}, '
      'tiles=${heatmapData.tiles.length}, isLoading=$isLoading, '
      'selectedSector=${selectedSector?.displayName ?? 'all'}',
      tag: 'UniversalHeatmapTemplateFactory.Display',
    );

    return HeatmapDisplayTemplate(
      data: heatmapData,
      isLoading: isLoading,
      error: error,
      onTilePressed: onTilePressed,
      layout: _convertToDisplayLayoutType(config.layoutType),
      selectedSector: selectedSector,
    );
  }

  /// Create selector template for filters
  static Widget? createSelectorTemplate({
    required ui_config.HeatmapConfig config,
    required InvestmentType investmentType,
    Function({
      TimeFrame? timeFrame,
      MetricType? metric,
      SectorType? sector,
      MarketCapType? marketCap,
      HeatmapLayoutType? layout,
    })?
    onFiltersChanged,
  }) {
    if (!_shouldShowSelectors(config)) {
      CommonLogger.debug(
        'Skipping selector template creation - no selectors enabled',
        tag: 'UniversalHeatmapTemplateFactory.Selector',
      );
      return null;
    }

    CommonLogger.debug(
      'Creating selector template with filters: timeFrame=${config.showTimeFrameSelector}, '
      'metric=${config.showMetricSelector}, sector=${config.showSectorSelector}, '
      'marketCap=${config.showMarketCapSelector}',
      tag: 'UniversalHeatmapTemplateFactory.Selector',
    );

    return HeatmapSelectorTemplate(
      initialTimeFrame: UniversalHeatmapConfigManager.getInitialTimeFrame(
        investmentType,
      ),
      initialMetric: UniversalHeatmapConfigManager.getInitialMetric(
        investmentType,
      ),
      initialSector: UniversalHeatmapConfigManager.getInitialSector(
        investmentType,
      ),
      initialMarketCap: UniversalHeatmapConfigManager.getInitialMarketCap(
        investmentType,
      ),
      initialLayout: HeatmapLayoutType.treemap,
      onFiltersChanged: onFiltersChanged,
      showTimeFrame: config.showTimeFrameSelector,
      showMetric: config.showMetricSelector,
      showSector: config.showSectorSelector,
      showMarketCap: config.showMarketCapSelector,
      showLayout: config.effectiveLayout.showLayoutSelector,
      layout: config.selectors?.selectorLayout ?? SelectorLayoutType.compact,
      primaryColor: config.accentColor,
      title: 'Filters',
      availableTimeFrames: config.availableTimeFrames,
      availableMetrics: config.availableMetrics,
      availableSectors: config.availableSectors,
      availableMarketCaps: config.availableMarketCaps,
      availableLayouts:
          config.selectors?.availableLayouts ??
          [
            HeatmapLayoutType.treemap,
            HeatmapLayoutType.grid,
            HeatmapLayoutType.list,
          ],
    );
  }

  /// Create layout template based on template type
  static Widget createLayoutTemplate({
    required BuildContext context,
    required UniversalTemplateType templateType,
    required ui_config.HeatmapConfig config,
    required HeatmapData data,
    required InvestmentType investmentType,
    required Widget displayWidget,
    Widget? selectorWidget,
    String? customTitle,
  }) {
    CommonLogger.methodEntry(
      'createLayoutTemplate',
      tag: 'UniversalHeatmapTemplateFactory.Layout',
      metadata: {
        'templateType': templateType.name,
        'hasSelectors': selectorWidget != null,
        'tilesCount': data.tiles.length,
      },
    );

    final title =
        customTitle ??
        UniversalHeatmapConfigManager.getDefaultTitle(investmentType);
    final subtitle = UniversalHeatmapConfigManager.getDefaultSubtitle(
      investmentType,
    );
    final icon = UniversalHeatmapConfigManager.getInvestmentIcon(
      investmentType,
    );

    Widget result;
    switch (templateType) {
      case UniversalTemplateType.minimal:
        CommonLogger.debug(
          'Creating minimal layout template',
          tag: 'UniversalHeatmapTemplateFactory.Layout',
        );
        result = HeatmapLayoutTemplate(
          data: data,
          displayWidget: displayWidget,
          title: title,
          showLegend: false,
          showSelectors: false,
          icon: icon,
        );
        break;

      case UniversalTemplateType.compact:
        CommonLogger.debug(
          'Creating compact layout template with selectors=${selectorWidget != null}',
          tag: 'UniversalHeatmapTemplateFactory.Layout',
        );
        result = HeatmapLayoutTemplate(
          data: data,
          displayWidget: displayWidget,
          selectorWidget: selectorWidget,
          title: title,
          showSelectors: selectorWidget != null,
          icon: icon,
          padding: const EdgeInsets.all(12),
        );
        break;

      case UniversalTemplateType.full:
        CommonLogger.debug(
          'Creating full layout template with all features enabled',
          tag: 'UniversalHeatmapTemplateFactory.Layout',
        );
        result = HeatmapLayoutTemplate(
          data: data,
          displayWidget: displayWidget,
          selectorWidget: selectorWidget,
          title: title,
          subtitle: subtitle,
          showSelectors: selectorWidget != null,
          icon: icon,
          headerActions: _getHeaderActions(context),
          padding: const EdgeInsets.all(16),
        );
        break;

      case UniversalTemplateType.dashboard:
        CommonLogger.debug(
          'Creating dashboard layout template optimized for widget display',
          tag: 'UniversalHeatmapTemplateFactory.Layout',
        );
        result = HeatmapLayoutTemplate(
          data: data,
          displayWidget: displayWidget,
          selectorWidget: selectorWidget,
          title: title,
          showLegend: false,
          showSelectors: selectorWidget != null,
          icon: icon,
          padding: const EdgeInsets.all(8),
        );
        break;

      case UniversalTemplateType.adaptive:
        // Choose template based on screen size and config
        CommonLogger.debug(
          'Creating adaptive layout template based on screen constraints',
          tag: 'UniversalHeatmapTemplateFactory.Layout',
        );
        result = LayoutBuilder(
          builder: (context, constraints) {
            CommonLogger.debug(
              'Adaptive layout constraints: width=${constraints.maxWidth}',
              tag: 'UniversalHeatmapTemplateFactory.Layout',
            );

            if (constraints.maxWidth < 600) {
              CommonLogger.debug(
                'Using mobile layout (width < 600px)',
                tag: 'UniversalHeatmapTemplateFactory.Layout',
              );
              return HeatmapLayoutTemplate(
                data: data,
                displayWidget: displayWidget,
                selectorWidget: selectorWidget,
                title: title,
                showLegend: false,
                showSelectors: selectorWidget != null,
                icon: icon,
                padding: const EdgeInsets.all(8),
              );
            } else if (constraints.maxWidth < 1024) {
              CommonLogger.debug(
                'Using tablet layout (600px <= width < 1024px)',
                tag: 'UniversalHeatmapTemplateFactory.Layout',
              );
              return HeatmapLayoutTemplate(
                data: data,
                displayWidget: displayWidget,
                selectorWidget: selectorWidget,
                title: title,
                subtitle: subtitle,
                showSelectors: selectorWidget != null,
                icon: icon,
                padding: const EdgeInsets.all(12),
              );
            } else {
              CommonLogger.debug(
                'Using desktop layout (width >= 1024px)',
                tag: 'UniversalHeatmapTemplateFactory.Layout',
              );
              return HeatmapLayoutTemplate(
                data: data,
                displayWidget: displayWidget,
                selectorWidget: selectorWidget,
                title: title,
                subtitle: subtitle,
                showSelectors: selectorWidget != null,
                icon: icon,
                headerActions: _getHeaderActions(context),
                padding: const EdgeInsets.all(16),
              );
            }
          },
        );
        break;
    }

    CommonLogger.methodExit(
      'createLayoutTemplate',
      tag: 'UniversalHeatmapTemplateFactory.Layout',
      metadata: {'result': 'Layout template created for ${templateType.name}'},
    );

    return result;
  }

  /// Helper method to check if selectors should be shown
  static bool _shouldShowSelectors(ui_config.HeatmapConfig config) =>
      config.showTimeFrameSelector ||
      config.showMetricSelector ||
      config.showSectorSelector ||
      config.showMarketCapSelector;

  /// Convert UI config layout to display template layout
  static HeatmapLayoutType _convertToDisplayLayoutType(
    HeatmapLayoutType layoutType,
  ) {
    // Since both enums are now the same, no conversion needed
    return layoutType;
  }

  /// Get header actions for full template
  static List<Widget> _getHeaderActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () {
        CommonLogger.userAction(
          'Refresh button pressed in heatmap header',
          tag: 'UniversalHeatmapTemplateFactory.Interaction',
          metadata: {'action': 'refresh_pressed', 'component': 'header'},
        );
      },
      tooltip: 'Refresh Data',
    ),
    IconButton(
      icon: const Icon(Icons.share),
      onPressed: () {
        CommonLogger.userAction(
          'Share button pressed in heatmap header',
          tag: 'UniversalHeatmapTemplateFactory.Interaction',
          metadata: {'action': 'share_pressed', 'component': 'header'},
        );
      },
      tooltip: 'Share Heatmap',
    ),
  ];
}
