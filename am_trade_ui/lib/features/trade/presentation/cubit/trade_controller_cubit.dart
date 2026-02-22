import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import '../../internal/domain/entities/trade_controller_entities.dart';
import '../../internal/domain/usecases/add_trade.dart';
import '../../internal/domain/usecases/delete_trade.dart';
import '../../internal/domain/usecases/get_trades_by_portfolio.dart';
import '../../internal/domain/usecases/update_trade.dart';
import 'trade_controller_state.dart';

/// Cubit for managing trade controller operations
/// Handles CRUD operations for trades with state management
class TradeControllerCubit extends Cubit<TradeControllerState> {
  TradeControllerCubit({
    required AddTrade addTrade,
    required UpdateTrade updateTrade,
    required DeleteTrade deleteTrade,
    required GetTradesByPortfolio getTradesByPortfolio,
  })  : _addTrade = addTrade,
        _updateTrade = updateTrade,
        _deleteTrade = deleteTrade,
        _getTradesByPortfolio = getTradesByPortfolio,
        super(const TradeControllerState.initial()) {
    AppLogger.info('TradeControllerCubit initialized', tag: 'TradeControllerCubit');
  }

  final AddTrade _addTrade;
  final UpdateTrade _updateTrade;
  final DeleteTrade _deleteTrade;
  final GetTradesByPortfolio _getTradesByPortfolio;

  /// Load trades for a specific portfolio
  Future<void> loadTrades({
    required String portfolioId,
    List<String>? symbols,
  }) async {
    AppLogger.methodEntry(
      'loadTrades',
      tag: 'TradeControllerCubit',
      params: {'portfolioId': portfolioId, 'symbols': symbols},
    );

    emit(const TradeControllerState.loading());

    try {
      final trades = await _getTradesByPortfolio(
        portfolioId: portfolioId,
        symbols: symbols,
      );

      AppLogger.info(
        'Trades loaded successfully - count: ${trades.length}',
        tag: 'TradeControllerCubit',
      );

      emit(TradeControllerState.loaded(
        trades: trades,
        portfolioId: portfolioId,
      ));
    } catch (e) {
      AppLogger.error(
        'Failed to load trades',
        tag: 'TradeControllerCubit',
        error: e,
        stackTrace: StackTrace.current,
      );

      emit(TradeControllerState.error(
        message: 'Failed to load trades: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// Add a new trade
  Future<void> addNewTrade(TradeDetails tradeDetails) async {
    AppLogger.methodEntry(
      'addNewTrade',
      tag: 'TradeControllerCubit',
      params: {
        'portfolioId': tradeDetails.portfolioId,
        'symbol': tradeDetails.instrumentInfo.symbol,
      },
    );

    emit(const TradeControllerState.adding());

    try {
      final createdTrade = await _addTrade(tradeDetails);

      AppLogger.info(
        'Trade added successfully - tradeId: ${createdTrade.tradeId}',
        tag: 'TradeControllerCubit',
      );

      emit(TradeControllerState.addSuccess(trade: createdTrade));

      // Reload trades for the portfolio
      await loadTrades(portfolioId: createdTrade.portfolioId);
    } catch (e) {
      AppLogger.error(
        'Failed to add trade',
        tag: 'TradeControllerCubit',
        error: e,
        stackTrace: StackTrace.current,
      );

      emit(TradeControllerState.error(
        message: 'Failed to add trade: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// Update an existing trade
  Future<void> updateExistingTrade({
    required String tradeId,
    required TradeDetails tradeDetails,
  }) async {
    AppLogger.methodEntry(
      'updateExistingTrade',
      tag: 'TradeControllerCubit',
      params: {'tradeId': tradeId},
    );

    emit(const TradeControllerState.updating());

    try {
      final updatedTrade = await _updateTrade(
        tradeId: tradeId,
        tradeDetails: tradeDetails,
      );

      AppLogger.info(
        'Trade updated successfully - tradeId: ${updatedTrade.tradeId}',
        tag: 'TradeControllerCubit',
      );

      emit(TradeControllerState.updateSuccess(trade: updatedTrade));

      // Reload trades for the portfolio
      await loadTrades(portfolioId: updatedTrade.portfolioId);
    } catch (e) {
      AppLogger.error(
        'Failed to update trade',
        tag: 'TradeControllerCubit',
        error: e,
        stackTrace: StackTrace.current,
      );

      emit(TradeControllerState.error(
        message: 'Failed to update trade: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// Delete a trade
  Future<void> removeTradeById(String tradeId, String portfolioId) async {
    AppLogger.methodEntry(
      'removeTrade',
      tag: 'TradeControllerCubit',
      params: {'tradeId': tradeId},
    );

    emit(const TradeControllerState.deleting());

    try {
      await _deleteTrade(tradeId);

      AppLogger.info(
        'Trade deleted successfully - tradeId: $tradeId',
        tag: 'TradeControllerCubit',
      );

      emit(TradeControllerState.deleteSuccess(tradeId: tradeId));

      // Reload trades for the portfolio
      await loadTrades(portfolioId: portfolioId);
    } catch (e) {
      AppLogger.error(
        'Failed to delete trade',
        tag: 'TradeControllerCubit',
        error: e,
        stackTrace: StackTrace.current,
      );

      emit(TradeControllerState.error(
        message: 'Failed to delete trade: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// Watch trades for real-time updates
  void watchTrades(String portfolioId) {
    AppLogger.methodEntry(
      'watchTrades',
      tag: 'TradeControllerCubit',
      params: {'portfolioId': portfolioId},
    );

    _getTradesByPortfolio.watch(portfolioId).listen(
      (trades) {
        AppLogger.info(
          'Trades updated from stream - count: ${trades.length}',
          tag: 'TradeControllerCubit',
        );

        emit(TradeControllerState.loaded(
          trades: trades,
          portfolioId: portfolioId,
        ));
      },
      onError: (error) {
        AppLogger.error(
          'Error watching trades',
          tag: 'TradeControllerCubit',
          error: error,
          stackTrace: StackTrace.current,
        );

        emit(TradeControllerState.error(
          message: 'Error watching trades: ${error.toString()}',
          error: error,
        ));
      },
    );
  }

  @override
  Future<void> close() {
    AppLogger.info('TradeControllerCubit closed', tag: 'TradeControllerCubit');
    return super.close();
  }
}

