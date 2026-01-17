
import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_basket.freezed.dart';
part 'custom_basket.g.dart';

@freezed
class CustomBasketStock with _$CustomBasketStock {
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
class CustomBasket with _$CustomBasket {
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
