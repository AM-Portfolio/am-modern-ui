import '../repositories/journal_repository.dart';

class DeleteJournalEntryUseCase {
  DeleteJournalEntryUseCase(this._repository);

  final JournalRepository _repository;

  Future<void> call(String entryId) {
    return _repository.deleteJournalEntry(entryId);
  }
}
