/// Universal Heatmap Widget Package
///
/// A comprehensive, modular heatmap system for investment data visualization.
/// Provides clean separation of concerns with data conversion, configuration management,
/// template composition, and investment-specific convenience widgets.
///
/// ## Architecture
///
/// - **UniversalHeatmapWidget**: Core orchestrator that composes display, selector, and layout templates
/// - **Data Converters**: Investment-type specific data transformation utilities
/// - **Config Manager**: Configuration merging, defaults, and effective config calculation
/// - **Template Factory**: Factory for creating display, selector, and layout templates
/// - **Investment Widgets**: Convenience widgets for specific investment types
///
/// ## Usage
///
/// ```dart
/// // Use the universal widget directly
/// UniversalHeatmapWidget(
///   investmentType: InvestmentType.portfolio,
///   rawData: portfolioData,
///   templateType: UniversalTemplateType.adaptive,
/// )
///
/// // Or use convenience widgets
/// PortfolioHeatmapWidget(
///   portfolioData: data,
///   templateType: UniversalTemplateType.full,
/// )
/// ```
///
/// ## Template Types
///
/// - **Minimal**: DisplayTemplate only, minimal layout
/// - **Compact**: DisplayTemplate + compact selectors
/// - **Full**: All components with full features
/// - **Dashboard**: Optimized for dashboard widgets
/// - **Adaptive**: Adapts based on screen size and config
library;

// Convenience investment-specific widgets
//export 'universal_heatmap/investment_widgets.dart';
export 'universal_heatmap/types.dart';
// Core widget and types
export 'universal_heatmap/universal_heatmap_widget.dart';

// Configuration and utilities (internal - consider carefully before exporting)
// These are typically not needed by consumers of the package
// export 'config_manager.dart';
// export 'data_converters.dart';
// export 'template_factory.dart';
