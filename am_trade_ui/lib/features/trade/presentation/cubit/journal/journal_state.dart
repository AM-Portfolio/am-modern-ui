import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../internal/domain/entities/journal_entry.dart';

part 'journal_state.freezed.dart';

@freezed
abstract class JournalState with _$JournalState {
  const factory JournalState.initial() = _Initial;
  const factory JournalState.loading() = _Loading;
  const factory JournalState.loaded(List<JournalEntry> entries) = _Loaded;
  const factory JournalState.error(String message) = _Error;
  const factory JournalState.success(String message) = _Success; // For one-off actions like create/update/delete
}
