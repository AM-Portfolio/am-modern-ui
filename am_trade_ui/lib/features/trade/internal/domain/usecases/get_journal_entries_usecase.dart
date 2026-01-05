import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class GetJournalEntriesUseCase {
  GetJournalEntriesUseCase(this._repository);

  final JournalRepository _repository;

  Future<JournalEntry> getById(String entryId) {
    return _repository.getJournalEntry(entryId);
  }

  Future<List<JournalEntry>> getByUser(String userId) {
    return _repository.getJournalEntriesByUser(userId);
  }

  Future<List<JournalEntry>> getByTrade(String tradeId) {
    return _repository.getJournalEntriesByTrade(tradeId);
  }

  Future<List<JournalEntry>> getByDateRange(String userId, DateTime startDate, DateTime endDate) {
    return _repository.getJournalEntriesByDateRange(userId, startDate, endDate);
  }
}
