import '../entities/notebook_item.dart';
import '../entities/notebook_tag.dart';
import '../enums/notebook_item_type.dart';
import '../repositories/notebook_repository.dart';

class GetNotebookItemsUseCase {
  final NotebookRepository repository;

  GetNotebookItemsUseCase(this.repository);

  Future<List<NotebookItem>> call({
    required String userId,
    String? parentId,
    NotebookItemType? type,
  }) {
    return repository.getNotebookItems(userId: userId, parentId: parentId, type: type);
  }
}

class CreateNotebookItemUseCase {
  final NotebookRepository repository;

  CreateNotebookItemUseCase(this.repository);

  Future<NotebookItem> call(NotebookItem item) {
    return repository.createNotebookItem(item);
  }
}

class UpdateNotebookItemUseCase {
  final NotebookRepository repository;

  UpdateNotebookItemUseCase(this.repository);

  Future<NotebookItem> call(NotebookItem item) {
    return repository.updateNotebookItem(item);
  }
}

class DeleteNotebookItemUseCase {
  final NotebookRepository repository;

  DeleteNotebookItemUseCase(this.repository);

  Future<void> call(String itemId) {
    return repository.deleteNotebookItem(itemId);
  }
}

class GetNotebookTagsUseCase {
  final NotebookRepository repository;

  GetNotebookTagsUseCase(this.repository);

  Future<List<NotebookTag>> call(String userId) {
    return repository.getNotebookTags(userId);
  }
}

class CreateNotebookTagUseCase {
  final NotebookRepository repository;

  CreateNotebookTagUseCase(this.repository);

  Future<NotebookTag> call(NotebookTag tag) {
    return repository.createNotebookTag(tag);
  }
}

class UpdateNotebookTagUseCase {
  final NotebookRepository repository;

  UpdateNotebookTagUseCase(this.repository);

  Future<NotebookTag> call(NotebookTag tag) {
    return repository.updateNotebookTag(tag);
  }
}

class DeleteNotebookTagUseCase {
  final NotebookRepository repository;

  DeleteNotebookTagUseCase(this.repository);

  Future<void> call(String tagId) {
    return repository.deleteNotebookTag(tagId);
  }
}
