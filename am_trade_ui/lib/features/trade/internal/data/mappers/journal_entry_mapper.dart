import '../../domain/entities/journal_entry.dart';
import '../dtos/journal_entry_dto.dart';

/// Mapper for journal entry between DTO and domain entity
class JournalEntryMapper {
  /// Convert BehaviorPatternSummaryDto to BehaviorPatternSummary domain entity
  static BehaviorPatternSummary fromBehaviorPatternDto(
    BehaviorPatternSummaryDto dto,
  ) =>
      BehaviorPatternSummary(
        summary: dto.summary,
        mood: dto.mood,
        marketSentiment: dto.marketSentiment,
        tags: dto.tags ?? [],
      );

  /// Convert BehaviorPatternSummary entity to BehaviorPatternSummaryDto
  static BehaviorPatternSummaryDto toBehaviorPatternDto(
    BehaviorPatternSummary summary,
  ) =>
      BehaviorPatternSummaryDto(
        summary: summary.summary,
        mood: summary.mood,
        marketSentiment: summary.marketSentiment,
        tags: summary.tags.isNotEmpty ? summary.tags : null,
      );

  /// Convert JournalAttachmentDto to JournalAttachment domain entity
  static JournalAttachment fromAttachmentDto(JournalAttachmentDto dto) =>
      JournalAttachment(
        fileName: dto.fileName,
        fileUrl: dto.fileUrl,
        fileType: dto.fileType,
        uploadedAt:
            dto.uploadedAt != null ? DateTime.tryParse(dto.uploadedAt!) : null,
        description: dto.description,
      );

  /// Convert JournalAttachment entity to JournalAttachmentDto
  static JournalAttachmentDto toAttachmentDto(JournalAttachment attachment) =>
      JournalAttachmentDto(
        fileName: attachment.fileName,
        fileUrl: attachment.fileUrl,
        fileType: attachment.fileType,
        uploadedAt: attachment.uploadedAt?.toIso8601String(),
        description: attachment.description,
      );

  /// Convert PreTradePlanDto to PreTradePlan domain entity
  static PreTradePlan fromPreTradePlanDto(PreTradePlanDto dto) => PreTradePlan(
        setupDescription: dto.setupDescription,
        entryRationale: dto.entryRationale,
        marketContext: dto.marketContext,
        strategy: dto.strategy,
        setup: dto.setup,
        plannedEntryPrice: dto.plannedEntryPrice,
        plannedStopLoss: dto.plannedStopLoss,
        plannedTarget: dto.plannedTarget,
        plannedQuantity: dto.plannedQuantity,
        plannedRiskAmount: dto.plannedRiskAmount,
        plannedRiskPercent: dto.plannedRiskPercent,
        plannedRRRatio: dto.plannedRRRatio,
        setupChecklist: dto.setupChecklist ?? [],
        confirmedChecklistItems: dto.confirmedChecklistItems ?? [],
      );

  /// Convert PreTradePlan to PreTradePlanDto
  static PreTradePlanDto toPreTradePlanDto(PreTradePlan plan) => PreTradePlanDto(
        setupDescription: plan.setupDescription,
        entryRationale: plan.entryRationale,
        marketContext: plan.marketContext,
        strategy: plan.strategy,
        setup: plan.setup,
        plannedEntryPrice: plan.plannedEntryPrice,
        plannedStopLoss: plan.plannedStopLoss,
        plannedTarget: plan.plannedTarget,
        plannedQuantity: plan.plannedQuantity,
        plannedRiskAmount: plan.plannedRiskAmount,
        plannedRiskPercent: plan.plannedRiskPercent,
        plannedRRRatio: plan.plannedRRRatio,
        setupChecklist: plan.setupChecklist,
        confirmedChecklistItems: plan.confirmedChecklistItems,
      );

  static TradeExecution fromTradeExecutionDto(TradeExecutionDto dto) =>
      TradeExecution(
        entryDateTime: dto.entryDateTime != null
            ? DateTime.tryParse(dto.entryDateTime!)
            : null,
        actualEntryPrice: dto.actualEntryPrice,
        quantity: dto.quantity,
        broker: dto.broker,
        orderType: dto.orderType,
        externalOrderId: dto.externalOrderId,
        notes: dto.notes,
      );

  static TradeExecutionDto toTradeExecutionDto(TradeExecution execution) =>
      TradeExecutionDto(
        entryDateTime: execution.entryDateTime?.toIso8601String(),
        actualEntryPrice: execution.actualEntryPrice,
        quantity: execution.quantity,
        broker: execution.broker,
        orderType: execution.orderType,
        externalOrderId: execution.externalOrderId,
        notes: execution.notes,
      );

  /// Convert PostTradeReviewDto to PostTradeReview domain entity
  static PostTradeReview fromPostTradeReviewDto(PostTradeReviewDto dto) =>
      PostTradeReview(
        exitDateTime: dto.exitDateTime != null
            ? DateTime.tryParse(dto.exitDateTime!)
            : null,
        actualExitPrice: dto.actualExitPrice,
        actualPnl: dto.actualPnl,
        actualRMultiple: dto.actualRMultiple,
        followedStopLoss: dto.followedStopLoss,
        followedTarget: dto.followedTarget,
        tradeOutcome: dto.tradeOutcome,
        whatWentWell: dto.whatWentWell,
        whatCouldBeImproved: dto.whatCouldBeImproved,
        lessonLearned: dto.lessonLearned,
        mistakeCategory: dto.mistakeCategory,
        executionScore: dto.executionScore,
        emotionalState: dto.emotionalState,
        postChecklist: dto.postChecklist ?? [],
        completedChecklistItems: dto.completedChecklistItems ?? [],
      );

  /// Convert PostTradeReview to PostTradeReviewDto
  static PostTradeReviewDto toPostTradeReviewDto(PostTradeReview review) =>
      PostTradeReviewDto(
        exitDateTime: review.exitDateTime?.toIso8601String(),
        actualExitPrice: review.actualExitPrice,
        actualPnl: review.actualPnl,
        actualRMultiple: review.actualRMultiple,
        followedStopLoss: review.followedStopLoss,
        followedTarget: review.followedTarget,
        tradeOutcome: review.tradeOutcome,
        whatWentWell: review.whatWentWell,
        whatCouldBeImproved: review.whatCouldBeImproved,
        lessonLearned: review.lessonLearned,
        mistakeCategory: review.mistakeCategory,
        executionScore: review.executionScore,
        emotionalState: review.emotionalState,
        postChecklist: review.postChecklist,
        completedChecklistItems: review.completedChecklistItems,
      );

  /// Convert TradeJournalEntryResponseDto to JournalEntry domain entity
  static JournalEntry fromResponseDto(TradeJournalEntryResponseDto dto) =>
      JournalEntry(
        id: dto.id,
        userId: dto.userId,
        tradeId: dto.tradeId,
        title: dto.title,
        content: dto.content,
        entryType: dto.entryType,
        journalStatus: dto.journalStatus,
        symbol: dto.symbol,
        setup: dto.setup,
        tradeDirection: dto.tradeDirection,
        folderId: dto.folderId,
        playbookId: dto.playbookId,
        preTradePlan: dto.preTradePlan != null
            ? fromPreTradePlanDto(dto.preTradePlan!)
            : null,
        tradeExecution: dto.tradeExecution != null
            ? fromTradeExecutionDto(dto.tradeExecution!)
            : null,
        postTradeReview: dto.postTradeReview != null
            ? fromPostTradeReviewDto(dto.postTradeReview!)
            : null,
        planAdherenceScore: dto.planAdherenceScore,
        checklistCompletionPct: dto.checklistCompletionPct,
        behaviorPatternSummaries:
            dto.behaviorPatternSummaries?.map(fromBehaviorPatternDto).toList() ??
                [],
        customFields: dto.customFields ?? {},
        entryDate: DateTime.parse(dto.entryDate),
        imageUrls: dto.imageUrls ?? [],
        attachments: dto.attachments?.map(fromAttachmentDto).toList() ?? [],
        relatedTradeIds: dto.relatedTradeIds ?? [],
        tagIds: dto.tagIds ?? [],
        chartUrls: dto.chartUrls ?? [],
        documentUrls: dto.documentUrls ?? [],
        videoUrls: dto.videoUrls ?? [],
        externalUrls: dto.externalUrls ?? [],
        createdAt: DateTime.parse(dto.createdAt),
        updatedAt: DateTime.parse(dto.updatedAt),
      );

  /// Convert JournalEntry entity to TradeJournalEntryRequestDto
  static TradeJournalEntryRequestDto toRequestDto(JournalEntry entry) =>
      TradeJournalEntryRequestDto(
        title: entry.title,
        content: entry.content,
        entryType: entry.entryType,
        journalStatus: entry.journalStatus,
        symbol: entry.symbol,
        setup: entry.setup,
        tradeDirection: entry.tradeDirection,
        folderId: entry.folderId,
        playbookId: entry.playbookId,
        preTradePlan: entry.preTradePlan != null
            ? toPreTradePlanDto(entry.preTradePlan!)
            : null,
        tradeExecution: entry.tradeExecution != null
            ? toTradeExecutionDto(entry.tradeExecution!)
            : null,
        postTradeReview: entry.postTradeReview != null
            ? toPostTradeReviewDto(entry.postTradeReview!)
            : null,
        planAdherenceScore: entry.planAdherenceScore,
        checklistCompletionPct: entry.checklistCompletionPct,
        entryDate: entry.entryDate.toIso8601String(),
        tradeId: entry.tradeId,
        behaviorPatternSummaries: entry.behaviorPatternSummaries.isNotEmpty
            ? entry.behaviorPatternSummaries.map(toBehaviorPatternDto).toList()
            : null,
        customFields: entry.customFields,
        imageUrls: entry.imageUrls,
        attachments: entry.attachments.map(toAttachmentDto).toList(),
        relatedTradeIds: entry.relatedTradeIds,
        tagIds: entry.tagIds,
        chartUrls: entry.chartUrls.isNotEmpty ? entry.chartUrls : null,
        documentUrls: entry.documentUrls.isNotEmpty ? entry.documentUrls : null,
        videoUrls: entry.videoUrls.isNotEmpty ? entry.videoUrls : null,
        externalUrls: entry.externalUrls.isNotEmpty ? entry.externalUrls : null,
      );
}
