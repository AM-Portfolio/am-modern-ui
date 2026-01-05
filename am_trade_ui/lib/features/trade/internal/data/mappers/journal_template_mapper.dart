import '../../domain/entities/journal_template.dart';
import '../../domain/entities/template_field.dart';
import '../../domain/enums/journal_template_category.dart';
import '../../domain/enums/template_field_type.dart';
import '../dtos/journal_template_dto.dart';

/// Mapper for converting between journal template domain entities and DTOs
class JournalTemplateMapper {
  /// Convert TemplateFieldResponseDto to TemplateField entity
  static TemplateField fromFieldResponseDto(TemplateFieldResponseDto dto) {
    return TemplateField(
      fieldId: dto.fieldId,
      fieldLabel: dto.fieldLabel,
      fieldType: TemplateFieldType.fromString(dto.fieldType),
      placeholder: dto.placeholder,
      defaultValue: dto.defaultValue,
      required: dto.required ?? false,
      order: dto.order ?? 0,
      options: dto.options,
      minLength: dto.minLength,
      maxLength: dto.maxLength,
      validationPattern: dto.validationPattern,
      helpText: dto.helpText,
    );
  }

  /// Convert TemplateField entity to TemplateFieldRequestDto
  static TemplateFieldRequestDto toFieldRequestDto(TemplateField field) {
    return TemplateFieldRequestDto(
      fieldId: field.fieldId,
      fieldLabel: field.fieldLabel,
      fieldType: field.fieldType.value,
      placeholder: field.placeholder,
      defaultValue: field.defaultValue,
      required: field.required,
      order: field.order,
      options: field.options,
      minLength: field.minLength,
      maxLength: field.maxLength,
      validationPattern: field.validationPattern,
      helpText: field.helpText,
    );
  }

  /// Convert JournalTemplateResponseDto to JournalTemplate entity
  static JournalTemplate fromResponseDto(JournalTemplateResponseDto dto) {
    return JournalTemplate(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      category: JournalTemplateCategory.fromString(dto.category),
      fields: dto.fields?.map(fromFieldResponseDto).toList() ?? [],
      isSystemTemplate: dto.isSystemTemplate ?? false,
      isRecommended: dto.isRecommended ?? false,
      usageCount: dto.usageCount ?? 0,
      createdBy: dto.createdBy,
      isFavorite: dto.isFavorite ?? false,
      tags: dto.tags ?? [],
      thumbnailUrl: dto.thumbnailUrl,
      createdAt: dto.createdAt != null ? DateTime.tryParse(dto.createdAt!) : null,
      updatedAt: dto.updatedAt != null ? DateTime.tryParse(dto.updatedAt!) : null,
    );
  }

  /// Convert JournalTemplate entity to JournalTemplateRequestDto
  static JournalTemplateRequestDto toRequestDto(
    JournalTemplate template,
  ) {
    return JournalTemplateRequestDto(
      name: template.name,
      description: template.description,
      category: template.category.value,
      fields: template.fields.map(toFieldRequestDto).toList(),
      isSystemTemplate: template.isSystemTemplate,
      isRecommended: template.isRecommended,
      createdBy: template.createdBy,
      tags: template.tags,
      thumbnailUrl: template.thumbnailUrl,
    );
  }

  /// Convert field values map to TemplateFieldRequestDto list
  static List<TemplateFieldRequestDto> fieldValuesToRequestDtos(
    Map<String, dynamic> fieldValues,
  ) {
    return fieldValues.entries.map((entry) {
      return TemplateFieldRequestDto(
        fieldId: entry.key,
        fieldLabel: entry.key,
        fieldType: 'TEXT', // Default type, actual type should come from template
        defaultValue: entry.value?.toString(),
      );
    }).toList();
  }
}
