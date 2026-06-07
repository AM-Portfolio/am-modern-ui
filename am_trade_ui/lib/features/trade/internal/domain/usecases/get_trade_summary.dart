import '../entities/trade_summary.dart';
import '../repositories/trade_repository.dart';
import 'package:am_common/am_common.dart';

/// Use case for getting trade summary
class GetTradeSummary {
  const GetTradeSummary(this._repository);
  final TradeRepository _repository;

  /// Execute the use case
  Future<TradeSummary> call(String portfolioId) async {
    AppLogger.methodEntry(
      'GetTradeSummary.call',
      tag: 'GetTradeSummary',
      params: {},
    );

    if (portfolioId.isEmpty) {
      AppLogger.error(
        'Validation failed - empty userId or portfolioId',
        tag: 'GetTradeSummary',
      );
      throw ArgumentError('Portfolio ID cannot be empty');
    }

    try {
      AppLogger.info(
        'Executing get trade summary use case',
        tag: 'GetTradeSummary',
      );

      final result = await _repository.getTradeSummary(portfolioId);

      AppLogger.info(
        'Trade summary use case completed successfully',
        tag: 'GetTradeSummary',
      );
      AppLogger.methodExit(
        'GetTradeSummary.call',
        tag: 'GetTradeSummary',
        result: 'success',
      );

      return result;
    } catch (e) {
      AppLogger.error(
        'Trade summary use case failed',
        tag: 'GetTradeSummary',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit(
        'GetTradeSummary.call',
        tag: 'GetTradeSummary',
        result: 'error',
      );
      rethrow;
    }
  }

  /// Execute with stream for real-time updates
  Stream<TradeSummary> watch(String portfolioId) {
    AppLogger.methodEntry(
      'GetTradeSummary.watch',
      tag: 'GetTradeSummary',
      params: {},
    );

    if (portfolioId.isEmpty) {
      AppLogger.error(
        'Validation failed for stream',
        tag: 'GetTradeSummary',
      );
      throw ArgumentError('Portfolio ID cannot be empty');
    }

    AppLogger.info(
      'Starting trade summary stream',
      tag: 'GetTradeSummary',
    );
    return _repository.watchTradeSummary(portfolioId);
  }
}

