import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_basket.freezed.dart';
part 'custom_basket.g.dart';

@freezed
// Changed to 'abstract class' to comply with Freezed code generation requirements
// and prevent "missing implementation" compilation errors during 'flutter test'.
abstract class CustomBasketStock with _$CustomBasketStock {
  const factory CustomBasketStock({
    required String symbol,
    required String name,
    required double weight,
    String? sector,
  }) = _CustomBasketStock;

  factory CustomBasketStock.fromJson(Map<String, dynamic> json) =>
      _$CustomBasketStockFromJson(json);
}

@freezed
// Changed to 'abstract class' to comply with Freezed code generation requirements
// and prevent "missing implementation" compilation errors during 'flutter test'.
abstract class CustomBasket with _$CustomBasket {
  @JsonSerializable(explicitToJson: true)
  const factory CustomBasket({
    String? id,
    required String name,
    required double investmentAmount,
    @Default([]) List<CustomBasketStock> stocks,
    double? projectedCAGR,
  }) = _CustomBasket;

  factory CustomBasket.fromJson(Map<String, dynamic> json) =>
      _$CustomBasketFromJson(json);
}
