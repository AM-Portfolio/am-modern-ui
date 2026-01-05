import '../entities/metrics/metrics_filter_request.dart';
import '../entities/report/timing_analysis.dart';
import '../repositories/trade_report_repository.dart';

class GetTimingAnalysisUseCase {
  final TradeReportRepository _repository;

  GetTimingAnalysisUseCase(this._repository);

  Future<TimingAnalysis> call(MetricsFilterRequest filter) {
    return _repository.getTimingAnalysis(filter);
  }
}
