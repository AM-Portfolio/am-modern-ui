import '../entities/journal_entry.dart';
import '../../data/dtos/journal_entry_dto.dart';

/// Repository interface for journal operations
abstract class JournalRepository {
  Future<JournalEntry> createJournalEntry({
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
  });

  Future<JournalEntry> getJournalEntry(String entryId);

  Future<JournalEntry> updateJournalEntry({
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
  });

  Future<void> deleteJournalEntry(String entryId);

  Future<List<JournalEntry>> getJournalEntriesByUser({
    Map<String, dynamic>? query,
  });

  Future<List<JournalEntry>> getJournalEntriesByTrade(String tradeId);

  Future<List<JournalEntry>> getJournalEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  Future<JournalSummaryDto> getSummary(DateTime startDate, DateTime endDate);

  Future<List<MistakeAnalysisDto>> getMistakesSummary(
    DateTime startDate,
    DateTime endDate,
  );

  Future<List<LessonLearnedDto>> getLessons(
    DateTime startDate,
    DateTime endDate, {
    int limit = 10,
  });

  Future<JournalAdherenceDto> getAdherence(
    DateTime startDate,
    DateTime endDate,
  );

  Future<JournalReportCardDto> getReportCard(
    DateTime startDate,
    DateTime endDate,
  );

  Future<JournalEntry> updatePrePlan(String entryId, PreTradePlan plan);

  Future<JournalEntry> updateExecution(String entryId, TradeExecution execution);

  Future<JournalEntry> updatePostReview(
    String entryId,
    PostTradeReview review, {
    bool markCompleted = false,
  });

  Future<JournalEntry> linkTrade(String entryId, String tradeId);

  Future<JournalEntry> addAttachment(
    String entryId,
    JournalAttachment attachment,
  );

  Future<JournalEntry> removeAttachment(String entryId, String fileUrl);

  Future<int> bulkArchive(List<String> entryIds);

  Future<int> bulkDelete(List<String> entryIds);

  Future<String> exportCsv(DateTime startDate, DateTime endDate);

  Future<List<JournalEntry>> createFromTrades(
    List<String> tradeIds, {
    String journalStatus = 'COMPLETED',
  });
}
