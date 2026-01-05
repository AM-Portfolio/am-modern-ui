/// Configuration for heatmap display features
/// Controls what information is shown on heatmap tiles and cards
class DisplayConfig {
  const DisplayConfig({
    this.showSubCards = true,
    this.showPerformance = true,
    this.showWeightage = true,
    this.showValue = true,
    this.showLegend = true,
    this.showHeader = true,
    this.showRefreshButton = true,
  });

  /// Mobile-optimized display configuration
  factory DisplayConfig.mobile() => const DisplayConfig(
    showSubCards: false,
    showValue: false,
    showLegend: false,
    showRefreshButton: false,
  );

  /// Web-optimized display configuration
  factory DisplayConfig.web() => const DisplayConfig();

  /// Minimal display configuration (for widgets, previews)
  factory DisplayConfig.minimal() => const DisplayConfig(
    showSubCards: false,
    showWeightage: false,
    showValue: false,
    showLegend: false,
    showRefreshButton: false,
  );

  /// Dashboard display configuration
  factory DisplayConfig.dashboard() =>
      const DisplayConfig(showValue: false, showRefreshButton: false);

  /// Portfolio-specific display configuration
  factory DisplayConfig.portfolio() => const DisplayConfig();

  /// Index fund display configuration
  factory DisplayConfig.index() => const DisplayConfig(
    showValue: false, // Index components might not show individual values
  );

  /// Mutual funds display configuration
  factory DisplayConfig.mutualFunds() => const DisplayConfig(
    showWeightage: false, // Mutual funds don't typically show weightage
  );

  /// ETF display configuration
  factory DisplayConfig.etf() => const DisplayConfig();

  // Card display options
  final bool showSubCards;
  final bool showPerformance;
  final bool showWeightage;
  final bool showValue;
  final bool showLegend;
  final bool showHeader;
  final bool showRefreshButton;

  /// Copy with modifications
  DisplayConfig copyWith({
    bool? showSubCards,
    bool? showPerformance,
    bool? showWeightage,
    bool? showValue,
    bool? showLegend,
    bool? showHeader,
    bool? showRefreshButton,
  }) => DisplayConfig(
    showSubCards: showSubCards ?? this.showSubCards,
    showPerformance: showPerformance ?? this.showPerformance,
    showWeightage: showWeightage ?? this.showWeightage,
    showValue: showValue ?? this.showValue,
    showLegend: showLegend ?? this.showLegend,
    showHeader: showHeader ?? this.showHeader,
    showRefreshButton: showRefreshButton ?? this.showRefreshButton,
  );

  /// Check if this is a minimal display configuration
  bool get isMinimal => !showSubCards && !showLegend && !showRefreshButton;

  /// Check if this shows comprehensive information
  bool get isComprehensive =>
      showSubCards &&
      showPerformance &&
      showWeightage &&
      showValue &&
      showLegend;

  /// Get count of enabled display features
  int get enabledFeatureCount {
    var count = 0;
    if (showSubCards) count++;
    if (showPerformance) count++;
    if (showWeightage) count++;
    if (showValue) count++;
    if (showLegend) count++;
    if (showHeader) count++;
    if (showRefreshButton) count++;
    return count;
  }

  /// Check if any performance data is shown
  bool get showsPerformanceData =>
      showPerformance || showWeightage || showValue;

  /// Check if header area is populated
  bool get hasHeaderContent => showHeader || showRefreshButton;
}
