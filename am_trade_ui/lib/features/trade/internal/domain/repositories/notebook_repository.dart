import '../entities/notebook_item.dart';
import '../entities/notebook_tag.dart';
import '../enums/notebook_item_type.dart';

abstract class NotebookRepository {
  // Notebook Items
  Future<NotebookItem> createNotebookItem(NotebookItem item);
  Future<List<NotebookItem>> getNotebookItems({
    required String userId,
    String? parentId,
    NotebookItemType? type,
  });
  Future<NotebookItem> getNotebookItem(String itemId);
  Future<NotebookItem> updateNotebookItem(NotebookItem item);
  Future<void> deleteNotebookItem(String itemId);

  // Notebook Tags
  Future<NotebookTag> createNotebookTag(NotebookTag tag);
  Future<List<NotebookTag>> getNotebookTags(String userId);
  Future<NotebookTag> updateNotebookTag(NotebookTag tag);
  Future<void> deleteNotebookTag(String tagId);
}
