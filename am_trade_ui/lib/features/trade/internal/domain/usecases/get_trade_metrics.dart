import '../entities/metrics/metrics_filter_request.dart';
import '../entities/metrics/trade_metrics_response.dart';
import '../repositories/trade_metrics_repository.dart';

class GetTradeMetrics {
  final TradeMetricsRepository repository;

  GetTradeMetrics(this.repository);

  Future<TradeMetricsResponse> call(MetricsFilterRequest filter) {
    return repository.getMetrics(filter);
  }
}
