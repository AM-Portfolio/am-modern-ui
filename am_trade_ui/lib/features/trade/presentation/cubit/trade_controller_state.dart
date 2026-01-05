import 'package:freezed_annotation/freezed_annotation.dart';

import '../../internal/domain/entities/trade_controller_entities.dart';

part 'trade_controller_state.freezed.dart';

/// States for Trade Controller operations
@freezed
abstract class TradeControllerState with _$TradeControllerState {
  /// Initial state
  const factory TradeControllerState.initial() = _Initial;

  /// Loading state - fetching trades
  const factory TradeControllerState.loading() = _Loading;

  /// Loaded state - trades fetched successfully
  const factory TradeControllerState.loaded({
    required List<TradeDetails> trades,
    String? portfolioId,
  }) = _Loaded;

  /// Adding trade state
  const factory TradeControllerState.adding() = _Adding;

  /// Trade added successfully
  const factory TradeControllerState.addSuccess({
    required TradeDetails trade,
  }) = _AddSuccess;

  /// Updating trade state
  const factory TradeControllerState.updating() = _Updating;

  /// Trade updated successfully
  const factory TradeControllerState.updateSuccess({
    required TradeDetails trade,
  }) = _UpdateSuccess;

  /// Deleting trade state
  const factory TradeControllerState.deleting() = _Deleting;

  /// Trade deleted successfully
  const factory TradeControllerState.deleteSuccess({
    required String tradeId,
  }) = _DeleteSuccess;

  /// Error state
  const factory TradeControllerState.error({
    required String message,
    Object? error,
  }) = _Error;
}
