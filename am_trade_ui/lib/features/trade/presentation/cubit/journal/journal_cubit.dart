import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_common/am_common.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';
import '../../../internal/domain/entities/journal_entry.dart';
import '../../../internal/domain/repositories/journal_repository.dart';
import '../../../internal/domain/usecases/create_journal_entry_usecase.dart';
import '../../../internal/domain/usecases/delete_journal_entry_usecase.dart';
import '../../../internal/domain/usecases/get_journal_entries_usecase.dart';
import '../../../internal/domain/usecases/update_journal_entry_usecase.dart';
import 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> {
  JournalCubit({
    required this.getJournalEntries,
    required this.createJournalEntry,
    required this.updateJournalEntry,
    required this.deleteJournalEntry,
    required this.repository,
  }) : super(const JournalState.initial());

  final GetJournalEntriesUseCase getJournalEntries;
  final CreateJournalEntryUseCase createJournalEntry;
  final UpdateJournalEntryUseCase updateJournalEntry;
  final DeleteJournalEntryUseCase deleteJournalEntry;
  final JournalRepository repository;

  String _statusFilter = '';
  String? _folderId;
  List<String> _tagIds = [];
  String _searchQuery = '';
  String? _setupFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  JournalSummaryDto? _summary;

  Map<String, dynamic> _buildQuery() {
    final query = <String, dynamic>{
      // Classic UI folders filter client-side; fetch a large page so lists are complete.
      'size': 100,
      'page': 0,
    };
    if (_statusFilter.isNotEmpty && _statusFilter != 'ALL') {
      query['journalStatus'] = _statusFilter;
    }
    if (_folderId != null && _folderId!.isNotEmpty) {
      query['folderId'] = _folderId;
    }
    if (_tagIds.isNotEmpty) query['tagIds'] = _tagIds;
    if (_searchQuery.trim().isNotEmpty) query['q'] = _searchQuery.trim();
    if (_setupFilter != null && _setupFilter!.isNotEmpty) {
      query['setup'] = _setupFilter;
    }
    if (_startDate != null) {
      query['startDate'] = _startDate!.toIso8601String().split('T').first;
    }
    if (_endDate != null) {
      query['endDate'] = _endDate!.toIso8601String().split('T').first;
    }
    return query;
  }

  DateTime get _defaultStart =>
      DateTime.now().subtract(const Duration(days: 90));
  DateTime get _defaultEnd => DateTime.now().add(const Duration(days: 1));

  Future<void> loadJournalEntries() async {
    AppLogger.methodEntry('loadJournalEntries', tag: 'JournalCubit');
    // Keep previous loaded entries visible — bare `loading` makes the page treat
    // state as empty and unmounts Log Day / create mode.
    final keepEntries = state.maybeWhen(
      loaded: (entries, summary, status, folder, tags, q, setup) => true,
      orElse: () => false,
    );
    if (!keepEntries) {
      emit(const JournalState.loading());
    }
    try {
      final query = _buildQuery();
      final entries = await getJournalEntries.getByUser(
        query: query.isEmpty ? null : query,
      );
      try {
        _summary = await repository.getSummary(
          _startDate ?? _defaultStart,
          _endDate ?? _defaultEnd,
        );
      } catch (e) {
        AppLogger.warning(
          'Failed to load journal summary: $e',
          tag: 'JournalCubit',
        );
      }
      emit(
        JournalState.loaded(
          entries: entries,
          summary: _summary,
          statusFilter: _statusFilter,
          folderId: _folderId,
          tagIds: _tagIds,
          searchQuery: _searchQuery,
          setupFilter: _setupFilter,
        ),
      );
    } catch (e) {
      AppLogger.error(
        'Failed to load journal entries',
        tag: 'JournalCubit',
        error: e,
      );
      emit(JournalState.error(e.toString()));
    }
  }

  Future<void> loadSummary({DateTime? start, DateTime? end}) async {
    try {
      _summary = await repository.getSummary(
        start ?? _startDate ?? _defaultStart,
        end ?? _endDate ?? _defaultEnd,
      );
      final current = state;
      current.maybeWhen(
        loaded: (entries, _, status, folder, tags, q, setup) {
          emit(
            JournalState.loaded(
              entries: entries,
              summary: _summary,
              statusFilter: status,
              folderId: folder,
              tagIds: tags,
              searchQuery: q,
              setupFilter: setup,
            ),
          );
        },
        orElse: () {},
      );
    } catch (e) {
      AppLogger.warning('loadSummary failed: $e', tag: 'JournalCubit');
    }
  }

  void setFilters({
    String? status,
    String? folderId,
    List<String>? tagIds,
    String? searchQuery,
    String? setup,
    DateTime? startDate,
    DateTime? endDate,
    bool reload = true,
  }) {
    if (status != null) _statusFilter = status;
    if (folderId != null) _folderId = folderId.isEmpty ? null : folderId;
    if (tagIds != null) _tagIds = tagIds;
    if (searchQuery != null) _searchQuery = searchQuery;
    if (setup != null) _setupFilter = setup.isEmpty ? null : setup;
    if (startDate != null) _startDate = startDate;
    if (endDate != null) _endDate = endDate;
    if (reload) loadJournalEntries();
  }

  Future<void> loadEntriesByTrade(String tradeId) async {
    emit(const JournalState.loading());
    try {
      final entries = await getJournalEntries.getByTrade(tradeId);
      emit(
        JournalState.loaded(
          entries: entries,
          summary: _summary,
          statusFilter: _statusFilter,
          folderId: _folderId,
          tagIds: _tagIds,
          searchQuery: _searchQuery,
          setupFilter: _setupFilter,
        ),
      );
    } catch (e) {
      emit(JournalState.error(e.toString()));
    }
  }

  Future<JournalEntry> saveEntryFull({
    String? entryId,
    required String title,
    String? content,
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
    AppLogger.methodEntry('saveEntryFull', tag: 'JournalCubit');
    try {
      final JournalEntry saved;
      if (entryId == null || entryId.isEmpty || entryId.startsWith('temp-')) {
        saved = await createJournalEntry(
          title: title,
          content: content ?? '',
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
      } else {
        saved = await updateJournalEntry(
          entryId: entryId,
          title: title,
          content: content ?? '',
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
      // Reload without an intermediate empty `success` state that drops entries.
      await loadJournalEntries();
      return saved;
    } catch (e) {
      emit(JournalState.error(e.toString()));
      rethrow;
    }
  }

  Future<JournalEntry?> linkTrade(String entryId, String tradeId) async {
    try {
      final entry = await repository.linkTrade(entryId, tradeId);
      await loadJournalEntries();
      return entry;
    } catch (e) {
      emit(JournalState.error(e.toString()));
      return null;
    }
  }

  Future<void> bulkArchive(List<String> entryIds) async {
    await repository.bulkArchive(entryIds);
    await loadJournalEntries();
  }

  Future<void> bulkDelete(List<String> entryIds) async {
    await repository.bulkDelete(entryIds);
    await loadJournalEntries();
  }

  Future<String> exportCsv({DateTime? start, DateTime? end}) =>
      repository.exportCsv(
        start ?? _startDate ?? _defaultStart,
        end ?? _endDate ?? _defaultEnd,
      );

  Future<List<JournalEntry>> createFromTrades(List<String> tradeIds) async {
    final created = await repository.createFromTrades(tradeIds);
    await loadJournalEntries();
    return created;
  }

  Future<List<MistakeAnalysisDto>> loadMistakesSummary({
    DateTime? start,
    DateTime? end,
  }) =>
      repository.getMistakesSummary(
        start ?? _defaultStart,
        end ?? _defaultEnd,
      );

  Future<List<LessonLearnedDto>> loadLessons({
    DateTime? start,
    DateTime? end,
    int limit = 10,
  }) =>
      repository.getLessons(
        start ?? _defaultStart,
        end ?? _defaultEnd,
        limit: limit,
      );

  Future<JournalAdherenceDto> loadAdherence({
    DateTime? start,
    DateTime? end,
  }) =>
      repository.getAdherence(start ?? _defaultStart, end ?? _defaultEnd);

  Future<JournalReportCardDto> loadReportCard({
    DateTime? start,
    DateTime? end,
  }) =>
      repository.getReportCard(start ?? _defaultStart, end ?? _defaultEnd);

  Future<JournalEntry> addAttachment(
    String entryId,
    JournalAttachment attachment,
  ) =>
      repository.addAttachment(entryId, attachment);

  Future<JournalEntry> removeAttachment(String entryId, String fileUrl) =>
      repository.removeAttachment(entryId, fileUrl);

  Future<JournalEntry> updatePrePlan(String entryId, PreTradePlan plan) async {
    final saved = await repository.updatePrePlan(entryId, plan);
    await loadJournalEntries();
    return saved;
  }

  Future<JournalEntry> updateExecution(
    String entryId,
    TradeExecution execution,
  ) async {
    final saved = await repository.updateExecution(entryId, execution);
    await loadJournalEntries();
    return saved;
  }

  Future<JournalEntry> updatePostReview(
    String entryId,
    PostTradeReview review, {
    bool markCompleted = false,
  }) async {
    final saved = await repository.updatePostReview(
      entryId,
      review,
      markCompleted: markCompleted,
    );
    await loadJournalEntries();
    return saved;
  }

  Future<JournalEntry> addJournalEntry({
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
  }) async =>
      saveEntryFull(
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

  Future<void> editJournalEntry({
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
    await saveEntryFull(
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

  Future<void> removeJournalEntry(String entryId) async {
    emit(const JournalState.loading());
    try {
      await deleteJournalEntry(entryId);
      emit(const JournalState.success('Journal entry deleted successfully'));
      await loadJournalEntries();
    } catch (e) {
      emit(JournalState.error(e.toString()));
    }
  }
}
