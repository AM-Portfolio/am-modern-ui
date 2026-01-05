import 'package:flutter/material.dart';
import 'package:am_common/core/config/environment.dart';
import 'package:am_design_system/am_design_system.dart';

// Import specific configs for the heatmap configurator
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart' as layout_config;
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart' as ui_config;
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';

/// Configuration manager for portfolio heatmap
/// Handles all configuration logic for portfolio-specific heatmap display
class PortfolioHeatmapConfig {
  /// Gets the appropriate heatmap configuration for portfolio display
  /// Loads configuration based on current environment
  static ui_config.HeatmapConfig getHeatmapConfig({
    required String title,
    required bool showSubCards,
    Color? accentColor,
    Environment? environment,
  }) {
    // Use provided environment or default to current environment
    final env = environment ?? EnvironmentConfig.environment;

    // Load environment and platform-specific default configuration
    final defaultConfig = _loadEnvironmentAwareConfig(showSubCards, env);

    // Apply portfolio-specific customizations
    return _applyPortfolioConfig(
      defaultConfig: defaultConfig,
      title: title,
      showSubCards: showSubCards,
      accentColor: accentColor,
      environment: env,
    );
  }

  /// Loads environment and platform-aware default configuration
  static ui_config.HeatmapConfig _loadEnvironmentAwareConfig(
    bool showSubCards,
    Environment environment,
  ) {
    // Get base platform configuration
    final platformConfig = _loadPlatformDefaultConfig(showSubCards);

    // Apply environment-specific overrides
    return _applyEnvironmentOverrides(platformConfig, environment);
  }

  /// Loads platform-specific default configuration
  static ui_config.HeatmapConfig _loadPlatformDefaultConfig(bool showSubCards) {
    // Use existing default configurations from template classes
    if (showSubCards) {
      // Web/desktop base configuration using WebHeatmapDefaults
      return WebHeatmapDefaults.portfolio(
        title: 'Portfolio Overview',
        selectorLayout: SelectorLayoutType.compact,
      );
    } else {
      // Mobile base configuration using MobileHeatmapDefaults
      return MobileHeatmapDefaults.portfolio(
        title: 'Portfolio',
        selectorLayout: SelectorLayoutType.compact,
      );
    }
  }

  /// Applies environment-specific configuration overrides
  static ui_config.HeatmapConfig _applyEnvironmentOverrides(
    ui_config.HeatmapConfig baseConfig,
    Environment environment,
  ) {
    switch (environment) {
      case Environment.development:
        return _applyDevelopmentOverrides(baseConfig);
      case Environment.preprod:
        return _applyPreprodOverrides(baseConfig);
      case Environment.production:
        return _applyProductionOverrides(baseConfig);
    }
  }

  /// Applies portfolio-specific configuration on top of platform defaults
  static ui_config.HeatmapConfig _applyPortfolioConfig({
    required ui_config.HeatmapConfig defaultConfig,
    required String title,
    required bool showSubCards,
    required Environment environment,
    Color? accentColor,
  }) {
    // Apply customizations using copyWith and individual sub-config updates
    return _applyPortfolioCustomizations(
      defaultConfig: defaultConfig,
      title: title,
      accentColor: accentColor,
      environment: environment,
    );
  }

  /// Applies portfolio-specific customizations on top of platform defaults
  static ui_config.HeatmapConfig _applyPortfolioCustomizations({
    required ui_config.HeatmapConfig defaultConfig,
    required String title,
    required Environment environment,
    Color? accentColor,
  }) {
    // Create custom selector configuration for portfolio heatmap based on environment
    final customSelectorConfig = createPortfolioSelectorConfig();

    return defaultConfig.copyWith(
      display: defaultConfig.display?.copyWith() ?? const DisplayConfig(),
      layout:
          defaultConfig.layout?.copyWith(
            customTitle: title,
            showLayoutSelector: true,
          ) ??
          layout_config.LayoutConfig(
            customTitle: title,
            showLayoutSelector: true,
          ),
      visual:
          defaultConfig.visual?.copyWith(accentColor: accentColor) ??
          VisualConfig(accentColor: accentColor),
      selectors: customSelectorConfig,
    );
  }

  /// Environment-specific configuration overrides

  /// Apply development environment overrides (more debugging features)
  static ui_config.HeatmapConfig _applyDevelopmentOverrides(
    ui_config.HeatmapConfig baseConfig,
  ) => baseConfig.copyWith(
    display:
        baseConfig.display?.copyWith(
          showRefreshButton: true,
          showLegend: true,
        ) ??
        const DisplayConfig(),
    interactions:
        baseConfig.interactions?.copyWith(
          showLoadingStates: true,
          showErrorStates: true,
        ) ??
        const InteractionConfig(),
  );

  /// Apply preprod environment overrides (testing features)
  static ui_config.HeatmapConfig _applyPreprodOverrides(
    ui_config.HeatmapConfig baseConfig,
  ) => baseConfig.copyWith(
    display:
        baseConfig.display?.copyWith(showRefreshButton: true) ??
        const DisplayConfig(),
    interactions:
        baseConfig.interactions?.copyWith(showLoadingStates: true) ??
        const InteractionConfig(),
  );

  /// Apply production environment overrides (minimal, performance optimized)
  static ui_config.HeatmapConfig _applyProductionOverrides(
    ui_config.HeatmapConfig baseConfig,
  ) => baseConfig.copyWith(
    display:
        baseConfig.display?.copyWith(
          showRefreshButton: false,
          showLegend: false,
        ) ??
        const DisplayConfig(showRefreshButton: false, showLegend: false),
    interactions:
        baseConfig.interactions?.copyWith(
          showLoadingStates: false,
          showErrorStates: false,
          enableHoverEffects: true,
        ) ??
        const InteractionConfig(
          showLoadingStates: false,
          showErrorStates: false,
        ),
  );

  /// Creates custom selector configuration for portfolio heatmap
  /// - Hides timeframe selector
  /// - Hides metric selector
  /// - Shows sector selector
  /// - Shows market cap selector with custom options including "no group"
  /// - Shows layout selector for switching between treemap, grid, and list views
  /// - Full control over selector behavior
  static SelectorConfig createPortfolioSelectorConfig() => SelectorConfig(
    // Hide all selectors except market cap, sector, and layout
    showTimeFrameSelector: false,
    showMetricSelector: false,
    showLayoutSelector: true, // Enable layout selector
    // Custom market cap options including "no group" equivalent (all)
    availableMarketCaps: portfolioMarketCapOptions,
    availableSectors: portfolioSectorOptions,
    availableLayouts: portfolioLayoutOptions,
  );

  /// Custom market cap options for portfolio heatmap
  /// Includes "no group" option (all) and other relevant market cap categories
  static List<MarketCapType> get portfolioMarketCapOptions => [
    MarketCapType.all, // No group option
    MarketCapType.largeCap, // Large cap grouping
    MarketCapType.midCap, // Mid cap grouping
    MarketCapType.smallCap, // Small cap grouping
    MarketCapType.megaCap, // Mega cap grouping
  ];

  /// Custom sector options for portfolio heatmap
  /// Includes "no group" option (all) and other relevant sector categories
  static List<SectorType> get portfolioSectorOptions => [
    SectorType.all, // No group option
    SectorType.technology, // Technology sector
    SectorType.healthcare, // Healthcare sector
    SectorType.finance, // Finance sector
    SectorType.noGroup, // Consumer discretionary sector
  ];

  /// Custom layout options for portfolio heatmap
  /// Provides different visualization options for users to choose from
  static List<HeatmapLayoutType> get portfolioLayoutOptions => [
    HeatmapLayoutType
        .treemap, // Default treemap view (best for hierarchical data)
    HeatmapLayoutType.grid, // Grid view (good for comparison)
    HeatmapLayoutType.list, // List view (good for detailed information)
  ];

  /// Configuration presets for different portfolio types

  /// Configuration for growth portfolio
  static ui_config.HeatmapConfig growthPortfolioConfig({
    required String title,
    required bool showSubCards,
    Color? accentColor,
  }) => getHeatmapConfig(
    title: title,
    showSubCards: showSubCards,
    accentColor: accentColor ?? Colors.green,
  );

  /// Configuration for value portfolio
  static ui_config.HeatmapConfig valuePortfolioConfig({
    required String title,
    required bool showSubCards,
    Color? accentColor,
  }) => getHeatmapConfig(
    title: title,
    showSubCards: showSubCards,
    accentColor: accentColor ?? Colors.blue,
  );

  /// Configuration for dividend portfolio
  static ui_config.HeatmapConfig dividendPortfolioConfig({
    required String title,
    required bool showSubCards,
    Color? accentColor,
  }) => getHeatmapConfig(
    title: title,
    showSubCards: showSubCards,
    accentColor: accentColor ?? Colors.orange,
  );

  /// Configuration for balanced portfolio
  static ui_config.HeatmapConfig balancedPortfolioConfig({
    required String title,
    required bool showSubCards,
    Color? accentColor,
  }) => getHeatmapConfig(
    title: title,
    showSubCards: showSubCards,
    accentColor: accentColor ?? Colors.purple,
  );
}
