import 'package:am_common/core/utils/logger.dart';
import '../entities/trade_calendar.dart';
import '../repositories/trade_repository.dart';

/// Use case for getting trade calendar by day
class GetTradeCalendarByDay {
  const GetTradeCalendarByDay(this._repository);
  final TradeRepository _repository;

  /// Execute the use case to get trade calendar for a specific portfolio by day
  Future<TradeCalendar> call(String userId, String portfolioId, {required DateTime date}) async {
    AppLogger.methodEntry(
      'GetTradeCalendarByDay.call',
      tag: 'GetTradeCalendarByDay',
      params: {'userId': userId, 'portfolioId': portfolioId, 'date': date.toIso8601String()},
    );

    if (userId.isEmpty || portfolioId.isEmpty) {
      AppLogger.error('Validation failed - empty userId or portfolioId', tag: 'GetTradeCalendarByDay');
      throw ArgumentError('User ID and Portfolio ID cannot be empty');
    }

    try {
      AppLogger.info('Executing get trade calendar by day use case', tag: 'GetTradeCalendarByDay');

      final result = await _repository.getTradeCalendarByDay(userId, portfolioId, date: date);

      AppLogger.info('Trade calendar by day use case completed successfully', tag: 'GetTradeCalendarByDay');
      AppLogger.methodExit('GetTradeCalendarByDay.call', tag: 'GetTradeCalendarByDay', result: 'success');

      return result;
    } catch (e) {
      AppLogger.error(
        'Trade calendar by day use case failed',
        tag: 'GetTradeCalendarByDay',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('GetTradeCalendarByDay.call', tag: 'GetTradeCalendarByDay', result: 'error');
      rethrow;
    }
  }
}
