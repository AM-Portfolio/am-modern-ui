import '../entities/journal_template.dart';
import '../repositories/journal_template_repository.dart';

/// Use case for deleting a journal template
class DeleteTemplateUseCase {
  const DeleteTemplateUseCase(this._repository);

  final JournalTemplateRepository _repository;

  Future<void> call({
    required String templateId,
    required String userId,
  }) {
    return _repository.deleteTemplate(
      templateId: templateId,
      userId: userId,
    );
  }
}
