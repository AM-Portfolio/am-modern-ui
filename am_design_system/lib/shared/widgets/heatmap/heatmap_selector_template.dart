import 'package:flutter/material.dart';

import '../../../../core/utils/common_logger.dart';
import '../selectors/selectors.dart';
import 'configs/selector_config.dart';
import 'core/heatmap_selector_core.dart';
import 'mobile/heatmap_selector_mobile.dart';
import 'web/heatmap_selector_web.dart';

/// A template widget that provides adaptive heatmap selector functionality.
///
/// This widget acts as a smart wrapper that chooses between [HeatmapSelectorWeb]
/// and [HeatmapSelectorMobile] based on screen size and configuration.
///
/// Key Features:
/// - Automatically adapts between web and mobile implementations
/// - Configurable breakpoints for responsive behavior
/// - Smart layout selection based on screen size
/// - Proper delegation to existing web/mobile components
///
/// Usage:
/// ```dart
/// HeatmapSelectorTemplate(
///   core: myHeatmapCore,
///   title: 'Stock Heatmap Filters',
///   enableAdaptiveLayout: true,
///   mobileBreakpoint: 768,
/// )
/// ```
class HeatmapSelectorTemplate extends StatefulWidget {
  const HeatmapSelectorTemplate({
    super.key,
    // New clean interface
    this.core,
    this.config,
    this.enableAdaptiveLayout = true,
    this.mobileBreakpoint = 768.0,
    this.tabletBreakpoint = 1024.0,
    this.forceLayout,
    this.onLayoutChanged,
    // Legacy interface for backwards compatibility
    this.initialTimeFrame,
    this.initialMetric,
    this.initialSector,
    this.initialMarketCap,
    this.initialLayout,
    this.onFiltersChanged,
    this.showTimeFrame = true,
    this.showMetric = true,
    this.showSector = true,
    this.showMarketCap = true,
    this.showLayout = true,
    this.layout = SelectorLayoutType.compact,
    this.availableTimeFrames,
    this.availableMetrics,
    this.availableSectors,
    this.availableMarketCaps,
    this.availableLayouts,
    // Common parameters
    this.title,
    this.primaryColor,
    this.showResetButton = true,
  });

  /// The core heatmap state manager (new interface)
  final HeatmapSelectorCore? core;

  /// Optional configuration - if null, auto-generates based on platform
  final SelectorConfig? config;

  /// Widget title displayed at the top
  final String? title;

  /// Primary color for theming
  final Color? primaryColor;

  /// Whether to show the reset button
  final bool showResetButton;

  /// Enable adaptive layout switching based on screen size
  final bool enableAdaptiveLayout;

  // Legacy interface parameters
  final TimeFrame? initialTimeFrame;
  final MetricType? initialMetric;
  final SectorType? initialSector;
  final MarketCapType? initialMarketCap;
  final HeatmapLayoutType? initialLayout;
  final Function({
    TimeFrame? timeFrame,
    MetricType? metric,
    SectorType? sector,
    MarketCapType? marketCap,
    HeatmapLayoutType? layout,
  })?
  onFiltersChanged;
  final bool showTimeFrame;
  final bool showMetric;
  final bool showSector;
  final bool showMarketCap;
  final bool showLayout;
  final SelectorLayoutType layout;
  final List<TimeFrame>? availableTimeFrames;
  final List<MetricType>? availableMetrics;
  final List<SectorType>? availableSectors;
  final List<MarketCapType>? availableMarketCaps;
  final List<HeatmapLayoutType>? availableLayouts;

  /// Breakpoint below which mobile layout is used (in logical pixels)
  final double mobileBreakpoint;

  /// Breakpoint above which desktop layout is used (in logical pixels)
  final double tabletBreakpoint;

  /// Force a specific layout type (overrides adaptive behavior)
  final SelectorLayoutType? forceLayout;

  /// Callback when layout changes due to responsive behavior
  final ValueChanged<SelectorLayoutType>? onLayoutChanged;

  @override
  State<HeatmapSelectorTemplate> createState() =>
      _HeatmapSelectorTemplateState();
}

class _HeatmapSelectorTemplateState extends State<HeatmapSelectorTemplate> {
  late HeatmapSelectorCore _effectiveCore;

  @override
  void initState() {
    super.initState();

    // Create core if not provided (legacy interface)
    if (widget.core != null) {
      _effectiveCore = widget.core!;
    } else {
      _effectiveCore = HeatmapSelectorCore(
        initialTimeFrame: widget.initialTimeFrame,
        initialMetric: widget.initialMetric,
        initialSector: widget.initialSector,
        initialMarketCap: widget.initialMarketCap,
        initialLayout: widget.initialLayout,
        availableTimeFrames: widget.availableTimeFrames,
        availableMetrics: widget.availableMetrics,
        availableSectors: widget.availableSectors,
        availableMarketCaps: widget.availableMarketCaps,
        availableLayouts: widget.availableLayouts,
      );

      // Set up legacy callback forwarding
      _effectiveCore.addListener(_onCoreChanged);
    }

    CommonLogger.debug(
      'HeatmapSelectorTemplate: initialized with adaptive layout=${widget.enableAdaptiveLayout}',
      tag: 'Heatmap.Selector.Template',
    );
  }

  void _onCoreChanged() {
    widget.onFiltersChanged?.call(
      timeFrame: _effectiveCore.selectedTimeFrame,
      metric: _effectiveCore.selectedMetric,
      sector: _effectiveCore.selectedSector,
      marketCap: _effectiveCore.selectedMarketCap,
      layout: _effectiveCore.selectedLayout,
    );
  }

  @override
  void dispose() {
    if (widget.core == null) {
      _effectiveCore.removeListener(_onCoreChanged);
      _effectiveCore.dispose();
    }
    super.dispose();
  }

  /// Determine the appropriate platform based on screen size
  _PlatformType get _platformType {
    if (!widget.enableAdaptiveLayout) {
      // If adaptive layout is disabled, use web as default
      return _PlatformType.web;
    }

    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < widget.mobileBreakpoint) {
      return _PlatformType.mobile;
    } else {
      return _PlatformType.web;
    }
  }

  /// Get the appropriate configuration based on platform
  SelectorConfig get _effectiveConfig {
    if (widget.config != null) {
      return widget.config!;
    }

    // If legacy parameters are provided, create config from them
    if (widget.core == null) {
      return SelectorConfig(
        showTimeFrameSelector: widget.showTimeFrame,
        showMetricSelector: widget.showMetric,
        showSectorSelector: widget.showSector,
        showMarketCapSelector: widget.showMarketCap,
        showLayoutSelector: widget.showLayout,
        selectorLayout: widget.layout,
        availableTimeFrames: widget.availableTimeFrames,
        availableMetrics: widget.availableMetrics,
        availableSectors: widget.availableSectors,
        availableMarketCaps: widget.availableMarketCaps,
        availableLayouts: widget.availableLayouts,
      );
    }

    // Auto-generate config based on platform
    switch (_platformType) {
      case _PlatformType.mobile:
        return SelectorConfig.mobile();
      case _PlatformType.web:
        return SelectorConfig.web();
    }
  }

  /// Get the appropriate layout type based on platform and config
  SelectorLayoutType get _effectiveLayout {
    if (widget.forceLayout != null) {
      return widget.forceLayout!;
    }

    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < widget.mobileBreakpoint) {
      // Mobile: prefer compact layouts
      return SelectorLayoutType.compact;
    } else if (screenWidth < widget.tabletBreakpoint) {
      // Tablet: prefer expanded or dropdown layouts
      return _effectiveConfig.selectorLayout == SelectorLayoutType.compact
          ? SelectorLayoutType.dropdown
          : SelectorLayoutType.expanded;
    } else {
      // Desktop: use configured layout
      return _effectiveConfig.selectorLayout;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _effectiveConfig;

    if (!config.hasSelectors) {
      return const SizedBox.shrink();
    }

    final layout = _effectiveLayout;

    // Notify layout changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLayoutChanged?.call(layout);
    });

    switch (_platformType) {
      case _PlatformType.mobile:
        return _buildMobileSelector(config, layout);
      case _PlatformType.web:
        return _buildWebSelector(config, layout);
    }
  }

  Widget _buildMobileSelector(
    SelectorConfig config,
    SelectorLayoutType layout,
  ) => HeatmapSelectorMobile(
    core: _effectiveCore,
    showTimeFrame: config.showTimeFrameSelector,
    showMetric: config.showMetricSelector,
    showSector: config.showSectorSelector,
    showMarketCap: config.showMarketCapSelector,
    showLayout: config.showLayoutSelector,
    primaryColor: widget.primaryColor,
    title: widget.title,
    showResetButton: widget.showResetButton,
    compactMode: layout == SelectorLayoutType.compact,
  );

  Widget _buildWebSelector(SelectorConfig config, SelectorLayoutType layout) =>
      HeatmapSelectorWeb(
        core: _effectiveCore,
        showTimeFrame: config.showTimeFrameSelector,
        showMetric: config.showMetricSelector,
        showSector: config.showSectorSelector,
        showMarketCap: config.showMarketCapSelector,
        showLayout: config.showLayoutSelector,
        layout: layout,
        primaryColor: widget.primaryColor,
        title: widget.title,
        showResetButton: widget.showResetButton,
      );
}

/// Internal enum to represent platform types
enum _PlatformType { mobile, web }

/// Extension methods for easy template usage
extension HeatmapSelectorTemplateExtensions on HeatmapSelectorTemplate {
  /// Create a mobile-optimized template
  static HeatmapSelectorTemplate mobile({
    required HeatmapSelectorCore core,
    String? title,
    Color? primaryColor,
    bool showResetButton = true,
    SelectorConfig? config,
  }) => HeatmapSelectorTemplate(
    core: core,
    title: title,
    primaryColor: primaryColor,
    showResetButton: showResetButton,
    config: config ?? SelectorConfig.mobile(),
    enableAdaptiveLayout: false,
    forceLayout: SelectorLayoutType.compact,
  );

  /// Create a web-optimized template
  static HeatmapSelectorTemplate web({
    required HeatmapSelectorCore core,
    String? title,
    Color? primaryColor,
    bool showResetButton = true,
    SelectorConfig? config,
    SelectorLayoutType layout = SelectorLayoutType.expanded,
  }) => HeatmapSelectorTemplate(
    core: core,
    title: title,
    primaryColor: primaryColor,
    showResetButton: showResetButton,
    config: config ?? SelectorConfig.web(),
    enableAdaptiveLayout: false,
    forceLayout: layout,
  );

  /// Create a fully adaptive template that switches based on screen size
  static HeatmapSelectorTemplate adaptive({
    required HeatmapSelectorCore core,
    String? title,
    Color? primaryColor,
    bool showResetButton = true,
    double mobileBreakpoint = 768.0,
    double tabletBreakpoint = 1024.0,
    ValueChanged<SelectorLayoutType>? onLayoutChanged,
  }) => HeatmapSelectorTemplate(
    core: core,
    title: title,
    primaryColor: primaryColor,
    showResetButton: showResetButton,
    mobileBreakpoint: mobileBreakpoint,
    tabletBreakpoint: tabletBreakpoint,
    onLayoutChanged: onLayoutChanged,
  );
}
