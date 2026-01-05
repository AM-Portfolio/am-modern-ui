import 'package:am_common/core/utils/logger.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/journal_template.dart';
import '../../domain/enums/journal_template_category.dart';
import '../../domain/repositories/journal_template_repository.dart';
import '../datasources/journal_template_remote_datasource.dart';
import '../dtos/journal_template_dto.dart';
import '../mappers/journal_entry_mapper.dart';
import '../mappers/journal_template_mapper.dart';

/// Repository implementation for journal template operations
class JournalTemplateRepositoryImpl implements JournalTemplateRepository {
  JournalTemplateRepositoryImpl({
    required JournalTemplateRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final JournalTemplateRemoteDataSource _remoteDataSource;

  @override
  Future<JournalTemplate> createTemplate({
    required String name,
    required JournalTemplateCategory category,
    required String createdBy,
    String? description,
    List<Map<String, dynamic>>? fields,
    bool isSystemTemplate = false,
    bool isRecommended = false,
    List<String>? tags,
    String? thumbnailUrl,
  }) async {
    AppLogger.methodEntry(
      'createTemplate',
      tag: 'JournalTemplateRepository',
      params: {'name': name, 'category': category.value},
    );

    try {
      final request = JournalTemplateRequestDto(
        name: name,
        category: category.value,
        createdBy: createdBy,
        description: description,
        fields: fields
            ?.map((f) => TemplateFieldRequestDto.fromJson(f))
            .toList(),
        isSystemTemplate: isSystemTemplate,
        isRecommended: isRecommended,
        tags: tags,
        thumbnailUrl: thumbnailUrl,
      );

      final dto = await _remoteDataSource.createTemplate(request);
      final template = JournalTemplateMapper.fromResponseDto(dto);

      AppLogger.info(
        'Template created successfully',
        tag: 'JournalTemplateRepository',
      );
      AppLogger.methodExit(
        'createTemplate',
        tag: 'JournalTemplateRepository',
        result: 'success',
      );

      return template;
    } catch (e) {
      AppLogger.error(
        'Failed to create template',
        tag: 'JournalTemplateRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<JournalTemplate>> getTemplates({
    required String userId,
    JournalTemplateCategory? category,
    String? search,
  }) async {
    AppLogger.methodEntry(
      'getTemplates',
      tag: 'JournalTemplateRepository',
      params: {'userId': userId, 'category': category?.value, 'search': search},
    );

    try {
      final dtos = await _remoteDataSource.getTemplates(
        userId: userId,
        category: category?.value,
        search: search,
      );
      final templates = dtos.map(JournalTemplateMapper.fromResponseDto).toList();

      AppLogger.info(
        'Templates fetched successfully: ${templates.length} templates',
        tag: 'JournalTemplateRepository',
      );
      AppLogger.methodExit(
        'getTemplates',
        tag: 'JournalTemplateRepository',
        result: 'success',
      );

      return templates;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch templates',
        tag: 'JournalTemplateRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<JournalTemplate> getTemplate({
    required String templateId,
    required String userId,
  }) async {
    AppLogger.methodEntry(
      'getTemplate',
      tag: 'JournalTemplateRepository',
      params: {'templateId': templateId},
    );

    try {
      final dto = await _remoteDataSource.getTemplate(templateId, userId);
      final template = JournalTemplateMapper.fromResponseDto(dto);

      AppLogger.info(
        'Template fetched successfully',
        tag: 'JournalTemplateRepository',
      );
      AppLogger.methodExit(
        'getTemplate',
        tag: 'JournalTemplateRepository',
        result: 'success',
      );

      return template;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch template',
        tag: 'JournalTemplateRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<JournalTemplate> updateTemplate({
    required String templateId,
    required String name,
    required JournalTemplateCategory category,
    required String createdBy,
    String? description,
    List<Map<String, dynamic>>? fields,
    bool isSystemTemplate = false,
    bool isRecommended = false,
    List<String>? tags,
    String? thumbnailUrl,
  }) async {
    AppLogger.methodEntry(
      'updateTemplate',
      tag: 'JournalTemplateRepository',
      params: {'templateId': templateId},
    );

    try {
      final request = JournalTemplateRequestDto(
        name: name,
        category: category.value,
        createdBy: createdBy,
        description: description,
        fields: fields
            ?.map((f) => TemplateFieldRequestDto.fromJson(f))
            .toList(),
        isSystemTemplate: isSystemTemplate,
        isRecommended: isRecommended,
        tags: tags,
        thumbnailUrl: thumbnailUrl,
      );

      final dto = await _remoteDataSource.updateTemplate(templateId, request);
      final template = JournalTemplateMapper.fromResponseDto(dto);

      AppLogger.info(
        'Template updated successfully',
        tag: 'JournalTemplateRepository',
      );
      AppLogger.methodExit(
        'updateTemplate',
        tag: 'JournalTemplateRepository',
        result: 'success',
      );

      return template;
    } catch (e) {
      AppLogger.error(
        'Failed to update template',
        tag: 'JournalTemplateRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteTemplate({
    required String templateId,
    required String userId,
  }) async {
    AppLogger.methodEntry(
      'deleteTemplate',
      tag: 'JournalTemplateRepository',
      params: {'templateId': templateId},
    );

    try {
      await _remoteDataSource.deleteTemplate(templateId, userId);

      AppLogger.info(
        'Template deleted successfully',
        tag: 'JournalTemplateRepository',
      );
      AppLogger.methodExit(
        'deleteTemplate',
        tag: 'JournalTemplateRepository',
        result: 'success',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to delete template',
        tag: 'JournalTemplateRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<JournalTemplate>> getFavoriteTemplates(String userId) async {
    AppLogger.methodEntry(
      'getFavoriteTemplates',
      tag: 'JournalTemplateRepository',
      params: {'userId': userId},
    );

    try {
      final dtos = await _remoteDataSource.getFavoriteTemplates(userId);
      final templates = dtos.map(JournalTemplateMapper.fromResponseDto).toList();

      AppLogger.info(
        'Favorite templates fetched successfully: ${templates.length} templates',
        tag: 'JournalTemplateRepository',
      );
      AppLogger.methodExit(
        'getFavoriteTemplates',
        tag: 'JournalTemplateRepository',
        result: 'success',
      );

      return templates;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch favorite templates',
        tag: 'JournalTemplateRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<JournalTemplate>> getRecommendedTemplates(String userId) async {
    AppLogger.methodEntry(
      'getRecommendedTemplates',
      tag: 'JournalTemplateRepository',
      params: {'userId': userId},
    );

    try {
      final dtos = await _remoteDataSource.getRecommendedTemplates(userId);
      final templates = dtos.map(JournalTemplateMapper.fromResponseDto).toList();

      AppLogger.info(
        'Recommended templates fetched successfully: ${templates.length} templates',
        tag: 'JournalTemplateRepository',
      );
      AppLogger.methodExit(
        'getRecommendedTemplates',
        tag: 'JournalTemplateRepository',
        result: 'success',
      );

      return templates;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch recommended templates',
        tag: 'JournalTemplateRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<JournalTemplate>> getMyTemplates(String userId) async {
    AppLogger.methodEntry(
      'getMyTemplates',
      tag: 'JournalTemplateRepository',
      params: {'userId': userId},
    );

    try {
      final dtos = await _remoteDataSource.getMyTemplates(userId);
      final templates = dtos.map(JournalTemplateMapper.fromResponseDto).toList();

      AppLogger.info(
        'My templates fetched successfully: ${templates.length} templates',
        tag: 'JournalTemplateRepository',
      );
      AppLogger.methodExit(
        'getMyTemplates',
        tag: 'JournalTemplateRepository',
        result: 'success',
      );

      return templates;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch my templates',
        tag: 'JournalTemplateRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<JournalTemplate> toggleFavorite({
    required String templateId,
    required String userId,
  }) async {
    AppLogger.methodEntry(
      'toggleFavorite',
      tag: 'JournalTemplateRepository',
      params: {'templateId': templateId},
    );

    try {
      final dto = await _remoteDataSource.toggleFavorite(templateId, userId);
      final template = JournalTemplateMapper.fromResponseDto(dto);

      AppLogger.info(
        'Template favorite toggled successfully',
        tag: 'JournalTemplateRepository',
      );
      AppLogger.methodExit(
        'toggleFavorite',
        tag: 'JournalTemplateRepository',
        result: 'success',
      );

      return template;
    } catch (e) {
      AppLogger.error(
        'Failed to toggle template favorite',
        tag: 'JournalTemplateRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<JournalEntry> useTemplate({
    required String userId,
    required String templateId,
    required Map<String, dynamic> fieldValues,
    String? tradeId,
    String? customTitle,
  }) async {
    AppLogger.methodEntry(
      'useTemplate',
      tag: 'JournalTemplateRepository',
      params: {'templateId': templateId, 'userId': userId},
    );

    try {
      final request = UseTemplateRequestDto(
        userId: userId,
        templateId: templateId,
        fieldValues: fieldValues,
        tradeId: tradeId,
        customTitle: customTitle,
      );

      final dto = await _remoteDataSource.useTemplate(templateId, request);
      final entry = JournalEntryMapper.fromResponseDto(dto);

      AppLogger.info(
        'Template used successfully, journal entry created',
        tag: 'JournalTemplateRepository',
      );
      AppLogger.methodExit(
        'useTemplate',
        tag: 'JournalTemplateRepository',
        result: 'success',
      );

      return entry;
    } catch (e) {
      AppLogger.error(
        'Failed to use template',
        tag: 'JournalTemplateRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}
