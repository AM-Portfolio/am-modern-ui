import '../enums/notebook_item_type.dart';

class NotebookItem {
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

  NotebookItem({
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

  NotebookItem copyWith({
    String? id,
    String? userId,
    NotebookItemType? type,
    String? parentId,
    String? title,
    String? content,
    List<String>? tagIds,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? goalDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotebookItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      title: title ?? this.title,
      content: content ?? this.content,
      tagIds: tagIds ?? this.tagIds,
      metadata: metadata ?? this.metadata,
      goalDetails: goalDetails ?? this.goalDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
