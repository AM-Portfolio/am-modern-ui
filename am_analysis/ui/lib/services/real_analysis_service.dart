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

  // Static cache to share across instances
  static String? _cachedAuthToken;
  static String? _cachedUserId;

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
    // 1. Check instance override
    if (_authToken != null) return _authToken!;
    
    final token = await SecureStorageService().getAccessToken();
    if (token == null || token.isEmpty) {
      _cachedAuthToken = null;
      _logger.w('No auth token found.');
      throw Exception('Authentication required. Token is missing.');
    }

    final bearerToken = 'Bearer $token';
    
    // 2. Check static cache and update if changed
    if (_cachedAuthToken != bearerToken) {
      _logger.d('Auth token changed or cache stale. Updating cached token.');
      _cachedAuthToken = bearerToken;
    }

    return _cachedAuthToken!;
  }

  /// Extract userId from token
  Future<String> get _userId async {
    final token = await SecureStorageService().getAccessToken();
    if (token == null) {
      _cachedUserId = null;
      return '';
    }
    
    // Safety check: if token changed, invalidating cached userId
    final derivedUserId = TokenExtractor.extractUserId(token);
    if (_cachedUserId != derivedUserId) {
      _logger.d('User ID changed or cache stale. Updating cached userId.');
      _cachedUserId = derivedUserId;
    }
    
    return _cachedUserId!;
  }

  /// Clear the static cache (useful for logout)
  static void clearCache() {
    _cachedAuthToken = null;
    _cachedUserId = null;
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
      
      // Call SDK method - maintain original parameter mapping
      final response = await _api.getAllocation(
        authHeader,
        type.name.toLowerCase(),
        id ?? userId,
        groupBy: groupBy?.name,
      );

      _logger.d('Allocation response: ${response?.sectors?.length ?? 0} items');
      
      // Map response to UI models based on groupBy
      return AnalysisMapper.toAllocationItems(response, groupBy ?? GroupBy.sector);
    } catch (e, stackTrace) {
      if (e is sdk.ApiException) {
        _logger.e('Allocation Error [${e.code}]: ${e.message}');
      }
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
        type.name.toLowerCase(),
        id ?? userId,
        timeFrame: timeFrame,
      );

      _logger.d('Performance response: ${response?.chartData?.length ?? 0} data points');
      
      return AnalysisMapper.toPerformanceDataPoints(response);
    } catch (e, stackTrace) {
      _logger.e('Error fetching performance: $e', error: e, stackTrace: stackTrace);
      if (e is sdk.ApiException) {
        _logger.e('API Error: ${e.code} - ${e.message}');
      }
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
              type!.name.toLowerCase(),
              entityId,
              timeFrame: timeFrame,
              groupBy: groupBy?.name,
            )
          : await _api.getTopMoversByCategory(
              authHeader,
              type!.name.toLowerCase(),
              timeFrame: timeFrame,
              groupBy: groupBy?.name,
            );

      _logger.d('Top movers response: ${response?.gainers?.length ?? 0} gainers');
      return AnalysisMapper.toMoverItems(response);
    } catch (e, stackTrace) {
      _logger.e('Error fetching top movers: $e', error: e, stackTrace: stackTrace);
      if (e is sdk.ApiException) {
        _logger.e('API Error: ${e.code} - ${e.message}');
      }
      rethrow;
    }
  }
}
