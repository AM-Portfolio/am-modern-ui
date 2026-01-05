import '../entities/portfolio_holding.dart';
import '../entities/portfolio_list.dart';
import '../entities/portfolio_summary.dart';

/// Repository interface for portfolio data operations
abstract class PortfolioRepository {
  /// Get portfolio holdings for a user
  Future<PortfolioHoldings> getPortfolioHoldings(String userId);

  /// Get portfolio holdings for a user and specific portfolio
  Future<PortfolioHoldings> getPortfolioHoldingsById(
    String userId,
    String portfolioId,
  );

  /// Get portfolio summary for a user
  Future<PortfolioSummary> getPortfolioSummary(String userId);

  /// Get portfolio summary for a user and specific portfolio
  Future<PortfolioSummary> getPortfolioSummaryById(
    String userId,
    String portfolioId,
  );

  /// Get holdings stream for real-time updates
  Stream<PortfolioHoldings> watchPortfolioHoldings(String userId);

  /// Get summary stream for real-time updates
  Stream<PortfolioSummary> watchPortfolioSummary(String userId);

  /// Get holding details by symbol
  Future<PortfolioHolding?> getHoldingDetails(String userId, String symbol);

  /// Get sector allocation
  Future<List<SectorAllocation>> getSectorAllocation(String userId);

  /// Get top performers
  Future<List<TopPerformer>> getTopPerformers(String userId, {int limit = 5});

  /// Get worst performers
  Future<List<TopPerformer>> getWorstPerformers(String userId, {int limit = 5});

  /// Get list of portfolios for a user
  Future<PortfolioList> getPortfoliosList(String userId);
}
