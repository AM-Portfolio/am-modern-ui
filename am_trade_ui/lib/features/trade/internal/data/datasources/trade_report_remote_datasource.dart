import 'package:am_library/am_library.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import '../dtos/metrics/metrics_dtos.dart';
import '../dtos/report/trade_performance_summary_dto.dart';
import '../dtos/report/daily_performance_dto.dart';
import '../dtos/report/timing_analysis_dto.dart';

class TradeReportRemoteDataSource {
  final ApiClient _client;
  final TradeApiConfig _tradeConfig;

  TradeReportRemoteDataSource(this._client, this._tradeConfig);

  String _buildUri(String baseUrl, String resource) {
    var cleanBase = baseUrl;
    if (cleanBase.endsWith('/')) {
      cleanBase = cleanBase.substring(0, cleanBase.length - 1);
    }
    
    var cleanResource = resource;
    if (cleanResource.startsWith('/')) {
      cleanResource = cleanResource.substring(1); 
    }
    // Ensure cleanResource starts with / to append to cleanBase
    cleanResource = '/$cleanResource';

    return '$cleanBase$cleanResource';
  }

  /// Get comprehensive trade performance summary
  Future<TradePerformanceSummaryDto> getSummary(MetricsFilterRequestDto filter) async {
    final queryParams = {
      if (filter.portfolioIds != null && filter.portfolioIds!.isNotEmpty) 'portfolioId': filter.portfolioIds!.first,
      'startDate': filter.dateRange.startDate.toIso8601String().split('T')[0], 
      'endDate': filter.dateRange.endDate.toIso8601String().split('T')[0], 
    };

    final fullUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/performance/summary');

    return _client.get(
      fullUri,
      queryParams: queryParams,
      parser: (data) => TradePerformanceSummaryDto.fromJson(data),
    );
  }

  /// Get daily performance breakdown
  Future<List<DailyPerformanceDto>> getDaily(MetricsFilterRequestDto filter) async {
    final queryParams = {
      if (filter.portfolioIds != null && filter.portfolioIds!.isNotEmpty) 'portfolioId': filter.portfolioIds!.first,
      'limit': '1000', 
    };

    final fullUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/performance/daily');

    return _client.get(
      fullUri,
      queryParams: queryParams,
      // API returns a List, parser handles dynamic data
      parser: (data) => (data as List).map((e) => DailyPerformanceDto.fromJson(e)).toList(),
    );
  }

  /// Get timing analysis
  Future<TimingAnalysisDto> getTiming(MetricsFilterRequestDto filter) async {
    final queryParams = {
      if (filter.portfolioIds != null && filter.portfolioIds!.isNotEmpty) 'portfolioId': filter.portfolioIds!.first,
    };

    final fullUri = _buildUri(_tradeConfig.baseUrl, 'api/v1/performance/timing');

    return _client.get(
      fullUri,
      queryParams: queryParams,
      parser: (data) => TimingAnalysisDto.fromJson(data),
    );
  }
}
