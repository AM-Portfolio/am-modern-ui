import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_catalog.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_portfolio_scope.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'portfolio_health_card.dart';
import 'portfolio_risk_radar_card.dart';
import 'portfolio_xray_panel.dart';

/// Registers Overview intelligence cards on the dashboard catalog.
/// Call once at app startup (before first dashboard render).
void registerDashboardIntelWidgets() {
  DashboardWidgetCatalog.portfolioHealthBuilder = (context, ref, ctx) {
    final portfolioId = _resolvePortfolioId(context, ref);
    return PortfolioHealthCard(
      key: ValueKey('dash_health_$portfolioId'),
      portfolioId: portfolioId,
      fillHeight: true,
      padding: const EdgeInsets.all(14),
      accentColor: ModuleColors.dashboard,
    );
  };

  DashboardWidgetCatalog.portfolioXrayBuilder = (context, ref, ctx) {
    final portfolioId = _resolvePortfolioId(context, ref);
    final aggregate =
        portfolioId == 'all' || portfolioId.startsWith('all|');
    return PortfolioXrayPanel(
      key: ValueKey('dash_xray_$portfolioId'),
      portfolioId: portfolioId,
      fillHeight: true,
      padding: const EdgeInsets.all(14),
      readOnly: aggregate,
      accentColor: ModuleColors.dashboard,
    );
  };

  DashboardWidgetCatalog.portfolioRiskBuilder = (context, ref, ctx) {
    final portfolioId = _resolvePortfolioId(context, ref);
    return PortfolioRiskRadarCard(
      key: ValueKey('dash_risk_$portfolioId'),
      portfolioId: portfolioId,
      fillHeight: true,
      padding: const EdgeInsets.all(14),
      accentColor: ModuleColors.dashboard,
    );
  };
}

String _resolvePortfolioId(BuildContext context, WidgetRef ref) {
  final scoped = ref.watch(dashboardPortfolioScopeProvider);
  if (scoped != null && scoped.isNotEmpty && scoped != 'all') {
    return scoped;
  }
  final inherited = context.selectedPortfolioId;
  if (inherited != null && inherited.isNotEmpty && inherited != 'all') {
    return inherited;
  }
  final filterKey = ref.watch(familyPortfolioFilterProvider);
  return scopedAllPortfolioId('all', filterKey);
}
