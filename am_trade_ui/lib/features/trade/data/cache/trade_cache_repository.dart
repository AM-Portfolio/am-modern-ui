import 'package:am_design_system/am_design_system.dart';

/// Repository for caching Trade module data
/// Uses CacheService with predefined TTL and keys
class TradeCacheRepository {
  final CacheService _cacheService;

  TradeCacheRepository(this._cacheService);

  // ============================================================================
  // Trade Portfolios
  // ============================================================================

  Future<List<dynamic>?> getPortfolios(String userId) async {
    final key = TradeCacheKeys.portfolios(userId);
    return await _cacheService.get<List<dynamic>>(key);
  }

  Future<void> cachePortfolios(String userId, List<dynamic> portfolios) async {
    final key = TradeCacheKeys.portfolios(userId);
    await _cacheService.set(key, portfolios, ttl: CacheTTL.medium);
  }

  // ============================================================================
  // Trades
  // ============================================================================

  Future<List<dynamic>?> getTrades(String userId, String portfolioId) async {
    final key = TradeCacheKeys.trades(userId, portfolioId);
    return await _cacheService.get<List<dynamic>>(key);
  }

  Future<void> cacheTrades(
    String userId,
    String portfolioId,
    List<dynamic> trades,
  ) async {
    final key = TradeCacheKeys.trades(userId, portfolioId);
    await _cacheService.set(key, trades, ttl: CacheTTL.medium);
  }

  // ============================================================================
  // Trade Metrics
  // ============================================================================

  Future<Map<String, dynamic>?> getMetrics(String userId, String portfolioId) async {
    final key = TradeCacheKeys.metrics(userId, portfolioId);
    return await _cacheService.get<Map<String, dynamic>>(key);
  }

  Future<void> cacheMetrics(
    String userId,
    String portfolioId,
    Map<String, dynamic> metrics,
  ) async {
    final key = TradeCacheKeys.metrics(userId, portfolioId);
    await _cacheService.set(key, metrics, ttl: CacheTTL.long);
  }

  // ============================================================================
  // Trade Calendar
  // ============================================================================

  Future<Map<String, dynamic>?> getCalendar(String userId, String portfolioId) async {
    final key = TradeCacheKeys.calendar(userId, portfolioId);
    return await _cacheService.get<Map<String, dynamic>>(key);
  }

  Future<void> cacheCalendar(
    String userId,
    String portfolioId,
    Map<String, dynamic> calendar,
  ) async {
    final key = TradeCacheKeys.calendar(userId, portfolioId);
    await _cacheService.set(key, calendar, ttl: CacheTTL.medium);
  }

  // ============================================================================
  // Clear Trade Cache
  // ============================================================================

  Future<void> clearTradeCache(String userId, String portfolioId) async {
    await _cacheService.clear(TradeCacheKeys.trades(userId, portfolioId));
    await _cacheService.clear(TradeCacheKeys.metrics(userId, portfolioId));
    await _cacheService.clear(TradeCacheKeys.calendar(userId, portfolioId));
  }

  Future<void> clearAllPortfolios(String userId) async {
    await _cacheService.clear(TradeCacheKeys.portfolios(userId));
  }
}
