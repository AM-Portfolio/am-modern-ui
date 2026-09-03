import 'package:flutter/foundation.dart';
import 'package:am_library/am_library.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/am_common.dart';
import '../dtos/trade_calendar_dto.dart';
import '../dtos/trade_controller_dtos.dart';
import '../dtos/trade_holding_dto.dart';
import '../dtos/trade_portfolio_dto.dart';
import '../dtos/trade_portfolio_summary_dto.dart';
import '../domain/enums/trade_directions.dart';
import '../domain/enums/trade_statuses.dart';
import 'trade_mock_data_helper.dart';

/// Abstract data source for trade data
abstract class TradeRemoteDataSource {
  /// Get trade portfolios from remote API
  Future<TradePortfolioListDto> getTradePortfolios();

  /// Get trade holdings from remote API
  Future<TradeHoldingsDto> getTradeHoldings(String portfolioId);

  /// Get trade summary from remote API
  Future<TradePortfolioSummaryDto> getTradeSummary(String portfolioId);

  /// Get trade calendar by month from remote API
  Future<TradeCalendarDto> getTradeCalendarByMonth(
    String portfolioId, {
    required int year,
    required int month,
  });

  /// Get trade calendar by day from remote API
  Future<TradeCalendarDto> getTradeCalendarByDay(String portfolioId,
      {required DateTime date});

  /// Get trade calendar by date range from remote API
  Future<TradeCalendarDto> getTradeCalendarByDateRange(
    String portfolioId, {
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get trade calendar by quarter from remote API
  Future<TradeCalendarDto> getTradeCalendarByQuarter(
    String portfolioId, {
    required int year,
    required int quarter,
  });

  /// Get trade calendar by financial year from remote API
  Future<TradeCalendarDto> getTradeCalendarByFinancialYear(
    String portfolioId, {
    required int financialYear,
  });

  /// Get trade calendar from remote API (legacy - delegates to getTradeCalendarByMonth)
  @Deprecated('Use getTradeCalendarByMonth instead')
  Future<TradeCalendarDto> getTradeCalendar(String portfolioId,
      {int? year, int? month});

  /// Delete trade by ID
  Future<void> deleteTrade(String tradeId);
}

/// Concrete implementation of trade remote data source
class TradeRemoteDataSourceImpl implements TradeRemoteDataSource {
  const TradeRemoteDataSourceImpl({
    required ApiClient apiClient,
    required TradeApiConfig tradeConfig,
    PortfolioApiConfig? portfolioConfig,
  })  : _apiClient = apiClient,
        _tradeConfig = tradeConfig,
        _portfolioConfig = portfolioConfig;

  final ApiClient _apiClient;
  final TradeApiConfig _tradeConfig;
  final PortfolioApiConfig? _portfolioConfig;

  /// Helper to safely build URI avoiding double slashes
  String _buildUri(String baseUrl, String resource) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanResource = resource.startsWith('/') ? resource : '/$resource';
    return '$cleanBase$cleanResource';
  }

  @override
  Future<TradePortfolioListDto> getTradePortfolios() async {
    AppLogger.methodEntry('getTradePortfolios',
        tag: 'TradeRemoteDataSource', params: {});

    try {
      // Trade API: GET /v1/portfolio-summary/by-owner — owner from JWT (UserContext).
      // Do not append userId: /by-owner/{id} is a different fallback endpoint (single summary).
      final fullUri =
          _buildUri(_tradeConfig.baseUrl, _tradeConfig.portfolioListResource);

      final response = await _apiClient.get<TradePortfolioListDto>(
        fullUri,
        parser: (data) {
          if (data is List) {
            return TradePortfolioListDto(
              portfolios: data.map((item) {
                final json = item as Map<String, dynamic>;
                final enriched = Map<String, dynamic>.from(json);
                final metrics = json['metrics'];
                if (metrics is Map<String, dynamic>) {
                  // Only copy non-null values from metrics to avoid overwriting
                  // top-level fields (e.g., totalValue) with explicit nulls.
                  metrics.forEach((key, value) {
                    if (value != null) {
                      enriched[key] = value;
                    }
                  });
                }
                // Map currentCapital → totalValue as a fallback when metrics.totalValue was null
                if (enriched['totalValue'] == null &&
                    enriched['currentCapital'] != null) {
                  enriched['totalValue'] = enriched['currentCapital'];
                }
                return TradePortfolioDto.fromJson(enriched);
              }).toList(),
              totalCount: data.length,
            );
          }
          return TradePortfolioListDto.fromJson(data! as Map<String, dynamic>);
        },
      );

      AppLogger.info('Trade portfolios fetched successfully from API',
          tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradePortfolios',
          tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade portfolios',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      if (kDebugMode) {
        try {
          AppLogger.info('Loading mock trade portfolios',
              tag: 'TradeRemoteDataSource');
          return await TradeMockDataHelper.getMockTradePortfolios();
        } catch (mockError) {
          AppLogger.error('Failed to load mock data',
              tag: 'TradeRemoteDataSource', error: mockError);
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<TradeHoldingsDto> getTradeHoldings(String portfolioId) async {
    AppLogger.methodEntry(
      'getTradeHoldings',
      tag: 'TradeRemoteDataSource',
      params: {'portfolioId': portfolioId},
    );

    try {
      // Trade API Spec: GET /v1/trades/details/portfolio/{portfolioId} returns List<TradeDetails>
      final baseUri =
          _buildUri(_tradeConfig.baseUrl, _tradeConfig.holdingsResource);
      final fullUri = '$baseUri/$portfolioId';

      final response = await _apiClient.get<TradeHoldingsDto>(
        fullUri,
        parser: (data) {
          if (data is List) {
            final list = data
                .map((item) =>
                    TradeDetailsDto.fromJson(item as Map<String, dynamic>))
                .toList();
            return TradeHoldingsDto(
                content: list,
                totalElements: list.length,
                totalPages: 1,
                last: true,
                first: true,
                size: list.isNotEmpty ? list.length : 50,
                numberOfElements: list.length,
                empty: list.isEmpty,
                pageable: const PageableDto(
                    pageNumber: 0, pageSize: 50, paged: false, unpaged: true));
          }
          return TradeHoldingsDto.fromJson(data! as Map<String, dynamic>);
        },
      );

      // Demo / broker portfolios often have holdings in am-portfolio but no
      // trade-execution rows. Fall back so Trade → Holdings stays in sync.
      if (response.empty || response.content.isEmpty) {
        final fromPortfolio = await _holdingsFromPortfolioApi(portfolioId);
        if (fromPortfolio != null && !fromPortfolio.empty) {
          AppLogger.info(
            'Trade holdings empty — using portfolio holdings fallback '
            '(${fromPortfolio.totalElements} rows) for $portfolioId',
            tag: 'TradeRemoteDataSource',
          );
          AppLogger.methodExit('getTradeHoldings',
              tag: 'TradeRemoteDataSource', result: 'success_portfolio_fallback');
          return fromPortfolio;
        }
      }

      AppLogger.info('Trade holdings fetched successfully from API',
          tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeHoldings',
          tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade holdings',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      try {
        final fromPortfolio = await _holdingsFromPortfolioApi(portfolioId);
        if (fromPortfolio != null && !fromPortfolio.empty) {
          AppLogger.info(
            'Trade holdings API failed — using portfolio holdings fallback',
            tag: 'TradeRemoteDataSource',
          );
          return fromPortfolio;
        }
      } catch (_) {}

      if (kDebugMode) {
        try {
          AppLogger.info('Loading mock trade holdings',
              tag: 'TradeRemoteDataSource');
          return await TradeMockDataHelper.getMockTradeHoldings();
        } catch (mockError) {
          AppLogger.error('Failed to load mock data',
              tag: 'TradeRemoteDataSource', error: mockError);
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// GET {portfolioBase}/v1/portfolios/holdings?portfolioId=… and map to trade holdings shape.
  Future<TradeHoldingsDto?> _holdingsFromPortfolioApi(String portfolioId) async {
    final portfolio = _portfolioConfig;
    if (portfolio == null || portfolio.baseUrl.isEmpty) {
      return null;
    }
    final baseUri = _buildUri(portfolio.baseUrl, portfolio.holdingsResource);
    final fullUri = portfolioId.isEmpty || portfolioId == 'all'
        ? baseUri
        : '$baseUri?portfolioId=$portfolioId';

    return _apiClient.get<TradeHoldingsDto>(
      fullUri,
      parser: (data) {
        if (data is! Map) {
          return const TradeHoldingsDto(empty: true);
        }
        final equities = (data['equityHoldings'] as List?) ?? const [];
        final list = <TradeDetailsDto>[];
        for (var i = 0; i < equities.length; i++) {
          final raw = equities[i];
          if (raw is! Map) continue;
          final json = Map<String, dynamic>.from(raw);
          final symbol = (json['symbol'] as String?)?.trim() ?? '';
          if (symbol.isEmpty) continue;
          final qty = _asDouble(json['quantity']);
          final investment = _asDouble(json['investmentCost']);
          final currentValue = _asDouble(json['currentValue']);
          final currentPrice = _asDouble(json['currentPrice']);
          final gainLoss = _asDouble(json['gainLoss']);
          final gainLossPct = _asDouble(json['gainLossPercentage']);
          final avgPrice = qty > 0 ? investment / qty : 0.0;
          final name = (json['name'] as String?)?.trim();
          final isin = (json['isin'] as String?)?.trim();

          list.add(TradeDetailsDto(
            tradeId: 'demo-holding-$portfolioId-$symbol-$i',
            portfolioId: portfolioId,
            symbol: symbol,
            instrumentInfo: InstrumentInfoDto(
              symbol: symbol,
              isin: isin?.isEmpty == true ? null : isin,
              description: (name != null && name.isNotEmpty) ? name : symbol,
            ),
            status: TradeStatuses.open,
            tradePositionType: TradeDirections.long,
            entryInfo: EntryExitInfoDto(
              price: avgPrice,
              quantity: qty.round(),
              totalValue: investment,
            ),
            currentPrice: currentPrice,
            metrics: TradeMetricsDto(
              profitLoss: gainLoss,
              profitLossPercentage: gainLossPct,
            ),
            notes: currentValue > 0 ? 'currentValue=$currentValue' : null,
          ));
        }
        return TradeHoldingsDto(
          content: list,
          totalElements: list.length,
          totalPages: 1,
          last: true,
          first: true,
          size: list.isNotEmpty ? list.length : 50,
          numberOfElements: list.length,
          empty: list.isEmpty,
          pageable: const PageableDto(
              pageNumber: 0, pageSize: 50, paged: false, unpaged: true),
        );
      },
    );
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Future<TradePortfolioSummaryDto> getTradeSummary(String portfolioId) async {
    AppLogger.methodEntry(
      'getTradeSummary',
      tag: 'TradeRemoteDataSource',
      params: {'portfolioId': portfolioId},
    );

    try {
      // Trade API Spec: GET /v1/portfolio-summary/{portfolioId}
      final baseUri = _buildUri(
          _tradeConfig.baseUrl, _tradeConfig.portfolioSummaryResource);
      final fullUri = '$baseUri/$portfolioId';

      final response = await _apiClient.get<TradePortfolioSummaryDto>(
        fullUri,
        parser: (data) =>
            TradePortfolioSummaryDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.info('Trade summary fetched successfully from API',
          tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeSummary',
          tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade summary',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      if (kDebugMode) {
        try {
          AppLogger.info('Loading mock trade summary',
              tag: 'TradeRemoteDataSource');
          return await TradeMockDataHelper.getMockTradeSummary();
        } catch (mockError) {
          AppLogger.error('Failed to load mock data',
              tag: 'TradeRemoteDataSource', error: mockError);
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendarByMonth(
    String portfolioId, {
    required int year,
    required int month,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByMonth',
      tag: 'TradeRemoteDataSource',
      params: {'portfolioId': portfolioId, 'year': year, 'month': month},
    );

    try {
      var resource = _tradeConfig.calendarMonthResource;

      String fullUri;
      if (resource.contains('{portfolioId}')) {
        fullUri =
            '${_buildUri(_tradeConfig.baseUrl, resource.replaceAll('{portfolioId}', portfolioId))}?year=$year&month=$month';
      } else {
        fullUri =
            '${_buildUri(_tradeConfig.baseUrl, resource)}?portfolioId=$portfolioId&year=$year&month=$month';
      }

      AppLogger.info('Fetching calendar for year=$year, month=$month',
          tag: 'TradeRemoteDataSource');

      final response = await _apiClient.get<TradeCalendarDto>(
        fullUri,
        parser: (data) {
          if (data == null) return const TradeCalendarDto(portfolioTrades: {});

          if (data is List) {
            if (data.isEmpty)
              return const TradeCalendarDto(portfolioTrades: {});
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

      AppLogger.info('Trade calendar by month fetched successfully from API',
          tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeCalendarByMonth',
          tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by month',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      if (kDebugMode) {
        try {
          AppLogger.info('Loading mock trade calendar',
              tag: 'TradeRemoteDataSource');
          return await TradeMockDataHelper.getMockTradeCalendar();
        } catch (mockError) {
          AppLogger.error('Failed to load mock data',
              tag: 'TradeRemoteDataSource', error: mockError);
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendarByDay(String portfolioId,
      {required DateTime date}) async {
    AppLogger.methodEntry(
      'getTradeCalendarByDay',
      tag: 'TradeRemoteDataSource',
      params: {'portfolioId': portfolioId, 'date': date.toIso8601String()},
    );

    try {
      // Trade API Spec: GET /v1/trades/calendar/day?date={date}&portfolioId={id}
      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      var resource = _tradeConfig.calendarDayResource;
      String fullUri;
      if (resource.contains('{portfolioId}')) {
        fullUri =
            '${_buildUri(_tradeConfig.baseUrl, resource.replaceAll('{portfolioId}', portfolioId))}?date=$formattedDate';
      } else {
        fullUri =
            '${_buildUri(_tradeConfig.baseUrl, resource)}?date=$formattedDate&portfolioId=$portfolioId';
      }

      AppLogger.info('Fetching calendar for date=$formattedDate',
          tag: 'TradeRemoteDataSource');

      final response = await _apiClient.get<TradeCalendarDto>(
        fullUri,
        parser: (data) {
          if (data == null) return const TradeCalendarDto(portfolioTrades: {});

          if (data is List) {
            if (data.isEmpty)
              return const TradeCalendarDto(portfolioTrades: {});
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

      AppLogger.info('Trade calendar by day fetched successfully from API',
          tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeCalendarByDay',
          tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by day',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      if (kDebugMode) {
        try {
          AppLogger.info('Loading mock trade calendar by day',
              tag: 'TradeRemoteDataSource');
          return await TradeMockDataHelper.getMockTradeCalendarByDay();
        } catch (mockError) {
          AppLogger.error('Failed to load mock data',
              tag: 'TradeRemoteDataSource', error: mockError);
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendarByDateRange(
    String portfolioId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByDateRange',
      tag: 'TradeRemoteDataSource',
      params: {
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
      final fullUri =
          '${_buildUri(_tradeConfig.baseUrl, 'v1/trades/calendar/custom')}?portfolioId=$portfolioId&startDate=$formattedStartDate&endDate=$formattedEndDate&page=0&size=50';

      AppLogger.info(
        'Fetching calendar for date range=$formattedStartDate to $formattedEndDate',
        tag: 'TradeRemoteDataSource',
      );

      final response = await _apiClient.get<TradeCalendarDto>(
        fullUri,
        parser: (data) {
          if (data == null) {
            AppLogger.debug('[DateRange Parser] Received null data',
                tag: 'TradeRemoteDataSource');
            return const TradeCalendarDto(portfolioTrades: {});
          }

          if (data is List) {
            AppLogger.info(
                '[DateRange Parser] Received array with ${data.length} items',
                tag: 'TradeRemoteDataSource');
            if (data.isEmpty)
              return const TradeCalendarDto(portfolioTrades: {});

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

          AppLogger.debug('[DateRange Parser] Received map data',
              tag: 'TradeRemoteDataSource');
          final json = data as Map<String, dynamic>;
          if (json.isEmpty) return const TradeCalendarDto(portfolioTrades: {});
          return TradeCalendarDto.fromJson(json);
        },
      );

      AppLogger.info(
          'Trade calendar by date range fetched successfully from API',
          tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeCalendarByDateRange',
          tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by date range',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      if (kDebugMode) {
        try {
          AppLogger.info('Loading mock trade calendar by date range',
              tag: 'TradeRemoteDataSource');
          return await TradeMockDataHelper.getMockTradeCalendarByDateRange();
        } catch (mockError) {
          AppLogger.error('Failed to load mock data',
              tag: 'TradeRemoteDataSource', error: mockError);
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendarByQuarter(
    String portfolioId, {
    required int year,
    required int quarter,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByQuarter',
      tag: 'TradeRemoteDataSource',
      params: {'portfolioId': portfolioId, 'year': year, 'quarter': quarter},
    );

    try {
      // Trade API Spec: GET /v1/trades/calendar/quarter?portfolioId={id}&year={year}&quarter={quarter}
      var resource = _tradeConfig.calendarQuarterResource;
      String fullUri;
      if (resource.contains('{portfolioId}')) {
        fullUri =
            '${_buildUri(_tradeConfig.baseUrl, resource.replaceAll('{portfolioId}', portfolioId))}?year=$year&quarter=$quarter';
      } else {
        fullUri =
            '${_buildUri(_tradeConfig.baseUrl, resource)}?portfolioId=$portfolioId&year=$year&quarter=$quarter';
      }

      AppLogger.info('Fetching calendar for year=$year, quarter=$quarter',
          tag: 'TradeRemoteDataSource');

      final response = await _apiClient.get<TradeCalendarDto>(
        fullUri,
        parser: (data) {
          if (data == null) return const TradeCalendarDto(portfolioTrades: {});

          if (data is List) {
            if (data.isEmpty)
              return const TradeCalendarDto(portfolioTrades: {});
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

      AppLogger.info('Trade calendar by quarter fetched successfully from API',
          tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeCalendarByQuarter',
          tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by quarter',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      if (kDebugMode) {
        try {
          AppLogger.info('Loading mock trade calendar',
              tag: 'TradeRemoteDataSource');
          return await TradeMockDataHelper.getMockTradeCalendar();
        } catch (mockError) {
          AppLogger.error('Failed to load mock data',
              tag: 'TradeRemoteDataSource', error: mockError);
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendarByFinancialYear(
    String portfolioId, {
    required int financialYear,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByFinancialYear',
      tag: 'TradeRemoteDataSource',
      params: {'portfolioId': portfolioId, 'financialYear': financialYear},
    );

    try {
      // Trade API Spec: GET /v1/trades/calendar/financial-year?portfolioId={id}&financialYear={year}
      var resource = _tradeConfig.calendarFinancialYearResource;
      String fullUri;
      if (resource.contains('{portfolioId}')) {
        fullUri =
            '${_buildUri(_tradeConfig.baseUrl, resource.replaceAll('{portfolioId}', portfolioId))}?financialYear=$financialYear';
      } else {
        fullUri =
            '${_buildUri(_tradeConfig.baseUrl, resource)}?portfolioId=$portfolioId&financialYear=$financialYear';
      }

      AppLogger.info('Fetching calendar for financial year=$financialYear',
          tag: 'TradeRemoteDataSource');

      final response = await _apiClient.get<TradeCalendarDto>(
        fullUri,
        parser: (data) {
          if (data == null) return const TradeCalendarDto(portfolioTrades: {});

          if (data is List) {
            if (data.isEmpty)
              return const TradeCalendarDto(portfolioTrades: {});
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

      AppLogger.info(
          'Trade calendar by financial year fetched successfully from API',
          tag: 'TradeRemoteDataSource');
      AppLogger.methodExit('getTradeCalendarByFinancialYear',
          tag: 'TradeRemoteDataSource', result: 'success');

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by financial year',
        tag: 'TradeRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      if (kDebugMode) {
        try {
          AppLogger.info('Loading mock trade calendar',
              tag: 'TradeRemoteDataSource');
          return await TradeMockDataHelper.getMockTradeCalendar();
        } catch (mockError) {
          AppLogger.error('Failed to load mock data',
              tag: 'TradeRemoteDataSource', error: mockError);
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<TradeCalendarDto> getTradeCalendar(String portfolioId,
      {int? year, int? month}) async {
    // Legacy method - delegates to getTradeCalendarByMonth
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    return getTradeCalendarByMonth(portfolioId,
        year: targetYear, month: targetMonth);
  }

  @override
  Future<void> deleteTrade(String tradeId) async {
    AppLogger.methodEntry('deleteTrade',
        tag: 'TradeRemoteDataSource', params: {'tradeId': tradeId});

    try {
      final baseUri = _buildUri(_tradeConfig.baseUrl, '/details/$tradeId');
      await _apiClient.delete<void>(
        baseUri,
        parser: (_) {}, // No content expected
      );
      AppLogger.info('Trade deleted successfully',
          tag: 'TradeRemoteDataSource');
    } catch (e) {
      AppLogger.error('Failed to delete trade',
          tag: 'TradeRemoteDataSource', error: e);
      rethrow;
    }
  }
}
