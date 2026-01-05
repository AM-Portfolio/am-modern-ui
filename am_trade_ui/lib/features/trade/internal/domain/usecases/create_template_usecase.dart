import '../entities/journal_template.dart';
import '../enums/journal_template_category.dart';
import '../repositories/journal_template_repository.dart';

/// Use case for creating a new journal template
class CreateTemplateUseCase {
  const CreateTemplateUseCase(this._repository);

  final JournalTemplateRepository _repository;

  Future<JournalTemplate> call({
    required String name,
    required JournalTemplateCategory category,
    required String createdBy,
    String? description,
    List<Map<String, dynamic>>? fields,
    bool isSystemTemplate = false,
    bool isRecommended = false,
    List<String>? tags,
    String? thumbnailUrl,
  }) {
    return _repository.createTemplate(
      name: name,
      category: category,
      createdBy: createdBy,
      description: description,
      fields: fields,
      isSystemTemplate: isSystemTemplate,
      isRecommended: isRecommended,
      tags: tags,
      thumbnailUrl: thumbnailUrl,
    );
  }
}
