import 'package:am_design_system/am_design_system.dart';

/// Repository for caching Portfolio module data
/// Uses CacheService with predefined TTL and keys
class PortfolioCacheRepository {
  final CacheService _cacheService;

  PortfolioCacheRepository(this._cacheService);

  // ============================================================================
  // Portfolio Summary
  // ============================================================================

  Future<Map<String, dynamic>?> getSummary(
    String portfolioId,
  ) async {
    final key = PortfolioCacheKeys.summary(portfolioId);
    return await _cacheService.get<Map<String, dynamic>>(key);
  }

  Future<void> cacheSummary(
    String portfolioId,
    Map<String, dynamic> summary,
  ) async {
    final key = PortfolioCacheKeys.summary(portfolioId);
    await _cacheService.set(key, summary, ttl: CacheTTL.medium);
  }

  // ============================================================================
  // Portfolio Holdings
  // ============================================================================

  Future<List<dynamic>?> getHoldings(String portfolioId) async {
    final key = PortfolioCacheKeys.holdings(portfolioId);
    return await _cacheService.get<List<dynamic>>(key);
  }

  Future<void> cacheHoldings(
    String portfolioId,
    List<dynamic> holdings,
  ) async {
    final key = PortfolioCacheKeys.holdings(portfolioId);
    await _cacheService.set(key, holdings, ttl: CacheTTL.medium);
  }

  // ============================================================================
  // Portfolio Heatmap
  // ============================================================================

  Future<Map<String, dynamic>?> getHeatmap(
    String portfolioId,
  ) async {
    final key = PortfolioCacheKeys.heatmap(portfolioId);
    return await _cacheService.get<Map<String, dynamic>>(key);
  }

  Future<void> cacheHeatmap(
    String portfolioId,
    Map<String, dynamic> heatmap,
  ) async {
    final key = PortfolioCacheKeys.heatmap(portfolioId);
    await _cacheService.set(key, heatmap, ttl: CacheTTL.medium);
  }

  // ============================================================================
  // Portfolio Analytics
  // ============================================================================

  Future<Map<String, dynamic>?> getAnalytics(
    String portfolioId,
  ) async {
    final key = PortfolioCacheKeys.analytics(portfolioId);
    return await _cacheService.get<Map<String, dynamic>>(key);
  }

  Future<void> cacheAnalytics(
    String portfolioId,
    Map<String, dynamic> analytics,
  ) async {
    final key = PortfolioCacheKeys.analytics(portfolioId);
    await _cacheService.set(key, analytics, ttl: CacheTTL.long);
  }

  // ============================================================================
  // Clear Portfolio Cache
  // ============================================================================

  Future<void> clearPortfolioCache(String portfolioId) async {
    await _cacheService.clear(PortfolioCacheKeys.summary(portfolioId));
    await _cacheService.clear(PortfolioCacheKeys.holdings(portfolioId));
    await _cacheService.clear(PortfolioCacheKeys.heatmap(portfolioId));
    await _cacheService.clear(
      PortfolioCacheKeys.analytics(portfolioId),
    );
  }

  Future<void> clearAllPortfolios() async {
    // This would require iterating through all keys
    // For now, individual clear is preferred
  }
}
