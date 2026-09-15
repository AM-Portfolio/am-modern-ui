import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class UpdateJournalEntryUseCase {
  UpdateJournalEntryUseCase(this._repository);

  final JournalRepository _repository;

  Future<JournalEntry> call({
    required String entryId,
    required String title,
    required String content,
    required DateTime entryDate,
    String? tradeId,
    String? entryType,
    String? journalStatus,
    String? symbol,
    String? setup,
    String? tradeDirection,
    String? folderId,
    String? playbookId,
    PreTradePlan? preTradePlan,
    TradeExecution? tradeExecution,
    PostTradeReview? postTradeReview,
    double? planAdherenceScore,
    double? checklistCompletionPct,
    List<BehaviorPatternSummary>? behaviorPatternSummaries,
    Map<String, dynamic>? customFields,
    List<String>? imageUrls,
    List<JournalAttachment>? attachments,
    List<String>? relatedTradeIds,
    List<String>? tagIds,
    List<String>? chartUrls,
    List<String>? documentUrls,
    List<String>? videoUrls,
    List<String>? externalUrls,
  }) =>
      _repository.updateJournalEntry(
        entryId: entryId,
        title: title,
        content: content,
        entryDate: entryDate,
        tradeId: tradeId,
        entryType: entryType,
        journalStatus: journalStatus,
        symbol: symbol,
        setup: setup,
        tradeDirection: tradeDirection,
        folderId: folderId,
        playbookId: playbookId,
        preTradePlan: preTradePlan,
        tradeExecution: tradeExecution,
        postTradeReview: postTradeReview,
        planAdherenceScore: planAdherenceScore,
        checklistCompletionPct: checklistCompletionPct,
        behaviorPatternSummaries: behaviorPatternSummaries,
        customFields: customFields,
        imageUrls: imageUrls,
        attachments: attachments,
        relatedTradeIds: relatedTradeIds,
        tagIds: tagIds,
        chartUrls: chartUrls,
        documentUrls: documentUrls,
        videoUrls: videoUrls,
        externalUrls: externalUrls,
      );
}
