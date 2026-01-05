import 'package:json_annotation/json_annotation.dart';

part 'journal_template_dto.g.dart';

/// DTO for template field request
@JsonSerializable(explicitToJson: true)
class TemplateFieldRequestDto {
  const TemplateFieldRequestDto({
    required this.fieldId,
    required this.fieldLabel,
    required this.fieldType,
    this.placeholder,
    this.defaultValue,
    this.required,
    this.order,
    this.options,
    this.minLength,
    this.maxLength,
    this.validationPattern,
    this.helpText,
  });

  factory TemplateFieldRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TemplateFieldRequestDtoFromJson(json);

  final String fieldId;
  final String fieldLabel;
  final String fieldType;
  final String? placeholder;
  final String? defaultValue;
  final bool? required;
  final int? order;
  final List<String>? options;
  final int? minLength;
  final int? maxLength;
  final String? validationPattern;
  final String? helpText;

  Map<String, dynamic> toJson() => _$TemplateFieldRequestDtoToJson(this);
}

/// DTO for template field response
@JsonSerializable(explicitToJson: true)
class TemplateFieldResponseDto {
  const TemplateFieldResponseDto({
    required this.fieldId,
    required this.fieldLabel,
    required this.fieldType,
    this.placeholder,
    this.defaultValue,
    this.required,
    this.order,
    this.options,
    this.minLength,
    this.maxLength,
    this.validationPattern,
    this.helpText,
  });

  factory TemplateFieldResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TemplateFieldResponseDtoFromJson(json);

  final String fieldId;
  final String fieldLabel;
  final String fieldType;
  final String? placeholder;
  final String? defaultValue;
  final bool? required;
  final int? order;
  final List<String>? options;
  final int? minLength;
  final int? maxLength;
  final String? validationPattern;
  final String? helpText;

  Map<String, dynamic> toJson() => _$TemplateFieldResponseDtoToJson(this);
}

/// DTO for creating/updating a journal template
@JsonSerializable(explicitToJson: true)
class JournalTemplateRequestDto {
  const JournalTemplateRequestDto({
    required this.name,
    required this.category,
    required this.createdBy,
    this.description,
    this.fields,
    this.isSystemTemplate,
    this.isRecommended,
    this.tags,
    this.thumbnailUrl,
  });

  factory JournalTemplateRequestDto.fromJson(Map<String, dynamic> json) =>
      _$JournalTemplateRequestDtoFromJson(json);

  final String name;
  final String? description;
  final String category;
  final List<TemplateFieldRequestDto>? fields;
  final bool? isSystemTemplate;
  final bool? isRecommended;
  final String createdBy;
  final List<String>? tags;
  final String? thumbnailUrl;

  Map<String, dynamic> toJson() => _$JournalTemplateRequestDtoToJson(this);
}

/// DTO for journal template response
@JsonSerializable(explicitToJson: true)
class JournalTemplateResponseDto {
  const JournalTemplateResponseDto({
    required this.id,
    required this.name,
    required this.category,
    required this.createdBy,
    this.description,
    this.fields,
    this.isSystemTemplate,
    this.isRecommended,
    this.usageCount,
    this.isFavorite,
    this.tags,
    this.thumbnailUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory JournalTemplateResponseDto.fromJson(Map<String, dynamic> json) =>
      _$JournalTemplateResponseDtoFromJson(json);

  final String id;
  final String name;
  final String? description;
  final String category;
  final List<TemplateFieldResponseDto>? fields;
  final bool? isSystemTemplate;
  final bool? isRecommended;
  final int? usageCount;
  final String createdBy;
  final bool? isFavorite;
  final List<String>? tags;
  final String? thumbnailUrl;
  final String? createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() => _$JournalTemplateResponseDtoToJson(this);
}

/// DTO for using a template request
@JsonSerializable(explicitToJson: true)
class UseTemplateRequestDto {
  const UseTemplateRequestDto({
    required this.userId,
    required this.templateId,
    required this.fieldValues,
    this.tradeId,
    this.customTitle,
  });

  factory UseTemplateRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UseTemplateRequestDtoFromJson(json);

  final String userId;
  final String templateId;
  final Map<String, dynamic> fieldValues;
  final String? tradeId;
  final String? customTitle;

  Map<String, dynamic> toJson() => _$UseTemplateRequestDtoToJson(this);
}
