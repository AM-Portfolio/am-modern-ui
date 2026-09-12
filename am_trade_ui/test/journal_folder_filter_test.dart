import 'package:am_trade_ui/features/trade/internal/domain/entities/journal_entry.dart';
import 'package:am_trade_ui/features/trade/presentation/journal/models/journal_folder_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JournalEntry entry({
    String? entryType,
    String? tradeId,
    List<String> related = const [],
  }) =>
      JournalEntry(
        id: '1',
        userId: 'u',
        title: 't',
        entryDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        entryType: entryType,
        tradeId: tradeId,
        relatedTradeIds: related,
      );

  test('isTradeLikeEntry detects trade types and linked trades', () {
    expect(
      JournalFolderFilter.isTradeLikeEntry(entry(entryType: 'TRADE_JOURNAL')),
      isTrue,
    );
    expect(
      JournalFolderFilter.isTradeLikeEntry(entry(entryType: 'DAILY')),
      isFalse,
    );
    expect(
      JournalFolderFilter.isTradeLikeEntry(entry(tradeId: 'tid-1')),
      isTrue,
    );
  });
}
