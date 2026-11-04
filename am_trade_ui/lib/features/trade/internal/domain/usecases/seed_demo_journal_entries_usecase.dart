import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

/// One-shot educational demos from `POST /v1/journal/seed-demo`.
class SeedDemoJournalEntriesUseCase {
  SeedDemoJournalEntriesUseCase(this._repository);

  final JournalRepository _repository;

  Future<List<JournalEntry>> call() => _repository.seedDemoEntries();
}
