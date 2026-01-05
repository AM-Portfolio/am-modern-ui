import '../models/portfolio_overview_data.dart';

/// Contract for portfolio overview data provision
abstract class PortfolioOverviewDataContract {
  /// Get complete overview data for a portfolio
  Future<PortfolioOverviewData> getOverviewData(String portfolioId);

  /// Refresh overview data
  Future<void> refreshOverviewData(String portfolioId);

  /// Stream of overview data updates
  Stream<PortfolioOverviewData>? watchOverviewData(String portfolioId);
}
