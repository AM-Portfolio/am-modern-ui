import 'package:freezed_annotation/freezed_annotation.dart';

import 'trade_controller_entities.dart';

part 'trade_holding.freezed.dart';

/// Domain entity for paginated trade holdings collection
/// Uses TradeDetails from trade_controller_entities as the core trade model
@freezed
abstract class TradeHoldings with _$TradeHoldings {
  const factory TradeHoldings({
    required String userId,
    required String portfolioId,
    @Default([]) List<TradeDetails> content,
    @Default(0) int totalPages,
    @Default(true) bool last,
    @Default(0) int totalElements,
    @Default(true) bool first,
    @Default(50) int size,
    @Default(0) int number,
    @Default(0) int numberOfElements,
    @Default(false) bool empty,
  }) = _TradeHoldings;

  /// Create empty holdings
  factory TradeHoldings.empty(String userId, String portfolioId) =>
      TradeHoldings(userId: userId, portfolioId: portfolioId, content: []);
}
