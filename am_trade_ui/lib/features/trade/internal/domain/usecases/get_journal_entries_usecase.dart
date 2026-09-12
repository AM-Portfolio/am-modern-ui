import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class GetJournalEntriesUseCase {
  GetJournalEntriesUseCase(this._repository);

  final JournalRepository _repository;

  Future<JournalEntry> getById(String entryId) {
    return _repository.getJournalEntry(entryId);
  }

  Future<List<JournalEntry>> getByUser({Map<String, dynamic>? query}) {
    return _repository.getJournalEntriesByUser(query: query);
  }

  Future<List<JournalEntry>> getByTrade(String tradeId) {
    return _repository.getJournalEntriesByTrade(tradeId);
  }

  Future<List<JournalEntry>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _repository.getJournalEntriesByDateRange(startDate, endDate);
  }
}
