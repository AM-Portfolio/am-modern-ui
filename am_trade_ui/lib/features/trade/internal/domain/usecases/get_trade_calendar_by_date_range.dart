import 'package:am_common/core/utils/logger.dart';
import '../entities/trade_calendar.dart';
import '../repositories/trade_repository.dart';

/// Use case for getting trade calendar by date range
class GetTradeCalendarByDateRange {
  const GetTradeCalendarByDateRange(this._repository);
  final TradeRepository _repository;

  /// Execute the use case to get trade calendar for a specific portfolio by date range
  Future<TradeCalendar> call(
    String userId,
    String portfolioId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    AppLogger.methodEntry(
      'GetTradeCalendarByDateRange.call',
      tag: 'GetTradeCalendarByDateRange',
      params: {
        'userId': userId,
        'portfolioId': portfolioId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );

    if (userId.isEmpty || portfolioId.isEmpty) {
      AppLogger.error('Validation failed - empty userId or portfolioId', tag: 'GetTradeCalendarByDateRange');
      throw ArgumentError('User ID and Portfolio ID cannot be empty');
    }

    if (startDate.isAfter(endDate)) {
      AppLogger.error('Validation failed - startDate is after endDate', tag: 'GetTradeCalendarByDateRange');
      throw ArgumentError('Start date must be before or equal to end date');
    }

    try {
      AppLogger.info('Executing get trade calendar by date range use case', tag: 'GetTradeCalendarByDateRange');

      final result = await _repository.getTradeCalendarByDateRange(
        userId,
        portfolioId,
        startDate: startDate,
        endDate: endDate,
      );

      AppLogger.info(
        'Trade calendar by date range use case completed successfully',
        tag: 'GetTradeCalendarByDateRange',
      );
      AppLogger.methodExit('GetTradeCalendarByDateRange.call', tag: 'GetTradeCalendarByDateRange', result: 'success');

      return result;
    } catch (e) {
      AppLogger.error(
        'Trade calendar by date range use case failed',
        tag: 'GetTradeCalendarByDateRange',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('GetTradeCalendarByDateRange.call', tag: 'GetTradeCalendarByDateRange', result: 'error');
      rethrow;
    }
  }
}
