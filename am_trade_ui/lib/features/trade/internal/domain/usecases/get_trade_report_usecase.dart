import '../entities/metrics/metrics_filter_request.dart';
import '../entities/trade_report.dart';
import '../repositories/trade_report_repository.dart';

class GetTradeReportUseCase {
  final TradeReportRepository _repository;

  GetTradeReportUseCase(this._repository);

  Future<TradeReport> call(MetricsFilterRequest filter) {
    return _repository.getReport(filter);
  }
}
