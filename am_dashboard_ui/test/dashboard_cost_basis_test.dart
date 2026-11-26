import 'package:am_dashboard_ui/domain/dashboard_cost_basis.dart';
import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unknown when invested missing or zero', () {
    expect(
      dashboardCostBasisKnown(
        const DashboardSummary(
          totalValue: 1e7,
          totalInvested: 0,
          totalGainLoss: 0,
          totalGainLossPercentage: 0,
          dayChange: 0,
          dayChangePercentage: 0,
          totalPortfolios: 1,
        ),
      ),
      isFalse,
    );
  });

  test('unknown when invested equals market value (CAS)', () {
    expect(
      dashboardCostBasisKnown(
        const DashboardSummary(
          totalValue: 100000,
          totalInvested: 99900,
          totalGainLoss: 100,
          totalGainLossPercentage: 0.1,
          dayChange: 0,
          dayChangePercentage: 0,
          totalPortfolios: 1,
        ),
      ),
      isFalse,
    );
  });

  test('unknown on absurd cross-scope invested vs value', () {
    expect(
      dashboardCostBasisKnown(
        const DashboardSummary(
          totalValue: 13754930,
          totalInvested: 854185,
          totalGainLoss: 12900745,
          totalGainLossPercentage: 1510.3,
          dayChange: 0,
          dayChangePercentage: 0,
          totalPortfolios: 1,
        ),
      ),
      isFalse,
    );
  });

  test('known for coherent broker cost basis', () {
    expect(
      dashboardCostBasisKnown(
        const DashboardSummary(
          totalValue: 100000,
          totalInvested: 80000,
          totalGainLoss: 20000,
          totalGainLossPercentage: 25,
          dayChange: 100,
          dayChangePercentage: 0.1,
          totalPortfolios: 1,
          totalHoldings: 10,
        ),
      ),
      isTrue,
    );
  });
}
