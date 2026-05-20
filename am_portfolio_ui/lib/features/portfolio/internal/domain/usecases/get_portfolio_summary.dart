import 'package:am_design_system/am_design_system.dart';
import '../entities/portfolio_summary.dart';
import '../repositories/portfolio_repository.dart';
import 'package:am_common/am_common.dart';

/// Use case for getting portfolio summary
class GetPortfolioSummary {
  const GetPortfolioSummary(this._repository);
  final PortfolioRepository _repository;

  /// Execute the use case
  Future<PortfolioSummary> call(String portfolioId) async {
    CommonLogger.methodEntry(
      'GetPortfolioSummary.call',
      tag: 'GetPortfolioSummary',
      metadata: {'portfolioId': portfolioId},
    );
    return _repository.getPortfolioSummaryById(portfolioId);
  }

  /// Get portfolio summary for specific portfolio
  Future<PortfolioSummary> callForPortfolio(
    String portfolioId,
  ) async => call(portfolioId);

  /// Execute with stream for real-time updates
  Stream<PortfolioSummary> watchSummary() {
    

    return _repository.watchPortfolioSummary();
  }
}
