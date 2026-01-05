import 'package:freezed_annotation/freezed_annotation.dart';

import 'metrics_filter_config.dart';

part 'favorite_filter.freezed.dart';

/// Domain entity for favorite filter
@freezed
abstract class FavoriteFilter with _$FavoriteFilter {
  const factory FavoriteFilter({
    required String id,
    required String name,
    required MetricsFilterConfig filterConfig,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isDefault,
  }) = _FavoriteFilter;
}

/// Domain entity for favorite filter list
@freezed
abstract class FavoriteFilterList with _$FavoriteFilterList {
  const factory FavoriteFilterList({
    required String userId,
    required List<FavoriteFilter> filters,
    @Default(0) int totalCount,
  }) = _FavoriteFilterList;

  /// Create empty filter list
  factory FavoriteFilterList.empty(String userId) => FavoriteFilterList(userId: userId, filters: []);
}

/// Domain entity for bulk delete result
@freezed
abstract class BulkDeleteResult with _$BulkDeleteResult {
  const factory BulkDeleteResult({required int deletedCount, required int totalRequested, String? message}) =
      _BulkDeleteResult;
}
