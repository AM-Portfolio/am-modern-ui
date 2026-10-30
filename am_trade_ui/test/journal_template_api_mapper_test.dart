import 'package:am_trade_ui/features/trade/internal/domain/entities/journal_template.dart';
import 'package:am_trade_ui/features/trade/internal/domain/entities/template_field.dart';
import 'package:am_trade_ui/features/trade/internal/domain/enums/journal_template_category.dart';
import 'package:am_trade_ui/features/trade/internal/domain/enums/template_field_type.dart';
import 'package:am_trade_ui/features/trade/presentation/journal/models/journal_template_api_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

JournalTemplate _template(List<TemplateField> fields) => JournalTemplate(
      id: 't1',
      name: 'Test',
      category: JournalTemplateCategory.dailyCheckin,
      createdBy: 'system',
      fields: fields,
    );

void main() {
  test('maps checklist fields and unique hints to prompts', () {
    final sel = journalTemplateToSelection(
      _template([
        const TemplateField(
          fieldId: '1',
          fieldLabel: 'Reviewed economic calendar',
          fieldType: TemplateFieldType.checkbox,
        ),
        const TemplateField(
          fieldId: '2',
          fieldLabel: 'What was your focus today?',
          fieldType: TemplateFieldType.textarea,
          placeholder: 'Describe your main focus for the session',
        ),
      ]),
    );

    expect(sel.checklistItems, ['Reviewed economic calendar']);
    expect(sel.notePrompts, ['Describe your main focus for the session']);
  });

  test('drops duplicate confirm junk and label-equals-placeholder', () {
    final sel = journalTemplateToSelection(
      _template([
        const TemplateField(
          fieldId: '1',
          fieldLabel: 'Confirm before entry',
          fieldType: TemplateFieldType.text,
          placeholder: 'Confirm before entry',
        ),
        const TemplateField(
          fieldId: '2',
          fieldLabel: 'Check risk limits',
          fieldType: TemplateFieldType.checkbox,
          helpText: 'Check risk limits',
        ),
      ]),
    );

    expect(sel.checklistItems, ['Check risk limits']);
    expect(sel.notePrompts, isEmpty);
  });
}
