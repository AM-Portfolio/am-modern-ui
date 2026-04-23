import 'package:am_library/am_library.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/am_common.dart';
import '../dtos/favorite_filter_dto.dart';

/// Abstract data source for favorite filter operations
abstract class FavoriteFilterRemoteDataSource {
  /// Get all favorite filters for a user
  Future<List<FavoriteFilterResponseDto>> getFavoriteFilters(String userId);

  /// Get a specific favorite filter by ID
  Future<FavoriteFilterResponseDto> getFavoriteFilterById(String userId, String filterId);

  /// Create a new favorite filter
  Future<FavoriteFilterResponseDto> createFavoriteFilter(String userId, FavoriteFilterRequestDto request);

  /// Update an existing favorite filter
  Future<FavoriteFilterResponseDto> updateFavoriteFilter(
    String userId,
    String filterId,
    FavoriteFilterRequestDto request,
  );

  /// Delete a favorite filter
  Future<void> deleteFavoriteFilter(String userId, String filterId);

  /// Bulk delete favorite filters
  Future<BulkDeleteResponseDto> bulkDeleteFavoriteFilters(BulkDeleteRequestDto request);

  /// Set a filter as default
  Future<FavoriteFilterResponseDto> setDefaultFilter(String userId, String filterId);
}

/// Concrete implementation of favorite filter remote data source
class FavoriteFilterRemoteDataSourceImpl implements FavoriteFilterRemoteDataSource {
  const FavoriteFilterRemoteDataSourceImpl({
    required ApiClient apiClient,
    required TradeApiConfig tradeConfig,
  }) : _apiClient = apiClient,
       _tradeConfig = tradeConfig;

  final ApiClient _apiClient;
  final TradeApiConfig _tradeConfig;

  /// Helper to safely build URI avoiding double slashes
  String _buildUri(String baseUrl, String resource) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanResource = resource.startsWith('/')
        ? resource
        : '/$resource';
    return '$cleanBase$cleanResource';
  }

  @override
  Future<List<FavoriteFilterResponseDto>> getFavoriteFilters(String userId) async {
    AppLogger.methodEntry('getFavoriteFilters', tag: 'FavoriteFilterRemoteDataSource', params: {'userId': userId});

    try {
     
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/filters');
      final fullUri = '$baseUri?userId=$userId';

      final response = await _apiClient.get<List<FavoriteFilterResponseDto>>(
        fullUri,
        parser: (data) {
          if (data is List) {
            return data.map((item) => FavoriteFilterResponseDto.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      AppLogger.info('Favorite filters fetched successfully', tag: 'FavoriteFilterRemoteDataSource');
      AppLogger.methodExit('getFavoriteFilters', tag: 'FavoriteFilterRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch favorite filters',
        tag: 'FavoriteFilterRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<FavoriteFilterResponseDto> getFavoriteFilterById(String userId, String filterId) async {
    AppLogger.methodEntry(
      'getFavoriteFilterById',
      tag: 'FavoriteFilterRemoteDataSource',
      params: {'userId': userId, 'filterId': filterId},
    );

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/filters');
      final fullUri = '$baseUri/$filterId?userId=$userId';

      final response = await _apiClient.get<FavoriteFilterResponseDto>(
        fullUri,
        parser: (data) => FavoriteFilterResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info('Favorite filter fetched successfully', tag: 'FavoriteFilterRemoteDataSource');
      AppLogger.methodExit('getFavoriteFilterById', tag: 'FavoriteFilterRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch favorite filter by ID',
        tag: 'FavoriteFilterRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<FavoriteFilterResponseDto> createFavoriteFilter(String userId, FavoriteFilterRequestDto request) async {
    AppLogger.methodEntry(
      'createFavoriteFilter',
      tag: 'FavoriteFilterRemoteDataSource',
      params: {'userId': userId, 'name': request.name},
    );

    try {
      // API Spec: POST /api/v1/filters?userId={userId}
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/filters');
      final fullUri = '$baseUri?userId=$userId';

      final response = await _apiClient.post<FavoriteFilterResponseDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => FavoriteFilterResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info('Favorite filter created successfully', tag: 'FavoriteFilterRemoteDataSource');
      AppLogger.methodExit('createFavoriteFilter', tag: 'FavoriteFilterRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to create favorite filter',
        tag: 'FavoriteFilterRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<FavoriteFilterResponseDto> updateFavoriteFilter(
    String userId,
    String filterId,
    FavoriteFilterRequestDto request,
  ) async {
    AppLogger.methodEntry(
      'updateFavoriteFilter',
      tag: 'FavoriteFilterRemoteDataSource',
      params: {'userId': userId, 'filterId': filterId},
    );

    try {
      // API Spec: PUT /api/v1/filters/{filterId}?userId={userId}
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/filters');
      final fullUri = '$baseUri/$filterId?userId=$userId';

      final response = await _apiClient.put<FavoriteFilterResponseDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => FavoriteFilterResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info('Favorite filter updated successfully', tag: 'FavoriteFilterRemoteDataSource');
      AppLogger.methodExit('updateFavoriteFilter', tag: 'FavoriteFilterRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to update favorite filter',
        tag: 'FavoriteFilterRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteFavoriteFilter(String userId, String filterId) async {
    AppLogger.methodEntry(
      'deleteFavoriteFilter',
      tag: 'FavoriteFilterRemoteDataSource',
      params: {'userId': userId, 'filterId': filterId},
    );

    try {
      // API Spec: DELETE /api/v1/filters/{filterId}?userId={userId}
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/filters');
      final fullUri = '$baseUri/$filterId?userId=$userId';

      await _apiClient.delete<void>(fullUri, parser: (_) {});

      AppLogger.info('Favorite filter deleted successfully', tag: 'FavoriteFilterRemoteDataSource');
      AppLogger.methodExit('deleteFavoriteFilter', tag: 'FavoriteFilterRemoteDataSource', result: 'success');
    } catch (e) {
      AppLogger.error(
        'Failed to delete favorite filter',
        tag: 'FavoriteFilterRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<BulkDeleteResponseDto> bulkDeleteFavoriteFilters(BulkDeleteRequestDto request) async {
    AppLogger.methodEntry(
      'bulkDeleteFavoriteFilters',
      tag: 'FavoriteFilterRemoteDataSource',
      params: {'userId': request.userId, 'filterCount': request.filterIds.length},
    );

    try {
      // API Spec: DELETE /api/v1/filters/bulk
      final fullUri = _buildUri(_tradeConfig.baseUrl, 'v1/filters/bulk');

      final response = await _apiClient.delete<BulkDeleteResponseDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => BulkDeleteResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info('Bulk delete completed successfully', tag: 'FavoriteFilterRemoteDataSource');
      AppLogger.methodExit('bulkDeleteFavoriteFilters', tag: 'FavoriteFilterRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to bulk delete favorite filters',
        tag: 'FavoriteFilterRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<FavoriteFilterResponseDto> setDefaultFilter(String userId, String filterId) async {
    AppLogger.methodEntry(
      'setDefaultFilter',
      tag: 'FavoriteFilterRemoteDataSource',
      params: {'userId': userId, 'filterId': filterId},
    );

    try {
      // API Spec: PUT /api/v1/filters/{filterId}/set-default?userId={userId}
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/filters');
      final fullUri = '$baseUri/$filterId/set-default?userId=$userId';

      final response = await _apiClient.put<FavoriteFilterResponseDto>(
        fullUri,
        parser: (data) => FavoriteFilterResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info('Filter set as default successfully', tag: 'FavoriteFilterRemoteDataSource');
      AppLogger.methodExit('setDefaultFilter', tag: 'FavoriteFilterRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to set default filter',
        tag: 'FavoriteFilterRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}

