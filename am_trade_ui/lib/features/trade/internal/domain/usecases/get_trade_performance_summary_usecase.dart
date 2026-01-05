import '../entities/metrics/metrics_filter_request.dart';
import '../entities/report/trade_performance_summary.dart';
import '../repositories/trade_report_repository.dart';

class GetTradePerformanceSummaryUseCase {
  final TradeReportRepository _repository;

  GetTradePerformanceSummaryUseCase(this._repository);

  Future<TradePerformanceSummary> call(MetricsFilterRequest filter) {
    return _repository.getPerformanceSummary(filter);
  }
}
