import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/entities/notebook_tag.dart';
import '../../../internal/domain/usecases/notebook_usecases.dart';
import 'notebook_state.dart';

class NotebookCubit extends Cubit<NotebookState> {
  final GetNotebookItemsUseCase getNotebookItemsUseCase;
  final CreateNotebookItemUseCase createNotebookItemUseCase;
  final UpdateNotebookItemUseCase updateNotebookItemUseCase;
  final DeleteNotebookItemUseCase deleteNotebookItemUseCase;
  final GetNotebookTagsUseCase getNotebookTagsUseCase;
  final CreateNotebookTagUseCase createNotebookTagUseCase;
  final UpdateNotebookTagUseCase updateNotebookTagUseCase;
  final DeleteNotebookTagUseCase deleteNotebookTagUseCase;

  NotebookCubit({
    required this.getNotebookItemsUseCase,
    required this.createNotebookItemUseCase,
    required this.updateNotebookItemUseCase,
    required this.deleteNotebookItemUseCase,
    required this.getNotebookTagsUseCase,
    required this.createNotebookTagUseCase,
    required this.updateNotebookTagUseCase,
    required this.deleteNotebookTagUseCase,
  }) : super(NotebookInitial());

  Future<void> loadNotebook(String userId, {String? parentId}) async {
    emit(NotebookLoading());
    try {
      final items = await getNotebookItemsUseCase(userId: userId, parentId: parentId);
      final tags = await getNotebookTagsUseCase(userId);
      emit(NotebookLoaded(items: items, tags: tags, currentParentId: parentId));
    } catch (e) {
      emit(NotebookError(e.toString()));
    }
  }

  Future<void> refreshItems(String userId, {String? parentId}) async {
    if (state is NotebookLoaded) {
      final currentState = state as NotebookLoaded;
      try {
        final items = await getNotebookItemsUseCase(userId: userId, parentId: parentId ?? currentState.currentParentId);
        emit(currentState.copyWith(items: items, currentParentId: parentId ?? currentState.currentParentId));
      } catch (e) {
        emit(NotebookError(e.toString()));
      }
    } else {
      loadNotebook(userId, parentId: parentId);
    }
  }

  Future<void> createItem(NotebookItem item) async {
    try {
      await createNotebookItemUseCase(item);
      // Refresh items after creation
      await refreshItems(item.userId, parentId: item.parentId);
    } catch (e) {
      emit(NotebookError(e.toString()));
    }
  }

  Future<void> updateItem(NotebookItem item) async {
    try {
      await updateNotebookItemUseCase(item);
      await refreshItems(item.userId, parentId: item.parentId);
    } catch (e) {
      emit(NotebookError(e.toString()));
    }
  }

  Future<void> deleteItem(String itemId, String userId, {String? parentId}) async {
    try {
      await deleteNotebookItemUseCase(itemId);
      await refreshItems(userId, parentId: parentId);
    } catch (e) {
      emit(NotebookError(e.toString()));
    }
  }

  // Tags
  Future<void> createTag(NotebookTag tag) async {
    try {
      await createNotebookTagUseCase(tag);
      if (state is NotebookLoaded) {
        final currentState = state as NotebookLoaded;
        final tags = await getNotebookTagsUseCase(tag.userId);
        emit(currentState.copyWith(tags: tags));
      }
    } catch (e) {
      emit(NotebookError(e.toString()));
    }
  }
}
