import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Portfolio id the dashboard should load. Null or `all` keeps the aggregate.
class DashboardPortfolioScope extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? portfolioId) {
    final next = (portfolioId == null ||
            portfolioId.isEmpty ||
            portfolioId == 'all')
        ? null
        : portfolioId;
    if (state == next) return;
    state = next;
  }
}

final dashboardPortfolioScopeProvider =
    NotifierProvider<DashboardPortfolioScope, String?>(
  DashboardPortfolioScope.new,
);
