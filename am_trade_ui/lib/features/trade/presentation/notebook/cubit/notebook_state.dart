import 'package:equatable/equatable.dart';
import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/entities/notebook_tag.dart';

abstract class NotebookState extends Equatable {
  const NotebookState();

  @override
  List<Object?> get props => [];
}

class NotebookInitial extends NotebookState {}

class NotebookLoading extends NotebookState {}

class NotebookLoaded extends NotebookState {
  final List<NotebookItem> items;
  final List<NotebookTag> tags;
  final String? currentParentId;

  const NotebookLoaded({
    this.items = const [],
    this.tags = const [],
    this.currentParentId,
  });

  NotebookLoaded copyWith({
    List<NotebookItem>? items,
    List<NotebookTag>? tags,
    String? currentParentId,
  }) {
    return NotebookLoaded(
      items: items ?? this.items,
      tags: tags ?? this.tags,
      currentParentId: currentParentId ?? this.currentParentId,
    );
  }

  @override
  List<Object?> get props => [items, tags, currentParentId];
}

class NotebookError extends NotebookState {
  final String message;

  const NotebookError(this.message);

  @override
  List<Object?> get props => [message];
}
