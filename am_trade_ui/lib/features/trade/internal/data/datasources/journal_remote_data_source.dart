import 'package:am_library/am_library.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/am_common.dart';
import '../dtos/journal_entry_dto.dart';

/// Abstract data source for journal operations
abstract class JournalRemoteDataSource {
  /// Create a new journal entry
  Future<TradeJournalEntryResponseDto> createJournalEntry(TradeJournalEntryRequestDto request);

  /// Get a journal entry by ID
  Future<TradeJournalEntryResponseDto> getJournalEntry(String entryId);

  /// Update a journal entry
  Future<TradeJournalEntryResponseDto> updateJournalEntry(String entryId, TradeJournalEntryRequestDto request);

  /// Delete a journal entry
  Future<void> deleteJournalEntry(String entryId);

  /// Get journal entries for a user
  Future<List<TradeJournalEntryResponseDto>> getJournalEntriesByUser(String userId);

  /// Get journal entries for a specific trade
  Future<List<TradeJournalEntryResponseDto>> getJournalEntriesByTrade(String tradeId);

  /// Get journal entries by date range
  Future<List<TradeJournalEntryResponseDto>> getJournalEntriesByDateRange(
    String userId,
    String startDate,
    String endDate,
  );
}

/// Concrete implementation of journal remote data source
class JournalRemoteDataSourceImpl implements JournalRemoteDataSource {
  const JournalRemoteDataSourceImpl({
    required ApiClient apiClient,
    required TradeApiConfig tradeConfig,
  }) : _apiClient = apiClient,
       _tradeConfig = tradeConfig;

  final ApiClient _apiClient;
  final TradeApiConfig _tradeConfig;

  /// Helper to safely build URI avoiding double slashes
  String _buildUri(String baseUrl, String resource) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanResource = resource.startsWith('/')
        ? resource
        : '/$resource';
    return '$cleanBase$cleanResource';
  }

  @override
  Future<TradeJournalEntryResponseDto> createJournalEntry(TradeJournalEntryRequestDto request) async {
    AppLogger.methodEntry(
      'createJournalEntry',
      tag: 'JournalRemoteDataSource',
      params: {'userId': request.userId, 'title': request.title},
    );

    try {
      // API Spec: POST /v1/journal
      final fullUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal');

      final response = await _apiClient.post<TradeJournalEntryResponseDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => TradeJournalEntryResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info('Journal entry created successfully', tag: 'JournalRemoteDataSource');
      AppLogger.methodExit('createJournalEntry', tag: 'JournalRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to create journal entry',
        tag: 'JournalRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<TradeJournalEntryResponseDto> getJournalEntry(String entryId) async {
    AppLogger.methodEntry('getJournalEntry', tag: 'JournalRemoteDataSource', params: {'entryId': entryId});

    try {
      // API Spec: GET /v1/journal/{entryId}
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal');
      final fullUri = '$baseUri/$entryId';

      final response = await _apiClient.get<TradeJournalEntryResponseDto>(
        fullUri,
        parser: (data) => TradeJournalEntryResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info('Journal entry fetched successfully', tag: 'JournalRemoteDataSource');
      AppLogger.methodExit('getJournalEntry', tag: 'JournalRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch journal entry',
        tag: 'JournalRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<TradeJournalEntryResponseDto> updateJournalEntry(
    String entryId,
    TradeJournalEntryRequestDto request,
  ) async {
    AppLogger.methodEntry('updateJournalEntry', tag: 'JournalRemoteDataSource', params: {'entryId': entryId});

    try {
      // API Spec: PUT /v1/journal/{entryId}
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal');
      final fullUri = '$baseUri/$entryId';

      final response = await _apiClient.put<TradeJournalEntryResponseDto>(
        fullUri,
        body: request.toJson(),
        parser: (data) => TradeJournalEntryResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info('Journal entry updated successfully', tag: 'JournalRemoteDataSource');
      AppLogger.methodExit('updateJournalEntry', tag: 'JournalRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to update journal entry',
        tag: 'JournalRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteJournalEntry(String entryId) async {
    AppLogger.methodEntry('deleteJournalEntry', tag: 'JournalRemoteDataSource', params: {'entryId': entryId});

    try {
      // API Spec: DELETE /v1/journal/{entryId}
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal');
      final fullUri = '$baseUri/$entryId';

      await _apiClient.delete<void>(fullUri, parser: (_) {});

      AppLogger.info('Journal entry deleted successfully', tag: 'JournalRemoteDataSource');
      AppLogger.methodExit('deleteJournalEntry', tag: 'JournalRemoteDataSource', result: 'success');
    } catch (e) {
      AppLogger.error(
        'Failed to delete journal entry',
        tag: 'JournalRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<TradeJournalEntryResponseDto>> getJournalEntriesByUser(String userId) async {
    AppLogger.methodEntry('getJournalEntriesByUser', tag: 'JournalRemoteDataSource', params: {'userId': userId});

    try {
      // API Spec: GET /v1/journal/user/{userId}
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal/user');
      final fullUri = '$baseUri/$userId';

      final response = await _apiClient.get<List<TradeJournalEntryResponseDto>>(
        fullUri,
        parser: (data) {
          if (data is Map<String, dynamic> && data.containsKey('content') && data['content'] is List) {
             return (data['content'] as List)
                .map((item) => TradeJournalEntryResponseDto.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );

      AppLogger.info('Journal entries fetched successfully', tag: 'JournalRemoteDataSource');
      AppLogger.methodExit('getJournalEntriesByUser', tag: 'JournalRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch journal entries for user',
        tag: 'JournalRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<TradeJournalEntryResponseDto>> getJournalEntriesByTrade(String tradeId) async {
    AppLogger.methodEntry('getJournalEntriesByTrade', tag: 'JournalRemoteDataSource', params: {'tradeId': tradeId});

    try {
      // API Spec: GET /v1/journal/trade/{tradeId}
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal/trade');
      final fullUri = '$baseUri/$tradeId';

      final response = await _apiClient.get<List<TradeJournalEntryResponseDto>>(
        fullUri,
        parser: (data) {
           if (data is List) {
            return data
                .map((item) => TradeJournalEntryResponseDto.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );

      AppLogger.info('Journal entries fetched successfully', tag: 'JournalRemoteDataSource');
      AppLogger.methodExit('getJournalEntriesByTrade', tag: 'JournalRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch journal entries for trade',
        tag: 'JournalRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<TradeJournalEntryResponseDto>> getJournalEntriesByDateRange(
    String userId,
    String startDate,
    String endDate,
  ) async {
    AppLogger.methodEntry(
      'getJournalEntriesByDateRange',
      tag: 'JournalRemoteDataSource',
      params: {'userId': userId, 'startDate': startDate, 'endDate': endDate},
    );

    try {
      // API Spec: GET /v1/journal/date-range?userId={userId}&startDate={startDate}&endDate={endDate}
      final baseUri = _buildUri(_tradeConfig.baseUrl, 'v1/journal/date-range');
      final fullUri = '$baseUri?userId=$userId&startDate=$startDate&endDate=$endDate';

      final response = await _apiClient.get<List<TradeJournalEntryResponseDto>>(
        fullUri,
        parser: (data) {
          if (data is Map<String, dynamic> && data.containsKey('content') && data['content'] is List) {
             return (data['content'] as List)
                .map((item) => TradeJournalEntryResponseDto.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );

      AppLogger.info('Journal entries fetched successfully', tag: 'JournalRemoteDataSource');
      AppLogger.methodExit('getJournalEntriesByDateRange', tag: 'JournalRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch journal entries by date range',
        tag: 'JournalRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}

