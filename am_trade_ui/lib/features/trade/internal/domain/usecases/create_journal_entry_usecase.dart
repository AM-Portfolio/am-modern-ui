import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class CreateJournalEntryUseCase {
  CreateJournalEntryUseCase(this._repository);

  final JournalRepository _repository;

  Future<JournalEntry> call({
    required String userId,
    required String title,
    required String content,
    required DateTime entryDate,
    String? tradeId,
    List<BehaviorPatternSummary>? behaviorPatternSummaries,
    Map<String, dynamic>? customFields,
    List<String>? imageUrls,
    List<JournalAttachment>? attachments,
    List<String>? relatedTradeIds,
    List<String>? tagIds,
  }) => _repository.createJournalEntry(
    userId: userId,
    title: title,
    content: content,
    entryDate: entryDate,
    tradeId: tradeId,
    behaviorPatternSummaries: behaviorPatternSummaries,
    customFields: customFields,
    imageUrls: imageUrls,
    attachments: attachments,
    relatedTradeIds: relatedTradeIds,
    tagIds: tagIds,
  );
}
