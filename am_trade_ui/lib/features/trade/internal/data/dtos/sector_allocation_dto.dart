import 'package:freezed_annotation/freezed_annotation.dart';

part 'sector_allocation_dto.freezed.dart';
part 'sector_allocation_dto.g.dart';

@freezed
abstract class SectorAllocationDto with _$SectorAllocationDto {
  const factory SectorAllocationDto({
    required String sector,
    required double value,
    required double percentage,
    @Default(0) int holdingsCount,
  }) = _SectorAllocationDto;

  factory SectorAllocationDto.fromJson(Map<String, dynamic> json) =>
      _$SectorAllocationDtoFromJson(json);
}

@freezed
abstract class TopPerformerDto with _$TopPerformerDto {
  const factory TopPerformerDto({
    required String symbol,
    required String name,
    required double change,
    required double changePercentage,
    double? currentPrice,
  }) = _TopPerformerDto;

  factory TopPerformerDto.fromJson(Map<String, dynamic> json) =>
      _$TopPerformerDtoFromJson(json);
}
