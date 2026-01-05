import 'package:json_annotation/json_annotation.dart';

part 'notebook_item_dto.g.dart';

enum NotebookItemType {
  @JsonValue('FOLDER')
  FOLDER,
  @JsonValue('NOTE')
  NOTE,
  @JsonValue('GOAL')
  GOAL,
}

@JsonSerializable()
class NotebookItemDto {
  final String? id;
  final String userId;
  final NotebookItemType type;
  final String? parentId;
  final String title;
  final String? content;
  final List<String>? tagIds;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? goalDetails;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NotebookItemDto({
    this.id,
    required this.userId,
    required this.type,
    this.parentId,
    required this.title,
    this.content,
    this.tagIds,
    this.metadata,
    this.goalDetails,
    this.createdAt,
    this.updatedAt,
  });

  factory NotebookItemDto.fromJson(Map<String, dynamic> json) =>
      _$NotebookItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NotebookItemDtoToJson(this);
}
