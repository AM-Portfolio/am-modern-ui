import 'package:am_common/am_common.dart';

import '../entities/calendar_latest_activity.dart';
import '../repositories/trade_repository.dart';

/// Resolves the most recent trade year/month for calendar default open.
class GetCalendarLatestActivity {
  const GetCalendarLatestActivity(this._repository);
  final TradeRepository _repository;

  /// Returns null when the portfolio has no trades (caller should fall back to now).
  Future<CalendarLatestActivity?> call(String portfolioId) async {
    AppLogger.methodEntry(
      'GetCalendarLatestActivity.call',
      tag: 'GetCalendarLatestActivity',
      params: {'portfolioId': portfolioId},
    );

    if (portfolioId.isEmpty) {
      throw ArgumentError('Portfolio ID cannot be empty');
    }

    try {
      final result = await _repository.getCalendarLatestActivity(portfolioId);
      AppLogger.methodExit(
        'GetCalendarLatestActivity.call',
        tag: 'GetCalendarLatestActivity',
        result: result == null ? 'empty' : '${result.year}-${result.month}',
      );
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get calendar latest activity failed',
        tag: 'GetCalendarLatestActivity',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
