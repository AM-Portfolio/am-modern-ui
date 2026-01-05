import '../entities/favorite_filter.dart';
import '../entities/metrics_filter_config.dart';

/// Repository interface for favorite filter operations
abstract class FavoriteFilterRepository {
  /// Get all favorite filters for a user
  Future<FavoriteFilterList> getFavoriteFilters(String userId);

  /// Get a specific favorite filter by ID
  Future<FavoriteFilter> getFavoriteFilterById(String userId, String filterId);

  /// Create a new favorite filter
  Future<FavoriteFilter> createFavoriteFilter(
    String userId,
    String name,
    MetricsFilterConfig filterConfig, {
    String? description,
    bool? isDefault,
  });

  /// Update an existing favorite filter
  Future<FavoriteFilter> updateFavoriteFilter(
    String userId,
    String filterId,
    String name,
    MetricsFilterConfig filterConfig, {
    String? description,
    bool? isDefault,
  });

  /// Delete a favorite filter
  Future<void> deleteFavoriteFilter(String userId, String filterId);

  /// Bulk delete favorite filters
  Future<BulkDeleteResult> bulkDeleteFavoriteFilters(String userId, List<String> filterIds);

  /// Set a filter as default
  Future<FavoriteFilter> setDefaultFilter(String userId, String filterId);

  /// Get filters stream for real-time updates
  Stream<FavoriteFilterList> watchFavoriteFilters(String userId);
}
