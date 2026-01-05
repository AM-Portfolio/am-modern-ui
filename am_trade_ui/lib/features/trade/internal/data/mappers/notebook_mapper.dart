import '../../domain/entities/notebook_item.dart';
import '../../domain/entities/notebook_tag.dart';
import '../../domain/enums/notebook_item_type.dart' as domain;
import '../dtos/notebook_item_dto.dart' as dto;
import '../dtos/notebook_tag_dto.dart';

class NotebookMapper {
  // --- Notebook Item ---

  static NotebookItem toNotebookItem(dto.NotebookItemDto dtoItem) {
    return NotebookItem(
      id: dtoItem.id,
      userId: dtoItem.userId,
      type: _mapItemType(dtoItem.type),
      parentId: dtoItem.parentId,
      title: dtoItem.title,
      content: dtoItem.content,
      tagIds: dtoItem.tagIds,
      metadata: dtoItem.metadata,
      goalDetails: dtoItem.goalDetails,
      createdAt: dtoItem.createdAt,
      updatedAt: dtoItem.updatedAt,
    );
  }

  static dto.NotebookItemDto toNotebookItemDto(NotebookItem entity) {
    return dto.NotebookItemDto(
      id: entity.id,
      userId: entity.userId,
      type: _mapItemTypeDto(entity.type),
      parentId: entity.parentId,
      title: entity.title,
      content: entity.content,
      tagIds: entity.tagIds,
      metadata: entity.metadata,
      goalDetails: entity.goalDetails,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static domain.NotebookItemType _mapItemType(dto.NotebookItemType dtoType) {
    switch (dtoType) {
      case dto.NotebookItemType.FOLDER:
        return domain.NotebookItemType.FOLDER;
      case dto.NotebookItemType.NOTE:
        return domain.NotebookItemType.NOTE;
      case dto.NotebookItemType.GOAL:
        return domain.NotebookItemType.GOAL;
    }
  }

  static dto.NotebookItemType _mapItemTypeDto(domain.NotebookItemType entityType) {
    switch (entityType) {
      case domain.NotebookItemType.FOLDER:
        return dto.NotebookItemType.FOLDER;
      case domain.NotebookItemType.NOTE:
        return dto.NotebookItemType.NOTE;
      case domain.NotebookItemType.GOAL:
        return dto.NotebookItemType.GOAL;
    }
  }

  // --- Notebook Tag ---

  static NotebookTag toNotebookTag(NotebookTagDto dto) {
    return NotebookTag(
      id: dto.id,
      userId: dto.userId,
      name: dto.name,
      colorHex: dto.colorHex,
    );
  }

  static NotebookTagDto toNotebookTagDto(NotebookTag entity) {
    return NotebookTagDto(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      colorHex: entity.colorHex,
    );
  }
}

// Helper alias to avoid conflict if needed, though import alias is better.
// But since DTO enum is inside the file, I need to check how it was generated.
// In notebook_item_dto.dart I defined `enum NotebookItemType`.
// In notebook_item.dart I defined `enum NotebookItemType`.
// They have the same name. I should use import alias in the mapper.
