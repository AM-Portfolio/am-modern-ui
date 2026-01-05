import '../entities/journal_entry.dart';
import '../repositories/journal_template_repository.dart';

/// Use case for using a template to create a journal entry
class UseTemplateUseCase {
  const UseTemplateUseCase(this._repository);

  final JournalTemplateRepository _repository;

  Future<JournalEntry> call({
    required String userId,
    required String templateId,
    required Map<String, dynamic> fieldValues,
    String? tradeId,
    String? customTitle,
  }) {
    return _repository.useTemplate(
      userId: userId,
      templateId: templateId,
      fieldValues: fieldValues,
      tradeId: tradeId,
      customTitle: customTitle,
    );
  }
}
