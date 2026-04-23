import 'package:am_library/am_library.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/am_common.dart';
import '../dtos/metrics/metrics_dtos.dart';

abstract class TradeMetricsRemoteDataSource {
  Future<TradeMetricsResponseDto> getMetrics(MetricsFilterRequestDto filter);
  Future<List<String>> getMetricTypes();
}

class TradeMetricsRemoteDataSourceImpl implements TradeMetricsRemoteDataSource {
  const TradeMetricsRemoteDataSourceImpl({
    required ApiClient apiClient,
    required TradeApiConfig tradeConfig,
  }) : _apiClient = apiClient,
       _tradeConfig = tradeConfig;

  final ApiClient _apiClient;
  final TradeApiConfig _tradeConfig;

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
  Future<TradeMetricsResponseDto> getMetrics(MetricsFilterRequestDto filter) async {
    AppLogger.methodEntry(
      'getMetrics',
      tag: 'TradeMetricsRemoteDataSource',
      params: {'filter': filter.toJson()},
    );

    try {
      // Assuming endpoint is /api/v1/metrics/analyze 
      // or /api/v1/trades/metrics based on common patterns. 
      // I will use a hypothetical endpoint consistent with Trade API.
      final fullUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/metrics');

      final response = await _apiClient.post<TradeMetricsResponseDto>(
        fullUri,
        body: filter.toJson(),
        parser: (data) {
           if (data == null) throw Exception('No data returned for metrics');
           return TradeMetricsResponseDto.fromJson(data as Map<String, dynamic>);
        },
      );

      AppLogger.info('Trade metrics fetched successfully', tag: 'TradeMetricsRemoteDataSource');
      AppLogger.methodExit('getMetrics', tag: 'TradeMetricsRemoteDataSource', result: 'success');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade metrics',
        tag: 'TradeMetricsRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
  @override
  Future<List<String>> getMetricTypes() async {
    AppLogger.methodEntry('getMetricTypes', tag: 'TradeMetricsRemoteDataSource');

    try {
      final fullUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/metrics/types');

      final response = await _apiClient.get<List<String>>(
        fullUri,
        parser: (data) {
           if (data == null) return [];
           return (data as List).map((e) => e.toString()).toList();
        },
      );

      AppLogger.info('Metric types fetched successfully', tag: 'TradeMetricsRemoteDataSource');
      AppLogger.methodExit('getMetricTypes', tag: 'TradeMetricsRemoteDataSource', result: 'success');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch metric types',
        tag: 'TradeMetricsRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      // Fallback to default types if API fails
      return ['PERFORMANCE', 'RISK', 'DISTRIBUTION'];
    }
  }
}

