import 'package:am_design_system/am_design_system.dart';

/// Repository for caching Portfolio module data
/// Uses CacheService with predefined TTL and keys
class PortfolioCacheRepository {
  final CacheService _cacheService;

  PortfolioCacheRepository(this._cacheService);

  // ============================================================================
  // Portfolio Summary
  // ============================================================================

  Future<Map<String, dynamic>?> getSummary(String userId, String portfolioId) async {
    final key = PortfolioCacheKeys.summary(userId, portfolioId);
    return await _cacheService.get<Map<String, dynamic>>(key);
  }

  Future<void> cacheSummary(
    String userId,
    String portfolioId,
    Map<String, dynamic> summary,
  ) async {
    final key = PortfolioCacheKeys.summary(userId, portfolioId);
    await _cacheService.set(key, summary, ttl: CacheTTL.medium);
  }

  // ============================================================================
  // Portfolio Holdings
  // ============================================================================

  Future<List<dynamic>?> getHoldings(String userId, String portfolioId) async {
    final key = PortfolioCacheKeys.holdings(userId, portfolioId);
    return await _cacheService.get<List<dynamic>>(key);
  }

  Future<void> cacheHoldings(
    String userId,
    String portfolioId,
    List<dynamic> holdings,
  ) async {
    final key = PortfolioCacheKeys.holdings(userId, portfolioId);
    await _cacheService.set(key, holdings, ttl: CacheTTL.medium);
  }

  // ============================================================================
  // Portfolio Heatmap
  // ============================================================================

  Future<Map<String, dynamic>?> getHeatmap(String userId, String portfolioId) async {
    final key = PortfolioCacheKeys.heatmap(userId, portfolioId);
    return await _cacheService.get<Map<String, dynamic>>(key);
  }

  Future<void> cacheHeatmap(
    String userId,
    String portfolioId,
    Map<String, dynamic> heatmap,
  ) async {
    final key = PortfolioCacheKeys.heatmap(userId, portfolioId);
    await _cacheService.set(key, heatmap, ttl: CacheTTL.medium);
  }

  // ============================================================================
  // Portfolio Analytics
  // ============================================================================

  Future<Map<String, dynamic>?> getAnalytics(String userId, String portfolioId) async {
    final key = PortfolioCacheKeys.analytics(userId, portfolioId);
    return await _cacheService.get<Map<String, dynamic>>(key);
  }

  Future<void> cacheAnalytics(
    String userId,
    String portfolioId,
    Map<String, dynamic> analytics,
  ) async {
    final key = PortfolioCacheKeys.analytics(userId, portfolioId);
    await _cacheService.set(key, analytics, ttl: CacheTTL.long);
  }

  // ============================================================================
  // Clear Portfolio Cache
  // ============================================================================

  Future<void> clearPortfolioCache(String userId, String portfolioId) async {
    await _cacheService.clear(PortfolioCacheKeys.summary(userId, portfolioId));
    await _cacheService.clear(PortfolioCacheKeys.holdings(userId, portfolioId));
    await _cacheService.clear(PortfolioCacheKeys.heatmap(userId, portfolioId));
    await _cacheService.clear(PortfolioCacheKeys.analytics(userId, portfolioId));
  }

  Future<void> clearAllPortfolios(String userId) async {
    // This would require iterating through all keys
    // For now, individual clear is preferred
  }
}
