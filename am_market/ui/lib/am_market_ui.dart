library am_market_ui;

/// Main app entry point and core features
/// Export widgets and pages available for external use

// Export core pages
export 'features/dashboard/presentation/pages/dashboard_page.dart' show MarketPage;
export 'features/equity_insider/presentation/pages/equity_insider_page.dart';
export 'features/equity_insider/presentation/widgets/equity_insider_kpis.dart';
export 'features/equity_insider/presentation/widgets/equity_insider_chart.dart';
export 'features/equity_insider/presentation/widgets/equity_insider_financials.dart';
export 'features/equity_insider/presentation/widgets/equity_insider_shareholding.dart';
export 'features/watchlists/presentation/pages/watchlists_page.dart';
export 'features/f_o/presentation/pages/fo_page.dart';
export 'features/f_o/providers/fo_provider.dart'
    show foActiveSymbolProvider, FoActiveSymbolNotifier;

// Export providers for Trade UI integration
export 'features/market_analysis/providers/market_analysis_providers.dart';

// Export shared widgets
export 'shared/widgets/trading_view_chart_widget.dart';

// Export domain models required by widgets
export 'features/market_analysis/internal/domain/models/chart_config.dart';
