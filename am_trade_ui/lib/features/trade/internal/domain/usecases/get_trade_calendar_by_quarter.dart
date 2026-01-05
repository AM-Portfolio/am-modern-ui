import 'package:am_common/core/utils/logger.dart';
import '../entities/trade_calendar.dart';
import '../repositories/trade_repository.dart';

/// Use case for getting trade calendar by quarter
class GetTradeCalendarByQuarter {
  const GetTradeCalendarByQuarter(this._repository);
  final TradeRepository _repository;

  /// Execute the use case to get trade calendar for a specific portfolio by quarter
  Future<TradeCalendar> call(String userId, String portfolioId, {required int year, required int quarter}) async {
    AppLogger.methodEntry(
      'GetTradeCalendarByQuarter.call',
      tag: 'GetTradeCalendarByQuarter',
      params: {'userId': userId, 'portfolioId': portfolioId, 'year': year, 'quarter': quarter},
    );

    if (userId.isEmpty || portfolioId.isEmpty) {
      AppLogger.error('Validation failed - empty userId or portfolioId', tag: 'GetTradeCalendarByQuarter');
      throw ArgumentError('User ID and Portfolio ID cannot be empty');
    }

    if (quarter < 1 || quarter > 4) {
      AppLogger.error('Validation failed - invalid quarter value: $quarter', tag: 'GetTradeCalendarByQuarter');
      throw ArgumentError('Quarter must be between 1 and 4');
    }

    try {
      AppLogger.info('Executing get trade calendar by quarter use case', tag: 'GetTradeCalendarByQuarter');

      final result = await _repository.getTradeCalendarByQuarter(userId, portfolioId, year: year, quarter: quarter);

      AppLogger.info('Trade calendar by quarter use case completed successfully', tag: 'GetTradeCalendarByQuarter');
      AppLogger.methodExit('GetTradeCalendarByQuarter.call', tag: 'GetTradeCalendarByQuarter', result: 'success');

      return result;
    } catch (e) {
      AppLogger.error(
        'Trade calendar by quarter use case failed',
        tag: 'GetTradeCalendarByQuarter',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('GetTradeCalendarByQuarter.call', tag: 'GetTradeCalendarByQuarter', result: 'error');
      rethrow;
    }
  }
}
