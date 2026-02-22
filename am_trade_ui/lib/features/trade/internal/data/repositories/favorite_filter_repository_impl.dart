import 'dart:async';

import 'package:am_common/am_common.dart';
import '../../domain/entities/favorite_filter.dart';
import '../../domain/entities/metrics_filter_config.dart';
import '../../domain/repositories/favorite_filter_repository.dart';
import '../datasources/favorite_filter_remote_data_source.dart';
import '../dtos/favorite_filter_dto.dart';
import '../mappers/favorite_filter_mapper.dart';

/// Repository implementation for favorite filter operations
class FavoriteFilterRepositoryImpl implements FavoriteFilterRepository {
  FavoriteFilterRepositoryImpl({required FavoriteFilterRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final FavoriteFilterRemoteDataSource _remoteDataSource;

  // Stream controllers for real-time updates
  final StreamController<FavoriteFilterList> _filtersController = StreamController<FavoriteFilterList>.broadcast();

  // Cache for the latest data
  FavoriteFilterList? _cachedFilterList;

  @override
  Future<FavoriteFilterList> getFavoriteFilters(String userId) async {
    AppLogger.methodEntry('getFavoriteFilters', tag: 'FavoriteFilterRepository', params: {'userId': userId});

    try {
      final dtos = await _remoteDataSource.getFavoriteFilters(userId);
      final filterList = FavoriteFilterMapper.fromListDto(dtos, userId);

      _cachedFilterList = filterList;
      _filtersController.add(filterList);

      AppLogger.info('Favorite filters fetched successfully', tag: 'FavoriteFilterRepository');
      AppLogger.methodExit('getFavoriteFilters', tag: 'FavoriteFilterRepository', result: 'success');

      return filterList;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch favorite filters',
        tag: 'FavoriteFilterRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('getFavoriteFilters', tag: 'FavoriteFilterRepository', result: 'error');

      if (_cachedFilterList != null) {
        AppLogger.info('Returning cached favorite filters', tag: 'FavoriteFilterRepository');
        return _cachedFilterList!;
      }

      rethrow;
    }
  }

  @override
  Future<FavoriteFilter> getFavoriteFilterById(String userId, String filterId) async {
    AppLogger.methodEntry(
      'getFavoriteFilterById',
      tag: 'FavoriteFilterRepository',
      params: {'userId': userId, 'filterId': filterId},
    );

    try {
      final dto = await _remoteDataSource.getFavoriteFilterById(userId, filterId);
      final filter = FavoriteFilterMapper.fromResponseDto(dto);

      AppLogger.info('Favorite filter fetched successfully', tag: 'FavoriteFilterRepository');
      AppLogger.methodExit('getFavoriteFilterById', tag: 'FavoriteFilterRepository', result: 'success');

      return filter;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch favorite filter by ID',
        tag: 'FavoriteFilterRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('getFavoriteFilterById', tag: 'FavoriteFilterRepository', result: 'error');

      rethrow;
    }
  }

  @override
  Future<FavoriteFilter> createFavoriteFilter(
    String userId,
    String name,
    MetricsFilterConfig filterConfig, {
    String? description,
    bool? isDefault,
  }) async {
    AppLogger.methodEntry(
      'createFavoriteFilter',
      tag: 'FavoriteFilterRepository',
      params: {'userId': userId, 'name': name},
    );

    try {
      final request = FavoriteFilterRequestDto(
        name: name,
        description: description,
        isDefault: isDefault,
        filterConfig: MetricsFilterConfigMapper.toDto(filterConfig),
      );

      final dto = await _remoteDataSource.createFavoriteFilter(userId, request);
      final filter = FavoriteFilterMapper.fromResponseDto(dto);

      // Refresh the list
      await getFavoriteFilters(userId);

      AppLogger.info('Favorite filter created successfully', tag: 'FavoriteFilterRepository');
      AppLogger.methodExit('createFavoriteFilter', tag: 'FavoriteFilterRepository', result: 'success');

      return filter;
    } catch (e) {
      AppLogger.error(
        'Failed to create favorite filter',
        tag: 'FavoriteFilterRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('createFavoriteFilter', tag: 'FavoriteFilterRepository', result: 'error');

      rethrow;
    }
  }

  @override
  Future<FavoriteFilter> updateFavoriteFilter(
    String userId,
    String filterId,
    String name,
    MetricsFilterConfig filterConfig, {
    String? description,
    bool? isDefault,
  }) async {
    AppLogger.methodEntry(
      'updateFavoriteFilter',
      tag: 'FavoriteFilterRepository',
      params: {'userId': userId, 'filterId': filterId},
    );

    try {
      final request = FavoriteFilterRequestDto(
        name: name,
        description: description,
        isDefault: isDefault,
        filterConfig: MetricsFilterConfigMapper.toDto(filterConfig),
      );

      final dto = await _remoteDataSource.updateFavoriteFilter(userId, filterId, request);
      final filter = FavoriteFilterMapper.fromResponseDto(dto);

      // Refresh the list
      await getFavoriteFilters(userId);

      AppLogger.info('Favorite filter updated successfully', tag: 'FavoriteFilterRepository');
      AppLogger.methodExit('updateFavoriteFilter', tag: 'FavoriteFilterRepository', result: 'success');

      return filter;
    } catch (e) {
      AppLogger.error(
        'Failed to update favorite filter',
        tag: 'FavoriteFilterRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('updateFavoriteFilter', tag: 'FavoriteFilterRepository', result: 'error');

      rethrow;
    }
  }

  @override
  Future<void> deleteFavoriteFilter(String userId, String filterId) async {
    AppLogger.methodEntry(
      'deleteFavoriteFilter',
      tag: 'FavoriteFilterRepository',
      params: {'userId': userId, 'filterId': filterId},
    );

    try {
      await _remoteDataSource.deleteFavoriteFilter(userId, filterId);

      // Refresh the list
      await getFavoriteFilters(userId);

      AppLogger.info('Favorite filter deleted successfully', tag: 'FavoriteFilterRepository');
      AppLogger.methodExit('deleteFavoriteFilter', tag: 'FavoriteFilterRepository', result: 'success');
    } catch (e) {
      AppLogger.error(
        'Failed to delete favorite filter',
        tag: 'FavoriteFilterRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('deleteFavoriteFilter', tag: 'FavoriteFilterRepository', result: 'error');

      rethrow;
    }
  }

  @override
  Future<BulkDeleteResult> bulkDeleteFavoriteFilters(String userId, List<String> filterIds) async {
    AppLogger.methodEntry(
      'bulkDeleteFavoriteFilters',
      tag: 'FavoriteFilterRepository',
      params: {'userId': userId, 'filterCount': filterIds.length},
    );

    try {
      final request = BulkDeleteRequestDto(userId: userId, filterIds: filterIds);
      final dto = await _remoteDataSource.bulkDeleteFavoriteFilters(request);
      final result = FavoriteFilterMapper.fromBulkDeleteDto(dto);

      // Refresh the list
      await getFavoriteFilters(userId);

      AppLogger.info('Bulk delete completed successfully', tag: 'FavoriteFilterRepository');
      AppLogger.methodExit('bulkDeleteFavoriteFilters', tag: 'FavoriteFilterRepository', result: 'success');

      return result;
    } catch (e) {
      AppLogger.error(
        'Failed to bulk delete favorite filters',
        tag: 'FavoriteFilterRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('bulkDeleteFavoriteFilters', tag: 'FavoriteFilterRepository', result: 'error');

      rethrow;
    }
  }

  @override
  Future<FavoriteFilter> setDefaultFilter(String userId, String filterId) async {
    AppLogger.methodEntry(
      'setDefaultFilter',
      tag: 'FavoriteFilterRepository',
      params: {'userId': userId, 'filterId': filterId},
    );

    try {
      final dto = await _remoteDataSource.setDefaultFilter(userId, filterId);
      final filter = FavoriteFilterMapper.fromResponseDto(dto);

      // Refresh the list
      await getFavoriteFilters(userId);

      AppLogger.info('Filter set as default successfully', tag: 'FavoriteFilterRepository');
      AppLogger.methodExit('setDefaultFilter', tag: 'FavoriteFilterRepository', result: 'success');

      return filter;
    } catch (e) {
      AppLogger.error(
        'Failed to set default filter',
        tag: 'FavoriteFilterRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('setDefaultFilter', tag: 'FavoriteFilterRepository', result: 'error');

      rethrow;
    }
  }

  @override
  Stream<FavoriteFilterList> watchFavoriteFilters(String userId) {
    // Trigger initial fetch if not already cached
    if (_cachedFilterList == null || _cachedFilterList!.userId != userId) {
      getFavoriteFilters(userId);
    }

    return _filtersController.stream;
  }
}

