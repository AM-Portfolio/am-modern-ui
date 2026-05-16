import 'package:am_design_system/am_design_system.dart';
import 'dart:async';

import 'package:am_common/am_common.dart';
import '../../domain/entities/portfolio_analytics.dart';
import '../../domain/entities/portfolio_analytics_request.dart';
import '../../domain/repositories/portfolio_analytics_repository.dart';
import '../datasources/portfolio_remote_data_source.dart';
import '../mappers/portfolio_analytics_mapper.dart';

/// Repository implementation for portfolio analytics data operations
///
/// Handles portfolio analytics data operations following clean architecture principles
/// - Coordinates between data sources (remote, local cache)
/// - Maps DTOs to domain entities
/// - Provides caching and error handling
/// - Implements comprehensive logging
class PortfolioAnalyticsRepositoryImpl implements PortfolioAnalyticsRepository {
  PortfolioAnalyticsRepositoryImpl({
    required PortfolioRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;
  final PortfolioRemoteDataSource _remoteDataSource;

  // Cache for the latest analytics data
  PortfolioAnalytics? _cachedAnalytics;
  PortfolioAnalyticsRequest? _lastRequest;
  DateTime? _lastFetchTime;

  // Cache expiry duration (5 minutes)
  static const Duration _cacheExpiryDuration = Duration(minutes: 5);

  @override
  Future<PortfolioAnalytics> getPortfolioAnalytics(
    PortfolioAnalyticsRequest request,
  ) async {
    try {
      // Check cache validity
      if (_isCacheValid(request)) {
        return _cachedAnalytics!;
      }

      // Convert request entity to DTO
      final requestDto = PortfolioAnalyticsMapper.requestToDto(request);

      // Fetch data from remote source
      final analyticsDto = await _remoteDataSource.getPortfolioAnalytics(
        request.coreIdentifiers.portfolioId,
        requestDto,
      );
      // Map DTO to domain entity using analytics mapper
      final analytics = PortfolioAnalyticsMapper.responseFromDto(analyticsDto);

      // Cache the result
      _cachedAnalytics = analytics;
      _lastRequest = request;
      _lastFetchTime = DateTime.now();

      CommonLogger.info(
        'Portfolio analytics fetched successfully',
        tag: 'PortfolioAnalyticsRepository',
      );
      CommonLogger.methodExit(
        'getPortfolioAnalytics',
        tag: 'PortfolioAnalyticsRepository',
        metadata: {'status': 'success'},
      );

      return analytics;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolio analytics',
        tag: 'PortfolioAnalyticsRepository',
        error: e,
      );

      // Return cached data if available, otherwise rethrow
      if (_cachedAnalytics != null && _isRequestSimilar(request)) {
        CommonLogger.warning(
          'Using cached data due to fetch error',
          tag: 'PortfolioAnalyticsRepository',
        );
        return _cachedAnalytics!;
      }

      rethrow;
    }
  }

  @override
  Future<Heatmap?> getHeatmapData(PortfolioAnalyticsRequest request) async {
    try {
      final analytics = await getPortfolioAnalytics(request);
      return analytics.analytics.heatmap;
    } catch (e) {
      CommonLogger.error(
        'Failed to get heatmap data',
        tag: 'PortfolioAnalyticsRepository',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<Movers?> getMoversData(PortfolioAnalyticsRequest request) async {
    try {
      final analytics = await getPortfolioAnalytics(request);
      return analytics.analytics.movers;
    } catch (e) {
      CommonLogger.error(
        'Failed to get movers data',
        tag: 'PortfolioAnalyticsRepository',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<SectorAllocation?> getSectorAllocation(
    PortfolioAnalyticsRequest request,
  ) async {
    try {
      final analytics = await getPortfolioAnalytics(request);
      return analytics.analytics.sectorAllocation;
    } catch (e) {
      CommonLogger.error(
        'Failed to get sector allocation data',
        tag: 'PortfolioAnalyticsRepository',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<MarketCapAllocation?> getMarketCapAllocation(
    PortfolioAnalyticsRequest request,
  ) async {
    try {
      final analytics = await getPortfolioAnalytics(request);
      return analytics.analytics.marketCapAllocation;
    } catch (e) {
      CommonLogger.error(
        'Failed to get market cap allocation data',
        tag: 'PortfolioAnalyticsRepository',
        error: e,
      );
      rethrow;
    }
  }

  /// Checks if cached data is still valid
  bool _isCacheValid(PortfolioAnalyticsRequest request) {
    if (_cachedAnalytics == null ||
        _lastFetchTime == null ||
        _lastRequest == null) {
      return false;
    }

    // Check if cache has expired
    final now = DateTime.now();
    if (now.difference(_lastFetchTime!) > _cacheExpiryDuration) {
      return false;
    }

    // Check if request is similar enough to use cached data
    return _isRequestSimilar(request);
  }

  /// Checks if the request is similar enough to the last request to use cached data
  bool _isRequestSimilar(PortfolioAnalyticsRequest request) {
    if (_lastRequest == null) return false;

    // Compare core identifiers (primary key for portfolio data)
    if (request.coreIdentifiers.portfolioId !=
        _lastRequest!.coreIdentifiers.portfolioId) {
      return false;
    }

    // Compare feature toggles (what data is being requested)
    final currentToggles = request.featureToggles;
    final lastToggles = _lastRequest!.featureToggles;

    if (currentToggles.includeHeatmap != lastToggles.includeHeatmap ||
        currentToggles.includeMovers != lastToggles.includeMovers ||
        currentToggles.includeSectorAllocation !=
            lastToggles.includeSectorAllocation ||
        currentToggles.includeMarketCapAllocation !=
            lastToggles.includeMarketCapAllocation) {
      return false;
    }

    return true;
  }

  /// Clears the cache
  void clearCache() {
    _cachedAnalytics = null;
    _lastRequest = null;
    _lastFetchTime = null;
  }

  /// Dispose method to clean up resources
  void dispose() {
    clearCache();
  }
}
