import 'package:am_common/core/utils/logger.dart';
import '../entities/trade_calendar.dart';
import '../repositories/trade_repository.dart';

/// Use case for getting trade calendar
class GetTradeCalendar {
  const GetTradeCalendar(this._repository);
  final TradeRepository _repository;

  /// Execute the use case to get trade calendar for a specific portfolio
  Future<TradeCalendar> call(String userId, String portfolioId, {int? year, int? month}) async {
    AppLogger.methodEntry(
      'GetTradeCalendar.call',
      tag: 'GetTradeCalendar',
      params: {'userId': userId, 'portfolioId': portfolioId, 'year': year, 'month': month},
    );

    if (userId.isEmpty || portfolioId.isEmpty) {
      AppLogger.error('Validation failed - empty userId or portfolioId', tag: 'GetTradeCalendar');
      throw ArgumentError('User ID and Portfolio ID cannot be empty');
    }

    try {
      AppLogger.info('Executing get trade calendar use case', tag: 'GetTradeCalendar');

      final result = await _repository.getTradeCalendar(userId, portfolioId, year: year, month: month);

      AppLogger.info('Trade calendar use case completed successfully', tag: 'GetTradeCalendar');
      AppLogger.methodExit('GetTradeCalendar.call', tag: 'GetTradeCalendar', result: 'success');

      return result;
    } catch (e) {
      AppLogger.error(
        'Trade calendar use case failed',
        tag: 'GetTradeCalendar',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('GetTradeCalendar.call', tag: 'GetTradeCalendar', result: 'error');
      rethrow;
    }
  }

  /// Execute with stream for real-time updates
  Stream<TradeCalendar> watch(String userId, String portfolioId) {
    AppLogger.methodEntry(
      'GetTradeCalendar.watch',
      tag: 'GetTradeCalendar',
      params: {'userId': userId, 'portfolioId': portfolioId},
    );

    if (userId.isEmpty || portfolioId.isEmpty) {
      AppLogger.error('Validation failed for stream', tag: 'GetTradeCalendar');
      throw ArgumentError('User ID and Portfolio ID cannot be empty');
    }

    AppLogger.info('Starting trade calendar stream', tag: 'GetTradeCalendar');
    return _repository.watchTradeCalendar(userId, portfolioId);
  }
}
