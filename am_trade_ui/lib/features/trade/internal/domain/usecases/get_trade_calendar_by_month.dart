import 'package:am_common/core/utils/logger.dart';
import '../entities/trade_calendar.dart';
import '../repositories/trade_repository.dart';

/// Use case for getting trade calendar by month
class GetTradeCalendarByMonth {
  const GetTradeCalendarByMonth(this._repository);
  final TradeRepository _repository;

  /// Execute the use case to get trade calendar for a specific portfolio by month
  Future<TradeCalendar> call(String userId, String portfolioId, {required int year, required int month}) async {
    AppLogger.methodEntry(
      'GetTradeCalendarByMonth.call',
      tag: 'GetTradeCalendarByMonth',
      params: {'userId': userId, 'portfolioId': portfolioId, 'year': year, 'month': month},
    );

    if (userId.isEmpty || portfolioId.isEmpty) {
      AppLogger.error('Validation failed - empty userId or portfolioId', tag: 'GetTradeCalendarByMonth');
      throw ArgumentError('User ID and Portfolio ID cannot be empty');
    }

    if (month < 1 || month > 12) {
      AppLogger.error('Validation failed - invalid month value: $month', tag: 'GetTradeCalendarByMonth');
      throw ArgumentError('Month must be between 1 and 12');
    }

    try {
      AppLogger.info('Executing get trade calendar by month use case', tag: 'GetTradeCalendarByMonth');

      final result = await _repository.getTradeCalendarByMonth(userId, portfolioId, year: year, month: month);

      AppLogger.info('Trade calendar by month use case completed successfully', tag: 'GetTradeCalendarByMonth');
      AppLogger.methodExit('GetTradeCalendarByMonth.call', tag: 'GetTradeCalendarByMonth', result: 'success');

      return result;
    } catch (e) {
      AppLogger.error(
        'Trade calendar by month use case failed',
        tag: 'GetTradeCalendarByMonth',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('GetTradeCalendarByMonth.call', tag: 'GetTradeCalendarByMonth', result: 'error');
      rethrow;
    }
  }
}
