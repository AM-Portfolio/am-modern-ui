import 'dart:convert';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_trade_ui/core/constants/trade_endpoints.dart';

import 'package:am_library/am_library.dart';
import 'package:am_common/am_common.dart';
import '../dtos/metrics_filter_config_dto.dart';
import '../dtos/trade_controller_dtos.dart';

/// Remote data source for Trade Controller API
/// Handles all HTTP requests related to trade details management
abstract class TradeControllerRemoteDataSource {
  /// GET /v1/trades/details/portfolio/{portfolioId}
  /// Get trade details by portfolio ID and optional symbols
  Future<List<TradeDetailsDto>> getTradeDetailsByPortfolioAndSymbols({
    required String portfolioId,
    List<String>? symbols,
  });

  /// POST /v1/trades/details
  /// Add a new trade
  Future<TradeDetailsDto> addTrade(TradeDetailsDto tradeDetails);

  /// PUT /v1/trades/details/{tradeId}
  /// Update an existing trade
  Future<TradeDetailsDto> updateTrade({required String tradeId, required TradeDetailsDto tradeDetails});

  /// DELETE /v1/trades/details/{tradeId}
  /// Delete a trade by ID
  Future<void> deleteTrade(String tradeId);

  /// GET /v1/trades/filter
  /// Filter trades by multiple criteria with pagination
  Future<PaginatedTradeResponseDto> getTradesByFilters({
    List<String>? portfolioIds,
    List<String>? symbols,
    List<String>? statuses,
    String? startDate,
    String? endDate,
    List<String>? strategies,
    int page = 0,
    int size = 20,
    String? sort,
  });

  /// POST /v1/trades/details/batch
  /// Add or update multiple trades in batch
  Future<List<TradeDetailsDto>> addOrUpdateTrades(List<TradeDetailsDto> trades);

  /// POST /v1/trades/details/by-ids
  /// Get trade details by trade IDs
  Future<List<TradeDetailsDto>> getTradeDetailsByTradeIds(List<String> tradeIds);

  /// POST /v1/trades/details/filter
  /// Filter trade details using favorite filter configuration
  Future<FilterTradeDetailsResponseDto> filterTradeDetails({
    required String userId,
    String? favoriteFilterId,
    MetricsFilterConfigDto? metricsConfig,
    int page = 0,
    int size = 20,
    String? sort,
  });
}

/// Implementation of TradeControllerRemoteDataSource
class TradeControllerRemoteDataSourceImpl implements TradeControllerRemoteDataSource {
  TradeControllerRemoteDataSourceImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;
  
  /// Use ConfigService baseUrl if configured, fall back to the constant
  String get _baseUrl {
    try {
      final configUrl = ConfigService.config.api.trade.baseUrl;
      return configUrl.isNotEmpty ? configUrl : TradeEndpoints.tradeBaseUrl;
    } catch (_) {
      return TradeEndpoints.tradeBaseUrl;
    }
  }

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
  Future<List<TradeDetailsDto>> getTradeDetailsByPortfolioAndSymbols({
    required String portfolioId,
    List<String>? symbols,
  }) async {
    AppLogger.methodEntry(
      'getTradeDetailsByPortfolioAndSymbols',
      tag: 'TradeControllerRemoteDataSource',
      params: {'portfolioId': portfolioId, 'symbols': symbols},
    );

    try {
      final baseUri = _buildUri(_baseUrl, TradeEndpoints.detailsByPortfolio);
      var fullUri = '$baseUri/$portfolioId';

      if (symbols != null && symbols.isNotEmpty) {
        final symbolsParam = symbols.map((s) => 'symbols=$s').join('&');
        fullUri = '$fullUri?$symbolsParam';
      }

      final response = await _apiClient.get<List<TradeDetailsDto>>(
        fullUri,
        parser: (data) {
          if (data is List) {
            return data.map((json) => TradeDetailsDto.fromJson(json as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      AppLogger.methodExit('getTradeDetailsByPortfolioAndSymbols', tag: 'TradeControllerRemoteDataSource');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to get trade details by portfolio',
        tag: 'TradeControllerRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<TradeDetailsDto> addTrade(TradeDetailsDto tradeDetails) async {
    AppLogger.methodEntry('addTrade', tag: 'TradeControllerRemoteDataSource');

    try {
      final fullUri = _buildUri(_baseUrl, TradeEndpoints.details);

      // Log a summary first (single line) - use DTO properties directly to avoid casting issues
      AppLogger.info(
        '📋 Payload Summary: portfolioId=${tradeDetails.portfolioId}, symbol=${tradeDetails.instrumentInfo.symbol}, tradeType=${tradeDetails.tradePositionType}, userId=${tradeDetails.userId}',
        tag: 'TradeControllerRemoteDataSource',
      );

      // Convert to JSON for API call
      final jsonPayload = tradeDetails.toJson();

      // Log the complete JSON payload for debugging (pretty printed, multi-line)
      final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonPayload);

      // Single-line JSON for easy copy-paste to Postman
      final singleLineJson = jsonEncode(jsonPayload);

      // Use print for complete output without truncation
      print('════════════════════════════════════════════════════════════════');
      print('📤 COMPLETE JSON PAYLOAD FOR POSTMAN (SINGLE LINE):');
      print('════════════════════════════════════════════════════════════════');

      // Split single-line JSON into chunks of 800 characters to avoid truncation
      const chunkSize = 800;
      for (var i = 0; i < singleLineJson.length; i += chunkSize) {
        final end = (i + chunkSize < singleLineJson.length) ? i + chunkSize : singleLineJson.length;
        print(singleLineJson.substring(i, end));
      }

      print('════════════════════════════════════════════════════════════════');
      print('📋 Endpoint: POST $fullUri');
      print('📋 Content-Type: application/json');
      print('📋 JSON Length: ${singleLineJson.length} characters');
      print('════════════════════════════════════════════════════════════════');

      AppLogger.debug('📤 POST Request Payload (Complete JSON):\n$prettyJson', tag: 'TradeControllerRemoteDataSource');

      final response = await _apiClient.post<TradeDetailsDto>(
        fullUri,
        body: jsonPayload,
        parser: (data) => TradeDetailsDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.methodExit('addTrade', tag: 'TradeControllerRemoteDataSource');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to add trade',
        tag: 'TradeControllerRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<TradeDetailsDto> updateTrade({required String tradeId, required TradeDetailsDto tradeDetails}) async {
    AppLogger.methodEntry('updateTrade', tag: 'TradeControllerRemoteDataSource', params: {'tradeId': tradeId});

    try {
      final baseUri = _buildUri(_baseUrl, TradeEndpoints.details);
      final fullUri = '$baseUri/$tradeId';

      final response = await _apiClient.put<TradeDetailsDto>(
        fullUri,
        body: tradeDetails.toJson(),
        parser: (data) => TradeDetailsDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.methodExit('updateTrade', tag: 'TradeControllerRemoteDataSource');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to update trade',
        tag: 'TradeControllerRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteTrade(String tradeId) async {
    AppLogger.methodEntry('deleteTrade', tag: 'TradeControllerRemoteDataSource', params: {'tradeId': tradeId});

    try {
      final baseUri = _buildUri(_baseUrl, TradeEndpoints.details);
      final fullUri = '$baseUri/$tradeId';

      await _apiClient.delete<void>(fullUri, parser: (_) {});

      AppLogger.info('Trade deleted successfully - tradeId: $tradeId', tag: 'TradeControllerRemoteDataSource');
      AppLogger.methodExit('deleteTrade', tag: 'TradeControllerRemoteDataSource');
    } catch (e) {
      AppLogger.error(
        'Failed to delete trade',
        tag: 'TradeControllerRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<PaginatedTradeResponseDto> getTradesByFilters({
    List<String>? portfolioIds,
    List<String>? symbols,
    List<String>? statuses,
    String? startDate,
    String? endDate,
    List<String>? strategies,
    int page = 0,
    int size = 20,
    String? sort,
  }) async {
    AppLogger.methodEntry('getTradesByFilters', tag: 'TradeControllerRemoteDataSource');

    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('size=$size');

      if (portfolioIds != null && portfolioIds.isNotEmpty) {
        queryParams.addAll(portfolioIds.map((id) => 'portfolioIds=$id'));
      }
      if (symbols != null && symbols.isNotEmpty) {
        queryParams.addAll(symbols.map((s) => 'symbols=$s'));
      }
      if (statuses != null && statuses.isNotEmpty) {
        queryParams.addAll(statuses.map((s) => 'statuses=$s'));
      }
      if (startDate != null) {
        queryParams.add('startDate=$startDate');
      }
      if (endDate != null) {
        queryParams.add('endDate=$endDate');
      }
      if (strategies != null && strategies.isNotEmpty) {
        queryParams.addAll(strategies.map((s) => 'strategies=$s'));
      }
      if (sort != null) {
        queryParams.add('sort=$sort');
      }

      final baseUri = _buildUri(_baseUrl, TradeEndpoints.filter);
      final fullUri = '$baseUri?${queryParams.join('&')}';

      final response = await _apiClient.get<PaginatedTradeResponseDto>(
        fullUri,
        parser: (data) => PaginatedTradeResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.methodExit('getTradesByFilters', tag: 'TradeControllerRemoteDataSource');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to get trades by filters',
        tag: 'TradeControllerRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<TradeDetailsDto>> addOrUpdateTrades(List<TradeDetailsDto> trades) async {
    AppLogger.methodEntry(
      'addOrUpdateTrades',
      tag: 'TradeControllerRemoteDataSource',
      params: {'count': trades.length},
    );

    try {
      final fullUri = _buildUri(_baseUrl, TradeEndpoints.detailsBatch);

      final response = await _apiClient.post<List<TradeDetailsDto>>(
        fullUri,
        body: trades.map((trade) => trade.toJson()).toList(),
        parser: (data) {
          if (data is List) {
            return data.map((json) => TradeDetailsDto.fromJson(json as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      AppLogger.methodExit('addOrUpdateTrades', tag: 'TradeControllerRemoteDataSource');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to add or update trades',
        tag: 'TradeControllerRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<TradeDetailsDto>> getTradeDetailsByTradeIds(List<String> tradeIds) async {
    AppLogger.methodEntry(
      'getTradeDetailsByTradeIds',
      tag: 'TradeControllerRemoteDataSource',
      params: {'count': tradeIds.length},
    );

    try {
      final fullUri = _buildUri(_baseUrl, TradeEndpoints.detailsByIds);

      final response = await _apiClient.post<List<TradeDetailsDto>>(
        fullUri,
        body: tradeIds,
        parser: (data) {
          if (data is List) {
            return data.map((json) => TradeDetailsDto.fromJson(json as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      AppLogger.methodExit('getTradeDetailsByTradeIds', tag: 'TradeControllerRemoteDataSource');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to get trade details by IDs',
        tag: 'TradeControllerRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<FilterTradeDetailsResponseDto> filterTradeDetails({
    required String userId,
    String? favoriteFilterId,
    MetricsFilterConfigDto? metricsConfig,
    int page = 0,
    int size = 20,
    String? sort,
  }) async {
    AppLogger.methodEntry('filterTradeDetails', tag: 'TradeControllerRemoteDataSource', params: {'userId': userId});

    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('size=$size');
      if (sort != null) {
        queryParams.add('sort=$sort');
      }

      final baseUri = _buildUri(_baseUrl, TradeEndpoints.detailsFilter);
      final fullUri = '$baseUri?${queryParams.join('&')}';

      final requestData = FilterTradeDetailsRequestDto(
        userId: userId,
        favoriteFilterId: favoriteFilterId,
        metricsConfig: metricsConfig,
      );

      final response = await _apiClient.post<FilterTradeDetailsResponseDto>(
        fullUri,
        body: requestData.toJson(),
        parser: (data) => FilterTradeDetailsResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      AppLogger.methodExit('filterTradeDetails', tag: 'TradeControllerRemoteDataSource');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to filter trade details',
        tag: 'TradeControllerRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}

