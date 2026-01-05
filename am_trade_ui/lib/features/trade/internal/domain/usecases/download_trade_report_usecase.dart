import '../entities/metrics/metrics_filter_request.dart';
import '../repositories/trade_report_repository.dart';

class DownloadTradeReportUseCase {
  final TradeReportRepository _repository;

  DownloadTradeReportUseCase(this._repository);

  Future<void> call(MetricsFilterRequest filter) {
    return _repository.downloadReport(filter);
  }
}
