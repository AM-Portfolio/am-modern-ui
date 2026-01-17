
import 'package:freezed_annotation/freezed_annotation.dart';
import 'basket_item.dart';

part 'basket_opportunity.freezed.dart';
part 'basket_opportunity.g.dart';

@freezed
class BasketOpportunity with _$BasketOpportunity {
  const factory BasketOpportunity({
    required String id,
    required String etfName,
    required double matchScore,
    required List<BasketItem> items,
    int? missingStockCount,
  }) = _BasketOpportunity;

  factory BasketOpportunity.fromJson(Map<String, dynamic> json) => 
      _$BasketOpportunityFromJson(json);
}
