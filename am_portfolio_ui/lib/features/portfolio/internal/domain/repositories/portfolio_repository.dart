import '../entities/portfolio_holding.dart';
import '../entities/portfolio_list.dart';
import '../entities/portfolio_summary.dart';

/// Repository interface for portfolio data operations
abstract class PortfolioRepository {
  /// Get portfolio holdings for a user
  Future<PortfolioHoldings> getPortfolioHoldings();

  /// Get portfolio holdings for a user and specific portfolio
  Future<PortfolioHoldings> getPortfolioHoldingsById(
    String portfolioId,
  );

  /// Get portfolio summary for a user
  Future<PortfolioSummary> getPortfolioSummary();

  /// Get portfolio summary for a user and specific portfolio
  Future<PortfolioSummary> getPortfolioSummaryById(
    String portfolioId,
  );

  /// Get holdings stream for real-time updates
  Stream<PortfolioHoldings> watchPortfolioHoldings();

  /// Get summary stream for real-time updates
  Stream<PortfolioSummary> watchPortfolioSummary();

  /// Get holding details by symbol
  Future<PortfolioHolding?> getHoldingDetails(String symbol);

  /// Get sector allocation
  Future<List<SectorAllocation>> getSectorAllocation();

  /// Get top performers
  Future<List<TopPerformer>> getTopPerformers({int limit = 5});

  /// Get worst performers
  Future<List<TopPerformer>> getWorstPerformers({int limit = 5});

  /// Get list of portfolios for a user
  Future<PortfolioList> getPortfoliosList();
}
