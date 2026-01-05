import 'package:am_common/core/utils/logger.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_remote_data_source.dart';
import '../dtos/journal_entry_dto.dart';
import '../mappers/journal_entry_mapper.dart';

/// Repository implementation for journal operations
class JournalRepositoryImpl implements JournalRepository {
  JournalRepositoryImpl({required JournalRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final JournalRemoteDataSource _remoteDataSource;

  @override
  Future<JournalEntry> createJournalEntry({
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
  }) async {
    AppLogger.methodEntry('createJournalEntry', tag: 'JournalRepository', params: {'userId': userId, 'title': title});

    try {
      final request = TradeJournalEntryRequestDto(
        userId: userId,
        title: title,
        content: content,
        entryDate: entryDate.toIso8601String(),
        tradeId: tradeId,
        behaviorPatternSummaries: behaviorPatternSummaries?.map(JournalEntryMapper.toBehaviorPatternDto).toList(),
        customFields: customFields,
        imageUrls: imageUrls,
        attachments: attachments?.map(JournalEntryMapper.toAttachmentDto).toList(),
        relatedTradeIds: relatedTradeIds,
        tagIds: tagIds,
      );

      final dto = await _remoteDataSource.createJournalEntry(request);
      final entry = JournalEntryMapper.fromResponseDto(dto);

      AppLogger.info('Journal entry created successfully', tag: 'JournalRepository');
      AppLogger.methodExit('createJournalEntry', tag: 'JournalRepository', result: 'success');

      return entry;
    } catch (e) {
      AppLogger.error(
        'Failed to create journal entry',
        tag: 'JournalRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<JournalEntry> getJournalEntry(String entryId) async {
    AppLogger.methodEntry('getJournalEntry', tag: 'JournalRepository', params: {'entryId': entryId});

    try {
      final dto = await _remoteDataSource.getJournalEntry(entryId);
      final entry = JournalEntryMapper.fromResponseDto(dto);

      AppLogger.info('Journal entry fetched successfully', tag: 'JournalRepository');
      AppLogger.methodExit('getJournalEntry', tag: 'JournalRepository', result: 'success');

      return entry;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch journal entry',
        tag: 'JournalRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<JournalEntry> updateJournalEntry({
    required String entryId,
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
  }) async {
    AppLogger.methodEntry('updateJournalEntry', tag: 'JournalRepository', params: {'entryId': entryId});

    try {
      final request = TradeJournalEntryRequestDto(
        userId: userId,
        title: title,
        content: content,
        entryDate: entryDate.toIso8601String(),
        tradeId: tradeId,
        behaviorPatternSummaries: behaviorPatternSummaries?.map(JournalEntryMapper.toBehaviorPatternDto).toList(),
        customFields: customFields,
        imageUrls: imageUrls,
        attachments: attachments?.map(JournalEntryMapper.toAttachmentDto).toList(),
        relatedTradeIds: relatedTradeIds,
        tagIds: tagIds,
      );

      final dto = await _remoteDataSource.updateJournalEntry(entryId, request);
      final entry = JournalEntryMapper.fromResponseDto(dto);

      AppLogger.info('Journal entry updated successfully', tag: 'JournalRepository');
      AppLogger.methodExit('updateJournalEntry', tag: 'JournalRepository', result: 'success');

      return entry;
    } catch (e) {
      AppLogger.error(
        'Failed to update journal entry',
        tag: 'JournalRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteJournalEntry(String entryId) async {
    AppLogger.methodEntry('deleteJournalEntry', tag: 'JournalRepository', params: {'entryId': entryId});

    try {
      await _remoteDataSource.deleteJournalEntry(entryId);

      AppLogger.info('Journal entry deleted successfully', tag: 'JournalRepository');
      AppLogger.methodExit('deleteJournalEntry', tag: 'JournalRepository', result: 'success');
    } catch (e) {
      AppLogger.error(
        'Failed to delete journal entry',
        tag: 'JournalRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<JournalEntry>> getJournalEntriesByUser(String userId) async {
    AppLogger.methodEntry('getJournalEntriesByUser', tag: 'JournalRepository', params: {'userId': userId});

    try {
      final dtos = await _remoteDataSource.getJournalEntriesByUser(userId);
      final entries = dtos.map(JournalEntryMapper.fromResponseDto).toList();

      AppLogger.info('Journal entries fetched successfully', tag: 'JournalRepository');
      AppLogger.methodExit('getJournalEntriesByUser', tag: 'JournalRepository', result: 'success');

      return entries;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch journal entries for user',
        tag: 'JournalRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<JournalEntry>> getJournalEntriesByTrade(String tradeId) async {
    AppLogger.methodEntry('getJournalEntriesByTrade', tag: 'JournalRepository', params: {'tradeId': tradeId});

    try {
      final dtos = await _remoteDataSource.getJournalEntriesByTrade(tradeId);
      final entries = dtos.map(JournalEntryMapper.fromResponseDto).toList();

      AppLogger.info('Journal entries fetched successfully', tag: 'JournalRepository');
      AppLogger.methodExit('getJournalEntriesByTrade', tag: 'JournalRepository', result: 'success');

      return entries;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch journal entries for trade',
        tag: 'JournalRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<JournalEntry>> getJournalEntriesByDateRange(String userId, DateTime startDate, DateTime endDate) async {
    AppLogger.methodEntry('getJournalEntriesByDateRange', tag: 'JournalRepository', params: {'userId': userId});

    try {
      final dtos = await _remoteDataSource.getJournalEntriesByDateRange(
        userId,
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      );
      final entries = dtos.map(JournalEntryMapper.fromResponseDto).toList();

      AppLogger.info('Journal entries fetched successfully', tag: 'JournalRepository');
      AppLogger.methodExit('getJournalEntriesByDateRange', tag: 'JournalRepository', result: 'success');

      return entries;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch journal entries by date range',
        tag: 'JournalRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}
