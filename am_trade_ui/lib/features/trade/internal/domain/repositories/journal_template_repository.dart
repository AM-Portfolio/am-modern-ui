import '../entities/journal_entry.dart';
import '../entities/journal_template.dart';
import '../enums/journal_template_category.dart';

/// Repository interface for journal template operations
abstract class JournalTemplateRepository {
  /// Create a new journal template
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
  });

  /// Get all templates with optional filters
  Future<List<JournalTemplate>> getTemplates({
    JournalTemplateCategory? category,
    String? search,
  });

  /// Get a specific template by ID
  Future<JournalTemplate> getTemplate({
    required String templateId,
    });

  /// Update a template
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
  });

  /// Delete a template
  Future<void> deleteTemplate({
    required String templateId,
    });

  /// Get favorite templates
  Future<List<JournalTemplate>> getFavoriteTemplates();

  /// Get recommended templates
  Future<List<JournalTemplate>> getRecommendedTemplates();

  /// Get user's custom templates
  Future<List<JournalTemplate>> getMyTemplates();

  /// Toggle favorite status of a template
  Future<JournalTemplate> toggleFavorite({
    required String templateId,
    });

  /// Use a template to create a journal entry
  Future<JournalEntry> useTemplate({
    required String templateId,
    required Map<String, dynamic> fieldValues,
    String? tradeId,
    String? customTitle,
  });
}
