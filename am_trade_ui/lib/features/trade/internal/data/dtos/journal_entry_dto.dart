import 'package:json_annotation/json_annotation.dart';

part 'journal_entry_dto.g.dart';

/// DTO for behavior pattern summary within a journal entry
@JsonSerializable(explicitToJson: true)
class BehaviorPatternSummaryDto {
  const BehaviorPatternSummaryDto({
    required this.summary,
    this.mood,
    this.marketSentiment,
    this.tags,
  });

  factory BehaviorPatternSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$BehaviorPatternSummaryDtoFromJson(json);

  final String summary;
  final String? mood;
  final int? marketSentiment;
  final List<String>? tags;

  Map<String, dynamic> toJson() => _$BehaviorPatternSummaryDtoToJson(this);
}

/// DTO for journal entry attachments
@JsonSerializable(explicitToJson: true)
class JournalAttachmentDto {
  const JournalAttachmentDto({
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.uploadedAt,
    this.description,
  });

  factory JournalAttachmentDto.fromJson(Map<String, dynamic> json) =>
      _$JournalAttachmentDtoFromJson(json);

  final String fileName;
  final String fileUrl;
  final String? fileType;
  final String? uploadedAt;
  final String? description;

  Map<String, dynamic> toJson() => _$JournalAttachmentDtoToJson(this);
}

/// DTO for Pre-Trade Plan
@JsonSerializable(explicitToJson: true)
class PreTradePlanDto {
  const PreTradePlanDto({
    this.setupDescription,
    this.entryRationale,
    this.marketContext,
    this.strategy,
    this.setup,
    this.plannedEntryPrice,
    this.plannedStopLoss,
    this.plannedTarget,
    this.plannedQuantity,
    this.plannedRiskAmount,
    this.plannedRiskPercent,
    this.plannedRRRatio,
    this.setupChecklist,
    this.confirmedChecklistItems,
  });

  factory PreTradePlanDto.fromJson(Map<String, dynamic> json) =>
      _$PreTradePlanDtoFromJson(json);

  final String? setupDescription;
  final String? entryRationale;
  final String? marketContext;
  final String? strategy;
  final String? setup;
  final double? plannedEntryPrice;
  final double? plannedStopLoss;
  final double? plannedTarget;
  final double? plannedQuantity;
  final double? plannedRiskAmount;
  final double? plannedRiskPercent;
  final double? plannedRRRatio;
  final List<String>? setupChecklist;
  final List<String>? confirmedChecklistItems;

  Map<String, dynamic> toJson() => _$PreTradePlanDtoToJson(this);
}

/// DTO for Trade Execution
@JsonSerializable(explicitToJson: true)
class TradeExecutionDto {
  const TradeExecutionDto({
    this.entryDateTime,
    this.actualEntryPrice,
    this.quantity,
    this.broker,
    this.orderType,
    this.externalOrderId,
    this.notes,
  });

  factory TradeExecutionDto.fromJson(Map<String, dynamic> json) =>
      _$TradeExecutionDtoFromJson(json);

  final String? entryDateTime;
  final double? actualEntryPrice;
  final double? quantity;
  final String? broker;
  final String? orderType;
  final String? externalOrderId;
  final String? notes;

  Map<String, dynamic> toJson() => _$TradeExecutionDtoToJson(this);
}

/// DTO for Post-Trade Review
@JsonSerializable(explicitToJson: true)
class PostTradeReviewDto {
  const PostTradeReviewDto({
    this.exitDateTime,
    this.actualExitPrice,
    this.actualPnl,
    this.actualRMultiple,
    this.followedStopLoss,
    this.followedTarget,
    this.tradeOutcome,
    this.whatWentWell,
    this.whatCouldBeImproved,
    this.lessonLearned,
    this.mistakeCategory,
    this.executionScore,
    this.emotionalState,
    this.postChecklist,
    this.completedChecklistItems,
  });

  factory PostTradeReviewDto.fromJson(Map<String, dynamic> json) =>
      _$PostTradeReviewDtoFromJson(json);

  final String? exitDateTime;
  final double? actualExitPrice;
  final double? actualPnl;
  final double? actualRMultiple;
  final String? followedStopLoss;
  final String? followedTarget;
  final String? tradeOutcome;
  final String? whatWentWell;
  final String? whatCouldBeImproved;
  final String? lessonLearned;
  final String? mistakeCategory;
  final int? executionScore;
  final String? emotionalState;
  final List<String>? postChecklist;
  final List<String>? completedChecklistItems;

  Map<String, dynamic> toJson() => _$PostTradeReviewDtoToJson(this);
}

/// DTO for creating/updating a journal entry
@JsonSerializable(explicitToJson: true)
class TradeJournalEntryRequestDto {
  const TradeJournalEntryRequestDto({
    this.tradeId,
    required this.title,
    this.content,
    required this.entryDate,
    this.entryType,
    this.journalStatus,
    this.symbol,
    this.setup,
    this.tradeDirection,
    this.folderId,
    this.playbookId,
    this.preTradePlan,
    this.tradeExecution,
    this.postTradeReview,
    this.planAdherenceScore,
    this.checklistCompletionPct,
    this.behaviorPatternSummaries,
    this.customFields,
    this.imageUrls,
    this.attachments,
    this.relatedTradeIds,
    this.tagIds,
    this.chartUrls,
    this.documentUrls,
    this.videoUrls,
    this.externalUrls,
  });

  factory TradeJournalEntryRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TradeJournalEntryRequestDtoFromJson(json);

  final String? tradeId;
  final String title;
  final String? content;
  final String? entryType;
  final String? journalStatus;
  final String? symbol;
  final String? setup;
  final String? tradeDirection;
  final String? folderId;
  final String? playbookId;
  final PreTradePlanDto? preTradePlan;
  final TradeExecutionDto? tradeExecution;
  final PostTradeReviewDto? postTradeReview;
  final double? planAdherenceScore;
  final double? checklistCompletionPct;
  final List<BehaviorPatternSummaryDto>? behaviorPatternSummaries;
  final Map<String, dynamic>? customFields;
  final String entryDate;
  @Deprecated('Use attachments instead')
  final List<String>? imageUrls;
  final List<JournalAttachmentDto>? attachments;
  final List<String>? relatedTradeIds;
  final List<String>? tagIds;
  final List<String>? chartUrls;
  final List<String>? documentUrls;
  final List<String>? videoUrls;
  final List<String>? externalUrls;

  Map<String, dynamic> toJson() => _$TradeJournalEntryRequestDtoToJson(this);
}

/// DTO for journal entry response
@JsonSerializable(explicitToJson: true)
class TradeJournalEntryResponseDto {
  const TradeJournalEntryResponseDto({
    required this.id,
    required this.userId,
    this.tradeId,
    required this.title,
    this.content,
    required this.entryDate,
    required this.createdAt,
    required this.updatedAt,
    this.entryType,
    this.journalStatus,
    this.symbol,
    this.setup,
    this.tradeDirection,
    this.folderId,
    this.playbookId,
    this.preTradePlan,
    this.tradeExecution,
    this.postTradeReview,
    this.planAdherenceScore,
    this.checklistCompletionPct,
    this.behaviorPatternSummaries,
    this.customFields,
    this.imageUrls,
    this.attachments,
    this.relatedTradeIds,
    this.tagIds,
    this.chartUrls,
    this.documentUrls,
    this.videoUrls,
    this.externalUrls,
  });

  factory TradeJournalEntryResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TradeJournalEntryResponseDtoFromJson(json);

  final String id;
  final String userId;
  final String? tradeId;
  final String title;
  final String? content;
  final String? entryType;
  final String? journalStatus;
  final String? symbol;
  final String? setup;
  final String? tradeDirection;
  final String? folderId;
  final String? playbookId;
  final PreTradePlanDto? preTradePlan;
  final TradeExecutionDto? tradeExecution;
  final PostTradeReviewDto? postTradeReview;
  final double? planAdherenceScore;
  final double? checklistCompletionPct;
  final List<BehaviorPatternSummaryDto>? behaviorPatternSummaries;
  final Map<String, dynamic>? customFields;
  final String entryDate;
  @Deprecated('Use attachments instead')
  final List<String>? imageUrls;
  final List<JournalAttachmentDto>? attachments;
  final List<String>? relatedTradeIds;
  final List<String>? tagIds;
  final List<String>? chartUrls;
  final List<String>? documentUrls;
  final List<String>? videoUrls;
  final List<String>? externalUrls;
  final String createdAt;
  final String updatedAt;

  Map<String, dynamic> toJson() => _$TradeJournalEntryResponseDtoToJson(this);
}

/// DTO for journal entry list response
@JsonSerializable()
class JournalEntryListResponseDto {
  const JournalEntryListResponseDto({required this.content});

  factory JournalEntryListResponseDto.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryListResponseDtoFromJson(json);

  final List<TradeJournalEntryResponseDto> content;

  Map<String, dynamic> toJson() => _$JournalEntryListResponseDtoToJson(this);
}

/// Summary metrics from GET /v1/journal/summary
@JsonSerializable()
class JournalSummaryDto {
  const JournalSummaryDto({
    this.totalTrades = 0,
    this.totalPnl,
    this.winRate,
    this.avgRR,
    this.plannedCount = 0,
    this.openCount = 0,
    this.completedCount = 0,
    this.archivedCount = 0,
  });

  factory JournalSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$JournalSummaryDtoFromJson(json);

  final int totalTrades;
  final double? totalPnl;
  final double? winRate;
  final double? avgRR;
  final int plannedCount;
  final int openCount;
  final int completedCount;
  final int archivedCount;

  Map<String, dynamic> toJson() => _$JournalSummaryDtoToJson(this);
}

@JsonSerializable()
class MistakeAnalysisDto {
  const MistakeAnalysisDto({
    this.mistakeCategory,
    this.occurrenceCount = 0,
    this.totalPnlImpact,
    this.avgPnlPerOccurrence,
    this.percentageOfLosses,
  });

  factory MistakeAnalysisDto.fromJson(Map<String, dynamic> json) =>
      _$MistakeAnalysisDtoFromJson(json);

  final String? mistakeCategory;
  final int occurrenceCount;
  final double? totalPnlImpact;
  final double? avgPnlPerOccurrence;
  final double? percentageOfLosses;

  Map<String, dynamic> toJson() => _$MistakeAnalysisDtoToJson(this);
}

@JsonSerializable()
class LessonLearnedDto {
  const LessonLearnedDto({
    this.entryId,
    this.symbol,
    this.lessonLearned,
    this.entryDate,
    this.mistakeCategory,
    this.executionScore,
  });

  factory LessonLearnedDto.fromJson(Map<String, dynamic> json) =>
      _$LessonLearnedDtoFromJson(json);

  final String? entryId;
  final String? symbol;
  final String? lessonLearned;
  final String? entryDate;
  final String? mistakeCategory;
  final int? executionScore;

  Map<String, dynamic> toJson() => _$LessonLearnedDtoToJson(this);
}

@JsonSerializable()
class JournalAdherenceDto {
  const JournalAdherenceDto({
    this.avgPlanAdherenceScore,
    this.avgChecklistCompletionPct,
    this.avgExecutionScore,
    this.sampleSize = 0,
  });

  factory JournalAdherenceDto.fromJson(Map<String, dynamic> json) =>
      _$JournalAdherenceDtoFromJson(json);

  final double? avgPlanAdherenceScore;
  final double? avgChecklistCompletionPct;
  final double? avgExecutionScore;
  final int sampleSize;

  Map<String, dynamic> toJson() => _$JournalAdherenceDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JournalReportCardDto {
  const JournalReportCardDto({
    this.from,
    this.to,
    this.summary,
    this.mistakes,
    this.adherence,
    this.topLessons,
  });

  factory JournalReportCardDto.fromJson(Map<String, dynamic> json) =>
      _$JournalReportCardDtoFromJson(json);

  final String? from;
  final String? to;
  final JournalSummaryDto? summary;
  final List<MistakeAnalysisDto>? mistakes;
  final JournalAdherenceDto? adherence;
  final List<LessonLearnedDto>? topLessons;

  Map<String, dynamic> toJson() => _$JournalReportCardDtoToJson(this);
}
