import 'package:am_analysis_client/api.dart' as sdk;
import 'package:logger/logger.dart';
import '../models/analysis_models.dart';
import '../models/analysis_enums.dart';
import '../services/analysis_service.dart';
import '../config/analysis_config.dart';
import '../mappers/analysis_mapper.dart';

/// Real implementation of AnalysisService using the generated SDK
class RealAnalysisService implements AnalysisService {
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
  String get _auth => _authToken ?? 'Bearer mock-token-for-testing';

  @override
  Future<List<AllocationItem>> getAllocation(
    String? id,
    AnalysisEntityType type, {
    GroupBy? groupBy,
  }) async {
    try {
      _logger.i('Fetching allocation for $type:$id with groupBy=$groupBy');
      
      // Call SDK method - send groupBy only as header, not as query param
      final response = await _api.getAllocation(
        _auth,
        type.name.toLowerCase(),  // Convert to lowercase for API
        id ?? '',
        groupBy: groupBy?.value,  // Sent as header by SDK
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
      
      final response = await _api.getPerformance(
        _auth,
        type.name.toLowerCase(),  // Convert to lowercase for API
        id ?? '',
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
      
      final response = id != null
          ? await _api.getTopMoversByEntity(
              _auth,
              type!.name.toLowerCase(),  // Convert to lowercase for API
              id,
              timeFrame: timeFrame,
              groupBy: groupBy?.value,  // Sent as header by SDK
            )
          : await _api.getTopMoversByCategory(
              _auth,
              type!.name.toLowerCase(),  // Convert to lowercase for API
              timeFrame: timeFrame,
              groupBy: groupBy?.value,  // Sent as header by SDK
            );

      _logger.d('Top movers response: ${response?.gainers?.length ?? 0} gainers, ${response?.losers?.length ?? 0} losers');
      
      return AnalysisMapper.toMoverItems(response);
    } catch (e, stackTrace) {
      _logger.e('Error fetching top movers', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
