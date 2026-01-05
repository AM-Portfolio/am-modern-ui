/// Common types and enums for universal heatmap system
library;

/// Investment type enumeration
enum InvestmentType { portfolio, indexFund, mutualFunds, etf }

/// Universal template composition types
enum UniversalTemplateType {
  minimal, // DisplayTemplate only, minimal layout
  compact, // DisplayTemplate + compact selectors
  full, // All components with full features
  dashboard, // Optimized for dashboard widgets
  adaptive, // Adapts based on screen size and config
}
