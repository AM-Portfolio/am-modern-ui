import '../entities/trade_holding.dart';
import '../repositories/trade_repository.dart';
import 'package:am_common/am_common.dart';

/// Use case for getting trade holdings
class GetTradeHoldings {
  const GetTradeHoldings(this._repository);
  final TradeRepository _repository;

  /// Execute the use case
  Future<TradeHoldings> call(String portfolioId) async {
    AppLogger.methodEntry('GetTradeHoldings.call', tag: 'GetTradeHoldings', params: {'portfolioId': portfolioId});

    if (portfolioId.isEmpty) {
      AppLogger.error('Portfolio ID validation failed - empty portfolioId', tag: 'GetTradeHoldings');
      throw ArgumentError('Portfolio ID cannot be empty');
    }

    try {
      AppLogger.info('Executing get trade holdings use case', tag: 'GetTradeHoldings');

      final result = await _repository.getTradeHoldings(portfolioId);

      AppLogger.info('Trade holdings use case completed successfully', tag: 'GetTradeHoldings');
      AppLogger.methodExit('GetTradeHoldings.call', tag: 'GetTradeHoldings', result: 'success');

      return result;
    } catch (e) {
      AppLogger.error('Trade holdings use case failed', tag: 'GetTradeHoldings', error: e, stackTrace: StackTrace.current);
      AppLogger.methodExit('GetTradeHoldings.call', tag: 'GetTradeHoldings', result: 'error');
      rethrow;
    }
  }

  /// Execute with stream for real-time updates
  Stream<TradeHoldings> watch(String portfolioId) {
    AppLogger.methodEntry('GetTradeHoldings.watch', tag: 'GetTradeHoldings', params: {'portfolioId': portfolioId});

    if (portfolioId.isEmpty) {
      AppLogger.error('Validation failed for stream', tag: 'GetTradeHoldings');
      throw ArgumentError('Portfolio ID cannot be empty');
    }

    AppLogger.info('Starting trade holdings stream', tag: 'GetTradeHoldings');
    return _repository.watchTradeHoldings(portfolioId);
  }
}
