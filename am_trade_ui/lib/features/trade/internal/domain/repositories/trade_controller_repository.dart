import '../../data/dtos/metrics_filter_config_dto.dart';
import '../entities/trade_controller_entities.dart';

/// Repository interface for Trade Controller operations
/// This is the domain layer abstraction that defines all trade-related operations
abstract class TradeControllerRepository {
  /// Get trade details by portfolio ID and optional symbols
  /// Returns a list of trade details matching the criteria
  Future<List<TradeDetails>> getTradeDetailsByPortfolioAndSymbols({required String portfolioId, List<String>? symbols});

  /// Stream of trade details for real-time updates
  /// Emits updates whenever trade data changes
  Stream<List<TradeDetails>> watchTradeDetailsByPortfolio(String portfolioId);

  /// Add a new trade
  /// Returns the created trade details with server-generated fields
  Future<TradeDetails> addTrade(TradeDetails tradeDetails);

  /// Update an existing trade
  /// Returns the updated trade details
  Future<TradeDetails> updateTrade({required String tradeId, required TradeDetails tradeDetails});

  /// Delete a trade by ID
  /// Returns void on successful deletion
  Future<void> deleteTrade(String tradeId);

  /// Filter trades by multiple criteria with pagination
  /// Returns paginated response with trades matching the filters
  Future<PaginatedTradeResponse> getTradesByFilters({
    List<String>? portfolioIds,
    List<String>? symbols,
    List<String>? statuses,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? strategies,
    int page = 0,
    int size = 20,
    String? sort,
  });

  /// Add or update multiple trades in batch
  /// Returns the list of processed trades
  Future<List<TradeDetails>> addOrUpdateTrades(List<TradeDetails> trades);

  /// Get trade details by trade IDs
  /// Returns a list of trade details for the specified IDs
  Future<List<TradeDetails>> getTradeDetailsByTradeIds(List<String> tradeIds);

  /// Filter trade details using favorite filter configuration
  /// Returns filtered trades with summary information
  Future<FilterTradeDetailsResponse> filterTradeDetails({
    required String userId,
    String? favoriteFilterId,
    MetricsFilterConfigDto? metricsConfig,
    int page = 0,
    int size = 20,
    String? sort,
  });

  /// Clear cached trade data
  /// Useful for forcing refresh from server
  Future<void> clearCache();

  /// Refresh trade data for a specific portfolio
  /// Fetches latest data and updates cache
  Future<void> refreshPortfolioTrades(String portfolioId);
}
