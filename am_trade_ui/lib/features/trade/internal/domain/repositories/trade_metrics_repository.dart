import '../entities/metrics/metrics_filter_request.dart';
import '../entities/metrics/trade_metrics_response.dart';
import '../enums/metric_types.dart';

abstract class TradeMetricsRepository {
  Future<TradeMetricsResponse> getMetrics(MetricsFilterRequest filter);
  Future<List<MetricTypes>> getMetricTypes();
}
