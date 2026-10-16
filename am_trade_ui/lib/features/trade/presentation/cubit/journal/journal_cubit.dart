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
  String? _portfolioId;
  List<String> _tagIds = [];
  String _searchQuery = '';
  String? _setupFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  JournalSummaryDto? _summary;
  JournalAdherenceDto? _adherence;

  /// Page size for hub lists. Callers needing more should use [fetchEntriesOnce] / load-more.
  static const int defaultPageSize = 250;

  Map<String, dynamic> _buildQuery() {
    final query = <String, dynamic>{
      // Classic UI folders filter client-side; fetch a large page so lists are complete.
      'size': defaultPageSize,
      'page': 0,
    };
    if (_statusFilter.isNotEmpty && _statusFilter != 'ALL') {
      query['journalStatus'] = _statusFilter;
    }
    if (_folderId != null && _folderId!.isNotEmpty) {
      query['folderId'] = _folderId;
    }
    if (_portfolioId != null && _portfolioId!.isNotEmpty) {
      query['portfolioId'] = _portfolioId;
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
      loaded: (entries, summary, adherence, status, folder, tags, q, setup) =>
          true,
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
      final rangeStart = _startDate ?? _defaultStart;
      final rangeEnd = _endDate ?? _defaultEnd;
      try {
        final results = await Future.wait([
          repository.getSummary(
            rangeStart,
            rangeEnd,
            portfolioId: _portfolioId,
          ),
          repository.getAdherence(
            rangeStart,
            rangeEnd,
            portfolioId: _portfolioId,
          ),
        ]);
        _summary = results[0] as JournalSummaryDto;
        _adherence = results[1] as JournalAdherenceDto;
      } catch (e) {
        AppLogger.warning(
          'Failed to load journal summary/adherence: $e',
          tag: 'JournalCubit',
        );
      }
      emit(
        JournalState.loaded(
          entries: entries,
          summary: _summary,
          adherence: _adherence,
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
        portfolioId: _portfolioId,
      );
      final current = state;
      current.maybeWhen(
        loaded: (entries, _, adherence, status, folder, tags, q, setup) {
          emit(
            JournalState.loaded(
              entries: entries,
              summary: _summary,
              adherence: adherence,
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
    String? portfolioId,
    List<String>? tagIds,
    String? searchQuery,
    String? setup,
    DateTime? startDate,
    DateTime? endDate,
    bool reload = true,
  }) {
    if (status != null) _statusFilter = status;
    if (folderId != null) _folderId = folderId.isEmpty ? null : folderId;
    if (portfolioId != null) {
      _portfolioId = portfolioId.isEmpty ? null : portfolioId;
    }
    if (tagIds != null) _tagIds = tagIds;
    if (searchQuery != null) _searchQuery = searchQuery;
    if (setup != null) _setupFilter = setup.isEmpty ? null : setup;
    if (startDate != null) _startDate = startDate;
    if (endDate != null) _endDate = endDate;
    if (reload) loadJournalEntries();
  }

  /// Scope hub lists / creates to the active portfolio (null = all portfolios).
  void setPortfolioId(String? portfolioId, {bool reload = true}) {
    _portfolioId = (portfolioId == null || portfolioId.isEmpty)
        ? null
        : portfolioId;
    if (reload) loadJournalEntries();
  }

  String? get portfolioId => _portfolioId;

  /// Entries from the current `loaded` state (empty otherwise).
  List<JournalEntry> get currentEntries => state.maybeWhen(
        loaded: (entries, summary, adherence, status, folder, tags, q, setup) =>
            entries,
        orElse: () => const <JournalEntry>[],
      );

  Future<void> loadEntriesByTrade(String tradeId) async {
    emit(const JournalState.loading());
    try {
      final entries = await getJournalEntries.getByTrade(tradeId);
      emit(
        JournalState.loaded(
          entries: entries,
          summary: _summary,
          adherence: _adherence,
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
    String? portfolioId,
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
    final resolvedPortfolio =
        portfolioId ?? _portfolioId;
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
          portfolioId: resolvedPortfolio,
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
          portfolioId: resolvedPortfolio,
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
        portfolioId: _portfolioId,
      );

  /// Upserts per-trade journal stubs (DRAFT by default) scoped to the active portfolio.
  Future<List<JournalEntry>> createFromTrades(
    List<String> tradeIds, {
    String journalStatus = 'DRAFT',
    String? portfolioId,
    bool reload = true,
  }) async {
    final created = await repository.createFromTrades(
      tradeIds,
      journalStatus: journalStatus,
      portfolioId: portfolioId ?? _portfolioId,
    );
    if (reload) await loadJournalEntries();
    return created;
  }

  DateTime get effectiveStart => _startDate ?? _defaultStart;
  DateTime get effectiveEnd => _endDate ?? _defaultEnd;

  /// One-off fetch that does **not** mutate hub Filters (used by Weekly Review).
  Future<List<JournalEntry>> fetchEntriesOnce({
    String? status,
    String? entryType,
    String? portfolioId,
    DateTime? start,
    DateTime? end,
    int size = 50,
  }) {
    final query = <String, dynamic>{
      'size': size,
      'page': 0,
    };
    if (status != null && status.isNotEmpty && status != 'ALL') {
      query['journalStatus'] = status;
    }
    if (entryType != null && entryType.isNotEmpty) {
      query['entryType'] = entryType;
    }
    final pid = portfolioId ?? _portfolioId;
    if (pid != null && pid.isNotEmpty) {
      query['portfolioId'] = pid;
    }
    final s = start ?? _startDate;
    final e = end ?? _endDate;
    if (s != null) {
      query['startDate'] = s.toIso8601String().split('T').first;
    }
    if (e != null) {
      query['endDate'] = e.toIso8601String().split('T').first;
    }
    return getJournalEntries.getByUser(query: query);
  }

  Future<List<MistakeAnalysisDto>> loadMistakesSummary({
    DateTime? start,
    DateTime? end,
  }) =>
      repository.getMistakesSummary(
        start ?? effectiveStart,
        end ?? effectiveEnd,
        portfolioId: _portfolioId,
      );

  Future<List<LessonLearnedDto>> loadLessons({
    DateTime? start,
    DateTime? end,
    int limit = 10,
  }) =>
      repository.getLessons(
        start ?? effectiveStart,
        end ?? effectiveEnd,
        limit: limit,
        portfolioId: _portfolioId,
      );

  Future<JournalAdherenceDto> loadAdherence({
    DateTime? start,
    DateTime? end,
  }) =>
      repository.getAdherence(
        start ?? effectiveStart,
        end ?? effectiveEnd,
        portfolioId: _portfolioId,
      );

  Future<JournalReportCardDto> loadReportCard({
    DateTime? start,
    DateTime? end,
  }) =>
      repository.getReportCard(
        start ?? effectiveStart,
        end ?? effectiveEnd,
        portfolioId: _portfolioId,
      );

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
    bool reload = true,
  }) async {
    final saved = await repository.updatePostReview(
      entryId,
      review,
      markCompleted: markCompleted,
    );
    if (reload) await loadJournalEntries();
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
    String? portfolioId,
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
        portfolioId: portfolioId,
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
    String? portfolioId,
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
      portfolioId: portfolioId,
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
