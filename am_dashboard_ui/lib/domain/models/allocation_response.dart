import 'package:freezed_annotation/freezed_annotation.dart';

part 'allocation_response.freezed.dart';
part 'allocation_response.g.dart';

@freezed
abstract class AllocationResponse with _$AllocationResponse {
  const factory AllocationResponse({
    String? portfolioId,
    @Default([]) List<DomainAllocationItem> sectors,
    @Default([]) List<DomainAllocationItem> assetClasses,
    @Default([]) List<DomainAllocationItem> marketCaps,
    @Default([]) List<DomainAllocationItem> stocks,
  }) = _AllocationResponse;

  factory AllocationResponse.fromJson(Map<String, dynamic> json) =>
      _$AllocationResponseFromJson(json);
}

@freezed
abstract class DomainAllocationItem with _$DomainAllocationItem {
  const factory DomainAllocationItem({
    required String name,
    required double value,
    required double percentage,
    @Default(0) int count,
    double? dayChangePercentage,
    double? dayChangeAmount,
    double? totalChangePercentage,
    double? totalChangeAmount,
  }) = _DomainAllocationItem;

  factory DomainAllocationItem.fromJson(Map<String, dynamic> json) =>
      _$DomainAllocationItemFromJson(json);
}
