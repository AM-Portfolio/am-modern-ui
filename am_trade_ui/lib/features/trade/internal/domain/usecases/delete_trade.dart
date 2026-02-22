import 'package:am_common/am_common.dart';
import '../repositories/trade_controller_repository.dart';

/// Use case for deleting a trade
class DeleteTrade {
  const DeleteTrade(this._repository);

  final TradeControllerRepository _repository;

  /// Execute the use case to delete a trade
  ///
  /// [tradeId] - The ID of the trade to delete
  /// Returns true if deletion was successful
  Future<bool> call(String tradeId) async {
    AppLogger.methodEntry('DeleteTrade.call', tag: 'DeleteTrade', params: {'tradeId': tradeId});

    if (tradeId.isEmpty) {
      AppLogger.error('Validation failed - empty tradeId', tag: 'DeleteTrade');
      throw ArgumentError('Trade ID cannot be empty');
    }

    try {
      AppLogger.info('Executing delete trade use case', tag: 'DeleteTrade');

      await _repository.deleteTrade(tradeId);

      AppLogger.info('Trade deleted successfully - tradeId: $tradeId', tag: 'DeleteTrade');
      AppLogger.methodExit('DeleteTrade.call', tag: 'DeleteTrade', result: 'success');

      return true;
    } catch (e) {
      AppLogger.error('Delete trade use case failed', tag: 'DeleteTrade', error: e, stackTrace: StackTrace.current);
      AppLogger.methodExit('DeleteTrade.call', tag: 'DeleteTrade', result: 'error');
      rethrow;
    }
  }
}

