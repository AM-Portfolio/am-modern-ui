import '../entities/metrics/metrics_filter_request.dart';
import '../entities/report/daily_performance.dart';
import '../repositories/trade_report_repository.dart';

class GetDailyPerformanceUseCase {
  final TradeReportRepository _repository;

  GetDailyPerformanceUseCase(this._repository);

  Future<List<DailyPerformance>> call(MetricsFilterRequest filter) {
    return _repository.getDailyPerformance(filter);
  }
}
