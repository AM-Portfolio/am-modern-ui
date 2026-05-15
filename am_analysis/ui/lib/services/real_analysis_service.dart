import 'package:am_analysis_sdk/api.dart' as sdk;
import 'package:logger/logger.dart';
import 'package:am_analysis_core/am_analysis_core.dart';
import '../services/analysis_service.dart';
import '../config/analysis_config.dart';
import '../mappers/analysis_mapper.dart';
import 'package:am_common/am_common.dart';

/// Real implementation of UiAnalysisService using the generated SDK
class RealAnalysisService implements UiAnalysisService {
  final sdk.AnalysisControllerApi _api;
  final Logger _logger = Logger();
  final String? _authToken;

  RealAnalysisService({
    String? baseUrl,
    String? authToken,
  })  : _authToken = authToken,
        _api = sdk.AnalysisControllerApi(
          sdk.ApiClient(
            basePath: baseUrl ?? AnalysisConfig.instance.baseUrl,
          ),
        );

  /// Get authorization header value
  Future<String> get _auth async {
    if (_authToken != null) return _authToken!;
    
    final token = await SecureStorageService().getAccessToken();
    if (token == null || token.isEmpty) {
      _logger.w('No auth token found.');
      // Token missing, user should be routed to login
      throw Exception('Authentication required. Token is missing.');
    }
    return 'Bearer $token';
  }

  /// Extract userId from token
  Future<String> get _userId async {
    final token = await SecureStorageService().getAccessToken();
    if (token == null) return '';
    return TokenExtractor.extractUserId(token);
  }

  @override
  Future<List<AllocationItem>> getAllocation(
    String? id,
    AnalysisEntityType type, {
    GroupBy? groupBy,
  }) async {
    try {
      _logger.i('Fetching allocation for $type:$id with groupBy=$groupBy');
      
      final authHeader = await _auth;
      final userId = await _userId;
      
      // Call SDK method - send groupBy only as header, not as query param
      final response = await _api.getAllocation(
        authHeader,
        type.name.toLowerCase(),  // Convert to lowercase for API
        id ?? userId,
        groupBy: groupBy?.name,  // Sent as header by SDK
        // Don't send groupBy2 to avoid duplication
      );

      _logger.d('Allocation response: ${response?.sectors?.length ?? 0} items');
      
      // Map response to UI models based on groupBy
      return AnalysisMapper.toAllocationItems(response, groupBy ?? GroupBy.sector);
    } catch (e, stackTrace) {
      _logger.e('Error fetching allocation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<PerformanceDataPoint>> getPerformance(
    String? id,
    AnalysisEntityType type,
    String timeFrame,
  ) async {
    try {
      _logger.i('Fetching performance for $type:$id with timeFrame=$timeFrame');
      
      final authHeader = await _auth;
      final userId = await _userId;
      
      final response = await _api.getPerformance(
        authHeader,
        type.name.toLowerCase(),  // Convert to lowercase for API
        id ?? userId,
        timeFrame: timeFrame,
      );

      _logger.d('Performance response: ${response?.chartData?.length ?? 0} data points');
      
      return AnalysisMapper.toPerformanceDataPoints(response);
    } catch (e, stackTrace) {
      _logger.e('Error fetching performance', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<MoverItem>> getTopMovers({
    String? id,
    AnalysisEntityType? type,
    String? timeFrame,
    GroupBy? groupBy,
  }) async {
    try {
      _logger.i('Fetching top movers for ${type?.name}:$id with timeFrame=$timeFrame, groupBy=$groupBy');
      
      final authHeader = await _auth;
      final userId = await _userId;
      final entityId = id ?? userId;
      
      final response = entityId.isNotEmpty
          ? await _api.getTopMoversByEntity(
              authHeader,
              type!.name.toLowerCase(),  // Convert to lowercase for API
              entityId,
              timeFrame: timeFrame,
              groupBy: groupBy?.name,  // Sent as header by SDK
            )
          : await _api.getTopMoversByCategory(
              authHeader,
              type!.name.toLowerCase(),  // Convert to lowercase for API
              timeFrame: timeFrame,
              groupBy: groupBy?.name,  // Sent as header by SDK
            );

      _logger.d('Top movers response: ${response?.gainers?.length ?? 0} gainers, ${response?.losers?.length ?? 0} losers');
      
      return AnalysisMapper.toMoverItems(response);
    } catch (e, stackTrace) {
      _logger.e('Error fetching top movers', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
