/// Configuration for heatmap interaction behaviors
/// Controls how users can interact with the heatmap
class InteractionConfig {
  const InteractionConfig({
    this.enableTileInteraction = true,
    this.enableSelectorInteraction = true,
    this.showLoadingStates = true,
    this.showErrorStates = true,
    this.enableHoverEffects = true,
    this.enableMultiSelect = false,
    this.enableDragAndDrop = false,
  });

  /// Mobile-optimized interaction configuration
  factory InteractionConfig.mobile() => const InteractionConfig(
    enableHoverEffects: false, // No hover on mobile
  );

  /// Web-optimized interaction configuration
  factory InteractionConfig.web() =>
      const InteractionConfig(enableMultiSelect: true);

  /// Minimal interaction configuration (for widgets, previews)
  factory InteractionConfig.minimal() => const InteractionConfig(
    enableTileInteraction: false,
    enableSelectorInteraction: false,
    showLoadingStates: false,
    showErrorStates: false,
    enableHoverEffects: false,
  );

  /// Dashboard interaction configuration
  factory InteractionConfig.dashboard({bool interactive = true}) =>
      InteractionConfig(
        enableTileInteraction: interactive,
        enableSelectorInteraction: interactive,
        enableHoverEffects: interactive,
      );

  /// Read-only interaction configuration (for reports, exports)
  factory InteractionConfig.readOnly() => const InteractionConfig(
    enableTileInteraction: false,
    enableSelectorInteraction: false,
    showLoadingStates: false,
    showErrorStates: false,
    enableHoverEffects: false,
  );

  /// Full-featured interaction configuration
  factory InteractionConfig.fullFeatured() =>
      const InteractionConfig(enableMultiSelect: true, enableDragAndDrop: true);

  /// Portfolio-specific interaction configuration
  factory InteractionConfig.portfolio() => const InteractionConfig();

  /// Index fund interaction configuration
  factory InteractionConfig.index() => const InteractionConfig();

  /// Mutual funds interaction configuration
  factory InteractionConfig.mutualFunds() => const InteractionConfig(
    enableMultiSelect: true, // Allow comparing multiple funds
  );

  /// ETF interaction configuration
  factory InteractionConfig.etf() => const InteractionConfig();

  // Interaction options
  final bool enableTileInteraction;
  final bool enableSelectorInteraction;
  final bool showLoadingStates;
  final bool showErrorStates;
  final bool enableHoverEffects;
  final bool enableMultiSelect;
  final bool enableDragAndDrop;

  /// Copy with modifications
  InteractionConfig copyWith({
    bool? enableTileInteraction,
    bool? enableSelectorInteraction,
    bool? showLoadingStates,
    bool? showErrorStates,
    bool? enableHoverEffects,
    bool? enableMultiSelect,
    bool? enableDragAndDrop,
  }) => InteractionConfig(
    enableTileInteraction: enableTileInteraction ?? this.enableTileInteraction,
    enableSelectorInteraction:
        enableSelectorInteraction ?? this.enableSelectorInteraction,
    showLoadingStates: showLoadingStates ?? this.showLoadingStates,
    showErrorStates: showErrorStates ?? this.showErrorStates,
    enableHoverEffects: enableHoverEffects ?? this.enableHoverEffects,
    enableMultiSelect: enableMultiSelect ?? this.enableMultiSelect,
    enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
  );

  /// Check if any interactions are enabled
  bool get hasInteractions =>
      enableTileInteraction || enableSelectorInteraction;

  /// Check if this is interactive
  bool get isInteractive => enableTileInteraction && enableSelectorInteraction;

  /// Check if this is read-only
  bool get isReadOnly => !enableTileInteraction && !enableSelectorInteraction;

  /// Check if advanced interactions are enabled
  bool get hasAdvancedInteractions => enableMultiSelect || enableDragAndDrop;

  /// Get count of enabled interaction features
  int get enabledInteractionCount {
    var count = 0;
    if (enableTileInteraction) count++;
    if (enableSelectorInteraction) count++;
    if (enableHoverEffects) count++;
    if (enableMultiSelect) count++;
    if (enableDragAndDrop) count++;
    return count;
  }

  /// Check if state feedback is enabled
  bool get hasStateFeedback => showLoadingStates || showErrorStates;
}
