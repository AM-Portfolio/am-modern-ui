import 'package:am_common/am_common.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_remote_data_source.dart';
import '../dtos/journal_entry_dto.dart';
import '../mappers/journal_entry_mapper.dart';

/// Repository implementation for journal operations
class JournalRepositoryImpl implements JournalRepository {
  JournalRepositoryImpl({required JournalRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final JournalRemoteDataSource _remoteDataSource;

  String _dateOnly(DateTime d) => d.toIso8601String().split('T').first;

  TradeJournalEntryRequestDto _toRequest({
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
      TradeJournalEntryRequestDto(
        title: title,
        content: content,
        entryDate: entryDate.toIso8601String(),
        tradeId: tradeId,
        entryType: entryType,
        journalStatus: journalStatus,
        symbol: symbol,
        setup: setup,
        tradeDirection: tradeDirection,
        folderId: folderId,
        playbookId: playbookId,
        preTradePlan: preTradePlan != null
            ? JournalEntryMapper.toPreTradePlanDto(preTradePlan)
            : null,
        tradeExecution: tradeExecution != null
            ? JournalEntryMapper.toTradeExecutionDto(tradeExecution)
            : null,
        postTradeReview: postTradeReview != null
            ? JournalEntryMapper.toPostTradeReviewDto(postTradeReview)
            : null,
        planAdherenceScore: planAdherenceScore,
        checklistCompletionPct: checklistCompletionPct,
        behaviorPatternSummaries:
            behaviorPatternSummaries?.map(JournalEntryMapper.toBehaviorPatternDto).toList(),
        customFields: customFields,
        imageUrls: imageUrls,
        attachments:
            attachments?.map(JournalEntryMapper.toAttachmentDto).toList(),
        relatedTradeIds: relatedTradeIds,
        tagIds: tagIds,
        chartUrls: chartUrls,
        documentUrls: documentUrls,
        videoUrls: videoUrls,
        externalUrls: externalUrls,
      );

  @override
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
  }) async {
    final request = _toRequest(
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
    final dto = await _remoteDataSource.createJournalEntry(request);
    return JournalEntryMapper.fromResponseDto(dto);
  }

  @override
  Future<JournalEntry> getJournalEntry(String entryId) async {
    final dto = await _remoteDataSource.getJournalEntry(entryId);
    return JournalEntryMapper.fromResponseDto(dto);
  }

  @override
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
  }) async {
    final request = _toRequest(
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
    final dto = await _remoteDataSource.updateJournalEntry(entryId, request);
    return JournalEntryMapper.fromResponseDto(dto);
  }

  @override
  Future<void> deleteJournalEntry(String entryId) =>
      _remoteDataSource.deleteJournalEntry(entryId);

  @override
  Future<List<JournalEntry>> getJournalEntriesByUser({
    Map<String, dynamic>? query,
  }) async {
    final dtos =
        await _remoteDataSource.getJournalEntriesByUser(query: query);
    return dtos.map(JournalEntryMapper.fromResponseDto).toList();
  }

  @override
  Future<List<JournalEntry>> getJournalEntriesByTrade(String tradeId) async {
    final dtos = await _remoteDataSource.getJournalEntriesByTrade(tradeId);
    return dtos.map(JournalEntryMapper.fromResponseDto).toList();
  }

  @override
  Future<List<JournalEntry>> getJournalEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final dtos = await _remoteDataSource.getJournalEntriesByDateRange(
      _dateOnly(startDate),
      _dateOnly(endDate),
    );
    return dtos.map(JournalEntryMapper.fromResponseDto).toList();
  }

  @override
  Future<JournalSummaryDto> getSummary(
    DateTime startDate,
    DateTime endDate,
  ) =>
      _remoteDataSource.getSummary(_dateOnly(startDate), _dateOnly(endDate));

  @override
  Future<List<MistakeAnalysisDto>> getMistakesSummary(
    DateTime startDate,
    DateTime endDate,
  ) =>
      _remoteDataSource.getMistakesSummary(
        _dateOnly(startDate),
        _dateOnly(endDate),
      );

  @override
  Future<List<LessonLearnedDto>> getLessons(
    DateTime startDate,
    DateTime endDate, {
    int limit = 10,
  }) =>
      _remoteDataSource.getLessons(
        _dateOnly(startDate),
        _dateOnly(endDate),
        limit: limit,
      );

  @override
  Future<JournalAdherenceDto> getAdherence(
    DateTime startDate,
    DateTime endDate,
  ) =>
      _remoteDataSource.getAdherence(_dateOnly(startDate), _dateOnly(endDate));

  @override
  Future<JournalReportCardDto> getReportCard(
    DateTime startDate,
    DateTime endDate,
  ) =>
      _remoteDataSource.getReportCard(
        _dateOnly(startDate),
        _dateOnly(endDate),
      );

  @override
  Future<JournalEntry> updatePrePlan(String entryId, PreTradePlan plan) async {
    final dto = await _remoteDataSource.updatePrePlan(
      entryId,
      JournalEntryMapper.toPreTradePlanDto(plan),
    );
    return JournalEntryMapper.fromResponseDto(dto);
  }

  @override
  Future<JournalEntry> updateExecution(
    String entryId,
    TradeExecution execution,
  ) async {
    final dto = await _remoteDataSource.updateExecution(
      entryId,
      JournalEntryMapper.toTradeExecutionDto(execution),
    );
    return JournalEntryMapper.fromResponseDto(dto);
  }

  @override
  Future<JournalEntry> updatePostReview(
    String entryId,
    PostTradeReview review, {
    bool markCompleted = false,
  }) async {
    final dto = await _remoteDataSource.updatePostReview(
      entryId,
      JournalEntryMapper.toPostTradeReviewDto(review),
      markCompleted: markCompleted,
    );
    return JournalEntryMapper.fromResponseDto(dto);
  }

  @override
  Future<JournalEntry> linkTrade(String entryId, String tradeId) async {
    final dto = await _remoteDataSource.linkTrade(entryId, tradeId);
    return JournalEntryMapper.fromResponseDto(dto);
  }

  @override
  Future<JournalEntry> addAttachment(
    String entryId,
    JournalAttachment attachment,
  ) async {
    final dto = await _remoteDataSource.addAttachment(
      entryId,
      JournalEntryMapper.toAttachmentDto(attachment),
    );
    return JournalEntryMapper.fromResponseDto(dto);
  }

  @override
  Future<JournalEntry> removeAttachment(String entryId, String fileUrl) async {
    final dto = await _remoteDataSource.removeAttachment(entryId, fileUrl);
    return JournalEntryMapper.fromResponseDto(dto);
  }

  @override
  Future<int> bulkArchive(List<String> entryIds) =>
      _remoteDataSource.bulkArchive(entryIds);

  @override
  Future<int> bulkDelete(List<String> entryIds) =>
      _remoteDataSource.bulkDelete(entryIds);

  @override
  Future<String> exportCsv(DateTime startDate, DateTime endDate) =>
      _remoteDataSource.exportCsv(_dateOnly(startDate), _dateOnly(endDate));

  @override
  Future<List<JournalEntry>> createFromTrades(
    List<String> tradeIds, {
    String journalStatus = 'COMPLETED',
  }) async {
    final dtos = await _remoteDataSource.createFromTrades(
      tradeIds,
      journalStatus: journalStatus,
    );
    return dtos.map(JournalEntryMapper.fromResponseDto).toList();
  }
}
