import 'package:json_annotation/json_annotation.dart';

import 'metrics_filter_config_dto.dart';

part 'favorite_filter_dto.g.dart';

/// DTO for favorite filter request (create/update)
@JsonSerializable()
class FavoriteFilterRequestDto {
  const FavoriteFilterRequestDto({required this.name, required this.filterConfig, this.description, this.isDefault});

  factory FavoriteFilterRequestDto.fromJson(Map<String, dynamic> json) => _$FavoriteFilterRequestDtoFromJson(json);

  final String name;
  final String? description;
  final bool? isDefault;
  final MetricsFilterConfigDto filterConfig;

  Map<String, dynamic> toJson() => _$FavoriteFilterRequestDtoToJson(this);
}

/// DTO for favorite filter response
@JsonSerializable()
class FavoriteFilterResponseDto {
  const FavoriteFilterResponseDto({
    required this.id,
    required this.name,
    required this.filterConfig,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.isDefault,
  });

  factory FavoriteFilterResponseDto.fromJson(Map<String, dynamic> json) => _$FavoriteFilterResponseDtoFromJson(json);

  final String id;
  final String name;
  final String? description;
  final String? createdAt;
  final String? updatedAt;
  final bool? isDefault;
  final MetricsFilterConfigDto filterConfig;

  Map<String, dynamic> toJson() => _$FavoriteFilterResponseDtoToJson(this);
}

/// DTO for bulk delete request
@JsonSerializable()
class BulkDeleteRequestDto {
  const BulkDeleteRequestDto({required this.userId, required this.filterIds});

  factory BulkDeleteRequestDto.fromJson(Map<String, dynamic> json) => _$BulkDeleteRequestDtoFromJson(json);

  final String userId;
  final List<String> filterIds;

  Map<String, dynamic> toJson() => _$BulkDeleteRequestDtoToJson(this);
}

/// DTO for bulk delete response
@JsonSerializable()
class BulkDeleteResponseDto {
  const BulkDeleteResponseDto({required this.deletedCount, required this.totalRequested, this.message});

  factory BulkDeleteResponseDto.fromJson(Map<String, dynamic> json) => _$BulkDeleteResponseDtoFromJson(json);

  final int deletedCount;
  final int totalRequested;
  final String? message;

  Map<String, dynamic> toJson() => _$BulkDeleteResponseDtoToJson(this);
}
