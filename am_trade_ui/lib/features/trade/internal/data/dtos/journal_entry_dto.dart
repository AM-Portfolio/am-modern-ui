import 'package:json_annotation/json_annotation.dart';

part 'journal_entry_dto.g.dart';

/// DTO for behavior pattern summary within a journal entry
@JsonSerializable(explicitToJson: true)
class BehaviorPatternSummaryDto {
  const BehaviorPatternSummaryDto({required this.summary, this.mood, this.marketSentiment, this.tags});

  factory BehaviorPatternSummaryDto.fromJson(Map<String, dynamic> json) => _$BehaviorPatternSummaryDtoFromJson(json);

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

  factory JournalAttachmentDto.fromJson(Map<String, dynamic> json) => _$JournalAttachmentDtoFromJson(json);

  final String fileName;
  final String fileUrl;
  final String? fileType;
  final String? uploadedAt;
  final String? description;

  Map<String, dynamic> toJson() => _$JournalAttachmentDtoToJson(this);
}

/// DTO for creating/updating a journal entry
@JsonSerializable(explicitToJson: true)
class TradeJournalEntryRequestDto {
  const TradeJournalEntryRequestDto({
    required this.userId,
    required this.title,
    required this.content,
    required this.entryDate,
    this.tradeId,
    this.behaviorPatternSummaries,
    this.customFields,
    this.imageUrls,
    this.attachments,
    this.relatedTradeIds,
    this.tagIds,
  });

  factory TradeJournalEntryRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TradeJournalEntryRequestDtoFromJson(json);

  final String userId;
  final String? tradeId;
  final String title;
  final String content;
  final List<BehaviorPatternSummaryDto>? behaviorPatternSummaries;
  final Map<String, dynamic>? customFields;
  final String entryDate;
  @Deprecated('Use attachments instead')
  final List<String>? imageUrls;
  final List<JournalAttachmentDto>? attachments;
  final List<String>? relatedTradeIds;
  final List<String>? tagIds;

  Map<String, dynamic> toJson() => _$TradeJournalEntryRequestDtoToJson(this);
}

/// DTO for journal entry response
@JsonSerializable(explicitToJson: true)
class TradeJournalEntryResponseDto {
  const TradeJournalEntryResponseDto({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.entryDate,
    required this.createdAt,
    required this.updatedAt,
    this.tradeId,
    this.behaviorPatternSummaries,
    this.customFields,
    this.imageUrls,
    this.attachments,
    this.relatedTradeIds,
    this.tagIds,
  });

  factory TradeJournalEntryResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TradeJournalEntryResponseDtoFromJson(json);

  final String id;
  final String userId;
  final String? tradeId;
  final String title;
  final String content;
  final List<BehaviorPatternSummaryDto>? behaviorPatternSummaries;
  final Map<String, dynamic>? customFields;
  final String entryDate;
  @Deprecated('Use attachments instead')
  final List<String>? imageUrls;
  final List<JournalAttachmentDto>? attachments;
  final List<String>? relatedTradeIds;
  final List<String>? tagIds;
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
