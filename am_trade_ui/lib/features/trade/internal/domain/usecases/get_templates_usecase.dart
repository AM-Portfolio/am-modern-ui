import '../entities/journal_template.dart';
import '../enums/journal_template_category.dart';
import '../repositories/journal_template_repository.dart';

/// Use case for getting journal templates with optional filters
class GetTemplatesUseCase {
  const GetTemplatesUseCase(this._repository);

  final JournalTemplateRepository _repository;

  Future<List<JournalTemplate>> call({
    JournalTemplateCategory? category,
    String? search,
  }) {
    return _repository.getTemplates(
      category: category,
      search: search,
    );
  }
}
