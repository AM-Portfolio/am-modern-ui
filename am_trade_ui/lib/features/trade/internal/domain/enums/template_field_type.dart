/// Types of fields that can be used in journal templates
enum TemplateFieldType {
  text('TEXT', 'Text'),
  textarea('TEXTAREA', 'Text Area'),
  checkbox('CHECKBOX', 'Checkbox'),
  checkboxList('CHECKBOX_LIST', 'Checkbox List'),
  dropdown('DROPDOWN', 'Dropdown'),
  date('DATE', 'Date'),
  time('TIME', 'Time'),
  number('NUMBER', 'Number'),
  imageUpload('IMAGE_UPLOAD', 'Image Upload');

  const TemplateFieldType(this.value, this.displayName);

  final String value;
  final String displayName;

  static TemplateFieldType fromString(String value) {
    return TemplateFieldType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TemplateFieldType.text,
    );
  }
}
