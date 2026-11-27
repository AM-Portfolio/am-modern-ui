import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';

/// When false, UI must not show Total Invested or Total Return.
bool dashboardCostBasisKnown(DashboardSummary summary) {
  final value = summary.totalValue;
  if (value <= 0) return false;

  final invested = summary.totalInvested;
  if (invested <= 0) return false;

  // CDSL/CAS: market value only — invested ≈ balance, overall return ≈ 0.
  if ((invested - value).abs() / value < 0.005) return false;

  // Cross-scope leak: tiny invested vs large value with absurd return %.
  final sleeveShare = invested / value;
  if (sleeveShare < 0.2 && summary.totalGainLossPercentage.abs() > 500) {
    return false;
  }

  // Value − invested should match reported overall P&L when both present.
  final implied = value - invested;
  final reported = summary.totalGainLoss;
  if (reported.abs() > 1 &&
      (implied - reported).abs() / value > 0.05 &&
      sleeveShare < 0.5) {
    return false;
  }

  return true;
}
