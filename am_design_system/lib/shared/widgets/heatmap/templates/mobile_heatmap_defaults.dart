import 'package:flutter/material.dart';

import '../../selectors/selectors.dart';
import '../configs/display_config.dart';
import '../configs/interaction_config.dart';
import '../configs/layout_config.dart' as layout_config;
import '../configs/selector_config.dart';
import '../configs/visual_config.dart';
import '../heatmap_config.dart';

/// Mobile-optimized heatmap default configurations
/// Provides sensible defaults for mobile devices with commonly needed features enabled
/// Use these default configs as the base for most mobile heatmap implementations
class MobileHeatmapDefaults {
  /// Portfolio-specific mobile configuration
  /// - Portfolio-relevant selectors enabled
  /// - Full performance display
  /// - Optimized for portfolio viewing
  static HeatmapConfig portfolio({
    String? title,
    Color? accentColor,
    SelectorLayoutType? selectorLayout,
  }) => HeatmapConfig(
    selectors: SelectorConfig(
      showSectorSelector: false, // Too crowded on mobile
      showMarketCapSelector: false, // Less relevant for personal portfolios
      availableTimeFrames: TimeFrame.mobileTimeFrames,
      availableMetrics: MetricType.mobileMetrics,
      availableSectors: SectorType.allSectors,
      availableMarketCaps: MarketCapType.allMarketCaps,
      selectorLayout: selectorLayout ?? SelectorLayoutType.compact,
    ),
    display: const DisplayConfig(
      showSubCards: false,
      showLegend: false,
      showRefreshButton: false,
    ),
    layout: layout_config.LayoutConfig(
      layoutType: HeatmapLayoutType.grid,
      compactView: true,
      customTitle: title ?? 'Portfolio',
    ),
    interactions: const InteractionConfig(enableHoverEffects: false),
    visual: VisualConfig(
      selectorPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      cardPadding: const EdgeInsets.all(12),
      selectorSpacing: 8,
      accentColor: accentColor ?? Colors.blue,
      borderRadius: 8,
      elevation: 2,
      animationDuration: const Duration(milliseconds: 250),
      tileSpacing: 2,
    ),
  );

  /// List all available mobile default configurations
  static Map<
    String,
    HeatmapConfig Function({
      String? title,
      Color? accentColor,
      SelectorLayoutType? selectorLayout,
    })
  >
  get defaults => {'portfolio': portfolio};
}
