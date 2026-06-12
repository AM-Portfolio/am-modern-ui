import 'package:am_design_system/am_design_system.dart';
import '../entities/portfolio_holding.dart';
import '../repositories/portfolio_repository.dart';
import 'package:am_common/am_common.dart';

/// Use case for getting portfolio holdings
class GetPortfolioHoldings {
  const GetPortfolioHoldings(this._repository);
  final PortfolioRepository _repository;

  /// Execute the use case
  Future<PortfolioHoldings> call(String portfolioId) async {
    CommonLogger.methodEntry(
      'GetPortfolioHoldings.call',
      tag: 'GetPortfolioHoldings',
      metadata: {'portfolioId': portfolioId},
    );
    return _repository.getPortfolioHoldingsById(portfolioId);
  }

  /// Get portfolio holdings for specific portfolio
  Future<PortfolioHoldings> callForPortfolio(
    String portfolioId,
  ) async => call(portfolioId);

  /// Gets cached portfolio holdings directly (synchronous return via future)
  Future<PortfolioHoldings?> getCached(String portfolioId) async {
    return _repository.getCachedPortfolioHoldingsById(portfolioId);
  }

  /// Execute with stream for real-time updates
  Stream<PortfolioHoldings> watchHoldings() {
    CommonLogger.methodEntry(
      'GetPortfolioHoldings.watchHoldings',
      tag: 'GetPortfolioHoldings',
      metadata: {},
    );

    

    CommonLogger.info(
      'Starting portfolio holdings stream',
      tag: 'GetPortfolioHoldings',
    );
    return _repository.watchPortfolioHoldings();
  }
}
