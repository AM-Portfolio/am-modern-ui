import 'package:flutter/material.dart';

import '../../selectors/selectors.dart';
import '../configs/display_config.dart';
import '../configs/interaction_config.dart';
import '../configs/layout_config.dart' as layout_config;
import '../configs/selector_config.dart';
import '../configs/visual_config.dart';
import '../heatmap_config.dart';

/// Web-optimized heatmap default configurations
/// Provides sensible defaults for web/desktop with full features enabled
/// Use these default configs as the base for most web heatmap implementations
class WebHeatmapDefaults {
  /// Portfolio-specific web configuration
  /// - Portfolio-relevant selectors
  /// - Complete performance display
  /// - Enhanced interactions for portfolio management
  static HeatmapConfig portfolio({
    String? title,
    Color? accentColor,
    SelectorLayoutType? selectorLayout,
  }) => HeatmapConfig(
    selectors: SelectorConfig(
      showTimeFrameSelector: false,
      showMarketCapSelector: false, // Less relevant for personal portfolios
      availableTimeFrames: TimeFrame.webTimeFrames,
      availableMetrics: MetricType.webMetrics,
      availableSectors: SectorType.allSectors,
      availableMarketCaps: MarketCapType.allMarketCaps,
      selectorLayout: selectorLayout ?? SelectorLayoutType.compact,
    ),
    display: const DisplayConfig(),
    layout: layout_config.LayoutConfig(
      customTitle: title ?? 'Portfolio Overview',
    ),
    interactions: const InteractionConfig(
      enableMultiSelect: true, // Useful for comparing holdings
    ),
    visual: VisualConfig(
      selectorPadding: const EdgeInsets.all(18),
      cardPadding: const EdgeInsets.all(18),
      selectorSpacing: 18,
      accentColor: accentColor ?? Colors.blue,
      borderRadius: 12,
      elevation: 4,
      animationDuration: const Duration(milliseconds: 300),
      tileSpacing: 4,
    ),
  );

  /// List all available web default configurations
  static Map<
    String,
    HeatmapConfig Function({String? title, Color? accentColor})
  >
  get defaults => {'portfolio': portfolio};
}
