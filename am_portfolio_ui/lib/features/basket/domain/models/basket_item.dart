
import 'package:freezed_annotation/freezed_annotation.dart';
import 'basket_enums.dart';

part 'basket_item.freezed.dart';
part 'basket_item.g.dart';

@freezed
class BasketItem with _$BasketItem {
  const factory BasketItem({
    required String symbol,
    required String name,
    required double weight,
    required BasketItemStatus status,
    String? reason, // Reason for substitution or missing recommendation
    String? userHoldingSymbol, // If substitute, what user holds
  }) = _BasketItem;

  factory BasketItem.fromJson(Map<String, dynamic> json) => 
      _$BasketItemFromJson(json);
}
