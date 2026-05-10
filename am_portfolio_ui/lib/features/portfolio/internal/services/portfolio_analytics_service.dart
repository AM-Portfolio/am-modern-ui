import 'package:am_design_system/am_design_system.dart';
import '../domain/entities/portfolio_analytics.dart';
import '../domain/entities/portfolio_analytics_request.dart';
import '../domain/usecases/get_portfolio_analytics.dart';
import '../data/mappers/portfolio_analytics_mapper.dart';
import 'package:am_common/am_common.dart';

/// Portfolio analytics orchestration service for comprehensive data workflows.
///
/// Combines analytics use cases and coordinates complex operations like:
/// - Portfolio analytics data retrieval
/// - Heatmap visualization data
/// - Market movers analysis
/// - Sector and market cap allocation insights
///
/// This service acts as a facade that combines analytics use cases
/// to perform comprehensive portfolio analysis operations.
class PortfolioAnalyticsService {
  const PortfolioAnalyticsService(this._getPortfolioAnalytics);
  final GetPortfolioAnalytics _getPortfolioAnalytics;

  /// Retrieves comprehensive portfolio analytics for the specified portfolio
  /// Returns complete analytics data or throws an exception if retrieval fails
  Future<PortfolioAnalytics> getPortfolioAnalytics(
    PortfolioAnalyticsRequest request,
  ) async {
    CommonLogger.methodEntry(
      'getPortfolioAnalytics',
      tag: 'PortfolioAnalyticsService',
      metadata: {'portfolioId': request.coreIdentifiers.portfolioId},
    );

    try {
      CommonLogger.info(
        'Getting comprehensive portfolio analytics',
        tag: 'PortfolioAnalyticsService',
      );
      final analytics = await _getPortfolioAnalytics(request);

      CommonLogger.info(
        'Portfolio analytics retrieved successfully',
        tag: 'PortfolioAnalyticsService',
      );
      CommonLogger.methodExit(
        'getPortfolioAnalytics',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': 'success'},
      );

      return analytics;
    } catch (error) {
      CommonLogger.error(
        'Failed to get portfolio analytics',
        tag: 'PortfolioAnalyticsService',
        error: error,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioAnalytics',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Retrieves portfolio analytics with default configuration
  /// Convenience method for getting analytics with standard settings
  Future<PortfolioAnalytics> getPortfolioAnalyticsWithDefaults(
    String portfolioId,
  ) async {
    CommonLogger.methodEntry(
      'getPortfolioAnalyticsWithDefaults',
      tag: 'PortfolioAnalyticsService',
      metadata: {'portfolioId': portfolioId},
    );

    try {
      // Create default request with all features enabled
      final request = PortfolioAnalyticsMapper.createDefaultRequest(
        portfolioId,
      );

      CommonLogger.info(
        'Getting portfolio analytics with default configuration',
        tag: 'PortfolioAnalyticsService',
      );
      final analytics = await _getPortfolioAnalytics(request);

      CommonLogger.info(
        'Portfolio analytics with defaults retrieved successfully',
        tag: 'PortfolioAnalyticsService',
      );
      CommonLogger.methodExit(
        'getPortfolioAnalyticsWithDefaults',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': 'success'},
      );

      return analytics;
    } catch (error) {
      CommonLogger.error(
        'Failed to get portfolio analytics with defaults',
        tag: 'PortfolioAnalyticsService',
        error: error,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioAnalyticsWithDefaults',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Retrieves only heatmap data for portfolio visualization
  /// Optimized method for getting visualization data only
  Future<Heatmap?> getPortfolioHeatmap(String portfolioId) async {
    CommonLogger.methodEntry(
      'getPortfolioHeatmap',
      tag: 'PortfolioAnalyticsService',
      metadata: {'portfolioId': portfolioId},
    );

    try {
      // Create request with only heatmap enabled
      final request = _createHeatmapOnlyRequest(portfolioId);

      CommonLogger.info(
        'Getting portfolio heatmap data',
        tag: 'PortfolioAnalyticsService',
      );
      final heatmap = await _getPortfolioAnalytics.getHeatmapData(request);

      CommonLogger.info(
        'Portfolio heatmap retrieved successfully',
        tag: 'PortfolioAnalyticsService',
      );
      CommonLogger.methodExit(
        'getPortfolioHeatmap',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': 'success'},
      );

      return heatmap;
    } catch (error) {
      CommonLogger.error(
        'Failed to get portfolio heatmap',
        tag: 'PortfolioAnalyticsService',
        error: error,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioHeatmap',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Retrieves only market movers data
  /// Optimized method for getting gainers and losers data only
  Future<Movers?> getPortfolioMovers(
    String portfolioId, {
    int limit = 10,
  }) async {
    CommonLogger.methodEntry(
      'getPortfolioMovers',
      tag: 'PortfolioAnalyticsService',
      metadata: {'portfolioId': portfolioId, 'limit': limit},
    );

    try {
      // Create request with only movers enabled
      final request = _createMoversOnlyRequest(portfolioId, limit: limit);

      CommonLogger.info(
        'Getting portfolio movers data',
        tag: 'PortfolioAnalyticsService',
      );
      final movers = await _getPortfolioAnalytics.getMoversData(request);

      CommonLogger.info(
        'Portfolio movers retrieved successfully',
        tag: 'PortfolioAnalyticsService',
      );
      CommonLogger.methodExit(
        'getPortfolioMovers',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': 'success'},
      );

      return movers;
    } catch (error) {
      CommonLogger.error(
        'Failed to get portfolio movers',
        tag: 'PortfolioAnalyticsService',
        error: error,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioMovers',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Retrieves comprehensive allocation data (sector + market cap)
  /// Convenient method for getting both allocation types in one call
  Future<AllocationData> getPortfolioAllocations(String portfolioId) async {
    CommonLogger.methodEntry(
      'getPortfolioAllocations',
      tag: 'PortfolioAnalyticsService',
      metadata: {'portfolioId': portfolioId},
    );

    try {
      // Create request with allocation features enabled
      final request = _createAllocationOnlyRequest(portfolioId);

      CommonLogger.info(
        'Getting portfolio allocation data',
        tag: 'PortfolioAnalyticsService',
      );

      // Get both allocation types
      final results = await Future.wait([
        _getPortfolioAnalytics.getSectorAllocation(request),
        _getPortfolioAnalytics.getMarketCapAllocation(request),
      ]);

      final allocationData = AllocationData(
        sectorAllocation: results[0] as SectorAllocation?,
        marketCapAllocation: results[1] as MarketCapAllocation?,
      );

      CommonLogger.info(
        'Portfolio allocations retrieved successfully',
        tag: 'PortfolioAnalyticsService',
      );
      CommonLogger.methodExit(
        'getPortfolioAllocations',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': 'success'},
      );

      return allocationData;
    } catch (error) {
      CommonLogger.error(
        'Failed to get portfolio allocations',
        tag: 'PortfolioAnalyticsService',
        error: error,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioAllocations',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Validates portfolio analytics data completeness
  /// Returns true if all requested analytics data is available and valid
  Future<bool> validateAnalyticsDataCompleteness(
    PortfolioAnalyticsRequest request,
  ) async {
    CommonLogger.methodEntry(
      'validateAnalyticsDataCompleteness',
      tag: 'PortfolioAnalyticsService',
      metadata: {'portfolioId': request.coreIdentifiers.portfolioId},
    );

    try {
      final analytics = await _getPortfolioAnalytics(request);

      // Check if requested features have data
      var isComplete = true;

      if (request.featureToggles.includeHeatmap &&
          analytics.analytics.heatmap == null) {
        CommonLogger.warning(
          'Heatmap data missing despite being requested',
          tag: 'PortfolioAnalyticsService',
        );
        isComplete = false;
      }

      if (request.featureToggles.includeMovers &&
          analytics.analytics.movers == null) {
        CommonLogger.warning(
          'Movers data missing despite being requested',
          tag: 'PortfolioAnalyticsService',
        );
        isComplete = false;
      }

      if (request.featureToggles.includeSectorAllocation &&
          analytics.analytics.sectorAllocation == null) {
        CommonLogger.warning(
          'Sector allocation data missing despite being requested',
          tag: 'PortfolioAnalyticsService',
        );
        isComplete = false;
      }

      if (request.featureToggles.includeMarketCapAllocation &&
          analytics.analytics.marketCapAllocation == null) {
        CommonLogger.warning(
          'Market cap allocation data missing despite being requested',
          tag: 'PortfolioAnalyticsService',
        );
        isComplete = false;
      }

      CommonLogger.info(
        'Analytics data completeness validation completed: $isComplete',
        tag: 'PortfolioAnalyticsService',
      );
      CommonLogger.methodExit(
        'validateAnalyticsDataCompleteness',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': isComplete ? 'complete' : 'incomplete'},
      );

      return isComplete;
    } catch (error) {
      CommonLogger.error(
        'Failed to validate analytics data completeness',
        tag: 'PortfolioAnalyticsService',
        error: error,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'validateAnalyticsDataCompleteness',
        tag: 'PortfolioAnalyticsService',
        metadata: {'status': 'error'},
      );
      return false;
    }
  }

  /// Creates a request with only heatmap feature enabled
  PortfolioAnalyticsRequest _createHeatmapOnlyRequest(String portfolioId) =>
      PortfolioAnalyticsRequest(
        coreIdentifiers: CoreIdentifiers(portfolioId: portfolioId),
        featureToggles: const FeatureToggles(
          includeHeatmap: true,
          includeMovers: false,
          includeSectorAllocation: false,
          includeMarketCapAllocation: false,
        ),
        featureConfiguration: const FeatureConfiguration(moversLimit: 10),
        pagination: const Pagination(
          page: 1,
          size: 50,
          sortBy: 'performance',
          sortDirection: 'desc',
          returnAllData: false,
        ),
      );

  /// Creates a request with only movers feature enabled
  PortfolioAnalyticsRequest _createMoversOnlyRequest(
    String portfolioId, {
    int limit = 10,
  }) => PortfolioAnalyticsRequest(
    coreIdentifiers: CoreIdentifiers(portfolioId: portfolioId),
    featureToggles: const FeatureToggles(
      includeHeatmap: false,
      includeMovers: true,
      includeSectorAllocation: false,
      includeMarketCapAllocation: false,
    ),
    featureConfiguration: FeatureConfiguration(moversLimit: limit),
    pagination: const Pagination(
      page: 1,
      size: 50,
      sortBy: 'changePercent',
      sortDirection: 'desc',
      returnAllData: false,
    ),
  );

  /// Creates a request with only allocation features enabled
  PortfolioAnalyticsRequest _createAllocationOnlyRequest(String portfolioId) =>
      PortfolioAnalyticsRequest(
        coreIdentifiers: CoreIdentifiers(portfolioId: portfolioId),
        featureToggles: const FeatureToggles(
          includeHeatmap: false,
          includeMovers: false,
          includeSectorAllocation: true,
          includeMarketCapAllocation: true,
        ),
        featureConfiguration: const FeatureConfiguration(moversLimit: 10),
        pagination: const Pagination(
          page: 1,
          size: 100,
          sortBy: 'weightage',
          sortDirection: 'desc',
          returnAllData: false,
        ),
      );
}

/// Data class for combined allocation information
class AllocationData {
  const AllocationData({this.sectorAllocation, this.marketCapAllocation});
  final SectorAllocation? sectorAllocation;
  final MarketCapAllocation? marketCapAllocation;

  /// Returns true if both allocation types have data
  bool get hasCompleteData =>
      sectorAllocation != null && marketCapAllocation != null;

  /// Returns true if at least one allocation type has data
  bool get hasAnyData =>
      sectorAllocation != null || marketCapAllocation != null;
}
