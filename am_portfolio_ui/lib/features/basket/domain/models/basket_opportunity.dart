import 'package:freezed_annotation/freezed_annotation.dart';

part 'basket_opportunity.freezed.dart';
part 'basket_opportunity.g.dart';

@freezed
class BasketOpportunity with _$BasketOpportunity {
  const factory BasketOpportunity({
    required String etfIsin,
    required String etfName,
    @Default(0.0) double matchScore,
    @Default(0.0) double replicaScore,
    @Default(false) bool readyToReplicate,
    @Default(0) int totalItems,
    @Default(0) int heldCount,
    @Default(0) int missingCount,
    @Default([]) List<BasketItem> composition,
    @Default([]) List<BasketItem> buyList,
  }) = _BasketOpportunity;

  factory BasketOpportunity.fromJson(Map<String, dynamic> json) =>
      _$BasketOpportunityFromJson(json);
}

@freezed
class BasketItem with _$BasketItem {
  const factory BasketItem({
    required String stockSymbol,
    required String isin,
    required String sector,
    required ItemStatus status,
    String? userHoldingSymbol, // Nullable
    String? reason, // Nullable
    @Default(0.0) double etfWeight,
    @Default(0.0) double userWeight,
    @Default(0.0) double replicaWeight,
    @Default(0.0) double buyQuantity,
    @Default([]) List<Alternative> alternatives,
  }) = _BasketItem;

  factory BasketItem.fromJson(Map<String, dynamic> json) =>
      _$BasketItemFromJson(json);
}

@freezed
class Alternative with _$Alternative {
  const factory Alternative({
    required String symbol,
    required String isin,
    @Default(0.0) double userWeight,
  }) = _Alternative;

  factory Alternative.fromJson(Map<String, dynamic> json) =>
      _$AlternativeFromJson(json);
}

enum ItemStatus {
  @JsonValue('HELD')
  held,
  @JsonValue('MISSING')
  missing,
  @JsonValue('SUBSTITUTE')
  substitute,
}
