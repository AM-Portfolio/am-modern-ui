import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_entry_exit_info.freezed.dart';

@freezed
abstract class TradeEntryExitInfo with _$TradeEntryExitInfo {
  const factory TradeEntryExitInfo({
    DateTime? timestamp,
    double? price,
    int? quantity,
    double? totalValue,
    @Default(0.0) double fees,
  }) = _TradeEntryExitInfo;
}
