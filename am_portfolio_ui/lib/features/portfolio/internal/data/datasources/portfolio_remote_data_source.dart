import 'package:am_design_system/am_design_system.dart';
import 'package:am_library/am_library.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/am_common.dart';
import 'package:am_portfolio_ui/core/constants/portfolio_endpoints.dart';
import '../dtos/portfolio_analytics_request_dto.dart';
import '../dtos/portfolio_analytics_response_dto.dart';
import '../dtos/portfolio_holdings_dto.dart';
import '../dtos/portfolio_list_dto.dart';
import '../dtos/portfolio_summary_dto.dart';
import '../mappers/portfolio_analytics_mapper.dart';
import '../mappers/portfolio_mapper.dart';
import 'portfolio_mock_data_helper.dart';

/// Abstract data source for portfolio data
abstract class PortfolioRemoteDataSource {
  /// Get portfolio holdings from remote API (legacy - uses default portfolio)
  Future<PortfolioHoldingsDto> getPortfolioHoldings(String userId);

  /// Get portfolio holdings from remote API for specific portfolio
  Future<PortfolioHoldingsDto> getPortfolioHoldingsById(
    String userId,
    String portfolioId,
  );

  /// Get portfolio summary from remote API (legacy - uses default portfolio)
  Future<PortfolioSummaryDto> getPortfolioSummary(String userId);

  /// Get portfolio summary from remote API for specific portfolio
  Future<PortfolioSummaryDto> getPortfolioSummaryById(
    String userId,
    String portfolioId,
  );

  /// Get portfolio analytics from remote API
  Future<PortfolioAnalyticsResponseDto> getPortfolioAnalytics(
    String portfolioId,
    PortfolioAnalyticsRequestDto request,
  );

  /// Get portfolios list from remote API
  Future<PortfolioListDto> getPortfoliosList(String userId);
}

/// Concrete implementation of portfolio remote data source
///
/// Handles API calls for portfolio operations following clean architecture principles
class PortfolioRemoteDataSourceImpl implements PortfolioRemoteDataSource {
  const PortfolioRemoteDataSourceImpl({
    required ApiClient apiClient,
    bool useMockData = false,
  }) : _apiClient = apiClient,
       _useMockData = useMockData;

  final ApiClient _apiClient;
  final bool _useMockData;


  // Use localized endpoints
  String get _baseUrl => PortfolioEndpoints.baseUrl;

  /// Helper to safely build URI avoiding double slashes
  String _buildUri(String baseUrl, String resource) {
    // Ensure baseUrl is clean
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    // Ensure resource starts with /
    var cleanResource = resource.startsWith('/') ? resource : '/$resource';

    return '$cleanBase$cleanResource';
  }

  @override
  Future<PortfolioHoldingsDto> getPortfolioHoldings(String userId) async {
    // Standardize to production user ID
    final effectiveUserId = userId;

    CommonLogger.methodEntry(
      'getPortfolioHoldings',
      tag: 'PortfolioRemoteDataSource',
      metadata: {'userId': effectiveUserId, 'originalUserId': userId},
    );

    try {
      CommonLogger.debug(
        'API request prepared for portfolio holdings with userId query param',
        tag: 'PortfolioRemoteDataSource',
      );

      // Construct full URI from portfolio config with userId query parameter
      final baseUri = _buildUri(_baseUrl, PortfolioEndpoints.holdings);
      final fullUri = '$baseUri?userId=$effectiveUserId';

      // Use ApiClient for consistent error handling and logging
      final holdingsResponse = await _apiClient.get<PortfolioHoldingsDto>(
        fullUri,
        parser: (data) => PortfolioMapper.portfolioHoldingsFromJson(
          data! as Map<String, dynamic>,
        ),
      );

      CommonLogger.info(
        'Portfolio holdings fetched successfully from API',
        tag: 'PortfolioRemoteDataSource',
      );
      CommonLogger.methodExit(
        'getPortfolioHoldings',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'success'},
      );

      return holdingsResponse;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolio holdings',
        tag: 'PortfolioRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioHoldings',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'error'},
      );

      // Fallback to mock data when API is unavailable
      if (!_useMockData) {
        rethrow;
      }
      try {
        CommonLogger.info(
          'Loading mock portfolio holdings',
          tag: 'PortfolioRemoteDataSource',
        );
        return await PortfolioMockDataHelper.getMockPortfolioHoldings();
      } catch (mockError) {
        CommonLogger.error(
          'Failed to load mock data',
          tag: 'PortfolioRemoteDataSource',
          error: mockError,
        );
        rethrow;
      }
    }
  }

  @override
  Future<PortfolioHoldingsDto> getPortfolioHoldingsById(
    String userId,
    String portfolioId,
  ) async {
    // Standardize to production user ID
    final effectiveUserId = userId;

    CommonLogger.methodEntry(
      'getPortfolioHoldingsById',
      tag: 'PortfolioRemoteDataSource',
      metadata: {
        'userId': effectiveUserId,
        'originalUserId': userId,
        'portfolioId': portfolioId,
      },
    );

    try {
      CommonLogger.debug(
        'API request prepared for portfolio holdings with userId and portfolioId query params',
        tag: 'PortfolioRemoteDataSource',
      );

      // Construct full URI from portfolio config with userId and portfolioId query parameters
      final baseUri = _buildUri(_baseUrl, PortfolioEndpoints.holdings);
      final fullUri =
          '$baseUri?userId=$effectiveUserId&portfolioId=$portfolioId';

      // Use ApiClient for consistent error handling and logging
      final holdingsResponse = await _apiClient.get<PortfolioHoldingsDto>(
        fullUri,
        parser: (data) => PortfolioMapper.portfolioHoldingsFromJson(
          data! as Map<String, dynamic>,
        ),
      );

      CommonLogger.info(
        'Portfolio holdings fetched successfully from API',
        tag: 'PortfolioRemoteDataSource',
      );
      CommonLogger.methodExit(
        'getPortfolioHoldingsById',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'success'},
      );

      return holdingsResponse;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolio holdings by ID from API. Attempting mock fallback.',
        tag: 'PortfolioRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );

      if (e is TypeError) {
        CommonLogger.error(
          'Parsing error in portfolio response. Check if DTO fields match API JSON.',
          tag: 'PortfolioRemoteDataSource',
          error: e,
        );
        // Log the raw data keys to help identify the missing or wrong type field
        try {
          final baseUri = _buildUri(_baseUrl, PortfolioEndpoints.holdings);
          final fullUri = '$baseUri?userId=$userId&portfolioId=$portfolioId';
          CommonLogger.debug(
            'Failed JSON structure keys: ${e.toString()}',
            tag: 'PortfolioRemoteDataSource',
          );
        } catch (_) {}
      }
      CommonLogger.methodExit(
        'getPortfolioHoldingsById',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'error'},
      );

      // Fallback to mock data when API is unavailable
      if (!_useMockData) {
        rethrow;
      }
      try {
        CommonLogger.info(
          'Loading mock portfolio holdings',
          tag: 'PortfolioRemoteDataSource',
        );
        return await PortfolioMockDataHelper.getMockPortfolioHoldings();
      } catch (mockError) {
        CommonLogger.error(
          'Failed to load mock data',
          tag: 'PortfolioRemoteDataSource',
          error: mockError,
        );
        rethrow;
      }
    }
  }

  @override
  Future<PortfolioSummaryDto> getPortfolioSummary(String userId) async {
    // Standardize to production user ID
    final effectiveUserId = userId;

    CommonLogger.methodEntry(
      'getPortfolioSummary',
      tag: 'PortfolioRemoteDataSource',
      metadata: {'userId': effectiveUserId, 'originalUserId': userId},
    );

    try {
      CommonLogger.debug(
        'API request prepared for portfolio summary with userId query param',
        tag: 'PortfolioRemoteDataSource',
      );

      // Construct full URI from portfolio config with userId query parameter
      final baseUri = _buildUri(_baseUrl, PortfolioEndpoints.summary);
      final fullUri = '$baseUri?userId=$effectiveUserId';

      // Use ApiClient for consistent error handling and logging
      final summaryResponse = await _apiClient.get<PortfolioSummaryDto>(
        fullUri,
        parser: (data) => PortfolioMapper.portfolioSummaryFromJson(
          data! as Map<String, dynamic>,
        ),
      );

      CommonLogger.info(
        'Portfolio summary fetched successfully from API',
        tag: 'PortfolioRemoteDataSource',
      );
      CommonLogger.methodExit(
        'getPortfolioSummary',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'success'},
      );

      return summaryResponse;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolio summary',
        tag: 'PortfolioRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioSummary',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'error'},
      );

      // Fallback to mock data when API is unavailable
      if (!_useMockData) {
        rethrow;
      }
      try {
        CommonLogger.info(
          'Loading mock portfolio summary',
          tag: 'PortfolioRemoteDataSource',
        );
        return await PortfolioMockDataHelper.getMockPortfolioSummary();
      } catch (mockError) {
        CommonLogger.error(
          'Failed to load mock data',
          tag: 'PortfolioRemoteDataSource',
          error: mockError,
        );
        rethrow;
      }
    }
  }

  @override
  Future<PortfolioSummaryDto> getPortfolioSummaryById(
    String userId,
    String portfolioId,
  ) async {
    // Standardize to production user ID
    final effectiveUserId = userId;

    CommonLogger.methodEntry(
      'getPortfolioSummaryById',
      tag: 'PortfolioRemoteDataSource',
      metadata: {
        'userId': effectiveUserId,
        'originalUserId': userId,
        'portfolioId': portfolioId,
      },
    );

    try {
      CommonLogger.debug(
        'API request prepared for portfolio summary with userId and portfolioId query params',
        tag: 'PortfolioRemoteDataSource',
      );

      // Construct full URI from portfolio config with userId and portfolioId query parameters
      final baseUri = _buildUri(_baseUrl, PortfolioEndpoints.summary);
      final fullUri =
          '$baseUri?userId=$effectiveUserId&portfolioId=$portfolioId';

      // Use ApiClient for consistent error handling and logging
      final summaryResponse = await _apiClient.get<PortfolioSummaryDto>(
        fullUri,
        parser: (data) => PortfolioMapper.portfolioSummaryFromJson(
          data! as Map<String, dynamic>,
        ),
      );

      CommonLogger.info(
        'Portfolio summary fetched successfully from API',
        tag: 'PortfolioRemoteDataSource',
      );
      CommonLogger.methodExit(
        'getPortfolioSummaryById',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'success'},
      );

      return summaryResponse;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolio summary by ID',
        tag: 'PortfolioRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioSummaryById',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'error'},
      );

      // Fallback to mock data when API is unavailable
      if (!_useMockData) {
        rethrow;
      }
      try {
        CommonLogger.info(
          'Loading mock portfolio summary',
          tag: 'PortfolioRemoteDataSource',
        );
        return await PortfolioMockDataHelper.getMockPortfolioSummary();
      } catch (mockError) {
        CommonLogger.error(
          'Failed to load mock data',
          tag: 'PortfolioRemoteDataSource',
          error: mockError,
        );
        rethrow;
      }
    }
  }

  @override
  Future<PortfolioAnalyticsResponseDto> getPortfolioAnalytics(
    String portfolioId,
    PortfolioAnalyticsRequestDto request,
  ) async {
    CommonLogger.methodEntry(
      'getPortfolioAnalytics',
      tag: 'PortfolioRemoteDataSource',
      metadata: {'portfolioId': portfolioId},
    );

    try {
      CommonLogger.debug(
        'API request prepared for portfolio analytics',
        tag: 'PortfolioRemoteDataSource',
      );

      // Construct full URI for analytics endpoint
      final baseUri = _buildUri(
        _baseUrl,
        PortfolioEndpoints.advancedAnalytics(portfolioId),
      );

      // Use ApiClient for consistent error handling and logging with POST request
      final analyticsResponse = await _apiClient.post<PortfolioAnalyticsResponseDto>(
        baseUri,
        body: request.toJson(),
        parser: (data) {
          final rawData = data! as Map<String, dynamic>;

          // Log raw API response for debugging
          CommonLogger.debug(
            '🔍 Raw API response keys: ${rawData.keys.toList()}',
            tag: 'PortfolioRemoteDataSource',
          );

          // Check if sectorAllocation exists in raw response
          if (rawData.containsKey('analytics')) {
            final analytics = rawData['analytics'] as Map<String, dynamic>?;
            if (analytics?.containsKey('sectorAllocation') == true) {
              final sectorAllocation =
                  analytics!['sectorAllocation'] as Map<String, dynamic>?;
              CommonLogger.debug(
                '🔍 Raw sectorAllocation keys: ${sectorAllocation?.keys.toList()}',
                tag: 'PortfolioRemoteDataSource',
              );
              if (sectorAllocation?.containsKey('sectorWeights') == true) {
                final sectorWeights = sectorAllocation!['sectorWeights'];
                CommonLogger.debug(
                  '🔍 Raw sectorWeights type: ${sectorWeights.runtimeType}, content: $sectorWeights',
                  tag: 'PortfolioRemoteDataSource',
                );
              } else {
                CommonLogger.debug(
                  '🔍 sectorWeights field is missing from raw sectorAllocation',
                  tag: 'PortfolioRemoteDataSource',
                );
              }
            } else {
              CommonLogger.debug(
                '🔍 sectorAllocation field is missing from raw analytics',
                tag: 'PortfolioRemoteDataSource',
              );
            }
          } else {
            CommonLogger.debug(
              '🔍 analytics field is missing from raw response',
              tag: 'PortfolioRemoteDataSource',
            );
          }

          try {
            return PortfolioAnalyticsMapper.responseFromJson(rawData);
          } catch (e) {
            CommonLogger.error(
              '🔍 PortfolioAnalyticsMapper.responseFromJson failed - Raw data: ${rawData.toString()}',
              tag: 'PortfolioRemoteDataSource',
              error: e,
              stackTrace: StackTrace.current,
            );
            rethrow;
          }
        },
      );

      CommonLogger.info(
        'Portfolio analytics fetched successfully from API for $portfolioId',
        tag: 'PortfolioRemoteDataSource',
      );
      CommonLogger.methodExit(
        'getPortfolioAnalytics',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'success'},
      );

      return analyticsResponse;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolio analytics',
        tag: 'PortfolioRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioAnalytics',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'error'},
      );

      // Fallback to mock data when API is unavailable
      if (!_useMockData) {
        rethrow;
      }
      try {
        CommonLogger.info(
          'Loading mock portfolio analytics',
          tag: 'PortfolioRemoteDataSource',
        );
        return await PortfolioMockDataHelper.getMockPortfolioAnalytics();
      } catch (mockError) {
        CommonLogger.error(
          'Failed to load mock data',
          tag: 'PortfolioRemoteDataSource',
          error: mockError,
        );
        rethrow;
      }
    }
  }

  @override
  Future<PortfolioListDto> getPortfoliosList(String userId) async {
    // Standardize to production user ID
    final effectiveUserId = userId;

    CommonLogger.methodEntry(
      'getPortfoliosList',
      tag: 'PortfolioRemoteDataSource',
      metadata: {'userId': effectiveUserId, 'originalUserId': userId},
    );

    try {
      CommonLogger.debug(
        'API request prepared for portfolios list with userId query param',
        tag: 'PortfolioRemoteDataSource',
      );

      // Construct full URI from portfolio config with userId query parameter
      // Use the trade configuration for this endpoint as it is hosted on the Trade service
      // The Trade service expects a path parameter: /v1/portfolio-summary/by-owner/{userId}
      final tradeBaseUrl = const String.fromEnvironment('AM_TRADE_BASE_URL', defaultValue: 'https://am.asrax.in/trade');
      final resourcePath = '/v1/portfolio-summary/by-owner';
      final fullUri = '${_buildUri(tradeBaseUrl, resourcePath)}/$effectiveUserId';

      // Use ApiClient for consistent error handling and logging
      final listResponse = await _apiClient.get<PortfolioListDto>(
        fullUri,
        parser: (data) {
          // Defensive parsing: Handle both List and String responses
          if (data == null) {
            CommonLogger.warning(
              'Portfolio list response is null, returning empty list',
              tag: 'PortfolioRemoteDataSource',
            );
            return PortfolioListDto(portfolios: []);
          }

          // If backend returns a string (error message), log it and return empty list
          if (data is String) {
            CommonLogger.warning(
              'Portfolio list API returned a String instead of List: "$data"',
              tag: 'PortfolioRemoteDataSource',
            );
            // Return empty portfolio list instead of crashing
            return PortfolioListDto(portfolios: []);
          }

          // If it's a Map (unexpected but possible), check if it contains an error message
          if (data is Map<String, dynamic>) {
            if (data.containsKey('error') || data.containsKey('message')) {
              final errorMsg = data['error'] ?? data['message'];
              CommonLogger.warning(
                'Portfolio list API returned error message: "$errorMsg"',
                tag: 'PortfolioRemoteDataSource',
              );
              return PortfolioListDto(portfolios: []);
            }
          }

          // Normal case: data is a List
          if (data is! List) {
            CommonLogger.error(
              'Portfolio list API returned unexpected type: ${data.runtimeType}',
              tag: 'PortfolioRemoteDataSource',
            );
            return PortfolioListDto(portfolios: []);
          }

          return PortfolioMapper.portfolioListFromJson(data as List<dynamic>);
        },
      );

      CommonLogger.info(
        'Portfolios list fetched successfully from API (${listResponse.portfolios.length} portfolios)',
        tag: 'PortfolioRemoteDataSource',
      );
      CommonLogger.methodExit(
        'getPortfoliosList',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'success'},
      );

      return listResponse;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolios list',
        tag: 'PortfolioRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfoliosList',
        tag: 'PortfolioRemoteDataSource',
        metadata: {'status': 'error'},
      );

      // Fallback to mock data when API is unavailable
      if (!_useMockData) {
        rethrow;
      }
      try {
        CommonLogger.info(
          'Loading mock portfolios list',
          tag: 'PortfolioRemoteDataSource',
        );
        return await PortfolioMockDataHelper.getMockPortfolioList();
      } catch (mockError) {
        CommonLogger.error(
          'Failed to load mock data',
          tag: 'PortfolioRemoteDataSource',
          error: mockError,
        );
        rethrow;
      }
    }
  }
}
