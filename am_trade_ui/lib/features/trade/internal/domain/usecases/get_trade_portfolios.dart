import '../entities/trade_portfolio.dart';
import '../repositories/trade_repository.dart';
import 'package:am_common/am_common.dart';

/// Use case for getting trade portfolios
class GetTradePortfolios {
  const GetTradePortfolios(this._repository);
  final TradeRepository _repository;

  /// Execute the use case
  Future<TradePortfolioList> call(String userId) async {
    AppLogger.methodEntry(
      'GetTradePortfolios.call',
      tag: 'GetTradePortfolios',
      params: {'userId': userId},
    );

    if (userId.isEmpty) {
      AppLogger.error(
        'User ID validation failed - empty userId',
        tag: 'GetTradePortfolios',
      );
      throw ArgumentError('User ID cannot be empty');
    }

    try {
      AppLogger.info(
        'Executing get trade portfolios use case',
        tag: 'GetTradePortfolios',
      );

      final result = await _repository.getTradePortfolios(userId);

      AppLogger.info(
        'Trade portfolios use case completed successfully',
        tag: 'GetTradePortfolios',
      );
      AppLogger.methodExit(
        'GetTradePortfolios.call',
        tag: 'GetTradePortfolios',
        result: 'success',
      );

      return result;
    } catch (e) {
      AppLogger.error(
        'Trade portfolios use case failed',
        tag: 'GetTradePortfolios',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit(
        'GetTradePortfolios.call',
        tag: 'GetTradePortfolios',
        result: 'error',
      );
      rethrow;
    }
  }

  /// Execute with stream for real-time updates
  Stream<TradePortfolioList> watch(String userId) {
    AppLogger.methodEntry(
      'GetTradePortfolios.watch',
      tag: 'GetTradePortfolios',
      params: {'userId': userId},
    );

    if (userId.isEmpty) {
      AppLogger.error(
        'Validation failed for stream',
        tag: 'GetTradePortfolios',
      );
      throw ArgumentError('User ID cannot be empty');
    }

    AppLogger.info(
      'Starting trade portfolios stream',
      tag: 'GetTradePortfolios',
    );
    return _repository.watchTradePortfolios(userId);
  }
}

