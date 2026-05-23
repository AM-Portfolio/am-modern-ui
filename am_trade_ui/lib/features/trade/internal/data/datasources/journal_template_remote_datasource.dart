import 'package:am_library/am_library.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/am_common.dart';
import '../dtos/journal_entry_dto.dart';
import '../dtos/journal_template_dto.dart';

/// Abstract interface for journal template remote data source
abstract class JournalTemplateRemoteDataSource {
  Future<JournalTemplateResponseDto> createTemplate(JournalTemplateRequestDto request);
  
  Future<List<JournalTemplateResponseDto>> getTemplates({
    required String userId,
    String? category,
    String? search,
  });
  
  Future<JournalTemplateResponseDto> getTemplate(String templateId, String userId);
  
  Future<JournalTemplateResponseDto> updateTemplate(
    String templateId,
    JournalTemplateRequestDto request,
  );
  
  Future<void> deleteTemplate(String templateId, String userId);
  
  Future<List<JournalTemplateResponseDto>> getFavoriteTemplates(String userId);
  
  Future<List<JournalTemplateResponseDto>> getRecommendedTemplates(String userId);
  
  Future<List<JournalTemplateResponseDto>> getMyTemplates(String userId);
  
  Future<JournalTemplateResponseDto> toggleFavorite(String templateId, String userId);
  
  Future<TradeJournalEntryResponseDto> useTemplate(
    String templateId,
    UseTemplateRequestDto request,
  );
}

/// Implementation of journal template remote data source
/// Implementation of journal template remote data source
class JournalTemplateRemoteDataSourceImpl implements JournalTemplateRemoteDataSource {
  JournalTemplateRemoteDataSourceImpl({
    required ApiClient apiClient,
    required TradeApiConfig tradeConfig,
  })  : _apiClient = apiClient,
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
  Future<JournalTemplateResponseDto> createTemplate(
    JournalTemplateRequestDto request,
  ) async {
    AppLogger.methodEntry(
      'createTemplate',
      tag: 'JournalTemplateRemoteDataSource',
      params: {'name': request.name},
    );

    try {
      final fullUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal-templates');

      final response = await _apiClient.post<JournalTemplateResponseDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => JournalTemplateResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info(
        'Template created successfully',
        tag: 'JournalTemplateRemoteDataSource',
      );
      AppLogger.methodExit(
        'createTemplate',
        tag: 'JournalTemplateRemoteDataSource',
        result: 'success',
      );

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to create template',
        tag: 'JournalTemplateRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<JournalTemplateResponseDto>> getTemplates({
    required String userId,
    String? category,
    String? search,
  }) async {
    AppLogger.methodEntry(
      'getTemplates',
      tag: 'JournalTemplateRemoteDataSource',
      params: {'userId': userId, 'category': category, 'search': search},
    );

    try {
      final queryParams = <String, dynamic>{
        'userId': userId,
        if (category != null) 'category': category,
        if (search != null) 'search': search,
      };

      final fullUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal-templates');

      final response = await _apiClient.get<List<JournalTemplateResponseDto>>(
        fullUri,
        queryParams: queryParams,
        parser: (data) {
          if (data is List) {
            return data.map((item) => JournalTemplateResponseDto.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      AppLogger.info(
        'Templates fetched successfully',
        tag: 'JournalTemplateRemoteDataSource',
      );
      AppLogger.methodExit(
        'getTemplates',
        tag: 'JournalTemplateRemoteDataSource',
        result: 'success',
      );

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch templates',
        tag: 'JournalTemplateRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<JournalTemplateResponseDto> getTemplate(
    String templateId,
    String userId,
  ) async {
    AppLogger.methodEntry(
      'getTemplate',
      tag: 'JournalTemplateRemoteDataSource',
      params: {'templateId': templateId},
    );

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal-templates');
      final fullUri = '$baseUri/$templateId';

      final response = await _apiClient.get<JournalTemplateResponseDto>(
        fullUri,
        queryParams: {'userId': userId},
        parser: (data) => JournalTemplateResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info(
        'Template fetched successfully',
        tag: 'JournalTemplateRemoteDataSource',
      );
      AppLogger.methodExit(
        'getTemplate',
        tag: 'JournalTemplateRemoteDataSource',
        result: 'success',
      );

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch template',
        tag: 'JournalTemplateRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<JournalTemplateResponseDto> updateTemplate(
    String templateId,
    JournalTemplateRequestDto request,
  ) async {
    AppLogger.methodEntry(
      'updateTemplate',
      tag: 'JournalTemplateRemoteDataSource',
      params: {'templateId': templateId},
    );

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal-templates');
      final fullUri = '$baseUri/$templateId';

      final response = await _apiClient.put<JournalTemplateResponseDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => JournalTemplateResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info(
        'Template updated successfully',
        tag: 'JournalTemplateRemoteDataSource',
      );
      AppLogger.methodExit(
        'updateTemplate',
        tag: 'JournalTemplateRemoteDataSource',
        result: 'success',
      );

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to update template',
        tag: 'JournalTemplateRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteTemplate(String templateId, String userId) async {
    AppLogger.methodEntry(
      'deleteTemplate',
      tag: 'JournalTemplateRemoteDataSource',
      params: {'templateId': templateId},
    );

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal-templates');
      final fullUri = '$baseUri/$templateId';

      await _apiClient.delete<void>(
        fullUri,
        queryParams: {'userId': userId},
        parser: (_) {},
      );

      AppLogger.info(
        'Template deleted successfully',
        tag: 'JournalTemplateRemoteDataSource',
      );
      AppLogger.methodExit(
        'deleteTemplate',
        tag: 'JournalTemplateRemoteDataSource',
        result: 'success',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to delete template',
        tag: 'JournalTemplateRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<JournalTemplateResponseDto>> getFavoriteTemplates(
    String userId,
  ) async {
    AppLogger.methodEntry(
      'getFavoriteTemplates',
      tag: 'JournalTemplateRemoteDataSource',
      params: {'userId': userId},
    );

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal-templates');
      final fullUri = '$baseUri/favorites';

      final response = await _apiClient.get<List<JournalTemplateResponseDto>>(
        fullUri,
        queryParams: {'userId': userId},
        parser: (data) {
          if (data is List) {
            return data.map((item) => JournalTemplateResponseDto.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      AppLogger.info(
        'Favorite templates fetched successfully',
        tag: 'JournalTemplateRemoteDataSource',
      );
      AppLogger.methodExit(
        'getFavoriteTemplates',
        tag: 'JournalTemplateRemoteDataSource',
        result: 'success',
      );

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch favorite templates',
        tag: 'JournalTemplateRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<JournalTemplateResponseDto>> getRecommendedTemplates(
    String userId,
  ) async {
    AppLogger.methodEntry(
      'getRecommendedTemplates',
      tag: 'JournalTemplateRemoteDataSource',
      params: {'userId': userId},
    );

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal-templates');
      final fullUri = '$baseUri/recommended';

      final response = await _apiClient.get<List<JournalTemplateResponseDto>>(
        fullUri,
        queryParams: {'userId': userId},
        parser: (data) {
          if (data is List) {
            return data.map((item) => JournalTemplateResponseDto.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      AppLogger.info(
        'Recommended templates fetched successfully',
        tag: 'JournalTemplateRemoteDataSource',
      );
      AppLogger.methodExit(
        'getRecommendedTemplates',
        tag: 'JournalTemplateRemoteDataSource',
        result: 'success',
      );

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch recommended templates',
        tag: 'JournalTemplateRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<JournalTemplateResponseDto>> getMyTemplates(String userId) async {
    AppLogger.methodEntry(
      'getMyTemplates',
      tag: 'JournalTemplateRemoteDataSource',
      params: {'userId': userId},
    );

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal-templates');
      final fullUri = '$baseUri/my-templates';

      final response = await _apiClient.get<List<JournalTemplateResponseDto>>(
        fullUri,
        queryParams: {'userId': userId},
        parser: (data) {
          if (data is List) {
            return data.map((item) => JournalTemplateResponseDto.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      AppLogger.info(
        'My templates fetched successfully',
        tag: 'JournalTemplateRemoteDataSource',
      );
      AppLogger.methodExit(
        'getMyTemplates',
        tag: 'JournalTemplateRemoteDataSource',
        result: 'success',
      );

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch my templates',
        tag: 'JournalTemplateRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<JournalTemplateResponseDto> toggleFavorite(
    String templateId,
    String userId,
  ) async {
    AppLogger.methodEntry(
      'toggleFavorite',
      tag: 'JournalTemplateRemoteDataSource',
      params: {'templateId': templateId},
    );

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal-templates');
      final fullUri = '$baseUri/$templateId/favorite';

      final response = await _apiClient.post<JournalTemplateResponseDto>(
        fullUri,
        queryParams: {'userId': userId},
        parser: (data) => JournalTemplateResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info(
        'Template favorite toggled successfully',
        tag: 'JournalTemplateRemoteDataSource',
      );
      AppLogger.methodExit(
        'toggleFavorite',
        tag: 'JournalTemplateRemoteDataSource',
        result: 'success',
      );

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to toggle template favorite',
        tag: 'JournalTemplateRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<TradeJournalEntryResponseDto> useTemplate(
    String templateId,
    UseTemplateRequestDto request,
  ) async {
    AppLogger.methodEntry(
      'useTemplate',
      tag: 'JournalTemplateRemoteDataSource',
      params: {'templateId': templateId},
    );

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal-templates');
      final fullUri = '$baseUri/$templateId/use';

      final response = await _apiClient.post<TradeJournalEntryResponseDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => TradeJournalEntryResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info(
        'Template used successfully',
        tag: 'JournalTemplateRemoteDataSource',
      );
      AppLogger.methodExit(
        'useTemplate',
        tag: 'JournalTemplateRemoteDataSource',
        result: 'success',
      );

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to use template',
        tag: 'JournalTemplateRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}

