library am_dashboard_ui;

// Models
export 'domain/models/dashboard_summary.dart';
export 'domain/models/portfolio_overview.dart';

// Repository
export 'data/repositories/dashboard_repository.dart';

// Providers
export 'presentation/providers/dashboard_provider.dart';

// Pages (Router)
export 'presentation/pages/dashboard_screen.dart';

// Shared Widgets (used by both mobile and web screens)
export 'presentation/shared/widgets/dashboard_summary_widget.dart';
export 'presentation/shared/widgets/dashboard_allocation_widget.dart';
export 'presentation/shared/widgets/dashboard_chart_widget.dart';
export 'presentation/shared/widgets/dashboard_ranking_widget.dart';
export 'presentation/shared/widgets/dashboard_recent_activity_widget.dart';
export 'presentation/shared/widgets/dashboard_portfolio_overview_card.dart';
