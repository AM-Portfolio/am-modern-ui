import '../../../internal/domain/entities/journal_template.dart';
import '../../../internal/domain/entities/template_field.dart';
import '../../../internal/domain/enums/journal_template_category.dart' as api;
import '../../../internal/domain/enums/template_field_type.dart';
import 'journal_template_catalog.dart';

/// Maps backend [JournalTemplate] entities into the Log Day apply model.
JournalTemplateSelection journalTemplateToSelection(JournalTemplate template) {
  final checklist = <String>[];
  final prompts = <String>[];
  final seen = <String>{};

  String norm(String s) => s.trim().toLowerCase();

  void addChecklist(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final key = norm(t);
    if (seen.add(key)) checklist.add(t);
  }

  void addPrompt(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    if (_isGenericConfirmJunk(t)) return;
    final key = norm(t);
    if (seen.contains(key)) return;
    if (seen.add(key)) prompts.add(t);
  }

  for (final f in template.fields) {
    final label = f.fieldLabel.trim();
    final hint = _fieldHint(f);

    if (_fieldIsChecklistCandidate(f)) {
      if (label.isNotEmpty && !_isGenericConfirmJunk(label)) {
        addChecklist(label);
      }
    }

    if (hint != null) {
      if (norm(hint) == norm(label)) continue;
      if (_isGenericConfirmJunk(hint, equalsLabel: label)) continue;
      addPrompt(hint);
    }
  }

  return JournalTemplateSelection(
    name: template.name,
    description: template.description ?? 'Playbook from your library',
    icon: _iconFor(template.category),
    category: _mapCategory(template.category),
    tags: template.tags,
    checklistItems: checklist,
    notePrompts: prompts,
    planningSummary: template.description,
    previewSections: [
      if (checklist.isNotEmpty)
        JournalTemplateSection(
          title: 'Checklist',
          items: checklist,
        ),
      if (prompts.isNotEmpty)
        JournalTemplateSection(
          title: 'Prompts',
          items: prompts,
        ),
    ],
    recommended: template.isRecommended || template.isSystemTemplate,
    estimatedMinutes: 5,
    badgeLabel: template.isSystemTemplate ? 'System' : 'Playbook',
  );
}

String? _fieldHint(TemplateField f) {
  final ph = f.placeholder?.trim();
  final help = f.helpText?.trim();
  if (ph != null && ph.isNotEmpty) return ph;
  if (help != null && help.isNotEmpty) return help;
  return null;
}

bool _fieldIsChecklistCandidate(TemplateField f) {
  switch (f.fieldType) {
    case TemplateFieldType.checkbox:
    case TemplateFieldType.checkboxList:
      return true;
    default:
      break;
  }
  final label = f.fieldLabel.trim();
  if (label.isEmpty) return false;
  if (label.endsWith('?')) return false;
  if (label.length > 96) return false;
  return _looksLikeChecklistLabel(label);
}

bool _looksLikeChecklistLabel(String label) {
  final lower = label.toLowerCase();
  if (lower.startsWith('confirm ') ||
      lower.startsWith('check ') ||
      lower.startsWith('verify ') ||
      lower.startsWith('review ')) {
    return true;
  }
  const verbs = [
    'reviewed',
    'checked',
    'confirmed',
    'validated',
    'completed',
    'defined',
    'identified',
    'set ',
    'logged',
  ];
  for (final v in verbs) {
    if (lower.startsWith(v)) return true;
  }
  return false;
}

bool _isGenericConfirmJunk(String text, {String? equalsLabel}) {
  final t = text.trim();
  if (t.isEmpty) return true;
  if (equalsLabel != null && t.toLowerCase() == equalsLabel.trim().toLowerCase()) {
    return true;
  }
  final lower = t.toLowerCase();
  const junk = {
    'confirm before entry',
    'confirm before trade',
    'confirm entry',
    'yes',
    'no',
    'n/a',
  };
  if (junk.contains(lower)) return true;
  if (lower == 'confirm') return true;
  return lower.startsWith('confirm before');
}

JournalTemplateCategory _mapCategory(api.JournalTemplateCategory c) {
  return switch (c) {
    api.JournalTemplateCategory.dailyCheckin ||
    api.JournalTemplateCategory.preMarket =>
      JournalTemplateCategory.daily,
    api.JournalTemplateCategory.tradeRecap =>
      JournalTemplateCategory.tradeSetup,
    api.JournalTemplateCategory.postMarket ||
    api.JournalTemplateCategory.weeklyReview ||
    api.JournalTemplateCategory.monthlyReview ||
    api.JournalTemplateCategory.quarterlyReview =>
      JournalTemplateCategory.review,
    api.JournalTemplateCategory.custom => JournalTemplateCategory.custom,
  };
}

String _iconFor(api.JournalTemplateCategory c) {
  return switch (c) {
    api.JournalTemplateCategory.dailyCheckin => 'sun',
    api.JournalTemplateCategory.preMarket => 'sunrise',
    api.JournalTemplateCategory.postMarket => 'moon',
    api.JournalTemplateCategory.tradeRecap => 'chart',
    api.JournalTemplateCategory.weeklyReview => 'calendar',
    api.JournalTemplateCategory.monthlyReview => 'calendar',
    api.JournalTemplateCategory.quarterlyReview => 'calendar',
    api.JournalTemplateCategory.custom => 'edit',
  };
}
