import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';
import '../../../internal/domain/entities/journal_entry.dart';

part 'journal_state.freezed.dart';

@freezed
abstract class JournalState with _$JournalState {
  const factory JournalState.initial() = _Initial;
  const factory JournalState.loading() = _Loading;
  const factory JournalState.loaded({
    required List<JournalEntry> entries,
    JournalSummaryDto? summary,
    @Default('') String statusFilter,
    String? folderId,
    @Default([]) List<String> tagIds,
    @Default('') String searchQuery,
    String? setupFilter,
  }) = _Loaded;
  const factory JournalState.error(String message) = _Error;
  const factory JournalState.success(String message) = _Success;
}
