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

  factory BehaviorPatternSummary.fromJson(Map<String, dynamic> json) =>
      _$BehaviorPatternSummaryFromJson(json);
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

  factory JournalAttachment.fromJson(Map<String, dynamic> json) =>
      _$JournalAttachmentFromJson(json);
}

@freezed
abstract class PreTradePlan with _$PreTradePlan {
  const factory PreTradePlan({
    String? setupDescription,
    String? entryRationale,
    String? marketContext,
    String? strategy,
    String? setup,
    double? plannedEntryPrice,
    double? plannedStopLoss,
    double? plannedTarget,
    double? plannedQuantity,
    double? plannedRiskAmount,
    double? plannedRiskPercent,
    double? plannedRRRatio,
    @Default([]) List<String> setupChecklist,
    @Default([]) List<String> confirmedChecklistItems,
  }) = _PreTradePlan;

  factory PreTradePlan.fromJson(Map<String, dynamic> json) =>
      _$PreTradePlanFromJson(json);
}

@freezed
abstract class TradeExecution with _$TradeExecution {
  const factory TradeExecution({
    DateTime? entryDateTime,
    double? actualEntryPrice,
    double? quantity,
    String? broker,
    String? orderType,
    String? externalOrderId,
    String? notes,
  }) = _TradeExecution;

  factory TradeExecution.fromJson(Map<String, dynamic> json) =>
      _$TradeExecutionFromJson(json);
}

@freezed
abstract class PostTradeReview with _$PostTradeReview {
  const factory PostTradeReview({
    DateTime? exitDateTime,
    double? actualExitPrice,
    double? actualPnl,
    double? actualRMultiple,
    String? followedStopLoss,
    String? followedTarget,
    String? tradeOutcome,
    String? whatWentWell,
    String? whatCouldBeImproved,
    String? lessonLearned,
    String? mistakeCategory,
    int? executionScore,
    String? emotionalState,
    @Default([]) List<String> postChecklist,
    @Default([]) List<String> completedChecklistItems,
  }) = _PostTradeReview;

  factory PostTradeReview.fromJson(Map<String, dynamic> json) =>
      _$PostTradeReviewFromJson(json);
}

@freezed
abstract class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    required String id,
    required String userId,
    required String title,
    String? content,
    required DateTime entryDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? tradeId,
    String? entryType,
    String? journalStatus,
    String? symbol,
    String? setup,
    String? tradeDirection,
    String? folderId,
    String? playbookId,
    PreTradePlan? preTradePlan,
    TradeExecution? tradeExecution,
    PostTradeReview? postTradeReview,
    double? planAdherenceScore,
    double? checklistCompletionPct,
    @Default([]) List<BehaviorPatternSummary> behaviorPatternSummaries,
    @Default({}) Map<String, dynamic> customFields,
    @Deprecated('Use attachments instead') @Default([]) List<String> imageUrls,
    @Default([]) List<JournalAttachment> attachments,
    @Default([]) List<String> relatedTradeIds,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> chartUrls,
    @Default([]) List<String> documentUrls,
    @Default([]) List<String> videoUrls,
    @Default([]) List<String> externalUrls,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}
