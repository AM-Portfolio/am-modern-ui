import 'package:am_library/am_library.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/am_common.dart';
import 'package:am_trade_ui/core/constants/trade_endpoints.dart';
import '../dtos/journal_entry_dto.dart';
import 'trade_api_request_util.dart';

/// Abstract data source for journal operations
abstract class JournalRemoteDataSource {
  Future<TradeJournalEntryResponseDto> createJournalEntry(
    TradeJournalEntryRequestDto request,
  );

  Future<TradeJournalEntryResponseDto> getJournalEntry(String entryId);

  Future<TradeJournalEntryResponseDto> updateJournalEntry(
    String entryId,
    TradeJournalEntryRequestDto request,
  );

  Future<void> deleteJournalEntry(String entryId);

  Future<List<TradeJournalEntryResponseDto>> getJournalEntriesByUser({
    Map<String, dynamic>? query,
  });

  Future<List<TradeJournalEntryResponseDto>> getJournalEntriesByTrade(
    String tradeId,
  );

  Future<List<TradeJournalEntryResponseDto>> getJournalEntriesByDateRange(
    String startDate,
    String endDate,
  );

  Future<JournalSummaryDto> getSummary(String startDate, String endDate);

  Future<List<MistakeAnalysisDto>> getMistakesSummary(
    String startDate,
    String endDate,
  );

  Future<List<LessonLearnedDto>> getLessons(
    String startDate,
    String endDate, {
    int limit = 10,
  });

  Future<JournalAdherenceDto> getAdherence(String startDate, String endDate);

  Future<JournalReportCardDto> getReportCard(String startDate, String endDate);

  Future<TradeJournalEntryResponseDto> updatePrePlan(
    String entryId,
    PreTradePlanDto plan,
  );

  Future<TradeJournalEntryResponseDto> updateExecution(
    String entryId,
    TradeExecutionDto execution,
  );

  Future<TradeJournalEntryResponseDto> updatePostReview(
    String entryId,
    PostTradeReviewDto review, {
    bool markCompleted = false,
  });

  Future<TradeJournalEntryResponseDto> linkTrade(String entryId, String tradeId);

  Future<TradeJournalEntryResponseDto> addAttachment(
    String entryId,
    JournalAttachmentDto attachment,
  );

  Future<TradeJournalEntryResponseDto> removeAttachment(
    String entryId,
    String fileUrl,
  );

  Future<int> bulkArchive(List<String> entryIds);

  Future<int> bulkDelete(List<String> entryIds);

  Future<String> exportCsv(String startDate, String endDate);

  Future<List<TradeJournalEntryResponseDto>> createFromTrades(
    List<String> tradeIds, {
    String journalStatus = 'COMPLETED',
  });
}

/// Concrete implementation of journal remote data source
class JournalRemoteDataSourceImpl implements JournalRemoteDataSource {
  const JournalRemoteDataSourceImpl({
    required ApiClient apiClient,
    required TradeApiConfig tradeConfig,
  })  : _apiClient = apiClient,
        _tradeConfig = tradeConfig;

  final ApiClient _apiClient;
  final TradeApiConfig _tradeConfig;

  String get _baseUrl {
    try {
      if (_tradeConfig.baseUrl.isNotEmpty) return _tradeConfig.baseUrl;
    } catch (_) {}
    return TradeEndpoints.tradeBaseUrl;
  }

  String _buildUri(String baseUrl, String resource) {
    final cleanBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanResource =
        resource.startsWith('/') ? resource : '/$resource';
    return '$cleanBase$cleanResource';
  }

  String _withQuery(String uri, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return uri;
    final params = <String>[];
    query.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        for (final item in value) {
          params.add(
            '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent('$item')}',
          );
        }
      } else {
        params.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent('$value')}',
        );
      }
    });
    if (params.isEmpty) return uri;
    return '$uri?${params.join('&')}';
  }

  List<TradeJournalEntryResponseDto> _parseEntryList(dynamic data) {
    if (data is Map<String, dynamic> &&
        data.containsKey('content') &&
        data['content'] is List) {
      return (data['content'] as List)
          .map(
            (item) => TradeJournalEntryResponseDto.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }
    if (data is List) {
      return data
          .map(
            (item) => TradeJournalEntryResponseDto.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<TradeJournalEntryResponseDto> createJournalEntry(
    TradeJournalEntryRequestDto request,
  ) async {
    AppLogger.methodEntry(
      'createJournalEntry',
      tag: 'JournalRemoteDataSource',
      params: {'title': request.title},
    );

    try {
      final fullUri = _buildUri(_baseUrl, 'v1/journal');
      final response = await _apiClient.post<TradeJournalEntryResponseDto>(
        fullUri,
        body: tradeRequestBodyWithoutUserId(request.toJson()),
        parser: (data) => TradeJournalEntryResponseDto.fromJson(
          data! as Map<String, dynamic>,
        ),
      );
      AppLogger.info(
        'Journal entry created successfully',
        tag: 'JournalRemoteDataSource',
      );
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
    try {
      final fullUri = '${_buildUri(_baseUrl, 'v1/journal')}/$entryId';
      return await _apiClient.get<TradeJournalEntryResponseDto>(
        fullUri,
        parser: (data) => TradeJournalEntryResponseDto.fromJson(
          data! as Map<String, dynamic>,
        ),
      );
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
    try {
      final fullUri = '${_buildUri(_baseUrl, 'v1/journal')}/$entryId';
      return await _apiClient.put<TradeJournalEntryResponseDto>(
        fullUri,
        body: tradeRequestBodyWithoutUserId(request.toJson()),
        parser: (data) => TradeJournalEntryResponseDto.fromJson(
          data! as Map<String, dynamic>,
        ),
      );
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
    try {
      final fullUri = '${_buildUri(_baseUrl, 'v1/journal')}/$entryId';
      await _apiClient.delete<void>(fullUri, parser: (_) {});
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
  Future<List<TradeJournalEntryResponseDto>> getJournalEntriesByUser({
    Map<String, dynamic>? query,
  }) async {
    try {
      final fullUri = _withQuery(
        _buildUri(_baseUrl, 'v1/journal/user'),
        query,
      );
      return await _apiClient.get<List<TradeJournalEntryResponseDto>>(
        fullUri,
        parser: (data) => _parseEntryList(data),
      );
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
  Future<List<TradeJournalEntryResponseDto>> getJournalEntriesByTrade(
    String tradeId,
  ) async {
    try {
      final fullUri = '${_buildUri(_baseUrl, 'v1/journal/trade')}/$tradeId';
      return await _apiClient.get<List<TradeJournalEntryResponseDto>>(
        fullUri,
        parser: (data) => _parseEntryList(data),
      );
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
    String startDate,
    String endDate,
  ) async {
    try {
      final fullUri = _withQuery(
        _buildUri(_baseUrl, 'v1/journal/date-range'),
        {'startDate': startDate, 'endDate': endDate},
      );
      return await _apiClient.get<List<TradeJournalEntryResponseDto>>(
        fullUri,
        parser: (data) => _parseEntryList(data),
      );
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

  @override
  Future<JournalSummaryDto> getSummary(String startDate, String endDate) async {
    final fullUri = _withQuery(
      _buildUri(_baseUrl, 'v1/journal/summary'),
      {'startDate': startDate, 'endDate': endDate},
    );
    return _apiClient.get<JournalSummaryDto>(
      fullUri,
      parser: (data) =>
          JournalSummaryDto.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<List<MistakeAnalysisDto>> getMistakesSummary(
    String startDate,
    String endDate,
  ) async {
    final fullUri = _withQuery(
      _buildUri(_baseUrl, 'v1/journal/mistakes/summary'),
      {'startDate': startDate, 'endDate': endDate},
    );
    return _apiClient.get<List<MistakeAnalysisDto>>(
      fullUri,
      parser: (data) {
        if (data is List) {
          return data
              .map(
                (e) => MistakeAnalysisDto.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }
        return [];
      },
    );
  }

  @override
  Future<List<LessonLearnedDto>> getLessons(
    String startDate,
    String endDate, {
    int limit = 10,
  }) async {
    final fullUri = _withQuery(
      _buildUri(_baseUrl, 'v1/journal/lessons'),
      {'startDate': startDate, 'endDate': endDate, 'limit': limit},
    );
    return _apiClient.get<List<LessonLearnedDto>>(
      fullUri,
      parser: (data) {
        if (data is List) {
          return data
              .map((e) => LessonLearnedDto.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  @override
  Future<JournalAdherenceDto> getAdherence(
    String startDate,
    String endDate,
  ) async {
    final fullUri = _withQuery(
      _buildUri(_baseUrl, 'v1/journal/adherence'),
      {'startDate': startDate, 'endDate': endDate},
    );
    return _apiClient.get<JournalAdherenceDto>(
      fullUri,
      parser: (data) =>
          JournalAdherenceDto.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<JournalReportCardDto> getReportCard(
    String startDate,
    String endDate,
  ) async {
    final fullUri = _withQuery(
      _buildUri(_baseUrl, 'v1/journal/report-card'),
      {'startDate': startDate, 'endDate': endDate},
    );
    return _apiClient.get<JournalReportCardDto>(
      fullUri,
      parser: (data) =>
          JournalReportCardDto.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<TradeJournalEntryResponseDto> updatePrePlan(
    String entryId,
    PreTradePlanDto plan,
  ) async {
    final fullUri = '${_buildUri(_baseUrl, 'v1/journal')}/$entryId/pre-plan';
    return _apiClient.put<TradeJournalEntryResponseDto>(
      fullUri,
      body: plan.toJson(),
      parser: (data) => TradeJournalEntryResponseDto.fromJson(
        data! as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<TradeJournalEntryResponseDto> updateExecution(
    String entryId,
    TradeExecutionDto execution,
  ) async {
    final fullUri = '${_buildUri(_baseUrl, 'v1/journal')}/$entryId/execution';
    return _apiClient.put<TradeJournalEntryResponseDto>(
      fullUri,
      body: execution.toJson(),
      parser: (data) => TradeJournalEntryResponseDto.fromJson(
        data! as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<TradeJournalEntryResponseDto> updatePostReview(
    String entryId,
    PostTradeReviewDto review, {
    bool markCompleted = false,
  }) async {
    final fullUri = _withQuery(
      '${_buildUri(_baseUrl, 'v1/journal')}/$entryId/post-review',
      {'markCompleted': markCompleted},
    );
    return _apiClient.put<TradeJournalEntryResponseDto>(
      fullUri,
      body: review.toJson(),
      parser: (data) => TradeJournalEntryResponseDto.fromJson(
        data! as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<TradeJournalEntryResponseDto> linkTrade(
    String entryId,
    String tradeId,
  ) async {
    final fullUri = '${_buildUri(_baseUrl, 'v1/journal')}/$entryId/link-trade';
    return _apiClient.post<TradeJournalEntryResponseDto>(
      fullUri,
      body: {'tradeId': tradeId},
      parser: (data) => TradeJournalEntryResponseDto.fromJson(
        data! as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<TradeJournalEntryResponseDto> addAttachment(
    String entryId,
    JournalAttachmentDto attachment,
  ) async {
    final fullUri = '${_buildUri(_baseUrl, 'v1/journal')}/$entryId/attachments';
    return _apiClient.post<TradeJournalEntryResponseDto>(
      fullUri,
      body: attachment.toJson(),
      parser: (data) => TradeJournalEntryResponseDto.fromJson(
        data! as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<TradeJournalEntryResponseDto> removeAttachment(
    String entryId,
    String fileUrl,
  ) async {
    final fullUri = _withQuery(
      '${_buildUri(_baseUrl, 'v1/journal')}/$entryId/attachments',
      {'fileUrl': fileUrl},
    );
    return _apiClient.delete<TradeJournalEntryResponseDto>(
      fullUri,
      parser: (data) => TradeJournalEntryResponseDto.fromJson(
        data! as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<int> bulkArchive(List<String> entryIds) async {
    final fullUri = _buildUri(_baseUrl, 'v1/journal/bulk/archive');
    final result = await _apiClient.post<Map<String, dynamic>>(
      fullUri,
      body: {'entryIds': entryIds},
      parser: (data) => data! as Map<String, dynamic>,
    );
    return (result['archived'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> bulkDelete(List<String> entryIds) async {
    final fullUri = _buildUri(_baseUrl, 'v1/journal/bulk/delete');
    final result = await _apiClient.post<Map<String, dynamic>>(
      fullUri,
      body: {'entryIds': entryIds},
      parser: (data) => data! as Map<String, dynamic>,
    );
    return (result['deleted'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<String> exportCsv(String startDate, String endDate) async {
    final fullUri = _withQuery(
      _buildUri(_baseUrl, 'v1/journal/export'),
      {'startDate': startDate, 'endDate': endDate},
    );
    return _apiClient.get<String>(
      fullUri,
      parser: (data) {
        if (data is String) return data;
        return data?.toString() ?? '';
      },
    );
  }

  @override
  Future<List<TradeJournalEntryResponseDto>> createFromTrades(
    List<String> tradeIds, {
    String journalStatus = 'COMPLETED',
  }) async {
    final fullUri = _buildUri(_baseUrl, 'v1/journal/from-trades');
    return _apiClient.post<List<TradeJournalEntryResponseDto>>(
      fullUri,
      body: {'tradeIds': tradeIds, 'journalStatus': journalStatus},
      parser: (data) => _parseEntryList(data),
    );
  }
}
