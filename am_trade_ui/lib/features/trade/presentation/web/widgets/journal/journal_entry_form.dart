import 'dart:async';
import 'dart:convert';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../internal/domain/entities/journal_entry.dart';
import '../../../../providers/trade_internal_providers.dart';
import '../../../../trade_controller_providers.dart';
import '../../../cubit/journal/journal_cubit.dart';
import '../../../models/trade_holding_view_model.dart';
import 'components/journal_attachment_section.dart';
import 'components/journal_form_actions.dart';
import 'components/journal_trade_section.dart';
import 'sections/behavior_tracking_section.dart';
import 'sections/optional_fields_section.dart';
import 'utils/journal_border_labeled_panel.dart';
import 'utils/journal_field_decoration.dart';
import 'utils/journal_form_helpers.dart';
import 'utils/journal_helpers.dart';
import 'widgets/rich_text_editor.dart';
import 'widgets/trade_overview_selector.dart';
import 'widgets/trade_preview_dialog.dart';
import '../../../journal/pages/trade_journal_workflow_page.dart';
import '../../../journal/widgets/journal_structured_review_section.dart';
import '../../../journal/widgets/simple_template_dialog.dart';

class JournalEntryForm extends ConsumerStatefulWidget {
  const JournalEntryForm({
    required this.cubit,
    required this.portfolioId,
    super.key,
    this.entry,
    this.showTemplateActions = false,
    this.defaultEntryType,
    this.defaultFolderId,
    this.initialTemplate,
    this.onCreated,
    this.onBrowseTemplates,
    this.onCancelCreate,
    this.onEditModeChanged,
    this.compact = false,
  });

  final JournalCubit cubit;
  final String portfolioId;
  final JournalEntry? entry;
  /// When true, form shows its own template CTA (prefer header CTA in layout).
  final bool showTemplateActions;
  /// Used when creating a new entry (e.g. DAILY / TRADE_NOTE / SESSION).
  final String? defaultEntryType;
  /// Custom notebook folder id when creating from a user folder.
  final String? defaultFolderId;
  /// Apply once on create (Playbooks → Log Day).
  final JournalTemplateSelection? initialTemplate;
  final ValueChanged<String>? onCreated;
  final VoidCallback? onBrowseTemplates;
  /// Dismiss create mode without saving (Log day flow).
  final VoidCallback? onCancelCreate;
  /// Notifies the detail chrome when view ↔ edit toggles (header Edit button).
  final ValueChanged<bool>? onEditModeChanged;
  /// When true, enables mobile-optimized compact selectors and actions.
  final bool compact;

  @override
  ConsumerState<JournalEntryForm> createState() => JournalEntryFormState();
}

class JournalEntryFormState extends ConsumerState<JournalEntryForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  late TextEditingController _tradeIdController;
  late TextEditingController _urlController;
  late DateTime _entryDate;

  // Planning phase (pre-market)
  late TextEditingController _planningBehaviorController;
  String? _planningMood;
  String? _planningSentiment;

  // Mid phase (during trading)
  late TextEditingController _midBehaviorController;
  String? _midMood;
  String? _midSentiment;

  // End phase (market close)
  late TextEditingController _endBehaviorController;
  String? _endMood;
  String? _endSentiment;

  final Set<String> _selectedTags = {};
  List<String> _imageUrls = [];
  bool _isSubmitting = false;
  String? _urlPreview;
  bool _isUrlExpanded = false;

  // Trade overview states
  DateTime _tradeOverviewDate = DateTime.now();
  TradePeriodType _tradePeriod = TradePeriodType.daily;
  List<String> _relatedTradeIds = [];
  List<TradeHoldingViewModel> _availableTrades = [];
  bool _isEditMode = false; // View mode by default when editing existing entry
  String? _appliedTemplateName;

  /// Template checklist / prompts live outside Quill so users don't clear placeholders.
  List<String> _checklistItems = [];
  final Set<String> _completedChecklistItems = {};
  final Map<String, TextEditingController> _promptControllers = {};
  List<String> _templateFields = [];
  final Map<String, TextEditingController> _fieldControllers = {};
  String? _templateFocusTip;

  bool get isEditMode => _isEditMode;

  void enterEditMode() => _setEditMode(true);

  void exitEditMode() {
    if (widget.entry != null) {
      _initFormFields();
    }
    _setEditMode(false);
  }

  void _setEditMode(bool value) {
    if (_isEditMode == value) return;
    setState(() => _isEditMode = value);
    widget.onEditModeChanged?.call(value);
  }

  // Per-trade mini reviews (feed Insights when trades are linked), keyed by tradeId.
  final Map<String, TradeMiniReviewRow> _reviewRows = {};

  // Drafts / autosave (create mode only)
  static const Duration _autosaveDelay = Duration(seconds: 20);
  Timer? _autosaveTimer;
  Future<void>? _autosaveFuture;
  String? _draftEntryId;
  String _lastSavedFingerprint = '';
  DateTime? _lastDraftSavedAt;

  /// Attachment URLs already persisted on the server (via addAttachment / loaded entry).
  Set<String> _syncedAttachmentUrls = {};

  @override
  void initState() {
    super.initState();

    // Set edit mode: true for new entries, false for existing (view mode)
    _isEditMode = widget.entry == null;

    _titleController = TextEditingController();
    _quillController = quill.QuillController(document: quill.Document(), selection: const TextSelection.collapsed(offset: 0));
    _tradeIdController = TextEditingController();
    _urlController = TextEditingController();
    _planningBehaviorController = TextEditingController();
    _midBehaviorController = TextEditingController();
    _endBehaviorController = TextEditingController();

    _initFormFields();

    _urlController.addListener(_onUrlChanged);
    _titleController.addListener(_scheduleAutosave);
    _quillController.addListener(_scheduleAutosave);
    _planningBehaviorController.addListener(_scheduleAutosave);
    _midBehaviorController.addListener(_scheduleAutosave);
    _endBehaviorController.addListener(_scheduleAutosave);

    // Load trades for the entry date; apply playbook seed if provided.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTradesForPeriod(_tradeOverviewDate, _tradePeriod);
      final seed = widget.initialTemplate;
      if (seed != null && widget.entry == null) {
        applyTemplate(seed);
      }
    });
  }

  @override
  void didUpdateWidget(covariant JournalEntryForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry?.id != widget.entry?.id) {
      _autosaveTimer?.cancel();
      _draftEntryId = null;
      _lastDraftSavedAt = null;
      _isEditMode = widget.entry == null;
      _appliedTemplateName = null;
      _initFormFields();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadTradesForPeriod(_tradeOverviewDate, _tradePeriod);
        }
      });
      setState(() {});
      return;
    }
    // Same entry hydrated from getById (list row → full) — pull attachments
    // without resetting edit mode / draft state.
    if (widget.entry != null && !_isEditMode) {
      final nextUrls = widget.entry!.attachments.isNotEmpty
          ? widget.entry!.attachments.map((a) => a.fileUrl).toList()
          : List<String>.from(widget.entry!.imageUrls);
      if (!_listEquals(_imageUrls, nextUrls)) {
        setState(() {
          _imageUrls = nextUrls;
          _syncedAttachmentUrls = nextUrls.toSet();
        });
      }
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Quill JSON when possible; plain text fallback (Weekly Review historically
  /// saved raw notes — never throw on open or the detail pane goes blank).
  quill.Document _documentFromContent(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return quill.Document();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return quill.Document.fromJson(decoded);
      }
      if (decoded is Map && decoded['ops'] is List) {
        return quill.Document.fromJson(decoded['ops'] as List);
      }
    } catch (_) {
      // Fall through to plain text.
    }
    final doc = quill.Document();
    doc.insert(0, raw.endsWith('\n') ? raw : '$raw\n');
    return doc;
  }

  void _initFormFields() {
    _titleController.text = widget.entry?.title ?? '';

    _quillController.document = _documentFromContent(widget.entry?.content);

    _tradeIdController.text = widget.entry?.tradeId ?? '';
    _entryDate = widget.entry?.entryDate ?? DateTime.now();

    final customFields = widget.entry?.customFields ?? {};
    
    _planningBehaviorController.text = customFields['planningBehavior'] ?? '';
    _planningMood = customFields['planningMood'];
    _planningSentiment = customFields['planningSentiment'];

    _midBehaviorController.text = customFields['midBehavior'] ?? '';
    _midMood = customFields['midMood'];
    _midSentiment = customFields['midSentiment'];

    _endBehaviorController.text = customFields['endBehavior'] ?? '';
    _endMood = customFields['endMood'] ??
        (widget.entry?.behaviorPatternSummaries.isNotEmpty == true
            ? JournalHelpers.mapMoodFromEntry(widget.entry!.behaviorPatternSummaries.first.mood)
            : null);
    _endSentiment = customFields['endSentiment'] ??
        (widget.entry?.behaviorPatternSummaries.isNotEmpty == true
            ? JournalHelpers.mapSentimentFromValue(widget.entry!.behaviorPatternSummaries.first.marketSentiment)
            : null);

    _selectedTags.clear();
    if (widget.entry?.behaviorPatternSummaries.isNotEmpty == true) {
      _selectedTags.addAll(widget.entry!.behaviorPatternSummaries.expand((pattern) => pattern.tags).toSet());
    }

    if (widget.entry?.attachments != null && widget.entry!.attachments.isNotEmpty) {
      _imageUrls = widget.entry!.attachments.map((a) => a.fileUrl).toList();
    } else if (widget.entry?.imageUrls != null) {
      _imageUrls = List.from(widget.entry!.imageUrls);
    } else {
      _imageUrls = [];
    }

    _syncedAttachmentUrls = widget.entry == null ? <String>{} : _imageUrls.toSet();

    _relatedTradeIds = List.from(widget.entry?.relatedTradeIds ?? const []);

    _tradeOverviewDate = widget.entry?.entryDate ?? DateTime.now();

    _loadStructuredSectionsFromEntry();

    _disposeAllReviewRows();
    _syncReviewRows();
    _lastSavedFingerprint = _draftFingerprint();
  }

  void _loadStructuredSectionsFromEntry() {
    final entry = widget.entry;
    final review = entry?.postTradeReview;
    final plan = entry?.preTradePlan;
    final custom = entry?.customFields ?? {};

    final checklist = <String>[];
    if (review?.postChecklist.isNotEmpty == true) {
      checklist.addAll(review!.postChecklist);
    } else if (plan?.setupChecklist.isNotEmpty == true) {
      checklist.addAll(plan!.setupChecklist);
    }

    final completed = <String>{
      ...?review?.completedChecklistItems,
      ...?plan?.confirmedChecklistItems,
    };

    final fieldAnswers =
        JournalFormHelpers.stringMapFromCustom(custom, 'templateFieldAnswers');
    final fieldLabels =
        JournalFormHelpers.stringListFromCustom(custom, 'templateFieldLabels');

    // Prefer stored label order; fall back to answer keys for older entries.
    final fields =
        fieldLabels.isNotEmpty ? fieldLabels : fieldAnswers.keys.toList();

    _replaceChecklist(checklist, completed: completed);
    // Prompts UI removed (web + mobile) — do not hydrate prompt fields.
    _replaceLabeledControllers(_promptControllers, prompts: const []);
    _templateFields = fields;
    _replaceLabeledControllers(
      _fieldControllers,
      prompts: fields,
      answers: fieldAnswers,
    );
  }

  void _replaceChecklist(
    List<String> items, {
    Set<String> completed = const {},
  }) {
    _checklistItems = List<String>.from(items);
    _completedChecklistItems
      ..clear()
      ..addAll(completed.where(_checklistItems.contains));
  }

  void _replaceLabeledControllers(
    Map<String, TextEditingController> target, {
    required List<String> prompts,
    Map<String, String> answers = const {},
  }) {
    for (final c in target.values) {
      c.removeListener(_scheduleAutosave);
      c.dispose();
    }
    target.clear();
    for (final label in prompts) {
      final t = label.trim();
      if (t.isEmpty) continue;
      final c = TextEditingController(text: answers[t] ?? '');
      c.addListener(_scheduleAutosave);
      target[t] = c;
    }
  }

  Map<String, String> _answersFromControllers(
    Map<String, TextEditingController> controllers,
  ) =>
      {
        for (final e in controllers.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      };

  void _clearStructuredSections() {
    _replaceChecklist(const []);
    _replaceLabeledControllers(_promptControllers, prompts: const []);
    _replaceLabeledControllers(_fieldControllers, prompts: const []);
    _templateFields = [];
    _appliedTemplateName = null;
    _templateFocusTip = null;
  }

  PostTradeReview? _buildPostTradeReviewForSave(JournalEntry? existing) {
    final base = existing?.postTradeReview;
    if (_checklistItems.isEmpty) {
      return base;
    }
    final completed = _completedChecklistItems
        .where(_checklistItems.contains)
        .toList(growable: false);
    if (base == null) {
      return PostTradeReview(
        postChecklist: _checklistItems,
        completedChecklistItems: completed,
      );
    }
    return base.copyWith(
      postChecklist: _checklistItems,
      completedChecklistItems: completed,
    );
  }

  double? _checklistCompletionPct() {
    if (_checklistItems.isEmpty) return null;
    return (_completedChecklistItems.length / _checklistItems.length) * 100;
  }

  // ---------------------------------------------------------------------------
  // Per-trade mini review rows
  // ---------------------------------------------------------------------------

  List<JournalEntry> _cubitEntries() => widget.cubit.currentEntries;

  JournalEntry? _findStubForTrade(String tradeId) {
    for (final e in _cubitEntries()) {
      if (e.tradeId == tradeId && e.id != widget.entry?.id) return e;
    }
    return null;
  }

  TradeHoldingViewModel? _availableTrade(String tradeId) {
    for (final t in _availableTrades) {
      if (t.tradeId == tradeId) return t;
    }
    return null;
  }

  String _pnlText(double? v) => v == null ? '' : v.toString();

  VoidCallback? _openFullReviewFor(JournalEntry? stub) {
    if (stub == null) return null;
    return () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TradeJournalWorkflowPage(
            journalCubit: widget.cubit,
            initialEntry: stub,
            portfolioId: widget.portfolioId.isEmpty ? null : widget.portfolioId,
          ),
        ),
      );
    };
  }

  /// Keeps [_reviewRows] aligned with [_relatedTradeIds] (adds/removes rows,
  /// prefilling from an existing stub or the trade's realised P&L).
  void _syncReviewRows() {
    final wanted = _relatedTradeIds.where((id) => id.isNotEmpty).toSet();
    final removed =
        _reviewRows.keys.where((id) => !wanted.contains(id)).toList();
    if (removed.isNotEmpty) {
      final dropped = [for (final id in removed) _reviewRows.remove(id)!];
      // Defer disposal: the old tiles are still mounted until the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final r in dropped) {
          r.dispose();
        }
      });
    }

    final legacy = widget.entry?.postTradeReview;
    for (final id in _relatedTradeIds) {
      if (id.isEmpty) continue;
      final trade = _availableTrade(id);
      final existingRow = _reviewRows[id];
      if (existingRow != null) {
        // Refresh label once trade details load.
        if (trade != null) existingRow.symbol = trade.symbol;
        continue;
      }
      final stub = _findStubForTrade(id);
      final review = stub?.postTradeReview ??
          ((legacy?.tradeOutcome != null && wanted.length == 1)
              ? legacy
              : null);
      final row = TradeMiniReviewRow(
        tradeId: id,
        symbol: trade?.symbol ??
            stub?.symbol ??
            'Trade ${id.length > 6 ? id.substring(0, 6) : id}',
        outcome: review?.tradeOutcome,
        mistake: review?.mistakeCategory,
        lesson: review?.lessonLearned ?? '',
        pnl: review?.actualPnl != null
            ? _pnlText(review!.actualPnl)
            : _pnlText(trade?.profitLoss),
        stubEntry: stub,
      );
      row.onOpenFullReview = _openFullReviewFor(stub);
      _reviewRows[id] = row;
    }
  }

  void _disposeAllReviewRows() {
    final old = _reviewRows.values.toList();
    _reviewRows.clear();
    if (old.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final r in old) {
        r.dispose();
      }
    });
  }

  /// New entries: a different day means different fills — clear links so the
  /// daily auto-select can pick up the new day's trades. (Call inside setState.)
  void _resetLinksForNewDay() {
    if (widget.entry != null || _tradePeriod != TradePeriodType.daily) return;
    _relatedTradeIds = [];
    _syncReviewRows();
  }

  void _setRelatedTradeIds(List<String> ids) {
    setState(() {
      _relatedTradeIds = ids;
      _syncReviewRows();
    });
    _scheduleAutosave();
  }

  List<TradeMiniReviewRow> get _linkedReviewRows => [
    for (final id in _relatedTradeIds)
      if (_reviewRows[id] != null) _reviewRows[id]!,
  ];

  /// Applies a template into the classic journal form (title, Quill body, tags, planning).
  void applyTemplate(JournalTemplateSelection selection) {
    setState(() {
      if (selection.isBlank) {
        _titleController.clear();
        _quillController.document = quill.Document();
        _quillController.updateSelection(
          const TextSelection.collapsed(offset: 0),
          quill.ChangeSource.local,
        );
        _clearStructuredSections();
        _isEditMode = true;
        return;
      }

      _titleController.text = selection.name;
      // Checklist + custom fields are form sections; Quill is free-form notes.
      // Prompts UI removed — ignore template notePrompts.
      _replaceChecklist(
        selection.effectiveChecklist,
        completed: selection.checkedItems,
      );
      _replaceLabeledControllers(_promptControllers, prompts: const []);
      _templateFields = List<String>.from(selection.fields);
      _replaceLabeledControllers(
        _fieldControllers,
        prompts: _templateFields,
      );
      // Notes stay a free-form Quill box; checklist sits above it inside Notes.
      _quillController.document = quill.Document();
      _quillController.updateSelection(
        const TextSelection.collapsed(offset: 0),
        quill.ChangeSource.local,
      );
      if (selection.tags.isNotEmpty) {
        _selectedTags
          ..clear()
          ..addAll(selection.tags);
      }
      if (selection.planningSummary != null &&
          selection.planningSummary!.trim().isNotEmpty) {
        _planningBehaviorController.text = selection.planningSummary!;
      }
      _planningMood ??= 'focused';
      _appliedTemplateName = selection.name;
      final tip = selection.focusLine?.trim();
      _templateFocusTip = (tip != null && tip.isNotEmpty) ? tip : null;
      _isEditMode = true;
    });
    widget.onEditModeChanged?.call(true);
  }

  Future<void> browseTemplates() async {
    if (widget.onBrowseTemplates != null) {
      widget.onBrowseTemplates!();
      return;
    }
    await EnhancedTemplateDialog.show(
      context: context,
      onTemplateSelected: applyTemplate,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _tradeIdController.dispose();
    _urlController.dispose();
    _planningBehaviorController.dispose();
    _midBehaviorController.dispose();
    _endBehaviorController.dispose();
    for (final c in _promptControllers.values) {
      c.dispose();
    }
    _promptControllers.clear();
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    _fieldControllers.clear();
    _autosaveTimer?.cancel();
    for (final r in _reviewRows.values) {
      r.dispose();
    }
    _reviewRows.clear();
    super.dispose();
  }

  String? get _portfolioIdOrNull =>
      widget.portfolioId.isEmpty ? null : widget.portfolioId;

  /// Selects every fill in the current list. Stubs are only created on Save.
  void _attachAllAvailableTrades() {
    if (!_isEditMode || _availableTrades.isEmpty) return;
    final ids = _availableTrades
        .map((t) => t.tradeId)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return;
    _setRelatedTradeIds(ids);
  }

  // ---------------------------------------------------------------------------
  // Drafts / autosave (create mode)
  // ---------------------------------------------------------------------------

  String _draftFingerprint() => [
    _titleController.text,
    _quillController.document.toPlainText(),
    _planningBehaviorController.text,
    _midBehaviorController.text,
    _endBehaviorController.text,
    _planningMood,
    _midMood,
    _endMood,
    _planningSentiment,
    _midSentiment,
    _endSentiment,
    _entryDate.toIso8601String().split('T').first,
    _relatedTradeIds.join(','),
    (_selectedTags.toList()..sort()).join(','),
    _checklistItems.join(','),
    (_completedChecklistItems.toList()..sort()).join(','),
    _answersFromControllers(_fieldControllers).entries
        .map((e) => '${e.key}=${e.value}')
        .join('|'),
    _imageUrls.join(','),
  ].join('\u241F');

  bool get _draftHasContent =>
      _titleController.text.trim().isNotEmpty ||
      _quillController.document.toPlainText().trim().isNotEmpty ||
      _planningBehaviorController.text.trim().isNotEmpty ||
      _midBehaviorController.text.trim().isNotEmpty ||
      _endBehaviorController.text.trim().isNotEmpty ||
      _planningMood != null ||
      _midMood != null ||
      _endMood != null ||
      _checklistItems.isNotEmpty ||
      _imageUrls.isNotEmpty ||
      _answersFromControllers(_fieldControllers).isNotEmpty;

  bool get _hasUnsavedChanges =>
      _draftHasContent && _draftFingerprint() != _lastSavedFingerprint;

  /// Public for parent shell (list selection / mode toggle) leave guards.
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Debounced (~20s) silent DRAFT save while composing a new entry.
  void _scheduleAutosave() {
    if (widget.entry != null || !mounted || _isSubmitting) return;
    if (_draftFingerprint() == _lastSavedFingerprint) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDelay, () {
      _autosaveFuture = _autosaveDraft();
    });
  }

  Future<void> _autosaveDraft() async {
    if (!mounted || widget.entry != null || _isSubmitting) return;
    if (!_draftHasContent) return;
    final fingerprint = _draftFingerprint();
    if (fingerprint == _lastSavedFingerprint) return;
    try {
      final id = await _persistDayEntry(journalStatus: 'DRAFT');
      _draftEntryId = id;
      try {
        await _syncNewAttachments(id);
      } catch (_) {
        // Attachment retry happens on explicit Save.
      }
      _lastSavedFingerprint = fingerprint;
      if (mounted) setState(() => _lastDraftSavedAt = DateTime.now());
    } catch (_) {
      // Silent: the explicit Save surfaces real errors.
    }
  }

  Future<void> _saveDraftExplicit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      try {
        await _autosaveFuture;
      } catch (_) {}
      final id = await _persistDayEntry(journalStatus: 'DRAFT');
      _draftEntryId = id;
      await _syncNewAttachments(id);
      _lastSavedFingerprint = _draftFingerprint();
      if (mounted) {
        setState(() => _lastDraftSavedAt = DateTime.now());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save draft: $e'),
            backgroundColor: context.statusError,
          ),
        );
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Warn before discarding journal work.
  /// Returns true if the caller should proceed with leave/discard.
  ///
  /// [force] — Cancel always warns; system back only when dirty.
  Future<bool> confirmLeaveIfUnsaved({bool force = false}) async {
    if (_isSubmitting) return true;
    if (!force && !_hasUnsavedChanges) return true;

    if (!_hasUnsavedChanges) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave journal?'),
          content: const Text('Leave without saving this journal entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ModuleColorProvider.maybeOf(ctx) ??
                    ModuleColors.trade,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      return discard == true;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved journal'),
        content: const Text(
          'Your journal may be lost if you leave now. '
          'Save it as a draft, or save completely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'stay'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Discard'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'draft'),
            child: const Text('Save draft'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ModuleColorProvider.maybeOf(ctx) ??
                  ModuleColors.trade,
            ),
            onPressed: () => Navigator.pop(ctx, 'complete'),
            child: const Text('Save completely'),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    switch (action) {
      case 'discard':
        return true;
      case 'draft':
        try {
          await _saveDraftExplicit();
          return true;
        } catch (_) {
          return false;
        }
      case 'complete':
        await _submit();
        // Leave only if save cleared unsaved state.
        return !_hasUnsavedChanges;
      case 'stay':
      default:
        return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Attachments (go through addAttachment once the entry has an id)
  // ---------------------------------------------------------------------------

  /// Attachments safe to embed in create/update bodies (already persisted).
  List<JournalAttachment>? _syncedAttachmentsForBody() {
    final urls = _imageUrls.where(_syncedAttachmentUrls.contains).toList();
    if (urls.isEmpty) return null;
    return JournalFormHelpers.convertImageUrlsToAttachments(urls);
  }

  Future<void> _syncNewAttachments(String entryId) async {
    final pending =
        _imageUrls.where((u) => !_syncedAttachmentUrls.contains(u)).toList();
    if (pending.isEmpty) return;
    final attachments =
        JournalFormHelpers.convertImageUrlsToAttachments(pending);
    for (final a in attachments) {
      await widget.cubit.addAttachment(entryId, a);
      _syncedAttachmentUrls.add(a.fileUrl);
    }
  }

  // ---------------------------------------------------------------------------
  // Persist day entry + per-trade stubs
  // ---------------------------------------------------------------------------

  /// Creates or updates the day entry. Returns the entry id.
  Future<String> _persistDayEntry({
    required String journalStatus,
  }) async {
    final existing = widget.entry;
    final targetId = existing?.id ?? _draftEntryId;
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled draft'
        : _titleController.text;
    final content = _getQuillContent();
    final customFields = JournalFormHelpers.buildCustomFields(
      planningBehavior: _planningBehaviorController.text,
      planningMood: _planningMood,
      planningSentiment: _planningSentiment,
      midBehavior: _midBehaviorController.text,
      midMood: _midMood,
      midSentiment: _midSentiment,
      endBehavior: _endBehaviorController.text,
      endMood: _endMood,
      endSentiment: _endSentiment,
      promptAnswers: null,
      fieldAnswers: _answersFromControllers(_fieldControllers),
      promptLabels: null,
      fieldLabels: _templateFields,
    );
    final postTradeReview = _buildPostTradeReviewForSave(existing);
    final checklistPct = _checklistCompletionPct();
    final behaviorPatternSummaries = _buildBehaviorPatternSummaries();
    final syncedAttachments = _syncedAttachmentsForBody();
    final syncedUrls = syncedAttachments?.map((a) => a.fileUrl).toList();
    final related = _relatedTradeIds.isEmpty ? null : _relatedTradeIds;
    // Primary tradeId from linked fills (Today's trades); keep entry value if still set.
    final tradeId = () {
      if (related != null && related.isNotEmpty) return related.first;
      final fromField = _tradeIdController.text.trim();
      if (fromField.isNotEmpty) return fromField;
      return widget.entry?.tradeId;
    }();

    if (targetId == null) {
      final saved = await widget.cubit.addJournalEntry(
        title: title,
        content: content,
        entryDate: _entryDate,
        tradeId: tradeId,
        entryType: widget.defaultEntryType,
        journalStatus: journalStatus,
        folderId: widget.defaultFolderId,
        portfolioId: _portfolioIdOrNull,
        postTradeReview: postTradeReview,
        checklistCompletionPct: checklistPct,
        behaviorPatternSummaries: behaviorPatternSummaries,
        relatedTradeIds: related,
        customFields: customFields,
      );
      return saved.id;
    }

    await widget.cubit.editJournalEntry(
      entryId: targetId,
      title: title,
      content: content,
      entryDate: _entryDate,
      tradeId: tradeId,
      entryType: existing?.entryType ?? widget.defaultEntryType,
      journalStatus: journalStatus,
      symbol: existing?.symbol,
      setup: existing?.setup,
      tradeDirection: existing?.tradeDirection,
      folderId: existing?.folderId ?? widget.defaultFolderId,
      playbookId: existing?.playbookId,
      portfolioId: _portfolioIdOrNull ?? existing?.portfolioId,
      preTradePlan: existing?.preTradePlan,
      tradeExecution: existing?.tradeExecution,
      postTradeReview: postTradeReview,
      checklistCompletionPct: checklistPct,
      tagIds: (existing?.tagIds.isEmpty ?? true) ? null : existing!.tagIds,
      chartUrls:
          (existing?.chartUrls.isEmpty ?? true) ? null : existing!.chartUrls,
      documentUrls: (existing?.documentUrls.isEmpty ?? true)
          ? null
          : existing!.documentUrls,
      videoUrls:
          (existing?.videoUrls.isEmpty ?? true) ? null : existing!.videoUrls,
      externalUrls: (existing?.externalUrls.isEmpty ?? true)
          ? null
          : existing!.externalUrls,
      behaviorPatternSummaries: behaviorPatternSummaries,
      imageUrls: syncedUrls,
      attachments: syncedAttachments,
      relatedTradeIds: related,
      customFields: customFields,
    );
    return targetId;
  }

  /// Upserts DRAFT stubs for every linked trade, then writes each trade's mini
  /// review (marking the stub COMPLETED when an outcome was chosen).
  Future<void> _persistTradeReviews() async {
    final rows = _linkedReviewRows;
    if (rows.isEmpty) return;
    final stubs = await widget.cubit.createFromTrades(
      rows.map((r) => r.tradeId).toList(),
      journalStatus: 'DRAFT',
      portfolioId: _portfolioIdOrNull,
      reload: false,
    );
    final byTrade = <String, JournalEntry>{
      for (final s in stubs)
        if (s.tradeId != null && s.tradeId!.isNotEmpty) s.tradeId!: s,
    };

    final missing = <String>[];
    for (final row in rows) {
      final stub = byTrade[row.tradeId] ?? _findStubForTrade(row.tradeId);
      if (stub == null) {
        if (row.hasOutcome) missing.add(row.symbol);
        continue;
      }
      row.stubEntry = stub;
      row.onOpenFullReview = _openFullReviewFor(stub);
      if (!row.hasOutcome) continue;
      final review = JournalStructuredReviewSection.buildReview(
        existing: stub.postTradeReview,
        tradeOutcome: row.outcome,
        mistakeCategory: row.mistake,
        lesson: row.lessonController.text,
        actualPnl: row.actualPnl,
      );
      await widget.cubit.updatePostReview(
        stub.id,
        review,
        markCompleted: true,
        reload: false,
      );
    }
    if (missing.isNotEmpty) {
      throw StateError(
        'Could not create trade review for ${missing.join(', ')}',
      );
    }
  }

  void _onUrlChanged() {
    final text = _urlController.text.trim();
    if (text.isNotEmpty && (text.startsWith('http://') || text.startsWith('https://'))) {
      setState(() => _urlPreview = text);
    } else {
      setState(() => _urlPreview = null);
    }
  }

  Future<void> _loadTradesForPeriod(DateTime date, TradePeriodType period) async {
    try {
      DateTime startDate;
      DateTime endDate;

      switch (period) {
        case TradePeriodType.daily:
          final getTradeCalendarByDay = await ref.read(getTradeCalendarByDayProvider.future);
          final calendar = await getTradeCalendarByDay(widget.portfolioId, date: date);
          final trades = calendar.allTrades;
          if (mounted) {
            setState(() {
              _availableTrades = TradeHoldingViewModel.fromEntityList(trades);
              // New daily entry: link every fill for the day by default.
              if (widget.entry == null &&
                  period == TradePeriodType.daily &&
                  _relatedTradeIds.isEmpty) {
                _relatedTradeIds = _availableTrades
                    .map((t) => t.tradeId)
                    .where((id) => id.isNotEmpty)
                    .toList();
              }
              _syncReviewRows();
            });
          }
          return;

        case TradePeriodType.weekly:
          startDate = date.subtract(Duration(days: date.weekday - 1));
          endDate = startDate.add(const Duration(days: 6));
          break;

        case TradePeriodType.monthly:
          final getTradeCalendarByMonth = await ref.read(getTradeCalendarByMonthProvider.future);
          final calendar = await getTradeCalendarByMonth(widget.portfolioId, year: date.year,
            month: date.month,
          );
          final trades = calendar.allTrades;
          if (mounted) {
            setState(() {
              _availableTrades = TradeHoldingViewModel.fromEntityList(trades);
            });
          }
          return;

        case TradePeriodType.yearly:
          startDate = DateTime(date.year);
          endDate = DateTime(date.year, 12, 31);
          break;
      }

      // For weekly and yearly, use date range
      final getTradeCalendarByDateRange = await ref.read(getTradeCalendarByDateRangeProvider.future);
      final calendar = await getTradeCalendarByDateRange(
        widget.portfolioId,
        startDate: startDate,
        endDate: endDate,
      );

      final trades = calendar.allTrades;
      if (mounted) {
        setState(() {
          _availableTrades = TradeHoldingViewModel.fromEntityList(trades);
        });
      }
    } catch (e) {
      // Keep Trade Overview usable: empty state, no blocking error banner.
      if (mounted) {
        setState(() {
          _availableTrades = [];
        });
      }
    }
  }

  Future<void> _showTradePreview() async {
    // If in view mode with linked trades, load trades by IDs instead of by date
    if (!_isEditMode && _relatedTradeIds.isNotEmpty) {
      // Show loading indicator
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Load trades by their IDs using the trade controller provider
        final tradeDetails = await ref.read(tradeDetailsByIdsProvider(_relatedTradeIds).future);

        // Convert TradeDetails to TradeHoldingViewModel
        final linkedTrades = tradeDetails.map(TradeHoldingViewModel.fromEntity).toList();

        // Close loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show dialog with linked trades
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => TradePreviewDialog(
              date: _tradeOverviewDate,
              trades: linkedTrades,
              selectedTradeIds: _relatedTradeIds,
              periodType: _tradePeriod,
            ),
          );
        }
      } catch (e) {
        // Close loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load linked trades: ${e.toString()}'),
              backgroundColor: context.statusError,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      return;
    }

    // Edit mode: show trade selection dialog with available trades
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => TradePreviewDialog(
        date: _tradeOverviewDate,
        trades: _availableTrades,
        selectedTradeIds: _relatedTradeIds,
        periodType: _tradePeriod,
      ),
    );

    if (result != null && _isEditMode) {
      _setRelatedTradeIds(result);
    }
  }

  String _getQuillContent() {
    final delta = _quillController.document.toDelta();
    return jsonEncode(delta.toJson());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rows = _linkedReviewRows;
    if (rows.any((r) => !r.hasOutcome)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Pick an outcome for every linked trade so Insights can update.',
          ),
          backgroundColor: context.colors.statusWarning,
        ),
      );
      return;
    }

    _autosaveTimer?.cancel();
    setState(() => _isSubmitting = true);
    try {
      // Let an in-flight autosave finish so we never create the day entry twice.
      try {
        await _autosaveFuture;
      } catch (_) {}

      final existing = widget.entry;
      final isCreate = existing == null;

      // 1) Per-trade stubs + mini reviews (Insights source of truth).
      await _persistTradeReviews();

      // 2) Day entry (mood / notes / links) — explicit Save promotes to COMPLETED.
      final status = isCreate || existing.journalStatus == 'DRAFT'
          ? 'COMPLETED'
          : (existing.journalStatus ?? 'COMPLETED');
      final entryId = await _persistDayEntry(journalStatus: status);

      // 3) Attachments added in the form go through addAttachment.
      try {
        final before = _syncedAttachmentUrls.length;
        await _syncNewAttachments(entryId);
        if (_syncedAttachmentUrls.length != before) {
          await widget.cubit.loadJournalEntries();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Entry saved, but an attachment failed: $e'),
              backgroundColor: context.colors.statusWarning,
            ),
          );
        }
      }

      _draftEntryId = null;
      _lastDraftSavedAt = null;
      _lastSavedFingerprint = _draftFingerprint();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCreate
                ? 'Journal entry created successfully'
                : 'Journal entry updated successfully',
          ),
          backgroundColor: context.colors.statusSuccess,
        ),
      );

      if (isCreate) {
        widget.onCreated?.call(entryId);
        if (widget.onCreated == null) {
          // Legacy standalone form: reset in place.
          _titleController.clear();
          _quillController.document = quill.Document();
          _tradeIdController.clear();
          _urlController.clear();
          _planningBehaviorController.clear();
          _midBehaviorController.clear();
          _endBehaviorController.clear();
          setState(() {
            _planningMood = null;
            _planningSentiment = null;
            _midMood = null;
            _midSentiment = null;
            _endMood = null;
            _endSentiment = null;
            _selectedTags.clear();
            _imageUrls = [];
            _syncedAttachmentUrls = {};
            _relatedTradeIds = [];
            _entryDate = DateTime.now();
            _clearStructuredSections();
            _disposeAllReviewRows();
            _lastSavedFingerprint = _draftFingerprint();
          });
        }
      } else {
        _setEditMode(false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save entry: $e'),
            backgroundColor: context.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  List<BehaviorPatternSummary>? _buildBehaviorPatternSummaries() {
    final summaries = <BehaviorPatternSummary>[];

    // Aggregate all behavior data into one summary
    final hasAnyData =
        _planningBehaviorController.text.isNotEmpty ||
        _midBehaviorController.text.isNotEmpty ||
        _endBehaviorController.text.isNotEmpty ||
        _planningMood != null ||
        _midMood != null ||
        _endMood != null ||
        _planningSentiment != null ||
        _midSentiment != null ||
        _endSentiment != null ||
        _selectedTags.isNotEmpty;

    if (!hasAnyData) return null;

    // Combine behavior summaries from all phases
    final summaryParts = <String>[];
    if (_planningBehaviorController.text.isNotEmpty) {
      summaryParts.add('Planning: ${_planningBehaviorController.text}');
    }
    if (_midBehaviorController.text.isNotEmpty) {
      summaryParts.add('Mid: ${_midBehaviorController.text}');
    }
    if (_endBehaviorController.text.isNotEmpty) {
      summaryParts.add('End: ${_endBehaviorController.text}');
    }

    final summary = summaryParts.isNotEmpty
        ? summaryParts.join(' | ')
        : 'Behavior tracking for ${_titleController.text}';

    // Use the most recent mood/sentiment (end > mid > planning)
    final mood = JournalHelpers.getMoodString(_endMood ?? _midMood ?? _planningMood);
    final sentiment = JournalHelpers.getSentimentValue(_endSentiment ?? _midSentiment ?? _planningSentiment);

    summaries.add(
      BehaviorPatternSummary(summary: summary, mood: mood, marketSentiment: sentiment, tags: _selectedTags.toList()),
    );

    return summaries;
  }

  /// Scroll end inset so sticky [JournalFormActions] never covers form fields.
  /// Uses the same action height + attachment clearance constants as the bar.
  static double _stickyActionsReserve({
    required bool isCompact,
    required double navOrKeyboardInset,
    required bool showDraftLine,
  }) {
    final verticalPad = isCompact
        ? (AppSpacing.xs + AppSpacing.xxs) * 2
        : AppSpacing.sm + (AppSpacing.sm + AppSpacing.xs);
    final draft = showDraftLine ? AppSpacing.lg : 0.0;
    return JournalFormActions.actionRowHeight +
        verticalPad +
        draft +
        navOrKeyboardInset +
        JournalFormActions.attachmentScrollClearance;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_hasUnsavedChanges,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      final leave = await confirmLeaveIfUnsaved();
      if (leave && mounted && context.mounted) {
        Navigator.of(context).maybePop();
      }
    },
    child: Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Desktop always Notes | meta (Entry Date / trades on the RIGHT).
          // Only [compact] mobile stacks. Widths are explicit so sidebar
          // changes cannot shove the right column off-screen.
          final useTwoColumn = !widget.compact;
          final isCompact = widget.compact;
          final denseTwoCol = useTwoColumn && constraints.maxWidth < 1000;
          final showSticky = _isEditMode || widget.entry == null;
          final showDraftLine =
              showSticky && widget.entry == null && _lastDraftSavedAt != null;
          final hPad = isCompact ? AppSpacing.md : AppSpacing.md;
          final vPad = isCompact ? AppSpacing.sm : AppSpacing.md;

          Widget scrollBody(double bottomInset) {
            // Use outer pane width — LayoutBuilder inside a vertical
            // ScrollView can report infinite maxWidth on web.
            final contentW = constraints.maxWidth.isFinite
                ? (constraints.maxWidth - hPad * 2).clamp(0.0, double.infinity)
                : 800.0;
            final gap = AppSpacing.md;
            final Widget columns;
            if (!useTwoColumn || contentW < 520) {
              columns = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLeftColumn(context, isCompact: true),
                  const SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
                  _buildRightColumn(isCompact: true),
                ],
              );
            } else {
              // ~38% meta rail on the RIGHT; Notes take the rest.
              final rightW = (contentW * 0.38).clamp(180.0, 360.0);
              final leftW = contentW - rightW - gap;
              columns = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: leftW,
                    child: _buildLeftColumn(
                      context,
                      isCompact: denseTwoCol,
                    ),
                  ),
                  SizedBox(width: gap),
                  SizedBox(
                    width: rightW,
                    child: _buildRightColumn(isCompact: denseTwoCol),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, bottomInset),
              child: SizedBox(width: contentW, child: columns),
            );
          }

          // Column(Expanded + sticky) is correct when the parent height is
          // tight. AnimatedSwitcher / some embeds pass loose height so the
          // sticky paints over the last fields — Stack + scroll inset is the
          // same contract used by template mobile composers.
          if (!showSticky) {
            return scrollBody(vPad);
          }

          Widget shell(double bottomInset) {
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(child: scrollBody(bottomInset)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildStickyActions(context, isCompact: isCompact),
                ),
              ],
            );
          }

          // Desktop sticky (also when dense two-col under 1000px).
          if (!widget.compact) {
            return shell(
              _stickyActionsReserve(
                isCompact: denseTwoCol,
                navOrKeyboardInset: 0,
                showDraftLine: showDraftLine,
              ),
            );
          }

          final navReserveFull =
              PlatformConstants.globalBottomNavReserve(context);
          final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

          if (navReserveFull <= 0) {
            return shell(
              _stickyActionsReserve(
                isCompact: true,
                navOrKeyboardInset: keyboardInset,
                showDraftLine: showDraftLine,
              ),
            );
          }

          return ValueListenableBuilder<double>(
            valueListenable: GlobalBottomNavVisibility.factor,
            builder: (context, navFactor, _) {
              final t = navFactor.clamp(0.0, 1.0);
              final inset = keyboardInset > 0
                  ? keyboardInset
                  : navReserveFull * t;
              return shell(
                _stickyActionsReserve(
                  isCompact: true,
                  navOrKeyboardInset: inset,
                  showDraftLine: showDraftLine,
                ),
              );
            },
          );
        },
      ),
    ),
  );

  Widget _buildStickyActions(BuildContext context, {bool isCompact = false}) {
    final colors = context.colors;
    if (isCompact) {
      final navReserveFull = PlatformConstants.globalBottomNavReserve(context);
      final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

      Widget buildContainer(double bottomPad) {
        return Material(
          color: colors.surface,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs + AppSpacing.xxs,
              AppSpacing.md,
              bottomPad,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.border.withValues(alpha: 0.3)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.entry == null && _lastDraftSavedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text(
                      'Draft saved ${TimeOfDay.fromDateTime(_lastDraftSavedAt!).format(context)}',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                JournalFormActions(
                  isEditMode: _isEditMode,
                  isSubmitting: _isSubmitting,
                  isNewEntry: widget.entry == null,
                  compact: isCompact,
                  onSubmit: _submit,
                  onToggleEditMode: () => _setEditMode(!_isEditMode),
                  onBrowseTemplates: _isEditMode ? browseTemplates : null,
                  onCancel: () async {
                    final leave = await confirmLeaveIfUnsaved(force: true);
                    if (!leave || !mounted) return;
                    if (widget.entry == null) {
                      widget.onCancelCreate?.call();
                      return;
                    }
                    exitEditMode();
                  },
                ),
              ],
            ),
          ),
        );
      }

      if (navReserveFull <= 0) {
        return buildContainer(
          AppSpacing.xs + AppSpacing.xxs + keyboardInset,
        );
      }

      return ValueListenableBuilder<double>(
        valueListenable: GlobalBottomNavVisibility.factor,
        builder: (context, navFactor, _) {
          final t = navFactor.clamp(0.0, 1.0);
          final bottomPad = keyboardInset > 0
              ? AppSpacing.xs + AppSpacing.xxs + keyboardInset
              : (AppSpacing.xs + AppSpacing.xxs) + (navReserveFull * t);
          return buildContainer(bottomPad);
        },
      );
    }

    return Material(
      color: colors.cardSurface,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm + AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.border.withValues(alpha: 0.35)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.entry == null && _lastDraftSavedAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  'Draft saved ${TimeOfDay.fromDateTime(_lastDraftSavedAt!).format(context)}',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            JournalFormActions(
              isEditMode: _isEditMode,
              isSubmitting: _isSubmitting,
              isNewEntry: widget.entry == null,
              compact: widget.compact,
              onSubmit: _submit,
              onToggleEditMode: () => _setEditMode(!_isEditMode),
              onBrowseTemplates: _isEditMode ? browseTemplates : null,
              onCancel: () async {
                final leave = await confirmLeaveIfUnsaved(force: true);
                if (!leave || !mounted) return;
                if (widget.entry == null) {
                  widget.onCancelCreate?.call();
                  return;
                }
                exitEditMode();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context, {bool isCompact = false}) {
    final sectionGap = isCompact ? AppSpacing.sm : AppSpacing.md;
    // Same field chrome as Trade journal — border labels / surface tint (no white cards).
    // Template banner + checklist + custom fields live inside Notes (not above it).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleField(floatingLabel: true),
        SizedBox(height: sectionGap),
        _buildNotesSection(context, isCompact: isCompact),
        SizedBox(height: sectionGap),
        _buildBorderLabeledBlock(
          label: 'Behavior & mood',
          child: _buildBehaviorTracking(isCompact: isCompact),
        ),
      ],
    );
  }

  static const _noteTopicTags = [
    'plan',
    'setup',
    'risk',
    'execution',
    'psychology',
    'review',
  ];

  Widget _buildNotesSection(BuildContext context, {required bool isCompact}) {
    final theme = Theme.of(context);
    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
    final hasTemplateChrome = _isEditMode && _appliedTemplateName != null;
    final hasChecklist = _checklistItems.isNotEmpty;
    final hasFields = _templateFields.isNotEmpty;
    final hasHeader = hasTemplateChrome || hasFields;

    Widget? header;
    if (hasHeader) {
      header = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasTemplateChrome)
            Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: _templateFocusTip ?? 'Applied template',
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + AppSpacing.xs,
                    vertical: isCompact ? AppSpacing.xs : AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: AppRadii.chip,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: AppSpacing.md,
                        color: accent,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          'Template: $_appliedTemplateName',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: isCompact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (hasTemplateChrome && hasFields)
            SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.md),
          if (hasFields)
            _buildLabeledFieldsEditor(
              labels: _templateFields,
              controllers: _fieldControllers,
              enabled: _isEditMode,
              hint: 'Add details…',
              floatingLabels: true,
            ),
        ],
      );
    }

    // Web-only note-topic chips — mobile keeps tags in Behavior & mood (compact).
    final Widget? footer = isCompact
        ? null
        : Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in _noteTopicTags)
                AmToggleChip(
                  label: '#$tag',
                  selected: _selectedTags.contains(tag),
                  compact: true,
                  accentColor: accent,
                  onTap: _isEditMode ? () => _toggleTag(tag) : null,
                ),
            ],
          );

    return RichTextEditor(
      controller: _quillController,
      readOnly: !_isEditMode,
      // Dedicated Quill box height (checklist is editorLeading above, not inside).
      minHeight: isCompact
          ? AppSpacing.xxl * 3 + AppSpacing.md
          : AppSpacing.xxl * 5,
      compact: isCompact,
      label: 'Notes',
      header: header,
      editorLeading: hasChecklist
          ? _buildChecklistEditor(enabled: _isEditMode)
          : null,
      footer: footer,
    );
  }

  Widget _buildBorderLabeledBlock({
    required String label,
    required Widget child,
  }) {
    return InputDecorator(
      decoration: JournalFieldDecoration.borderLabel(context, label: label),
      child: child,
    );
  }

  /// Same borderLabel contract as Notes ([JournalBorderLabeledPanel]) —
  /// InputDecorator must not wrap the file picker on web.
  Widget _buildAttachmentBlock() {
    return JournalBorderLabeledPanel(
      label: 'Supporting Evidence',
      readOnly: !_isEditMode,
      child: JournalAttachmentSection(
        userId: widget.entry?.userId ?? '',
        imageUrls: _imageUrls,
        onAttachmentsChanged: (urls) {
          setState(() => _imageUrls = urls);
          _scheduleAutosave();
        },
        featureName: 'journal',
        isEditMode: _isEditMode,
        omitSectionTitle: true,
      ),
    );
  }

  Widget _buildChecklistEditor({required bool enabled}) {
    final colors = context.colors;
    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in _checklistItems)
          Material(
            color: colors.cardSurface.withValues(alpha: 0),
            child: CheckboxListTile(
              value: _completedChecklistItems.contains(item),
              activeColor: accent,
              onChanged: !enabled
                  ? null
                  : (v) {
                      setState(() {
                        if (v == true) {
                          _completedChecklistItems.add(item);
                        } else {
                          _completedChecklistItems.remove(item);
                        }
                      });
                      _scheduleAutosave();
                    },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text(
                item,
                // Tick only — no strikethrough / muted “cut” style when checked.
                style: context.text.body(compact: true).copyWith(
                      color: colors.textPrimary,
                    ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLabeledFieldsEditor({
    required List<String> labels,
    required Map<String, TextEditingController> controllers,
    required bool enabled,
    required String hint,
    bool floatingLabels = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            SizedBox(height: floatingLabels ? AppSpacing.sm : AppSpacing.md),
          if (!floatingLabels) ...[
            Text(
              labels[i],
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          TextFormField(
            controller: controllers[labels[i]],
            enabled: enabled,
            maxLines: floatingLabels ? 2 : 3,
            minLines: floatingLabels ? 1 : 2,
            style: theme.textTheme.bodyMedium,
            decoration: JournalFieldDecoration.outlined(
              context,
              labelText: floatingLabels ? labels[i] : null,
              hintText: hint,
              floatingLabel: floatingLabels,
              dense: floatingLabels,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitleField({bool floatingLabel = false}) {
    final colors = context.colors;
    return TextFormField(
      controller: _titleController,
      enabled: _isEditMode,
      style: context.text.sectionTitle(compact: true).copyWith(
            fontWeight: FontWeight.w600,
            color: _isEditMode
                ? colors.textPrimary
                : colors.textPrimary.withValues(alpha: 0.9),
          ),
      decoration: JournalFieldDecoration.outlined(
        context,
        labelText: floatingLabel ? 'Title' : null,
        hintText: 'e.g. Pre-market plan — Nifty bias',
        floatingLabel: floatingLabel,
        dense: floatingLabel,
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Widget _buildRightColumn({bool isCompact = false}) {
    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
    final sectionGap = isCompact ? AppSpacing.sm : AppSpacing.md;
    // Same chrome as Trade journal / left column — border labels, no white cards.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionalFields(),
        SizedBox(height: sectionGap),
        _buildBorderLabeledBlock(
          label: "Today's trades",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditMode && _availableTrades.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _attachAllAvailableTrades,
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: const Text('Attach all for this day'),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              JournalTradeSection(
                selectedDate: _tradeOverviewDate,
                selectedPeriod: _tradePeriod,
                selectedTradeIds: _relatedTradeIds,
                availableTrades: _availableTrades,
                isEditMode: _isEditMode,
                onDateChanged: (date) {
                  setState(() {
                    _tradeOverviewDate = date;
                    _entryDate = date;
                    _resetLinksForNewDay();
                  });
                  _loadTradesForPeriod(date, _tradePeriod);
                },
                onPeriodChanged: (period) {
                  setState(() => _tradePeriod = period);
                  _loadTradesForPeriod(_tradeOverviewDate, period);
                },
                onTradesSelected: _setRelatedTradeIds,
                onViewTrades: _showTradePreview,
              ),
            ],
          ),
        ),
        if (_linkedReviewRows.isNotEmpty) ...[
          SizedBox(height: sectionGap),
          _buildBorderLabeledBlock(
            label: 'Trade review',
            child: JournalStructuredReviewSection(
              rows: _linkedReviewRows,
              isEditMode: _isEditMode,
              onChanged: () => setState(() {}),
            ),
          ),
        ],
        SizedBox(height: sectionGap),
        _buildAttachmentBlock(),
      ],
    );
  }

  Widget _buildOptionalFields() => OptionalFieldsSection(
    entryDate: _entryDate,
    urlController: _urlController,
    isEditMode: _isEditMode,
    isUrlExpanded: _isUrlExpanded,
    urlPreview: _urlPreview,
    onDateSelect: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: _entryDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date != null) {
        setState(() {
          _entryDate = date;
          _tradeOverviewDate = date;
          _resetLinksForNewDay();
        });
        _loadTradesForPeriod(date, _tradePeriod);
      }
    },
    onToggleUrlExpansion: () => setState(() => _isUrlExpanded = !_isUrlExpanded),
    onClearUrl: () {
      _urlController.clear();
      setState(() => _urlPreview = null);
    },
  );

  Widget _buildBehaviorTracking({bool isCompact = false}) => BehaviorTrackingSection(
    planningBehaviorController: _planningBehaviorController,
    planningMood: _planningMood,
    planningSentiment: _planningSentiment,
    midBehaviorController: _midBehaviorController,
    midMood: _midMood,
    midSentiment: _midSentiment,
    endBehaviorController: _endBehaviorController,
    endMood: _endMood,
    endSentiment: _endSentiment,
    onPlanningMoodChanged: (mood) {
      setState(() => _planningMood = mood);
      _scheduleAutosave();
    },
    onPlanningSentimentChanged: (sentiment) {
      setState(() => _planningSentiment = sentiment);
      _scheduleAutosave();
    },
    onMidMoodChanged: (mood) {
      setState(() => _midMood = mood);
      _scheduleAutosave();
    },
    onMidSentimentChanged: (sentiment) {
      setState(() => _midSentiment = sentiment);
      _scheduleAutosave();
    },
    onEndMoodChanged: (mood) {
      setState(() => _endMood = mood);
      _scheduleAutosave();
    },
    onEndSentimentChanged: (sentiment) {
      setState(() => _endSentiment = sentiment);
      _scheduleAutosave();
    },
    selectedTags: _selectedTags,
    onTagToggled: _toggleTag,
    isEditMode: _isEditMode,
    compact: isCompact,
  );

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    _scheduleAutosave();
  }
}
