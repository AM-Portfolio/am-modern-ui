import 'package:json_annotation/json_annotation.dart';

part 'notebook_tag_dto.g.dart';

@JsonSerializable()
class NotebookTagDto {
  final String? id;
  final String userId;
  final String name;
  final String colorHex;

  NotebookTagDto({
    this.id,
    required this.userId,
    required this.name,
    required this.colorHex,
  });

  factory NotebookTagDto.fromJson(Map<String, dynamic> json) =>
      _$NotebookTagDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NotebookTagDtoToJson(this);
}
