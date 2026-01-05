import '../../selectors/heatmap_layout_selector.dart';

/// Layout configuration for heatmap display
/// Controls how the heatmap is arranged and displayed
class LayoutConfig {
  const LayoutConfig({
    this.layoutType = HeatmapLayoutType.treemap,
    this.compactView = false,
    this.showTitle = true,
    this.customTitle,
    this.showLayoutSelector = false,
  });

  /// Mobile-optimized layout configuration
  factory LayoutConfig.mobile({
    String? title,
    bool showLayoutSelector = false,
  }) => LayoutConfig(
    layoutType: HeatmapLayoutType.grid,
    compactView: true,
    showTitle: title != null,
    customTitle: title,
    showLayoutSelector: showLayoutSelector,
  );

  /// Web-optimized layout configuration
  factory LayoutConfig.web({String? title, bool showLayoutSelector = true}) =>
      LayoutConfig(
        showTitle: title != null,
        customTitle: title,
        showLayoutSelector: showLayoutSelector,
      );

  /// Minimal layout configuration (for widgets, previews)
  factory LayoutConfig.minimal({String? title}) => LayoutConfig(
    layoutType: HeatmapLayoutType.grid,
    compactView: true,
    showTitle: title != null,
    customTitle: title,
  );

  /// Dashboard layout configuration
  factory LayoutConfig.dashboard({
    String? title,
    bool showLayoutSelector = true,
  }) => LayoutConfig(
    showTitle: title != null,
    customTitle: title,
    showLayoutSelector: showLayoutSelector,
  );

  /// Portfolio-specific layout configuration
  factory LayoutConfig.portfolio({String? title}) =>
      LayoutConfig(customTitle: title ?? 'Portfolio Heatmap');

  /// Index fund layout configuration
  factory LayoutConfig.index({String? title}) =>
      LayoutConfig(customTitle: title ?? 'Index Heatmap');

  /// Mutual funds layout configuration
  factory LayoutConfig.mutualFunds({String? title}) => LayoutConfig(
    layoutType: HeatmapLayoutType.grid,
    customTitle: title ?? 'Mutual Funds Heatmap',
  );

  /// ETF layout configuration
  factory LayoutConfig.etf({String? title}) =>
      LayoutConfig(customTitle: title ?? 'ETF Heatmap');

  // Layout options
  final HeatmapLayoutType layoutType;
  final bool compactView;
  final bool showTitle;
  final String? customTitle;
  final bool showLayoutSelector;

  /// Copy with modifications
  LayoutConfig copyWith({
    HeatmapLayoutType? layoutType,
    bool? compactView,
    bool? showTitle,
    String? customTitle,
    bool? showLayoutSelector,
  }) => LayoutConfig(
    layoutType: layoutType ?? this.layoutType,
    compactView: compactView ?? this.compactView,
    showTitle: showTitle ?? this.showTitle,
    customTitle: customTitle ?? this.customTitle,
    showLayoutSelector: showLayoutSelector ?? this.showLayoutSelector,
  );

  /// Get effective title (custom or default)
  String? get effectiveTitle => showTitle ? customTitle : null;

  /// Check if this is a compact layout
  bool get isCompact => compactView;

  /// Check if this is a spacious layout
  bool get isSpacious => !compactView;

  /// Check if layout shows detailed information
  bool get isDetailed =>
      layoutType == HeatmapLayoutType.treemap && !compactView;

  /// Check if layout is optimized for mobile
  bool get isMobileOptimized =>
      layoutType == HeatmapLayoutType.grid && compactView;

  /// Check if layout is optimized for web
  bool get isWebOptimized =>
      layoutType == HeatmapLayoutType.treemap && !compactView;
}
