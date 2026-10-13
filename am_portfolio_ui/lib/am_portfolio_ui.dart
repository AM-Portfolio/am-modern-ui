library am_portfolio_ui;

export 'package:am_common/am_common.dart'
    show PortfolioSelectionContext, PortfolioSelectionScope;

// Exports temporarily disabled for Phase 1 to focus on Market UI
export 'features/portfolio/presentation/pages/portfolio_screen.dart';

//Presentation - Pages
export 'features/portfolio/presentation/web/pages/portfolio_overview_web_page.dart';
export 'features/portfolio/presentation/web/pages/portfolio_holdings_web_page.dart';
export 'features/portfolio/presentation/web/pages/portfolio_analysis_web_page.dart';
export 'features/portfolio/presentation/web/pages/portfolio_heatmap_web_page.dart';
export 'features/portfolio/presentation/mobile/portfolio_mobile_screen.dart';

// Presentation - Widgets
export 'features/portfolio/presentation/widgets/sidebar/portfolio_sidebar.dart';
export 'features/portfolio/presentation/widgets/global_portfolio_wrapper.dart';
export 'features/portfolio/presentation/sections/portfolio_comparison_chart_section.dart';
export 'features/portfolio/presentation/sections/portfolio_chart_section.dart';

// Intelligence Widgets
export 'features/portfolio/presentation/widgets/intelligence/portfolio_health_card.dart';
export 'features/portfolio/presentation/widgets/intelligence/portfolio_xray_panel.dart';
export 'features/portfolio/presentation/widgets/intelligence/portfolio_risk_radar_card.dart';
export 'features/portfolio/presentation/widgets/portfolio_overview_widget.dart';

// State Management (Cubits needed for embedding intelligence widgets)
export 'features/portfolio/presentation/cubit/portfolio_cubit.dart';
export 'features/portfolio/presentation/cubit/portfolio_analytics_cubit.dart';
export 'features/portfolio/providers/portfolio_providers.dart';
