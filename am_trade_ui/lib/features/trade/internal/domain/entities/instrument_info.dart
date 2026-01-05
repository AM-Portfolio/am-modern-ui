import 'package:freezed_annotation/freezed_annotation.dart';

part 'instrument_info.freezed.dart';

@freezed
abstract class InstrumentInfo with _$InstrumentInfo {
  const factory InstrumentInfo({
    required String symbol,
    String? isin,
    String? rawSymbol,
    String? exchange,
    String? segment,
    String? series,
    String? description,
    String? baseSymbol,
    String? formattedDescription,
    @Default(false) bool isDerivative,
    @Default(false) bool isIndex,
  }) = _InstrumentInfo;
}
