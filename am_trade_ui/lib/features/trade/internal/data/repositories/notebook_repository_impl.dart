import '../../domain/entities/notebook_item.dart';
import '../../domain/entities/notebook_tag.dart';
import '../../domain/enums/notebook_item_type.dart';
import '../../domain/repositories/notebook_repository.dart';
import '../datasources/notebook_remote_datasource.dart';
import '../mappers/notebook_mapper.dart';

class NotebookRepositoryImpl implements NotebookRepository {
  final NotebookRemoteDataSource _remoteDataSource;

  NotebookRepositoryImpl(this._remoteDataSource);

  // --- Notebook Items ---

  @override
  Future<NotebookItem> createNotebookItem(NotebookItem item) async {
    final dto = NotebookMapper.toNotebookItemDto(item);
    final createdDto = await _remoteDataSource.createNotebookItem(dto);
    return NotebookMapper.toNotebookItem(createdDto);
  }

  @override
  Future<List<NotebookItem>> getNotebookItems({
    required String userId,
    String? parentId,
    NotebookItemType? type,
  }) async {
    final dtos = await _remoteDataSource.getNotebookItems(
      userId: userId,
      parentId: parentId,
      type: type != null ? NotebookMapper.toNotebookItemDto(NotebookItem(userId: '', type: type, title: '')).type : null, // Hacky way to get enum, better to expose helper in mapper
    );
    // Wait, the mapper has private helper methods. I should expose them or handle enum mapping better.
    // Let's fix the mapper usage.
    return dtos.map((dto) => NotebookMapper.toNotebookItem(dto)).toList();
  }

  @override
  Future<NotebookItem> getNotebookItem(String itemId) async {
    final dto = await _remoteDataSource.getNotebookItem(itemId);
    return NotebookMapper.toNotebookItem(dto);
  }

  @override
  Future<NotebookItem> updateNotebookItem(NotebookItem item) async {
    if (item.id == null) throw Exception('Item ID is required for update');
    final dto = NotebookMapper.toNotebookItemDto(item);
    final updatedDto = await _remoteDataSource.updateNotebookItem(item.id!, dto);
    return NotebookMapper.toNotebookItem(updatedDto);
  }

  @override
  Future<void> deleteNotebookItem(String itemId) async {
    await _remoteDataSource.deleteNotebookItem(itemId);
  }

  // --- Notebook Tags ---

  @override
  Future<NotebookTag> createNotebookTag(NotebookTag tag) async {
    final dto = NotebookMapper.toNotebookTagDto(tag);
    final createdDto = await _remoteDataSource.createNotebookTag(dto);
    return NotebookMapper.toNotebookTag(createdDto);
  }

  @override
  Future<List<NotebookTag>> getNotebookTags(String userId) async {
    final dtos = await _remoteDataSource.getNotebookTags(userId);
    return dtos.map((dto) => NotebookMapper.toNotebookTag(dto)).toList();
  }

  @override
  Future<NotebookTag> updateNotebookTag(NotebookTag tag) async {
    if (tag.id == null) throw Exception('Tag ID is required for update');
    final dto = NotebookMapper.toNotebookTagDto(tag);
    final updatedDto = await _remoteDataSource.updateNotebookTag(tag.id!, dto);
    return NotebookMapper.toNotebookTag(updatedDto);
  }

  @override
  Future<void> deleteNotebookTag(String tagId) async {
    await _remoteDataSource.deleteNotebookTag(tagId);
  }
}
