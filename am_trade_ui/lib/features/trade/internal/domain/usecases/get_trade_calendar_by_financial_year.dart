import 'package:am_common/core/utils/logger.dart';
import '../entities/trade_calendar.dart';
import '../repositories/trade_repository.dart';

/// Use case for getting trade calendar by financial year
class GetTradeCalendarByFinancialYear {
  const GetTradeCalendarByFinancialYear(this._repository);
  final TradeRepository _repository;

  /// Execute the use case to get trade calendar for a specific portfolio by financial year
  Future<TradeCalendar> call(String userId, String portfolioId, {required int financialYear}) async {
    AppLogger.methodEntry(
      'GetTradeCalendarByFinancialYear.call',
      tag: 'GetTradeCalendarByFinancialYear',
      params: {'userId': userId, 'portfolioId': portfolioId, 'financialYear': financialYear},
    );

    if (userId.isEmpty || portfolioId.isEmpty) {
      AppLogger.error('Validation failed - empty userId or portfolioId', tag: 'GetTradeCalendarByFinancialYear');
      throw ArgumentError('User ID and Portfolio ID cannot be empty');
    }

    try {
      AppLogger.info('Executing get trade calendar by financial year use case', tag: 'GetTradeCalendarByFinancialYear');

      final result = await _repository.getTradeCalendarByFinancialYear(
        userId,
        portfolioId,
        financialYear: financialYear,
      );

      AppLogger.info(
        'Trade calendar by financial year use case completed successfully',
        tag: 'GetTradeCalendarByFinancialYear',
      );
      AppLogger.methodExit(
        'GetTradeCalendarByFinancialYear.call',
        tag: 'GetTradeCalendarByFinancialYear',
        result: 'success',
      );

      return result;
    } catch (e) {
      AppLogger.error(
        'Trade calendar by financial year use case failed',
        tag: 'GetTradeCalendarByFinancialYear',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit(
        'GetTradeCalendarByFinancialYear.call',
        tag: 'GetTradeCalendarByFinancialYear',
        result: 'error',
      );
      rethrow;
    }
  }
}
