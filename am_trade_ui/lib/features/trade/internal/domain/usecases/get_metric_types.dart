import '../repositories/trade_metrics_repository.dart';
import '../enums/metric_types.dart';

class GetMetricTypes {
  final TradeMetricsRepository repository;

  GetMetricTypes(this.repository);

  Future<List<MetricTypes>> call() async {
    return await repository.getMetricTypes();
  }
}
