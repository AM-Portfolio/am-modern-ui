import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Preview / Quill section within a template (numbered block in the mockup).
class JournalTemplateSection {
  const JournalTemplateSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;
}

/// Template category for filter chips.
enum JournalTemplateCategory {
  daily,
  tradeSetup,
  review,
  custom,
}

/// Result when a user picks a journal template in the classic UI.
class JournalTemplateSelection {
  const JournalTemplateSelection({
    required this.name,
    required this.description,
    required this.icon,
    this.category = JournalTemplateCategory.tradeSetup,
    this.tags = const [],
    this.planningSummary,
    this.checklistItems = const [],
    this.fields = const [],
    this.notePrompts = const [],
    this.focusLine,
    this.previewSections = const [],
    this.recommended = false,
    this.estimatedMinutes = 5,
    this.badgeLabel,
    this.quote,
    this.isBlank = false,
  });

  final String name;
  final String description;
  final String icon;
  final JournalTemplateCategory category;
  final List<String> tags;
  final String? planningSummary;
  final List<String> checklistItems;
  final List<String> fields;
  final List<String> notePrompts;
  final String? focusLine;
  final List<JournalTemplateSection> previewSections;
  final bool recommended;
  final int estimatedMinutes;
  final String? badgeLabel;
  final String? quote;
  final bool isBlank;

  int get itemCount {
    if (previewSections.isNotEmpty) {
      return previewSections.fold<int>(
        0,
        (sum, s) => sum + s.items.length,
      );
    }
    return checklistItems.length;
  }

  List<String> get effectiveChecklist {
    if (previewSections.isNotEmpty) {
      return previewSections.expand((s) => s.items).toList();
    }
    return checklistItems;
  }

  /// Plain preview text for accessibility / fallback.
  String get previewText {
    final buf = StringBuffer()
      ..writeln(name.toUpperCase())
      ..writeln();
    if (previewSections.isNotEmpty) {
      for (final section in previewSections) {
        buf.writeln(section.title.toUpperCase());
        for (final item in section.items) {
          buf.writeln('☐  $item');
        }
        buf.writeln();
      }
    } else {
      buf.writeln('SETUP CHECKLIST');
      for (final item in checklistItems) {
        buf.writeln('☐  $item');
      }
    }
    return buf.toString().trimRight();
  }
}

/// Builds a typed Quill document (headers + real checklists) from a template.
quill.Document buildTemplateDocument(JournalTemplateSelection template) {
  if (template.isBlank) {
    return quill.Document();
  }

  final ops = <Map<String, dynamic>>[];

  void header(String text, {int level = 2}) {
    ops.add({
      'insert': '$text\n',
      'attributes': {'header': level},
    });
  }

  void paragraph(String text) {
    ops.add({'insert': '$text\n'});
  }

  void blank() => ops.add({'insert': '\n'});

  void checklist(String text) {
    ops.add({
      'insert': '$text\n',
      'attributes': {'list': 'unchecked'},
    });
  }

  void fieldLine(String label) {
    // Bold label + empty line to type into (no underscore blanks).
    ops
      ..add({
        'insert': '$label\n',
        'attributes': {'bold': true},
      })
      ..add({'insert': '\n'});
  }

  header(template.name, level: 1);
  paragraph('Tip: check items as you go, then type under each field.');
  blank();

  if (template.focusLine != null && template.focusLine!.trim().isNotEmpty) {
    paragraph(template.focusLine!);
    blank();
  }

  if (template.previewSections.isNotEmpty) {
    for (final section in template.previewSections) {
      header(section.title);
      for (final item in section.items) {
        checklist(item);
      }
      blank();
    }
  } else if (template.checklistItems.isNotEmpty) {
    header('Setup checklist');
    for (final item in template.checklistItems) {
      checklist(item);
    }
    blank();
  }

  if (template.fields.isNotEmpty) {
    header('Trade details');
    paragraph('Type your answers on the blank lines:');
    blank();
    for (final field in template.fields) {
      fieldLine(field);
    }
  }

  if (template.notePrompts.isNotEmpty) {
    header('Notes');
    for (final prompt in template.notePrompts) {
      ops.add({
        'insert': '$prompt\n',
        'attributes': {'italic': true},
      });
      blank();
    }
  }

  if (ops.isEmpty) {
    ops.add({'insert': '\n'});
  }

  return quill.Document.fromJson(ops);
}

/// Built-in journal templates (aligned with seeded system playbooks + mockup).
class JournalTemplateCatalog {
  JournalTemplateCatalog._();

  static const blank = JournalTemplateSelection(
    name: 'Blank Journal',
    description: 'Start from scratch with an empty entry.',
    icon: 'blank',
    category: JournalTemplateCategory.custom,
    isBlank: true,
    estimatedMinutes: 1,
    badgeLabel: 'CUSTOM',
  );

  static final List<JournalTemplateSelection> all = [
    JournalTemplateSelection(
      name: 'Daily Game Plan',
      icon: 'calendar',
      category: JournalTemplateCategory.daily,
      description:
          'A structured pre-market routine to define bias, watchlist, and risk before the open.',
      tags: const ['Discipline', 'Analysis', 'Patience', 'Daily Routine'],
      planningSummary: 'Pre-market preparation and plan',
      focusLine: 'Start the day with a clear plan before the open.',
      recommended: true,
      estimatedMinutes: 5,
      badgeLabel: 'DAILY TEMPLATE',
      quote: 'A well planned day leads to better trades.',
      previewSections: const [
        JournalTemplateSection(
          title: 'Market Outlook',
          items: [
            'Overall market sentiment',
            'Key global and domestic cues',
          ],
        ),
        JournalTemplateSection(
          title: 'Watchlist',
          items: [
            'Primary setups for today',
            'Levels to watch (support / resistance)',
          ],
        ),
        JournalTemplateSection(
          title: 'Trade Plan',
          items: [
            'Entry criteria',
            'Invalidation / stop rules',
          ],
        ),
        JournalTemplateSection(
          title: 'Risk & Mindset',
          items: [
            'Max loss for the day',
            'Emotional state check-in',
          ],
        ),
      ],
      checklistItems: const [
        'Overall market sentiment',
        'Key global and domestic cues',
        'Primary setups for today',
        'Levels to watch',
        'Entry criteria',
        'Invalidation / stop rules',
        'Max loss for the day',
        'Emotional state check-in',
      ],
      fields: const [
        'Overall bias',
        'Key levels',
        'Watchlist #1 (symbol / setup / entry / stop)',
        'Watchlist #2 (symbol / setup / entry / stop)',
        'Max loss (₹)',
        'Max size',
      ],
      notePrompts: const [
        'Focus for today:',
        'What would make today a success?',
      ],
    ),
    JournalTemplateSelection(
      name: 'Breakout Trade',
      icon: 'breakout',
      category: JournalTemplateCategory.tradeSetup,
      description: 'Level break with volume confirmation and clear invalidation.',
      tags: const ['Breakout', 'Equity', 'Swing', 'Support/Resistance'],
      planningSummary: 'Breakout plan — level, volume, invalidation',
      focusLine: 'Only take the breakout if volume and structure confirm.',
      recommended: true,
      estimatedMinutes: 6,
      badgeLabel: 'TRADE SETUP',
      quote: 'Wait for confirmation. Let the market come to you.',
      previewSections: const [
        JournalTemplateSection(
          title: 'Setup checklist',
          items: [
            'Trend aligned with setup',
            'Key level identified',
            'Volume confirmation',
            'Risk-reward > 2:1',
          ],
        ),
        JournalTemplateSection(
          title: 'Risk filters',
          items: [
            'No major news risk',
            'Emotionally neutral',
          ],
        ),
      ],
      checklistItems: const [
        'Trend aligned with setup',
        'Key level identified',
        'Volume confirmation',
        'Risk-reward > 2:1',
        'No major news risk',
        'Emotionally neutral',
      ],
      fields: const [
        'Symbol',
        'Direction (Long / Short)',
        'Setup (Resistance / Support breakout)',
        'Planned entry',
        'Stop loss',
        'Target',
        'Planned R:R',
      ],
      notePrompts: const [
        'Why this breakout?',
        'What invalidates the idea?',
      ],
    ),
    JournalTemplateSelection(
      name: 'Pullback Trade',
      icon: 'pullback',
      category: JournalTemplateCategory.tradeSetup,
      description: 'Trend continuation after a pullback into value.',
      tags: const ['Pattern', 'Equity', 'Swing', 'Patience'],
      planningSummary: 'Pullback into value — trend continuation',
      focusLine: 'Wait for value. Do not chase mid-move.',
      recommended: true,
      estimatedMinutes: 5,
      badgeLabel: 'TRADE SETUP',
      previewSections: const [
        JournalTemplateSection(
          title: 'Setup checklist',
          items: [
            'Higher-timeframe trend clear',
            'Pullback to value (MA / VWAP / zone)',
            'Trigger candle / reclaim defined',
            'Stop below / above structure',
            'R:R acceptable',
          ],
        ),
      ],
      checklistItems: const [
        'Higher-timeframe trend clear',
        'Pullback to value',
        'Trigger defined',
        'Stop below / above structure',
        'R:R acceptable',
      ],
      fields: const [
        'Symbol',
        'Trend direction',
        'Value area (MA / VWAP / zone)',
        'Entry',
        'Stop',
        'Target',
      ],
      notePrompts: const [
        'Why this pullback?',
        'Mistake to avoid: chasing mid-move / FOMO',
      ],
    ),
    JournalTemplateSelection(
      name: 'Reversal Trade',
      icon: 'reversal',
      category: JournalTemplateCategory.tradeSetup,
      description: 'Reversals at major S/R with confirmation.',
      tags: const ['Support/Resistance', 'Equity', 'Swing', 'Analysis'],
      planningSummary: 'Reversal at major S/R — confirmation required',
      focusLine: 'Size down vs trend trades. Wait for confirmation.',
      estimatedMinutes: 6,
      badgeLabel: 'TRADE SETUP',
      previewSections: const [
        JournalTemplateSection(
          title: 'Setup checklist',
          items: [
            'Major S/R identified',
            'Exhaustion / divergence signal',
            'Confirmation candle',
            'Defined invalidation',
            'Size reduced vs trend trades',
            'No conflicting news',
          ],
        ),
      ],
      checklistItems: const [
        'Major S/R identified',
        'Exhaustion / divergence',
        'Confirmation candle',
        'Invalidation defined',
        'Size reduced vs trend trades',
        'No conflicting news',
      ],
      fields: const [
        'Symbol',
        'Level type',
        'Confirmation',
        'Entry',
        'Stop',
        'Target',
      ],
      notePrompts: const ['Why reversal (not continuation)?'],
    ),
    JournalTemplateSelection(
      name: 'Opening Range',
      icon: 'opening',
      category: JournalTemplateCategory.tradeSetup,
      description: 'OR breakout or fade with time and spread rules.',
      tags: const ['Intraday', 'Breakout', 'OR'],
      planningSummary: 'Opening range — OR high/low, breakout or fade plan',
      focusLine: 'Mark OR high/low first. Decide breakout vs fade before entry.',
      estimatedMinutes: 4,
      badgeLabel: 'TRADE SETUP',
      previewSections: const [
        JournalTemplateSection(
          title: 'Setup checklist',
          items: [
            'OR high / low marked',
            'Breakout or fade plan ready',
            'Spread acceptable',
            'Time stop set',
            'News risk checked',
          ],
        ),
      ],
      checklistItems: const [
        'OR high/low marked',
        'Breakout or fade plan ready',
        'Spread acceptable',
        'Time stop set',
        'News risk checked',
      ],
      fields: const [
        'Instrument',
        'Session',
        'OR high',
        'OR low',
        'Plan (Breakout / Fade)',
        'Entry trigger',
        'Stop',
        'Target / scale plan',
      ],
      notePrompts: const ['Session notes:'],
    ),
    JournalTemplateSelection(
      name: 'Options Trade',
      icon: 'options',
      category: JournalTemplateCategory.tradeSetup,
      description: 'Options thesis with IV, DTE, max loss, and exit rules.',
      tags: const ['Options', 'Analysis', 'Discipline'],
      planningSummary: 'Options thesis — delta, IV, max loss, DTE',
      focusLine: 'Define max loss and exit rules before clicking buy/sell.',
      estimatedMinutes: 7,
      badgeLabel: 'TRADE SETUP',
      previewSections: const [
        JournalTemplateSection(
          title: 'Setup checklist',
          items: [
            'Underlying thesis clear',
            'IV rank checked',
            'Max loss defined',
            'DTE confirmed',
            'Exit rules written',
            'Event risk noted',
          ],
        ),
      ],
      checklistItems: const [
        'Underlying thesis clear',
        'IV rank checked',
        'Max loss defined',
        'DTE confirmed',
        'Exit rules written',
        'No lottery-ticket sizing',
        'Event risk noted',
      ],
      fields: const [
        'Underlying',
        'Strategy',
        'Strike / Exp / DTE',
        'Debit / Credit',
        'Max loss',
        'Targets',
      ],
      notePrompts: const ['Thesis:'],
    ),
    JournalTemplateSelection(
      name: 'Scalp Trade',
      icon: 'scalp',
      category: JournalTemplateCategory.tradeSetup,
      description: 'Quick intraday scalps with tight stop and time stop.',
      tags: const ['Intraday', 'Discipline', 'Patience'],
      planningSummary: 'Scalp — tight stop, time stop, no averaging',
      focusLine: 'Tight stop + time stop. Never average down.',
      estimatedMinutes: 3,
      badgeLabel: 'TRADE SETUP',
      previewSections: const [
        JournalTemplateSection(
          title: 'Setup checklist',
          items: [
            'Session window defined',
            'Level / micro-structure clear',
            'Tight stop set',
            'Time stop set',
            'No averaging down',
          ],
        ),
      ],
      checklistItems: const [
        'Session window defined',
        'Level clear',
        'Tight stop set',
        'Time stop set',
        'No averaging down',
      ],
      fields: const [
        'Symbol',
        'Session window',
        'Level',
        'Entry',
        'Stop',
        'Target',
        'Result',
      ],
      notePrompts: const ['Did I follow the time stop?'],
    ),
    JournalTemplateSelection(
      name: 'Weekly Review',
      icon: 'review',
      category: JournalTemplateCategory.review,
      description: 'End-of-week process review — wins, mistakes, and next focus.',
      tags: const ['Discipline', 'Analysis', 'Lesson'],
      planningSummary: 'Weekly review — process over P&L',
      focusLine: 'Judge the week by process quality, not just P&L.',
      estimatedMinutes: 10,
      badgeLabel: 'REVIEW',
      quote: 'Review the process. The P&L follows.',
      previewSections: const [
        JournalTemplateSection(
          title: 'Week summary',
          items: [
            'Best trade of the week',
            'Worst trade of the week',
          ],
        ),
        JournalTemplateSection(
          title: 'Process',
          items: [
            'Plan adherence score',
            'Repeated mistakes',
            'One improvement for next week',
          ],
        ),
      ],
      checklistItems: const [
        'Best trade of the week',
        'Worst trade of the week',
        'Plan adherence score',
        'Repeated mistakes',
        'One improvement for next week',
      ],
      notePrompts: const [
        'What will I do differently next week?',
      ],
    ),
  ];

  static JournalTemplateSelection byName(String name) =>
      all.firstWhere((t) => t.name == name, orElse: () => all.first);
}
