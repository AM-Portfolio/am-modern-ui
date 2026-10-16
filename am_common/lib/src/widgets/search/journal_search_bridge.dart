/// Journal hub registers [applySearchQuery] so Global Search can filter entries
/// via [JournalCubit.setFilters] without a second in-page search field.
class JournalSearchBridge {
  JournalSearchBridge._();

  static void Function(String query)? applySearchQuery;
  static void Function(String entryId)? focusEntry;

  /// Lightweight index for Global Search result rows (title / symbol / body / mistake).
  static List<JournalSearchIndexEntry> indexedEntries = const [];

  static void bind({
    required void Function(String query) applySearchQuery,
    void Function(String entryId)? focusEntry,
  }) {
    JournalSearchBridge.applySearchQuery = applySearchQuery;
    JournalSearchBridge.focusEntry = focusEntry;
  }

  static void unbind() {
    applySearchQuery = null;
    focusEntry = null;
    indexedEntries = const [];
  }

  static bool get isBound => applySearchQuery != null;

  static void tryApply(String query) {
    applySearchQuery?.call(query);
  }

  static void updateIndex(List<JournalSearchIndexEntry> entries) {
    indexedEntries = List<JournalSearchIndexEntry>.unmodifiable(entries);
  }

  /// Matches query against precomputed haystack; returns up to [limit] hits.
  static List<JournalSearchIndexEntry> searchLocal(String query, {int limit = 8}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty || indexedEntries.isEmpty) return const [];
    final out = <JournalSearchIndexEntry>[];
    for (final e in indexedEntries) {
      if (e.haystack.contains(q)) {
        out.add(e);
        if (out.length >= limit) break;
      }
    }
    return out;
  }
}

class JournalSearchIndexEntry {
  const JournalSearchIndexEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.haystack,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Lowercased concatenation of title, symbol, plain text, mistake, etc.
  final String haystack;
}
