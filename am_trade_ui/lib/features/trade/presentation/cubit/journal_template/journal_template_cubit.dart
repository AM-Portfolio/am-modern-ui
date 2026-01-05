import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_common/core/utils/logger.dart';
import '../../../internal/domain/entities/journal_template.dart';
import '../../../internal/domain/enums/journal_template_category.dart';
import '../../../internal/domain/usecases/create_template_usecase.dart';
import '../../../internal/domain/usecases/delete_template_usecase.dart';
import '../../../internal/domain/usecases/get_templates_usecase.dart';
import '../../../internal/domain/usecases/toggle_favorite_template_usecase.dart';
import '../../../internal/domain/usecases/use_template_usecase.dart';
import 'journal_template_state.dart';

/// Cubit for managing journal template state
class JournalTemplateCubit extends Cubit<JournalTemplateState> {
  JournalTemplateCubit({
    required GetTemplatesUseCase getTemplatesUseCase,
    required CreateTemplateUseCase createTemplateUseCase,
    required UseTemplateUseCase useTemplateUseCase,
    required ToggleFavoriteTemplateUseCase toggleFavoriteTemplateUseCase,
    required DeleteTemplateUseCase deleteTemplateUseCase,
  })  : _getTemplatesUseCase = getTemplatesUseCase,
        _createTemplateUseCase = createTemplateUseCase,
        _useTemplateUseCase = useTemplateUseCase,
        _toggleFavoriteTemplateUseCase = toggleFavoriteTemplateUseCase,
        _deleteTemplateUseCase = deleteTemplateUseCase,
        super(const JournalTemplateInitial());

  final GetTemplatesUseCase _getTemplatesUseCase;
  final CreateTemplateUseCase _createTemplateUseCase;
  final UseTemplateUseCase _useTemplateUseCase;
  final ToggleFavoriteTemplateUseCase _toggleFavoriteTemplateUseCase;
  final DeleteTemplateUseCase _deleteTemplateUseCase;

  /// Load all templates for a user
  Future<void> loadTemplates({
    required String userId,
    JournalTemplateCategory? category,
    String? search,
  }) async {
    AppLogger.methodEntry(
      'loadTemplates',
      tag: 'JournalTemplateCubit',
      params: {'userId': userId, 'category': category?.value, 'search': search},
    );

    emit(const JournalTemplateLoading());

    try {
      final templates = await _getTemplatesUseCase(
        userId: userId,
        category: category,
        search: search,
      );

      AppLogger.info(
        'Templates loaded successfully: ${templates.length} templates',
        tag: 'JournalTemplateCubit',
      );

      emit(JournalTemplateLoaded(templates: templates));
    } catch (e) {
      AppLogger.error(
        'Failed to load templates',
        tag: 'JournalTemplateCubit',
        error: e,
        stackTrace: StackTrace.current,
      );

      emit(JournalTemplateError(e.toString()));
    }
  }

  /// Select a template
  void selectTemplate(JournalTemplate template) {
    AppLogger.info(
      'Template selected: ${template.name}',
      tag: 'JournalTemplateCubit',
    );

    final currentState = state;
    if (currentState is JournalTemplateLoaded) {
      emit(currentState.copyWith(selectedTemplate: template));
    }
  }

  /// Clear selected template
  void clearSelection() {
    AppLogger.info('Template selection cleared', tag: 'JournalTemplateCubit');

    final currentState = state;
    if (currentState is JournalTemplateLoaded) {
      emit(currentState.copyWith(selectedTemplate: null));
    }
  }

  /// Create a new template
  Future<void> createTemplate({
    required String name,
    required JournalTemplateCategory category,
    required String createdBy,
    String? description,
    List<Map<String, dynamic>>? fields,
    List<String>? tags,
    String? thumbnailUrl,
  }) async {
    AppLogger.methodEntry(
      'createTemplate',
      tag: 'JournalTemplateCubit',
      params: {'name': name, 'category': category.value},
    );

    emit(const JournalTemplateLoading());

    try {
      final template = await _createTemplateUseCase(
        name: name,
        category: category,
        createdBy: createdBy,
        description: description,
        fields: fields,
        tags: tags,
        thumbnailUrl: thumbnailUrl,
      );

      AppLogger.info(
        'Template created successfully: ${template.name}',
        tag: 'JournalTemplateCubit',
      );

      emit(JournalTemplateCreated(template));
    } catch (e) {
      AppLogger.error(
        'Failed to create template',
        tag: 'JournalTemplateCubit',
        error: e,
        stackTrace: StackTrace.current,
      );

      emit(JournalTemplateError(e.toString()));
    }
  }

  /// Toggle favorite status of a template
  Future<void> toggleFavorite({
    required String templateId,
    required String userId,
  }) async {
    AppLogger.methodEntry(
      'toggleFavorite',
      tag: 'JournalTemplateCubit',
      params: {'templateId': templateId},
    );

    try {
      final updatedTemplate = await _toggleFavoriteTemplateUseCase(
        templateId: templateId,
        userId: userId,
      );

      AppLogger.info(
        'Template favorite toggled: ${updatedTemplate.name}, isFavorite: ${updatedTemplate.isFavorite}',
        tag: 'JournalTemplateCubit',
      );

      // Update the template in the current state
      final currentState = state;
      if (currentState is JournalTemplateLoaded) {
        final updatedTemplates = currentState.templates.map((t) {
          return t.id == updatedTemplate.id ? updatedTemplate : t;
        }).toList();

        emit(currentState.copyWith(templates: updatedTemplates));
      }
    } catch (e) {
      AppLogger.error(
        'Failed to toggle favorite',
        tag: 'JournalTemplateCubit',
        error: e,
        stackTrace: StackTrace.current,
      );

      emit(JournalTemplateError(e.toString()));
    }
  }

  /// Delete a template
  Future<void> deleteTemplate({
    required String templateId,
    required String userId,
  }) async {
    AppLogger.methodEntry(
      'deleteTemplate',
      tag: 'JournalTemplateCubit',
      params: {'templateId': templateId},
    );

    emit(const JournalTemplateLoading());

    try {
      await _deleteTemplateUseCase(
        templateId: templateId,
        userId: userId,
      );

      AppLogger.info(
        'Template deleted successfully',
        tag: 'JournalTemplateCubit',
      );

      emit(const JournalTemplateDeleted());
    } catch (e) {
      AppLogger.error(
        'Failed to delete template',
        tag: 'JournalTemplateCubit',
        error: e,
        stackTrace: StackTrace.current,
      );

      emit(JournalTemplateError(e.toString()));
    }
  }

  /// Use a template to create a journal entry
  Future<void> useTemplate({
    required String userId,
    required String templateId,
    required Map<String, dynamic> fieldValues,
    String? tradeId,
    String? customTitle,
  }) async {
    AppLogger.methodEntry(
      'useTemplate',
      tag: 'JournalTemplateCubit',
      params: {'templateId': templateId},
    );

    emit(const JournalTemplateLoading());

    try {
      final entry = await _useTemplateUseCase(
        userId: userId,
        templateId: templateId,
        fieldValues: fieldValues,
        tradeId: tradeId,
        customTitle: customTitle,
      );

      AppLogger.info(
        'Template used successfully, journal entry created: ${entry.id}',
        tag: 'JournalTemplateCubit',
      );

      emit(JournalTemplateUsed(entry.id));
    } catch (e) {
      AppLogger.error(
        'Failed to use template',
        tag: 'JournalTemplateCubit',
        error: e,
        stackTrace: StackTrace.current,
      );

      emit(JournalTemplateError(e.toString()));
    }
  }
}
