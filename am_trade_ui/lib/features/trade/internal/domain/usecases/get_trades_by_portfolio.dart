import 'package:am_common/core/utils/logger.dart';
import '../entities/trade_controller_entities.dart';
import '../repositories/trade_controller_repository.dart';

/// Use case for getting trades by portfolio
class GetTradesByPortfolio {
  const GetTradesByPortfolio(this._repository);
  
  final TradeControllerRepository _repository;

  /// Execute the use case to get trades for a specific portfolio
  /// 
  /// [portfolioId] - The portfolio ID
  /// [symbols] - Optional list of symbols to filter by
  /// Returns a list of [TradeDetails]
  Future<List<TradeDetails>> call({
    required String portfolioId,
    List<String>? symbols,
  }) async {
    AppLogger.methodEntry(
      'GetTradesByPortfolio.call',
      tag: 'GetTradesByPortfolio',
      params: {'portfolioId': portfolioId, 'symbols': symbols},
    );

    if (portfolioId.isEmpty) {
      AppLogger.error('Validation failed - empty portfolioId', tag: 'GetTradesByPortfolio');
      throw ArgumentError('Portfolio ID cannot be empty');
    }

    try {
      AppLogger.info('Executing get trades by portfolio use case', tag: 'GetTradesByPortfolio');

      final result = await _repository.getTradeDetailsByPortfolioAndSymbols(
        portfolioId: portfolioId,
        symbols: symbols,
      );

      AppLogger.info(
        'Trades fetched successfully - count: ${result.length}',
        tag: 'GetTradesByPortfolio',
      );
      AppLogger.methodExit('GetTradesByPortfolio.call', tag: 'GetTradesByPortfolio', result: 'success');

      return result;
    } catch (e) {
      AppLogger.error(
        'Get trades by portfolio use case failed',
        tag: 'GetTradesByPortfolio',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('GetTradesByPortfolio.call', tag: 'GetTradesByPortfolio', result: 'error');
      rethrow;
    }
  }

  /// Watch trades for real-time updates
  /// 
  /// [portfolioId] - The portfolio ID
  /// Returns a stream of [TradeDetails] lists
  Stream<List<TradeDetails>> watch(String portfolioId) {
    AppLogger.methodEntry(
      'GetTradesByPortfolio.watch',
      tag: 'GetTradesByPortfolio',
      params: {'portfolioId': portfolioId},
    );

    if (portfolioId.isEmpty) {
      AppLogger.error('Validation failed - empty portfolioId', tag: 'GetTradesByPortfolio');
      throw ArgumentError('Portfolio ID cannot be empty');
    }

    return _repository.watchTradeDetailsByPortfolio(portfolioId);
  }
}
