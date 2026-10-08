import 'package:am_common/am_common.dart';
import '../repositories/trade_repository.dart';

/// Use case for getting the most recent trade year
class GetMostRecentTradeYear {
  const GetMostRecentTradeYear(this._repository);
  final TradeRepository _repository;

  /// Execute the use case to get most recent trade year
  Future<int> call(String portfolioId) async {
    AppLogger.methodEntry(
      'GetMostRecentTradeYear.call',
      tag: 'GetMostRecentTradeYear',
      params: {'portfolioId': portfolioId},
    );

    try {
      final year = await _repository.getMostRecentTradeYear(portfolioId);
      AppLogger.info('Most recent trade year fetched: $year', tag: 'GetMostRecentTradeYear');
      return year;
    } catch (e) {
      AppLogger.warning(
        'Failed to get most recent trade year, falling back to current year',
        tag: 'GetMostRecentTradeYear',
        error: e,
      );
      return DateTime.now().year;
    }
  }
}
