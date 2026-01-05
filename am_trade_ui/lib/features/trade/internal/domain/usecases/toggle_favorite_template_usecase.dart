import '../entities/journal_template.dart';
import '../repositories/journal_template_repository.dart';

/// Use case for toggling favorite status of a template
class ToggleFavoriteTemplateUseCase {
  const ToggleFavoriteTemplateUseCase(this._repository);

  final JournalTemplateRepository _repository;

  Future<JournalTemplate> call({
    required String templateId,
    required String userId,
  }) {
    return _repository.toggleFavorite(
      templateId: templateId,
      userId: userId,
    );
  }
}
