import 'package:am_common/core/utils/logger.dart';
import '../entities/trade_controller_entities.dart';
import '../repositories/trade_controller_repository.dart';

/// Use case for updating an existing trade
class UpdateTrade {
  const UpdateTrade(this._repository);

  final TradeControllerRepository _repository;

  /// Execute the use case to update an existing trade
  ///
  /// [tradeId] - The ID of the trade to update
  /// [tradeDetails] - The updated trade details
  /// Returns the updated [TradeDetails]
  Future<TradeDetails> call({required String tradeId, required TradeDetails tradeDetails}) async {
    AppLogger.methodEntry(
      'UpdateTrade.call',
      tag: 'UpdateTrade',
      params: {
        'tradeId': tradeId,
        'portfolioId': tradeDetails.portfolioId,
        'symbol': tradeDetails.instrumentInfo.symbol,
      },
    );

    // Validate required fields
    if (tradeId.isEmpty) {
      AppLogger.error('Validation failed - empty tradeId', tag: 'UpdateTrade');
      throw ArgumentError('Trade ID cannot be empty');
    }

    if (tradeDetails.portfolioId.isEmpty) {
      AppLogger.error('Validation failed - empty portfolioId', tag: 'UpdateTrade');
      throw ArgumentError('Portfolio ID cannot be empty');
    }

    try {
      AppLogger.info('Executing update trade use case', tag: 'UpdateTrade');

      final result = await _repository.updateTrade(tradeId: tradeId, tradeDetails: tradeDetails);

      AppLogger.info('Trade updated successfully - tradeId: ${result.tradeId}', tag: 'UpdateTrade');
      AppLogger.methodExit('UpdateTrade.call', tag: 'UpdateTrade', result: 'success');

      return result;
    } catch (e) {
      AppLogger.error('Update trade use case failed', tag: 'UpdateTrade', error: e, stackTrace: StackTrace.current);
      AppLogger.methodExit('UpdateTrade.call', tag: 'UpdateTrade', result: 'error');
      rethrow;
    }
  }
}
