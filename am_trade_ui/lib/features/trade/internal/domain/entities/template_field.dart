import 'package:equatable/equatable.dart';
import '../enums/template_field_type.dart';

/// Entity representing a field in a journal template
class TemplateField extends Equatable {
  const TemplateField({
    required this.fieldId,
    required this.fieldLabel,
    required this.fieldType,
    this.placeholder,
    this.defaultValue,
    this.required = false,
    this.order = 0,
    this.options,
    this.minLength,
    this.maxLength,
    this.validationPattern,
    this.helpText,
  });

  final String fieldId;
  final String fieldLabel;
  final TemplateFieldType fieldType;
  final String? placeholder;
  final String? defaultValue;
  final bool required;
  final int order;
  final List<String>? options;
  final int? minLength;
  final int? maxLength;
  final String? validationPattern;
  final String? helpText;

  @override
  List<Object?> get props => [
        fieldId,
        fieldLabel,
        fieldType,
        placeholder,
        defaultValue,
        required,
        order,
        options,
        minLength,
        maxLength,
        validationPattern,
        helpText,
      ];

  TemplateField copyWith({
    String? fieldId,
    String? fieldLabel,
    TemplateFieldType? fieldType,
    String? placeholder,
    String? defaultValue,
    bool? required,
    int? order,
    List<String>? options,
    int? minLength,
    int? maxLength,
    String? validationPattern,
    String? helpText,
  }) {
    return TemplateField(
      fieldId: fieldId ?? this.fieldId,
      fieldLabel: fieldLabel ?? this.fieldLabel,
      fieldType: fieldType ?? this.fieldType,
      placeholder: placeholder ?? this.placeholder,
      defaultValue: defaultValue ?? this.defaultValue,
      required: required ?? this.required,
      order: order ?? this.order,
      options: options ?? this.options,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      validationPattern: validationPattern ?? this.validationPattern,
      helpText: helpText ?? this.helpText,
    );
  }
}
