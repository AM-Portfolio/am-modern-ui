import 'package:equatable/equatable.dart';
import '../enums/journal_template_category.dart';
import 'template_field.dart';

/// Entity representing a journal template
class JournalTemplate extends Equatable {
  const JournalTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.createdBy,
    this.description,
    this.fields = const [],
    this.isSystemTemplate = false,
    this.isRecommended = false,
    this.usageCount = 0,
    this.isFavorite = false,
    this.tags = const [],
    this.thumbnailUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final JournalTemplateCategory category;
  final List<TemplateField> fields;
  final bool isSystemTemplate;
  final bool isRecommended;
  final int usageCount;
  final String createdBy;
  final bool isFavorite;
  final List<String> tags;
  final String? thumbnailUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        fields,
        isSystemTemplate,
        isRecommended,
        usageCount,
        createdBy,
        isFavorite,
        tags,
        thumbnailUrl,
        createdAt,
        updatedAt,
      ];

  JournalTemplate copyWith({
    String? id,
    String? name,
    String? description,
    JournalTemplateCategory? category,
    List<TemplateField>? fields,
    bool? isSystemTemplate,
    bool? isRecommended,
    int? usageCount,
    String? createdBy,
    bool? isFavorite,
    List<String>? tags,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      fields: fields ?? this.fields,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      isRecommended: isRecommended ?? this.isRecommended,
      usageCount: usageCount ?? this.usageCount,
      createdBy: createdBy ?? this.createdBy,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
