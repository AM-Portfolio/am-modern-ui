import '../../../internal/domain/entities/journal_entry.dart';
import '../../../internal/domain/entities/notebook_item.dart';

/// Built-in notebook folders → journal entryType mapping.
class JournalFolderFilter {
  JournalFolderFilter._();

  static const allNotes = 'All notes';
  static const tradeNotes = 'Trade Notes';
  static const dailyJournal = 'Daily Journal';
  static const sessionsRecap = 'Sessions Recap';
  static const recentlyDeleted = 'Recently Deleted';

  /// Default `entryType` when creating from this folder.
  static String? createEntryType(String folder) {
    switch (folder) {
      case tradeNotes:
        return 'TRADE_NOTE';
      case dailyJournal:
        return 'DAILY';
      case sessionsRecap:
        return 'SESSION';
      case allNotes:
      case recentlyDeleted:
        return 'DAILY';
      default:
        return 'GENERAL';
    }
  }

  /// Notebook folder document id for custom folders; null for built-ins.
  static String? createFolderId(
    String folder, {
    List<NotebookItem> notebookFolders = const [],
  }) {
    switch (folder) {
      case allNotes:
      case tradeNotes:
      case dailyJournal:
      case sessionsRecap:
      case recentlyDeleted:
        return null;
      default:
        final match = notebookFolders.where((f) => f.title == folder);
        if (match.isEmpty) return null;
        final id = match.first.id;
        return (id == null || id.isEmpty) ? null : id;
    }
  }

  /// Maps drag-drop target ids from the sidebar to entryType / folderId.
  static ({String? entryType, String? folderId}) dropTargetMapping(
    String targetId,
  ) {
    switch (targetId) {
      case 'all-notes':
        return (entryType: null, folderId: null);
      case 'trade-notes':
        return (entryType: 'TRADE_NOTE', folderId: null);
      case 'daily-journal':
        return (entryType: 'DAILY', folderId: null);
      case 'sessions-recap':
        return (entryType: 'SESSION', folderId: null);
      default:
        return (entryType: 'GENERAL', folderId: targetId);
    }
  }

  static String listTitle(String folder) {
    switch (folder) {
      case tradeNotes:
        return 'Trade notes';
      case dailyJournal:
        return 'Daily journal';
      case sessionsRecap:
        return 'Sessions';
      case recentlyDeleted:
        return 'Recently deleted';
      case allNotes:
        return 'All notes';
      default:
        return folder;
    }
  }

  static String emptyMessage(String folder) {
    switch (folder) {
      case tradeNotes:
        return 'No trade notes yet.\nLog a trade-linked entry to see it here.';
      case dailyJournal:
        return 'No daily journals yet.\nTap Log Day to start.';
      case sessionsRecap:
        return 'No session recaps yet.\nCreate a session journal to review here.';
      case recentlyDeleted:
        return 'Nothing in recently deleted.';
      default:
        return 'No journal entries yet.\nTap Log Day to start.';
    }
  }

  static List<JournalEntry> filter({
    required List<JournalEntry> entries,
    required String folder,
    List<NotebookItem> notebookFolders = const [],
  }) {
    switch (folder) {
      case allNotes:
        return List<JournalEntry>.from(entries);
      case tradeNotes:
        return entries.where(_isTradeNote).toList();
      case dailyJournal:
        return entries.where(_isDaily).toList();
      case sessionsRecap:
        return entries.where(_isSession).toList();
      case recentlyDeleted:
        return entries
            .where(
              (e) =>
                  (e.journalStatus ?? '').toUpperCase() == 'ARCHIVED' ||
                  (e.journalStatus ?? '').toUpperCase() == 'DELETED',
            )
            .toList();
      default:
        final match = notebookFolders.where((f) => f.title == folder);
        if (match.isEmpty) return List<JournalEntry>.from(entries);
        final id = match.first.id;
        if (id == null || id.isEmpty) {
          return List<JournalEntry>.from(entries);
        }
        return entries.where((e) => e.folderId == id).toList();
    }
  }

  static bool _isTradeNote(JournalEntry e) {
    final type = (e.entryType ?? '').toUpperCase();
    if (type == 'TRADE_NOTE' ||
        type == 'TRADE_JOURNAL' ||
        type == 'PRE_PLAN' ||
        type == 'POST_REVIEW' ||
        type == 'MISSED') {
      return true;
    }
    if (e.tradeId != null && e.tradeId!.trim().isNotEmpty) return true;
    return e.relatedTradeIds.isNotEmpty;
  }

  /// Trade-discipline entries open the Pre/Execute/Post workflow.
  static bool isTradeLikeEntry(JournalEntry e) => _isTradeNote(e);

  static bool _isDaily(JournalEntry e) {
    final type = (e.entryType ?? '').toUpperCase();
    return type == 'DAILY' || type == 'GENERAL' || type.isEmpty;
  }

  static bool _isSession(JournalEntry e) {
    final type = (e.entryType ?? '').toUpperCase();
    return type == 'SESSION';
  }
}
