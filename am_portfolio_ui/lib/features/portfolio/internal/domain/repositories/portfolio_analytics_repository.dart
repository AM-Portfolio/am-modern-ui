import '../entities/portfolio_analytics.dart';
import '../entities/portfolio_analytics_request.dart';

/// Abstract repository interface for portfolio analytics operations
///
/// Defines contracts for analytics data operations following clean architecture principles:
/// - Fetches comprehensive portfolio analytics data
/// - Support for configurable analytics requests
/// - Provides error handling and caching abstractions
/// - Follows repository pattern for data access abstraction
abstract class PortfolioAnalyticsRepository {
  /// Fetches comprehensive portfolio analytics data
  ///
  /// [request] - Configuration for analytics request including features and filters
  ///
  /// Returns [PortfolioAnalytics] containing heatmap, movers, sector allocation,
  /// market cap allocation, and other analytical data
  ///
  /// Throws [Exception] on network or parsing errors
  Future<PortfolioAnalytics> getPortfolioAnalytics(
    PortfolioAnalyticsRequest request,
  );

  /// Fetches heatmap data only for performance optimization
  ///
  /// [request] - Analytics request with heatmap feature enabled
  ///
  /// Returns [Heatmap] for portfolio visualization
  ///
  /// Throws [Exception] on network or parsing errors
  Future<Heatmap?> getHeatmapData(PortfolioAnalyticsRequest request);

  /// Fetches market movers data (gainers and losers)
  ///
  /// [request] - Analytics request with movers feature enabled
  ///
  /// Returns [Movers] containing top gainers and losers
  ///
  /// Throws [Exception] on network or parsing errors
  Future<Movers?> getMoversData(PortfolioAnalyticsRequest request);

  /// Fetches sector allocation breakdown
  ///
  /// [request] - Analytics request with sector allocation feature enabled
  ///
  /// Returns [SectorAllocation] showing portfolio distribution by sectors
  ///
  /// Throws [Exception] on network or parsing errors
  Future<SectorAllocation?> getSectorAllocation(
    PortfolioAnalyticsRequest request,
  );

  /// Fetches market cap allocation breakdown
  ///
  /// [request] - Analytics request with market cap allocation feature enabled
  ///
  /// Returns [MarketCapAllocation] showing portfolio distribution by market cap
  ///
  /// Throws [Exception] on network or parsing errors
  Future<MarketCapAllocation?> getMarketCapAllocation(
    PortfolioAnalyticsRequest request,
  );
}
