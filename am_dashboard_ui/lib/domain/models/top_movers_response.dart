import 'package:freezed_annotation/freezed_annotation.dart';

part 'top_movers_response.freezed.dart';
part 'top_movers_response.g.dart';

@freezed
abstract class TopMoversResponse with _$TopMoversResponse {
  const factory TopMoversResponse({
    @Default([]) List<MoverItem> gainers,
    @Default([]) List<MoverItem> losers,
  }) = _TopMoversResponse;

  factory TopMoversResponse.fromJson(Map<String, dynamic> json) =>
      _$TopMoversResponseFromJson(json);
}

@freezed
abstract class MoverItem with _$MoverItem {
  const factory MoverItem({
    required String symbol,
    required String name,
    required double price,
    required double changePercentage,
    required double changeAmount,
    String? sector,
    String? assetClass,
    String? marketCapType,
    double? quantity,
    double? currentValue,
    double? investedValue,
    double? allocationPercentage,
    double? pnlPercentage,
  }) = _MoverItem;

  factory MoverItem.fromJson(Map<String, dynamic> json) =>
      _$MoverItemFromJson(json);
}
