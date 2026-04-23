import 'package:am_library/am_library.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/am_common.dart';
import '../dtos/notebook_item_dto.dart';
import '../dtos/notebook_tag_dto.dart';

abstract class NotebookRemoteDataSource {
  // Notebook Items
  Future<NotebookItemDto> createNotebookItem(NotebookItemDto request);
  Future<List<NotebookItemDto>> getNotebookItems({
    required String userId,
    String? parentId,
    NotebookItemType? type,
  });
  Future<NotebookItemDto> getNotebookItem(String itemId);
  Future<NotebookItemDto> updateNotebookItem(String itemId, NotebookItemDto request);
  Future<void> deleteNotebookItem(String itemId);

  // Notebook Tags
  Future<NotebookTagDto> createNotebookTag(NotebookTagDto request);
  Future<List<NotebookTagDto>> getNotebookTags(String userId);
  Future<NotebookTagDto> updateNotebookTag(String tagId, NotebookTagDto request);
  Future<void> deleteNotebookTag(String tagId);
}

class NotebookRemoteDataSourceImpl implements NotebookRemoteDataSource {
  const NotebookRemoteDataSourceImpl({
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

  // --- Notebook Items ---

  @override
  Future<NotebookItemDto> createNotebookItem(NotebookItemDto request) async {
    AppLogger.methodEntry(
      'createNotebookItem',
      tag: 'NotebookRemoteDataSource',
      params: {'userId': request.userId, 'title': request.title, 'type': request.type},
    );

    try {
      final fullUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/notebook/items');
      final response = await _apiClient.post<NotebookItemDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => NotebookItemDto.fromJson(data! as Map<String, dynamic>),
      );
      AppLogger.info('Notebook item created successfully', tag: 'NotebookRemoteDataSource');
      AppLogger.methodExit('createNotebookItem', tag: 'NotebookRemoteDataSource', result: 'success');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to create notebook item',
        tag: 'NotebookRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<NotebookItemDto>> getNotebookItems({
    required String userId,
    String? parentId,
    NotebookItemType? type,
  }) async {
    AppLogger.methodEntry(
      'getNotebookItems',
      tag: 'NotebookRemoteDataSource',
      params: {'userId': userId, 'parentId': parentId, 'type': type},
    );

    try {
      var queryParams = 'userId=$userId';
      if (parentId != null) queryParams += '&parentId=$parentId';
      if (type != null) queryParams += '&type=${type.toString().split('.').last}';

      final baseUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/notebook/items');
      final fullUri = '$baseUri?$queryParams';

      final response = await _apiClient.get<List<NotebookItemDto>>(
        fullUri,
        parser: (data) {
          if (data is List) {
            return data.map((item) => NotebookItemDto.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );
      AppLogger.info('Notebook items fetched successfully', tag: 'NotebookRemoteDataSource');
      AppLogger.methodExit('getNotebookItems', tag: 'NotebookRemoteDataSource', result: 'success');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch notebook items',
        tag: 'NotebookRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<NotebookItemDto> getNotebookItem(String itemId) async {
    AppLogger.methodEntry('getNotebookItem', tag: 'NotebookRemoteDataSource', params: {'itemId': itemId});

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/notebook/items');
      final fullUri = '$baseUri/$itemId';

      final response = await _apiClient.get<NotebookItemDto>(
        fullUri,
        parser: (data) => NotebookItemDto.fromJson(data! as Map<String, dynamic>),
      );
      AppLogger.info('Notebook item fetched successfully', tag: 'NotebookRemoteDataSource');
      AppLogger.methodExit('getNotebookItem', tag: 'NotebookRemoteDataSource', result: 'success');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch notebook item',
        tag: 'NotebookRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<NotebookItemDto> updateNotebookItem(String itemId, NotebookItemDto request) async {
    AppLogger.methodEntry('updateNotebookItem', tag: 'NotebookRemoteDataSource', params: {'itemId': itemId});

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/notebook/items');
      final fullUri = '$baseUri/$itemId';

      final response = await _apiClient.put<NotebookItemDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => NotebookItemDto.fromJson(data! as Map<String, dynamic>),
      );
      AppLogger.info('Notebook item updated successfully', tag: 'NotebookRemoteDataSource');
      AppLogger.methodExit('updateNotebookItem', tag: 'NotebookRemoteDataSource', result: 'success');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to update notebook item',
        tag: 'NotebookRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteNotebookItem(String itemId) async {
    AppLogger.methodEntry('deleteNotebookItem', tag: 'NotebookRemoteDataSource', params: {'itemId': itemId});

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/notebook/items');
      final fullUri = '$baseUri/$itemId';

      await _apiClient.delete<void>(fullUri, parser: (_) {});
      AppLogger.info('Notebook item deleted successfully', tag: 'NotebookRemoteDataSource');
      AppLogger.methodExit('deleteNotebookItem', tag: 'NotebookRemoteDataSource', result: 'success');
    } catch (e) {
      AppLogger.error(
        'Failed to delete notebook item',
        tag: 'NotebookRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  // --- Notebook Tags ---

  @override
  Future<NotebookTagDto> createNotebookTag(NotebookTagDto request) async {
    AppLogger.methodEntry(
      'createNotebookTag',
      tag: 'NotebookRemoteDataSource',
      params: {'userId': request.userId, 'name': request.name},
    );

    try {
      final fullUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/notebook/tags');
      final response = await _apiClient.post<NotebookTagDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => NotebookTagDto.fromJson(data! as Map<String, dynamic>),
      );
      AppLogger.info('Notebook tag created successfully', tag: 'NotebookRemoteDataSource');
      AppLogger.methodExit('createNotebookTag', tag: 'NotebookRemoteDataSource', result: 'success');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to create notebook tag',
        tag: 'NotebookRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<NotebookTagDto>> getNotebookTags(String userId) async {
    AppLogger.methodEntry('getNotebookTags', tag: 'NotebookRemoteDataSource', params: {'userId': userId});

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/notebook/tags');
      final fullUri = '$baseUri?userId=$userId';

      final response = await _apiClient.get<List<NotebookTagDto>>(
        fullUri,
        parser: (data) {
          if (data is List) {
            return data.map((item) => NotebookTagDto.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );
      AppLogger.info('Notebook tags fetched successfully', tag: 'NotebookRemoteDataSource');
      AppLogger.methodExit('getNotebookTags', tag: 'NotebookRemoteDataSource', result: 'success');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch notebook tags',
        tag: 'NotebookRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<NotebookTagDto> updateNotebookTag(String tagId, NotebookTagDto request) async {
    AppLogger.methodEntry('updateNotebookTag', tag: 'NotebookRemoteDataSource', params: {'tagId': tagId});

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/notebook/tags');
      final fullUri = '$baseUri/$tagId';

      final response = await _apiClient.put<NotebookTagDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => NotebookTagDto.fromJson(data! as Map<String, dynamic>),
      );
      AppLogger.info('Notebook tag updated successfully', tag: 'NotebookRemoteDataSource');
      AppLogger.methodExit('updateNotebookTag', tag: 'NotebookRemoteDataSource', result: 'success');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to update notebook tag',
        tag: 'NotebookRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteNotebookTag(String tagId) async {
    AppLogger.methodEntry('deleteNotebookTag', tag: 'NotebookRemoteDataSource', params: {'tagId': tagId});

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/notebook/tags');
      final fullUri = '$baseUri/$tagId';

      await _apiClient.delete<void>(fullUri, parser: (_) {});
      AppLogger.info('Notebook tag deleted successfully', tag: 'NotebookRemoteDataSource');
      AppLogger.methodExit('deleteNotebookTag', tag: 'NotebookRemoteDataSource', result: 'success');
    } catch (e) {
      AppLogger.error(
        'Failed to delete notebook tag',
        tag: 'NotebookRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}

