import '../entities/trade_portfolio.dart';
import '../repositories/trade_repository.dart';
import 'package:am_common/am_common.dart';

/// Use case for getting trade portfolios
class GetTradePortfolios {
  const GetTradePortfolios(this._repository);
  final TradeRepository _repository;

  /// Execute the use case
  Future<TradePortfolioList> call() async {
    AppLogger.methodEntry('GetTradePortfolios.call', tag: 'GetTradePortfolios');

    try {
      AppLogger.info('Executing get trade portfolios use case', tag: 'GetTradePortfolios');

      final result = await _repository.getTradePortfolios();

      AppLogger.info('Trade portfolios use case completed successfully', tag: 'GetTradePortfolios');
      AppLogger.methodExit('GetTradePortfolios.call', tag: 'GetTradePortfolios', result: 'success');

      return result;
    } catch (e) {
      AppLogger.error('Trade portfolios use case failed', tag: 'GetTradePortfolios', error: e, stackTrace: StackTrace.current);
      AppLogger.methodExit('GetTradePortfolios.call', tag: 'GetTradePortfolios', result: 'error');
      rethrow;
    }
  }

  /// Execute with stream for real-time updates
  Stream<TradePortfolioList> watch() {
    AppLogger.methodEntry('GetTradePortfolios.watch', tag: 'GetTradePortfolios');
    AppLogger.info('Starting trade portfolios stream', tag: 'GetTradePortfolios');
    return _repository.watchTradePortfolios();
  }
}
