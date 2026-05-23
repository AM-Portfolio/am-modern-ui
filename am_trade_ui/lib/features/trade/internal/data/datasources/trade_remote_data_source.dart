import 'package:am_library/am_library.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/am_common.dart';
import '../dtos/trade_calendar_dto.dart';
import '../dtos/trade_controller_dtos.dart';
import '../dtos/trade_holding_dto.dart';
import '../dtos/trade_portfolio_dto.dart';
import '../dtos/trade_portfolio_summary_dto.dart';
import 'trade_mock_data_helper.dart';

/// Abstract data source for trade data
abstract class TradeRemoteDataSource {
  /// Get trade portfolios from remote API
  Future<TradePortfolioListDto> getTradePortfolios(String userId);

  /// Get trade holdings from remote API
  Future<TradeHoldingsDto> getTradeHoldings(String userId, String portfolioId);

  /// Get trade summary from remote API
  Future<TradePortfolioSummaryDto> getTradeSummary(String userId, String portfolioId);

  /// Get trade calendar by month from remote API
  Future<TradeCalendarDto> getTradeCalendarByMonth(
    String userId,
    String portfolioId, {
    required int year,
    required int month,
  });

  /// Get trade calendar by day from remote API
  Future<TradeCalendarDto> getTradeCalendarByDay(String userId, String portfolioId, {required DateTime date});

  /// Get trade calendar by date range from remote API
  Future<TradeCalendarDto> getTradeCalendarByDateRange(
    String userId,
    String portfolioId, {
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get trade calendar by quarter from remote API
  Future<TradeCalendarDto> getTradeCalendarByQuarter(
    String userId,
    String portfolioId, {
    required int year,
    required int quarter,
  });

  /// Get trade calendar by financial year from remote API
  Future<TradeCalendarDto>
  
   getTradeCalendarByFinancialYear(
    String userId,
    String portfolioId, {
    required int financialYear,
  });

  /// Get trade calendar from remote API (legacy - delegates to getTradeCalendarByMonth)
  @Deprecated('Use getTradeCalendarByMonth instead')
  Future<TradeCalendarDto> getTradeCalendar(String userId, String portfolioId, {int? year, int? month});
}

/// Concrete implementation of trade remote data source
class TradeRemoteDataSourceImpl implements TradeRemoteDataSource {
  const TradeRemoteDataSourceImpl({
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
  Future<TradePortfolioListDto> getTradePortfolios(String userId) async {
    AppLogger.methodEntry('getTradePortfolios', tag: 'TradeRemoteDataSource', params: {'userId': userId});

    try {
      // Trade API Spec: GET /v1/portfolio-summary/by-owner/{ownerId}
      final baseUri = _buildUri(_tradeConfig.baseUrl, _tradeConfig.portfolioListResource);
      final fullUri = '$baseUri/$userId';

      final response = await _apiClient.get<TradePortfolioListDto>(
        fullUri,
        parser: (data) {
          if (data is List) {
            return TradePortfolioListDto(
              portfolios: data.map((item) => TradePortfolioDto.fromJson(item as Map<String, dynamic>)).toList(),
              totalCount: data.length,
            );
          }
          return TradePortfolioListDto.fromJson(data! as Map<String, dynamic>);
        },
      );

      AppLogger.info('Trade portfolios fetched successfully from API', tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradePortfolios', tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade portfolios',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      try {
        AppLogger.info('Loading mock trade portfolios', tag: 'TradeRemoteDataSource');
        return await TradeMockDataHelper.getMockTradePortfolios();
      } catch (mockError) {
        AppLogger.error('Failed to load mock data', tag: 'TradeRemoteDataSource', error: mockError);
        rethrow;
      }
    }
  }

  @override
  Future<TradeHoldingsDto> getTradeHoldings(String userId, String portfolioId) async {
    AppLogger.methodEntry(
      'getTradeHoldings',
      tag: 'TradeRemoteDataSource',
      params: {'userId': userId, 'portfolioId': portfolioId},
    );

    try {
      // Trade API Spec: GET /v1/trades/details/portfolio/{portfolioId} returns List<TradeDetails>
      // The backend endpoint configured in ConfigService (holdingsResource) points to a List endpoint, not a Page endpoint.
      final baseUri = _buildUri(_tradeConfig.baseUrl, _tradeConfig.holdingsResource);
      final fullUri = '$baseUri/$portfolioId'; // Pagination params removed as backend ignores/doesn't support them for this endpoint

      final response = await _apiClient.get<TradeHoldingsDto>(
        fullUri,
        parser: (data) {
          // Handle List response by wrapping it in TradeHoldingsDto
          if (data is List) {
             final list = data.map((item) => TradeDetailsDto.fromJson(item as Map<String, dynamic>)).toList();
             return TradeHoldingsDto(
               content: list,
               totalElements: list.length,
               totalPages: 1,
               last: true,
               first: true,
               size: list.length > 0 ? list.length : 50,
               numberOfElements: list.length,
               empty: list.isEmpty,
               pageable: const PageableDto(
                  pageNumber: 0,
                  pageSize: 50,
                  paged: false,
                  unpaged: true
               )
             );
          }
          // Fallback if data is already a Map (e.g. if backend changes future)
          return TradeHoldingsDto.fromJson(data! as Map<String, dynamic>);
        },
      );

      AppLogger.info('Trade holdings fetched successfully from API', tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeHoldings', tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade holdings',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      try {
        AppLogger.info('Loading mock trade holdings', tag: 'TradeRemoteDataSource');
        return await TradeMockDataHelper.getMockTradeHoldings();
      } catch (mockError) {
        AppLogger.error('Failed to load mock data', tag: 'TradeRemoteDataSource', error: mockError);
        rethrow;
      }
    }
  }

  @override
  Future<TradePortfolioSummaryDto> getTradeSummary(String userId, String portfolioId) async {
    AppLogger.methodEntry(
      'getTradeSummary',
      tag: 'TradeRemoteDataSource',
      params: {'userId': userId, 'portfolioId': portfolioId},
    );

    try {
      // Trade API Spec: GET /v1/portfolio-summary/{portfolioId}
      final baseUri = _buildUri(_tradeConfig.baseUrl, _tradeConfig.portfolioSummaryResource);
      final fullUri = '$baseUri/$portfolioId';

      final response = await _apiClient.get<TradePortfolioSummaryDto>(
        fullUri,
        parser: (data) => TradePortfolioSummaryDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info('Trade summary fetched successfully from API', tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeSummary', tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade summary',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      try {
        AppLogger.info('Loading mock trade summary', tag: 'TradeRemoteDataSource');
        return await TradeMockDataHelper.getMockTradeSummary();
      } catch (mockError) {
        AppLogger.error('Failed to load mock data', tag: 'TradeRemoteDataSource', error: mockError);
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendarByMonth(
    String userId,
    String portfolioId, {
    required int year,
    required int month,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByMonth',
      tag: 'TradeRemoteDataSource',
      params: {'userId': userId, 'portfolioId': portfolioId, 'year': year, 'month': month},
    );

    try {
      var resource = _tradeConfig.calendarMonthResource;
      
      String fullUri;
      if (resource.contains('{portfolioId}')) {
          fullUri = '${_buildUri(_tradeConfig.baseUrl, resource.replaceAll('{portfolioId}', portfolioId))}?year=$year&month=$month';
      } else {
          fullUri = '${_buildUri(_tradeConfig.baseUrl, resource)}?portfolioId=$portfolioId&year=$year&month=$month';
      }

      AppLogger.info('Fetching calendar for year=$year, month=$month', tag: 'TradeRemoteDataSource');

      final response = await _apiClient.get<TradeCalendarDto>(
        fullUri,
        parser: (data) {
          if (data == null) return const TradeCalendarDto(portfolioTrades: {});

          if (data is List) {
            if (data.isEmpty) return const TradeCalendarDto(portfolioTrades: {});
            final portfolioTrades = <String, List<TradeDetailsDto>>{};
            for (final item in data) {
              final tradeJson = item as Map<String, dynamic>;
              final portfolioId = tradeJson['customPortfolioId'] as String?;
              if (portfolioId != null) {
                final trade = TradeDetailsDto.fromJson(tradeJson);
                portfolioTrades.putIfAbsent(portfolioId, () => []).add(trade);
              }
            }
            return TradeCalendarDto(portfolioTrades: portfolioTrades);
          }

          final json = data as Map<String, dynamic>;
          if (json.isEmpty) return const TradeCalendarDto(portfolioTrades: {});
          return TradeCalendarDto.fromJson(json);
        },
      );

      AppLogger.info('Trade calendar by month fetched successfully from API', tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeCalendarByMonth', tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by month',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      try {
        AppLogger.info('Loading mock trade calendar', tag: 'TradeRemoteDataSource');
        return await TradeMockDataHelper.getMockTradeCalendar();
      } catch (mockError) {
        AppLogger.error('Failed to load mock data', tag: 'TradeRemoteDataSource', error: mockError);
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendarByDay(String userId, String portfolioId, {required DateTime date}) async {
    AppLogger.methodEntry(
      'getTradeCalendarByDay',
      tag: 'TradeRemoteDataSource',
      params: {'userId': userId, 'portfolioId': portfolioId, 'date': date.toIso8601String()},
    );

    try {
      // Trade API Spec: GET /v1/trades/calendar/day?date={date}&portfolioId={id}
      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      var resource = _tradeConfig.calendarDayResource;
      String fullUri;
      if (resource.contains('{portfolioId}')) {
           fullUri = '${_buildUri(_tradeConfig.baseUrl, resource.replaceAll('{portfolioId}', portfolioId))}?date=$formattedDate';
      } else {
           fullUri = '${_buildUri(_tradeConfig.baseUrl, resource)}?date=$formattedDate&portfolioId=$portfolioId';
      }

      AppLogger.info('Fetching calendar for date=$formattedDate', tag: 'TradeRemoteDataSource');

      final response = await _apiClient.get<TradeCalendarDto>(
        fullUri,
        parser: (data) {
          if (data == null) return const TradeCalendarDto(portfolioTrades: {});

          if (data is List) {
            if (data.isEmpty) return const TradeCalendarDto(portfolioTrades: {});
            final portfolioTrades = <String, List<TradeDetailsDto>>{};
            for (final item in data) {
              final tradeJson = item as Map<String, dynamic>;
              final portfolioId = tradeJson['customPortfolioId'] as String?;
              if (portfolioId != null) {
                final trade = TradeDetailsDto.fromJson(tradeJson);
                portfolioTrades.putIfAbsent(portfolioId, () => []).add(trade);
              }
            }
            return TradeCalendarDto(portfolioTrades: portfolioTrades);
          }

          final json = data as Map<String, dynamic>;
          if (json.isEmpty) return const TradeCalendarDto(portfolioTrades: {});
          return TradeCalendarDto.fromJson(json);
        },
      );

      AppLogger.info('Trade calendar by day fetched successfully from API', tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeCalendarByDay', tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by day',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      try {
        AppLogger.info('Loading mock trade calendar by day', tag: 'TradeRemoteDataSource');
        return await TradeMockDataHelper.getMockTradeCalendarByDay();
      } catch (mockError) {
        AppLogger.error('Failed to load mock data', tag: 'TradeRemoteDataSource', error: mockError);
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendarByDateRange(
    String userId,
    String portfolioId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByDateRange',
      tag: 'TradeRemoteDataSource',
      params: {
        'userId': userId,
        'portfolioId': portfolioId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );

    try {
      // Trade API Spec: GET /v1/trades/calendar/custom?portfolioId={id}&startDate={start}&endDate={end}&page=0&size=50
      final formattedStartDate =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final formattedEndDate =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      
      // Using generic resource if available or hardcoded for now, but using _buildUri
      // "v1/trades/calendar/custom"
      final fullUri = '${_buildUri(_tradeConfig.baseUrl, 'v1/trades/calendar/custom')}?portfolioId=$portfolioId&startDate=$formattedStartDate&endDate=$formattedEndDate&page=0&size=50';

      AppLogger.info(
        'Fetching calendar for date range=$formattedStartDate to $formattedEndDate',
        tag: 'TradeRemoteDataSource',
      );

      final response = await _apiClient.get<TradeCalendarDto>(
        fullUri,
        parser: (data) {
          if (data == null) {
            AppLogger.debug('[DateRange Parser] Received null data', tag: 'TradeRemoteDataSource');
            return const TradeCalendarDto(portfolioTrades: {});
          }

          if (data is List) {
            AppLogger.info('[DateRange Parser] Received array with ${data.length} items', tag: 'TradeRemoteDataSource');
            if (data.isEmpty) return const TradeCalendarDto(portfolioTrades: {});

            final portfolioTrades = <String, List<TradeDetailsDto>>{};
            for (final item in data) {
              final tradeJson = item as Map<String, dynamic>;
              final portfolioId = tradeJson['customPortfolioId'] as String?;
              if (portfolioId != null) {
                final trade = TradeDetailsDto.fromJson(tradeJson);
                portfolioTrades.putIfAbsent(portfolioId, () => []).add(trade);
              }
            }
            return TradeCalendarDto(portfolioTrades: portfolioTrades);
          }

          AppLogger.debug('[DateRange Parser] Received map data', tag: 'TradeRemoteDataSource');
          final json = data as Map<String, dynamic>;
          if (json.isEmpty) return const TradeCalendarDto(portfolioTrades: {});
          return TradeCalendarDto.fromJson(json);
        },
      );

      AppLogger.info('Trade calendar by date range fetched successfully from API', tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeCalendarByDateRange', tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by date range',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      try {
        AppLogger.info('Loading mock trade calendar by date range', tag: 'TradeRemoteDataSource');
        return await TradeMockDataHelper.getMockTradeCalendarByDateRange();
      } catch (mockError) {
        AppLogger.error('Failed to load mock data', tag: 'TradeRemoteDataSource', error: mockError);
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendarByQuarter(
    String userId,
    String portfolioId, {
    required int year,
    required int quarter,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByQuarter',
      tag: 'TradeRemoteDataSource',
      params: {'userId': userId, 'portfolioId': portfolioId, 'year': year, 'quarter': quarter},
    );

    try {
      // Trade API Spec: GET /v1/trades/calendar/quarter?portfolioId={id}&year={year}&quarter={quarter}
      var resource = _tradeConfig.calendarQuarterResource;
      String fullUri;
      if (resource.contains('{portfolioId}')) {
           fullUri = '${_buildUri(_tradeConfig.baseUrl, resource.replaceAll('{portfolioId}', portfolioId))}?year=$year&quarter=$quarter';
      } else {
           fullUri = '${_buildUri(_tradeConfig.baseUrl, resource)}?portfolioId=$portfolioId&year=$year&quarter=$quarter';
      }

      AppLogger.info('Fetching calendar for year=$year, quarter=$quarter', tag: 'TradeRemoteDataSource');

      final response = await _apiClient.get<TradeCalendarDto>(
        fullUri,
        parser: (data) {
          if (data == null) return const TradeCalendarDto(portfolioTrades: {});

          if (data is List) {
            if (data.isEmpty) return const TradeCalendarDto(portfolioTrades: {});
            final portfolioTrades = <String, List<TradeDetailsDto>>{};
            for (final item in data) {
              final tradeJson = item as Map<String, dynamic>;
              final portfolioId = tradeJson['customPortfolioId'] as String?;
              if (portfolioId != null) {
                final trade = TradeDetailsDto.fromJson(tradeJson);
                portfolioTrades.putIfAbsent(portfolioId, () => []).add(trade);
              }
            }
            return TradeCalendarDto(portfolioTrades: portfolioTrades);
          }

          final json = data as Map<String, dynamic>;
          if (json.isEmpty) return const TradeCalendarDto(portfolioTrades: {});
          return TradeCalendarDto.fromJson(json);
        },
      );

      AppLogger.info('Trade calendar by quarter fetched successfully from API', tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeCalendarByQuarter', tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by quarter',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      try {
        AppLogger.info('Loading mock trade calendar', tag: 'TradeRemoteDataSource');
        return await TradeMockDataHelper.getMockTradeCalendar();
      } catch (mockError) {
        AppLogger.error('Failed to load mock data', tag: 'TradeRemoteDataSource', error: mockError);
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendarByFinancialYear(
    String userId,
    String portfolioId, {
    required int financialYear,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByFinancialYear',
      tag: 'TradeRemoteDataSource',
      params: {'userId': userId, 'portfolioId': portfolioId, 'financialYear': financialYear},
    );

    try {
      // Trade API Spec: GET /v1/trades/calendar/financial-year?portfolioId={id}&financialYear={year}
      var resource = _tradeConfig.calendarFinancialYearResource;
      String fullUri;
      if (resource.contains('{portfolioId}')) {
           fullUri = '${_buildUri(_tradeConfig.baseUrl, resource.replaceAll('{portfolioId}', portfolioId))}?financialYear=$financialYear';
      } else {
           fullUri = '${_buildUri(_tradeConfig.baseUrl, resource)}?portfolioId=$portfolioId&financialYear=$financialYear';
      }

      AppLogger.info('Fetching calendar for financial year=$financialYear', tag: 'TradeRemoteDataSource');

      final response = await _apiClient.get<TradeCalendarDto>(
        fullUri,
        parser: (data) {
          if (data == null) return const TradeCalendarDto(portfolioTrades: {});

          if (data is List) {
            if (data.isEmpty) return const TradeCalendarDto(portfolioTrades: {});
            final portfolioTrades = <String, List<TradeDetailsDto>>{};
            for (final item in data) {
              final tradeJson = item as Map<String, dynamic>;
              final portfolioId = tradeJson['customPortfolioId'] as String?;
              if (portfolioId != null) {
                final trade = TradeDetailsDto.fromJson(tradeJson);
                portfolioTrades.putIfAbsent(portfolioId, () => []).add(trade);
              }
            }
            return TradeCalendarDto(portfolioTrades: portfolioTrades);
          }

          final json = data as Map<String, dynamic>;
          if (json.isEmpty) return const TradeCalendarDto(portfolioTrades: {});
          return TradeCalendarDto.fromJson(json);
        },
      );

      AppLogger.info('Trade calendar by financial year fetched successfully from API', tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeCalendarByFinancialYear', tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by financial year',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      try {
        AppLogger.info('Loading mock trade calendar', tag: 'TradeRemoteDataSource');
        return await TradeMockDataHelper.getMockTradeCalendar();
      } catch (mockError) {
        AppLogger.error('Failed to load mock data', tag: 'TradeRemoteDataSource', error: mockError);
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendar(String userId, String portfolioId, {int? year, int? month}) async {
    // Legacy method - delegates to getTradeCalendarByMonth
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    return getTradeCalendarByMonth(userId, portfolioId, year: targetYear, month: targetMonth);
  }
}

