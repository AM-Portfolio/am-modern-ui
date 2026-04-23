import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';

import '../../models/heatmap/heatmap_tile_data.dart';
import '../selectors/selectors.dart';
import 'configs/display_config.dart';
import 'configs/interaction_config.dart';
import 'configs/layout_config.dart';
import 'configs/selector_config.dart';
import 'configs/visual_config.dart';

/// Main heatmap configuration that composes smaller, focused config objects
/// This provides a clean API while breaking down complexity into manageable pieces
class HeatmapConfig {
  const HeatmapConfig({
    this.selectors,
    this.display,
    this.layout,
    this.interactions,
    this.visual,
  });

  /// Create from mobile defaults configuration
  factory HeatmapConfig.fromMobile(HeatmapConfig mobileConfig) => mobileConfig;

  /// Create from web defaults configuration
  factory HeatmapConfig.fromWeb(HeatmapConfig webConfig) => webConfig;

  /// Selector configuration (what selectors to show and their options) - nullable
  final SelectorConfig? selectors;

  /// Display configuration (what information to show on tiles) - nullable
  final DisplayConfig? display;

  /// Layout configuration (how to arrange the heatmap) - nullable
  final LayoutConfig? layout;

  /// Interaction configuration (how users can interact) - nullable
  final InteractionConfig? interactions;

  /// Visual configuration (styling, spacing, colors) - nullable
  final VisualConfig? visual;

  /// Get effective selector configuration with fallbacks
  SelectorConfig get effectiveSelectors => selectors ?? const SelectorConfig();

  /// Get effective display configuration with fallbacks
  DisplayConfig get effectiveDisplay => display ?? const DisplayConfig();

  /// Get effective layout configuration with fallbacks
  LayoutConfig get effectiveLayout => layout ?? const LayoutConfig();

  /// Get effective interaction configuration with fallbacks
  InteractionConfig get effectiveInteractions =>
      interactions ?? const InteractionConfig();

  /// Get effective visual configuration with fallbacks
  VisualConfig get effectiveVisual => visual ?? const VisualConfig();

  // Backward compatibility getters (delegate to sub-configs)
  bool get showTimeFrameSelector => effectiveSelectors.showTimeFrameSelector;
  bool get showMetricSelector => effectiveSelectors.showMetricSelector;
  bool get showSectorSelector => effectiveSelectors.showSectorSelector;
  bool get showMarketCapSelector => effectiveSelectors.showMarketCapSelector;

  List<TimeFrame>? get availableTimeFrames =>
      effectiveSelectors.availableTimeFrames;
  List<MetricType>? get availableMetrics => effectiveSelectors.availableMetrics;
  List<SectorType>? get availableSectors => effectiveSelectors.availableSectors;
  List<MarketCapType>? get availableMarketCaps =>
      effectiveSelectors.availableMarketCaps;

  bool get showSubCards => effectiveDisplay.showSubCards;
  bool get showPerformance => effectiveDisplay.showPerformance;
  bool get showWeightage => effectiveDisplay.showWeightage;
  bool get showValue => effectiveDisplay.showValue;
  bool get showLegend => effectiveDisplay.showLegend;
  bool get showHeader => effectiveDisplay.showHeader;
  bool get showRefreshButton => effectiveDisplay.showRefreshButton;

  HeatmapLayoutType get layoutType =>
      HeatmapLayoutType.values[effectiveLayout.layoutType.index];
  bool get compactView => effectiveLayout.compactView;
  bool get showTitle => effectiveLayout.showTitle;
  String? get customTitle => effectiveLayout.customTitle;

  bool get enableTileInteraction => effectiveInteractions.enableTileInteraction;
  bool get enableSelectorInteraction =>
      effectiveInteractions.enableSelectorInteraction;
  bool get showLoadingStates => effectiveInteractions.showLoadingStates;
  bool get showErrorStates => effectiveInteractions.showErrorStates;
  bool get enableHoverEffects => effectiveInteractions.enableHoverEffects;
  bool get enableMultiSelect => effectiveInteractions.enableMultiSelect;
  bool get enableDragAndDrop => effectiveInteractions.enableDragAndDrop;

  EdgeInsets? get selectorPadding => effectiveVisual.selectorPadding;
  EdgeInsets? get cardPadding => effectiveVisual.cardPadding;
  double? get selectorSpacing => effectiveVisual.selectorSpacing;
  Color? get accentColor => effectiveVisual.accentColor;
  double? get borderRadius => effectiveVisual.borderRadius;
  double? get elevation => effectiveVisual.elevation;
  Duration? get animationDuration => effectiveVisual.animationDuration;
  double? get tileSpacing => effectiveVisual.tileSpacing;

  // Additional missing properties for compatibility
  double? get minTileWidth => effectiveLayout.compactView ? 80.0 : 120.0;
  double? get maxTileWidth => effectiveLayout.compactView ? 180.0 : 300.0;
  double? get minTileHeight => effectiveLayout.compactView ? 60.0 : 80.0;
  double? get maxTileHeight => effectiveLayout.compactView ? 120.0 : 200.0;
  EdgeInsets? get tileMargin => const EdgeInsets.all(1.0);
  EdgeInsets? get tilePadding => const EdgeInsets.all(4.0);
  HeatmapColorSchemeType get colorScheme => HeatmapColorSchemeType.performance;

  /// Copy this configuration with some sub-configs overridden
  HeatmapConfig copyWith({
    SelectorConfig? selectors,
    DisplayConfig? display,
    LayoutConfig? layout,
    InteractionConfig? interactions,
    VisualConfig? visual,
  }) => HeatmapConfig(
    selectors: selectors ?? this.selectors,
    display: display ?? this.display,
    layout: layout ?? this.layout,
    interactions: interactions ?? this.interactions,
    visual: visual ?? this.visual,
  );

  /// Create configuration with modified selectors
  HeatmapConfig withSelectors({
    bool timeFrame = true,
    bool metric = true,
    bool sector = false,
    bool marketCap = false,
  }) => copyWith(
    selectors: effectiveSelectors.copyWith(
      showTimeFrameSelector: timeFrame,
      showMetricSelector: metric,
      showSectorSelector: sector,
      showMarketCapSelector: marketCap,
    ),
  );

  /// Create configuration with specific display features
  HeatmapConfig withDisplay({
    bool? subCards,
    bool? performance,
    bool? weightage,
    bool? value,
    bool? legend,
    bool? header,
  }) => copyWith(
    display: effectiveDisplay.copyWith(
      showSubCards: subCards,
      showPerformance: performance,
      showWeightage: weightage,
      showValue: value,
      showLegend: legend,
      showHeader: header,
    ),
  );

  /// Create configuration with specific layout settings
  HeatmapConfig withLayout({
    HeatmapLayoutType? type,
    bool? compact,
    String? title,
  }) => copyWith(
    layout: effectiveLayout.copyWith(
      layoutType: type,
      compactView: compact,
      customTitle: title,
      showTitle: title != null,
    ),
  );

  /// Create configuration with specific interaction settings
  HeatmapConfig withInteractions({
    bool? tileInteraction,
    bool? selectorInteraction,
    bool? loadingStates,
    bool? errorStates,
    bool? hoverEffects,
    bool? multiSelect,
    bool? dragAndDrop,
  }) => copyWith(
    interactions: effectiveInteractions.copyWith(
      enableTileInteraction: tileInteraction,
      enableSelectorInteraction: selectorInteraction,
      showLoadingStates: loadingStates,
      showErrorStates: errorStates,
      enableHoverEffects: hoverEffects,
      enableMultiSelect: multiSelect,
      enableDragAndDrop: dragAndDrop,
    ),
  );

  /// Create configuration with specific visual settings
  HeatmapConfig withVisual({
    EdgeInsets? selectorPadding,
    EdgeInsets? cardPadding,
    double? selectorSpacing,
    Color? accentColor,
    double? borderRadius,
    double? elevation,
    Duration? animationDuration,
    double? tileSpacing,
  }) => copyWith(
    visual: effectiveVisual.copyWith(
      selectorPadding: selectorPadding,
      cardPadding: cardPadding,
      selectorSpacing: selectorSpacing,
      accentColor: accentColor,
      borderRadius: borderRadius,
      elevation: elevation,
      animationDuration: animationDuration,
      tileSpacing: tileSpacing,
    ),
  );

  /// Check if any selectors should be shown
  bool get hasSelectors =>
      showTimeFrameSelector ||
      showMetricSelector ||
      showSectorSelector ||
      showMarketCapSelector;

  /// Check if this is a minimal configuration
  bool get isMinimal => !showSubCards && !showLegend && compactView;

  /// Check if this is a mobile configuration
  bool get isMobile =>
      compactView && !showSectorSelector && !showMarketCapSelector;

  /// Check if this is a web configuration
  bool get isWeb => !compactView && showSectorSelector && showMarketCapSelector;
}
