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
import 'utils/journal_form_helpers.dart';
import 'utils/journal_helpers.dart';
import 'widgets/rich_text_editor.dart';
import 'widgets/trade_overview_selector.dart';
import 'widgets/trade_preview_dialog.dart';
import '../../../journal/pages/trade_journal_workflow_page.dart';
import '../../../journal/widgets/journal_form_surface.dart';
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
    }
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

    _disposeAllReviewRows();
    _syncReviewRows();
    _lastSavedFingerprint = _draftFingerprint();
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
        _appliedTemplateName = null;
        _isEditMode = true;
        return;
      }

      _titleController.text = selection.name;
      final doc = buildTemplateDocument(selection);
      _quillController.document = doc;
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
  ].join('\u241F');

  bool get _draftHasContent =>
      _titleController.text.trim().isNotEmpty ||
      _quillController.document.toPlainText().trim().isNotEmpty ||
      _planningBehaviorController.text.trim().isNotEmpty ||
      _midBehaviorController.text.trim().isNotEmpty ||
      _endBehaviorController.text.trim().isNotEmpty ||
      _planningMood != null ||
      _midMood != null ||
      _endMood != null;

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
      _lastSavedFingerprint = fingerprint;
      if (mounted) setState(() => _lastDraftSavedAt = DateTime.now());
    } catch (_) {
      // Silent: the explicit Save surfaces real errors.
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
    );
    final behaviorPatternSummaries = _buildBehaviorPatternSummaries();
    final syncedAttachments = _syncedAttachmentsForBody();
    final syncedUrls = syncedAttachments?.map((a) => a.fileUrl).toList();
    final related = _relatedTradeIds.isEmpty ? null : _relatedTradeIds;
    final tradeId =
        _tradeIdController.text.isEmpty ? null : _tradeIdController.text;

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
      postTradeReview: existing?.postTradeReview,
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
      // Log error silently for debugging if needed but don't leak to console
      // AppLogger.error('Error loading trades for period', error: e);
      if (mounted) {
        setState(() {
          _availableTrades = [];
        });
      }

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load trades: ${e.toString()}'),
            backgroundColor: context.statusError,
            duration: const Duration(seconds: 3),
          ),
        );
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
            _appliedTemplateName = null;
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

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reading mode: full-width notes — skip the empty sidebar chrome.
                    if (!_isEditMode && widget.entry != null)
                      _buildLeftColumn(context)
                    else if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _buildLeftColumn(context)),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(flex: 3, child: _buildRightColumn()),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLeftColumn(context),
                          const SizedBox(height: AppSpacing.lg),
                          _buildRightColumn(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Sticky bar only while composing / editing — view mode uses header Edit.
            if (_isEditMode || widget.entry == null)
              _buildStickyActions(context),
          ],
        );
      },
    ),
  );

  Widget _buildStickyActions(BuildContext context) {
    final colors = context.colors;
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
              onSubmit: _submit,
              onToggleEditMode: () => _setEditMode(!_isEditMode),
              onCancel: () {
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

  bool get _hasBehaviorData =>
      _planningBehaviorController.text.trim().isNotEmpty ||
      _midBehaviorController.text.trim().isNotEmpty ||
      _endBehaviorController.text.trim().isNotEmpty ||
      _planningMood != null ||
      _midMood != null ||
      _endMood != null;

  Widget _buildLeftColumn(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    // Reader-first layout: title + notes dominate; hide empty chrome.
    if (!_isEditMode && widget.entry != null) {
      final review = widget.entry!.postTradeReview;
      final checklist = review?.postChecklist ?? const <String>[];
      final completed = review?.completedChecklistItems ?? const <String>[];
      final lesson = review?.lessonLearned?.trim();
      final isWeekly =
          (widget.entry!.entryType ?? '').toUpperCase() == 'WEEKLY_REVIEW';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleController.text.trim().isEmpty
                ? 'Untitled entry'
                : _titleController.text.trim(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (isWeekly && checklist.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            JournalFormSurface(
              title: 'Process checklist',
              subtitle: '${completed.length} / ${checklist.length} completed',
              leading: Icon(
                Icons.checklist_rounded,
                size: 18,
                color: ModuleColors.trade,
              ),
              child: Column(
                children: [
                  for (final item in checklist)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            completed.contains(item)
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: completed.contains(item)
                                ? const Color(0xFF00B894)
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              item,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                decoration: completed.contains(item)
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: completed.contains(item)
                                    ? colors.textSecondary
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          JournalFormSurface(
            title: isWeekly ? 'Notes / lessons' : 'Notes',
            leading: Icon(
              Icons.notes_rounded,
              size: 18,
              color: ModuleColors.trade,
            ),
            child: (lesson != null &&
                    lesson.isNotEmpty &&
                    _quillController.document.toPlainText().trim().isEmpty)
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SelectableText(
                      lesson,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                  )
                : RichTextEditor(
                    controller: _quillController,
                    readOnly: true,
                    minHeight: 320,
                  ),
          ),
          if (_hasBehaviorData) ...[
            const SizedBox(height: AppSpacing.md),
            JournalFormSurface(
              title: 'Behavior & mood',
              leading: Icon(
                Icons.psychology_alt_outlined,
                size: 18,
                color: ModuleColors.trade,
              ),
              child: _buildBehaviorTracking(),
            ),
          ],
          if (_relatedTradeIds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '${_relatedTradeIds.length} linked trade(s)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JournalFormSurface(
          title: 'Title',
          subtitle: 'Give this day a clear name',
          leading: Icon(
            Icons.title_rounded,
            size: 18,
            color: ModuleColors.trade,
          ),
          child: _buildTitleField(),
        ),
        if (_isEditMode && _appliedTemplateName != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: ModuleColors.trade.withValues(alpha: 0.1),
              borderRadius: AppRadii.card,
              border: Border.all(
                color: ModuleColors.trade.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: ModuleColors.trade,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Template: $_appliedTemplateName',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: ModuleColors.trade,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        JournalFormSurface(
          title: 'Notes',
          subtitle: 'Checklist and free-form writing',
          leading: Icon(
            Icons.notes_rounded,
            size: 18,
            color: ModuleColors.trade,
          ),
          child: RichTextEditor(
            controller: _quillController,
            readOnly: !_isEditMode,
            minHeight: 360,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        JournalFormSurface(
          title: 'Behavior & mood',
          subtitle: 'Planning, mid-session, and end-of-day',
          leading: Icon(
            Icons.psychology_alt_outlined,
            size: 18,
            color: ModuleColors.trade,
          ),
          child: _buildBehaviorTracking(),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    final theme = Theme.of(context);
    final colors = context.colors;
    return TextFormField(
      controller: _titleController,
      enabled: _isEditMode,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: _isEditMode
            ? null
            : theme.colorScheme.onSurface.withValues(alpha: 0.9),
      ),
      decoration: InputDecoration(
        hintText: 'e.g. Pre-market plan — Nifty bias',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
        filled: true,
        fillColor: colors.surface.withValues(alpha: 0.45),
        border: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide(
            color: ModuleColors.trade.withValues(alpha: 0.7),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.2)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Widget _buildRightColumn() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      JournalFormSurface(
        title: 'Details',
        subtitle: 'Date, links, and context',
        leading: Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: ModuleColors.trade,
        ),
        child: _buildOptionalFields(),
      ),
      const SizedBox(height: AppSpacing.md),
      JournalFormSurface(
        title: "Today's trades",
        subtitle: _availableTrades.isEmpty
            ? 'No fills for this date — change date or period'
            : '${_availableTrades.length} trade(s) · ${_relatedTradeIds.length} linked',
        leading: Icon(
          Icons.candlestick_chart_outlined,
          size: 18,
          color: ModuleColors.trade,
        ),
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
                    foregroundColor: ModuleColors.trade,
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
        const SizedBox(height: AppSpacing.md),
        JournalFormSurface(
          title: 'Trade review',
          subtitle: 'Outcome + mistake → Insights',
          leading: Icon(
            Icons.rate_review_outlined,
            size: 18,
            color: ModuleColors.trade,
          ),
          child: JournalStructuredReviewSection(
            rows: _linkedReviewRows,
            isEditMode: _isEditMode,
            onChanged: () => setState(() {}),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      JournalFormSurface(
        title: 'Attachments',
        subtitle: 'Charts and screenshots',
        leading: Icon(
          Icons.attach_file_rounded,
          size: 18,
          color: ModuleColors.trade,
        ),
        child: JournalAttachmentSection(
          userId: widget.entry?.userId ?? '',
          imageUrls: _imageUrls,
          onAttachmentsChanged: (urls) => setState(() => _imageUrls = urls),
          featureName: 'journal',
          isEditMode: _isEditMode,
        ),
      ),
    ],
  );

  Widget _buildOptionalFields() => OptionalFieldsSection(
    entryDate: _entryDate,
    tradeIdController: _tradeIdController,
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

  Widget _buildBehaviorTracking() => BehaviorTrackingSection(
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
