import 'package:am_design_system/am_design_system.dart';
import '../entities/portfolio_analytics.dart';
import '../entities/portfolio_analytics_request.dart';
import '../repositories/portfolio_analytics_repository.dart';
import 'package:am_common/am_common.dart';

/// Use case for getting portfolio analytics
class GetPortfolioAnalytics {
  const GetPortfolioAnalytics(this._repository);
  final PortfolioAnalyticsRepository _repository;

  /// Execute the use case
  Future<PortfolioAnalytics> call(PortfolioAnalyticsRequest request) async {
    CommonLogger.methodEntry(
      'GetPortfolioAnalytics.call',
      tag: 'GetPortfolioAnalytics',
      metadata: {'portfolioId': request.coreIdentifiers.portfolioId},
    );

    // Validate request
    _validateRequest(request);

    try {
      CommonLogger.info(
        'Executing get portfolio analytics use case',
        tag: 'GetPortfolioAnalytics',
      );
      final result = await _repository.getPortfolioAnalytics(request);

      CommonLogger.info(
        'Portfolio analytics use case completed successfully',
        tag: 'GetPortfolioAnalytics',
      );
      CommonLogger.methodExit(
        'GetPortfolioAnalytics.call',
        tag: 'GetPortfolioAnalytics',
        metadata: {'status': 'success'},
      );

      return result;
    } catch (e) {
      CommonLogger.error(
        'Portfolio analytics use case failed',
        tag: 'GetPortfolioAnalytics',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'GetPortfolioAnalytics.call',
        tag: 'GetPortfolioAnalytics',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Get heatmap data only
  Future<Heatmap?> getHeatmapData(PortfolioAnalyticsRequest request) async {
    CommonLogger.methodEntry(
      'GetPortfolioAnalytics.getHeatmapData',
      tag: 'GetPortfolioAnalytics',
      metadata: {'portfolioId': request.coreIdentifiers.portfolioId},
    );

    // Validate request and ensure heatmap is enabled
    _validateRequest(request);
    if (!request.featureToggles.includeHeatmap) {
      CommonLogger.warning(
        'Heatmap feature is not enabled in request',
        tag: 'GetPortfolioAnalytics',
      );
      throw ArgumentError(
        'Heatmap feature must be enabled to fetch heatmap data',
      );
    }

    try {
      final result = await _repository.getHeatmapData(request);
      CommonLogger.methodExit(
        'GetPortfolioAnalytics.getHeatmapData',
        tag: 'GetPortfolioAnalytics',
        metadata: {'status': 'success'},
      );
      return result;
    } catch (e) {
      CommonLogger.error(
        'Get heatmap data failed',
        tag: 'GetPortfolioAnalytics',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'GetPortfolioAnalytics.getHeatmapData',
        tag: 'GetPortfolioAnalytics',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Get movers data only
  Future<Movers?> getMoversData(PortfolioAnalyticsRequest request) async {
    CommonLogger.methodEntry(
      'GetPortfolioAnalytics.getMoversData',
      tag: 'GetPortfolioAnalytics',
      metadata: {'portfolioId': request.coreIdentifiers.portfolioId},
    );

    // Validate request and ensure movers is enabled
    _validateRequest(request);
    if (!request.featureToggles.includeMovers) {
      CommonLogger.warning(
        'Movers feature is not enabled in request',
        tag: 'GetPortfolioAnalytics',
      );
      throw ArgumentError(
        'Movers feature must be enabled to fetch movers data',
      );
    }

    try {
      final result = await _repository.getMoversData(request);
      CommonLogger.methodExit(
        'GetPortfolioAnalytics.getMoversData',
        tag: 'GetPortfolioAnalytics',
        metadata: {'status': 'success'},
      );
      return result;
    } catch (e) {
      CommonLogger.error(
        'Get movers data failed',
        tag: 'GetPortfolioAnalytics',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'GetPortfolioAnalytics.getMoversData',
        tag: 'GetPortfolioAnalytics',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Get sector allocation data only
  Future<SectorAllocation?> getSectorAllocation(
    PortfolioAnalyticsRequest request,
  ) async {
    CommonLogger.methodEntry(
      'GetPortfolioAnalytics.getSectorAllocation',
      tag: 'GetPortfolioAnalytics',
      metadata: {'portfolioId': request.coreIdentifiers.portfolioId},
    );

    // Validate request and ensure sector allocation is enabled
    _validateRequest(request);
    if (!request.featureToggles.includeSectorAllocation) {
      CommonLogger.warning(
        'Sector allocation feature is not enabled in request',
        tag: 'GetPortfolioAnalytics',
      );
      throw ArgumentError(
        'Sector allocation feature must be enabled to fetch sector allocation data',
      );
    }

    try {
      final result = await _repository.getSectorAllocation(request);
      CommonLogger.methodExit(
        'GetPortfolioAnalytics.getSectorAllocation',
        tag: 'GetPortfolioAnalytics',
        metadata: {'status': 'success'},
      );
      return result;
    } catch (e) {
      CommonLogger.error(
        'Get sector allocation data failed',
        tag: 'GetPortfolioAnalytics',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'GetPortfolioAnalytics.getSectorAllocation',
        tag: 'GetPortfolioAnalytics',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Get market cap allocation data only
  Future<MarketCapAllocation?> getMarketCapAllocation(
    PortfolioAnalyticsRequest request,
  ) async {
    CommonLogger.methodEntry(
      'GetPortfolioAnalytics.getMarketCapAllocation',
      tag: 'GetPortfolioAnalytics',
      metadata: {'portfolioId': request.coreIdentifiers.portfolioId},
    );

    // Validate request and ensure market cap allocation is enabled
    _validateRequest(request);
    if (!request.featureToggles.includeMarketCapAllocation) {
      CommonLogger.warning(
        'Market cap allocation feature is not enabled in request',
        tag: 'GetPortfolioAnalytics',
      );
      throw ArgumentError(
        'Market cap allocation feature must be enabled to fetch market cap allocation data',
      );
    }

    try {
      final result = await _repository.getMarketCapAllocation(request);
      CommonLogger.methodExit(
        'GetPortfolioAnalytics.getMarketCapAllocation',
        tag: 'GetPortfolioAnalytics',
        metadata: {'status': 'success'},
      );
      return result;
    } catch (e) {
      CommonLogger.error(
        'Get market cap allocation data failed',
        tag: 'GetPortfolioAnalytics',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'GetPortfolioAnalytics.getMarketCapAllocation',
        tag: 'GetPortfolioAnalytics',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Validate the analytics request
  void _validateRequest(PortfolioAnalyticsRequest request) {
    if (request.coreIdentifiers.portfolioId.isEmpty) {
      CommonLogger.error(
        'Portfolio ID validation failed - empty portfolioId',
        tag: 'GetPortfolioAnalytics',
      );
      throw ArgumentError('Portfolio ID cannot be empty');
    }

    // Validate pagination parameters
    if (request.pagination.page < 1) {
      CommonLogger.error(
        'Pagination validation failed - invalid page number',
        tag: 'GetPortfolioAnalytics',
      );
      throw ArgumentError('Page number must be greater than 0');
    }

    if (request.pagination.size < 1 || request.pagination.size > 1000) {
      CommonLogger.error(
        'Pagination validation failed - invalid page size',
        tag: 'GetPortfolioAnalytics',
      );
      throw ArgumentError('Page size must be between 1 and 1000');
    }

    // Validate feature configuration
    if (request.featureConfiguration.moversLimit < 1 ||
        request.featureConfiguration.moversLimit > 100) {
      CommonLogger.error(
        'Feature configuration validation failed - invalid movers limit',
        tag: 'GetPortfolioAnalytics',
      );
      throw ArgumentError('Movers limit must be between 1 and 100');
    }

    CommonLogger.info(
      'Request validation passed',
      tag: 'GetPortfolioAnalytics',
    );
  }
}
