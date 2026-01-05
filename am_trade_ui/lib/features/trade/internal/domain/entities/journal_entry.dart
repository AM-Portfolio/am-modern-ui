import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

@freezed
abstract class BehaviorPatternSummary with _$BehaviorPatternSummary {
  const factory BehaviorPatternSummary({
    required String summary,
    String? mood,
    int? marketSentiment,
    @Default([]) List<String> tags,
  }) = _BehaviorPatternSummary;

  factory BehaviorPatternSummary.fromJson(Map<String, dynamic> json) => _$BehaviorPatternSummaryFromJson(json);
}

@freezed
abstract class JournalAttachment with _$JournalAttachment {
  const factory JournalAttachment({
    required String fileName,
    required String fileUrl,
    String? fileType,
    DateTime? uploadedAt,
    String? description,
  }) = _JournalAttachment;

  factory JournalAttachment.fromJson(Map<String, dynamic> json) => _$JournalAttachmentFromJson(json);
}

@freezed
abstract class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    required String id,
    required String userId,
    required String title,
    required String content,
    required DateTime entryDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? tradeId,
    @Default([]) List<BehaviorPatternSummary> behaviorPatternSummaries,
    @Default({}) Map<String, dynamic> customFields,
    @Deprecated('Use attachments instead') @Default([]) List<String> imageUrls,
    @Default([]) List<JournalAttachment> attachments,
    @Default([]) List<String> relatedTradeIds,
    @Default([]) List<String> tagIds,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) => _$JournalEntryFromJson(json);
}
