import 'package:am_common/core/utils/logger.dart';
import '../entities/trade_controller_entities.dart';
import '../repositories/trade_controller_repository.dart';

/// Use case for adding a new trade
class AddTrade {
  const AddTrade(this._repository);

  final TradeControllerRepository _repository;

  /// Execute the use case to add a new trade
  ///
  /// [tradeDetails] - The trade details to be added
  /// Returns the created [TradeDetails] with server-generated fields (id, timestamps)
  Future<TradeDetails> call(TradeDetails tradeDetails) async {
    AppLogger.methodEntry(
      'AddTrade.call',
      tag: 'AddTrade',
      params: {
        'portfolioId': tradeDetails.portfolioId,
        'symbol': tradeDetails.instrumentInfo.symbol,
        'direction': tradeDetails.tradePositionType.name,
        'status': tradeDetails.status.name,
      },
    );

    // Validate required fields
    if (tradeDetails.portfolioId.isEmpty) {
      AppLogger.error('Validation failed - empty portfolioId', tag: 'AddTrade');
      throw ArgumentError('Portfolio ID cannot be empty');
    }

    if (tradeDetails.instrumentInfo.symbol == null || tradeDetails.instrumentInfo.symbol!.isEmpty) {
      AppLogger.error('Validation failed - empty symbol', tag: 'AddTrade');
      throw ArgumentError('Symbol cannot be empty');
    }

    if (tradeDetails.entryInfo.price == null || tradeDetails.entryInfo.price! <= 0) {
      AppLogger.error('Validation failed - invalid entry price', tag: 'AddTrade');
      throw ArgumentError('Entry price must be greater than 0');
    }

    if (tradeDetails.entryInfo.quantity == null || tradeDetails.entryInfo.quantity! <= 0) {
      AppLogger.error('Validation failed - invalid entry quantity', tag: 'AddTrade');
      throw ArgumentError('Entry quantity must be greater than 0');
    }

    try {
      AppLogger.info('Executing add trade use case', tag: 'AddTrade');

      final result = await _repository.addTrade(tradeDetails);

      AppLogger.info('Trade added successfully with ID: ${result.tradeId}', tag: 'AddTrade');
      AppLogger.methodExit('AddTrade.call', tag: 'AddTrade', result: 'success');

      return result;
    } catch (e) {
      AppLogger.error('Add trade use case failed', tag: 'AddTrade', error: e, stackTrace: StackTrace.current);
      AppLogger.methodExit('AddTrade.call', tag: 'AddTrade', result: 'error');
      rethrow;
    }
  }
}
