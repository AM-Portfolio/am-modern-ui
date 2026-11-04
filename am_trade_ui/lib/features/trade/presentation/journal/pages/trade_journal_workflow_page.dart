import 'dart:async';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../utils/journal_calc_helper.dart';
import '../utils/journal_entry_validation.dart';
import '../widgets/execute_trade_step.dart';
import '../widgets/journal_form_surface.dart';
import '../widgets/journal_trade_header.dart';
import '../widgets/post_trade_review_step.dart';
import '../widgets/pre_trade_plan_step.dart';
import '../widgets/pre_trade_plan_step_mobile.dart';

class TradeJournalWorkflowPage extends ConsumerStatefulWidget {
  const TradeJournalWorkflowPage({
    super.key,
    required this.journalCubit,
    this.initialEntry,
    this.portfolioId,
    this.embedded = false,
    this.useMobileLayout = false,
    this.onEmbeddedDone,
    this.onEmbeddedCancel,
    this.onEmbeddedDeleted,
    this.startAtStep,
    this.initialReadOnly = false,
  });

  final JournalCubit journalCubit;
  final JournalEntry? initialEntry;
  final String? portfolioId;

  /// When true, render without Scaffold/AppBar for classic Entries pane.
  final bool embedded;

  /// Mobile Trade journal only — stacked Pre-Trade layout. Web stays row layout.
  final bool useMobileLayout;

  /// Called after save. [complete] is true only for Save Journal.
  final void Function(String entryId, {required bool complete})? onEmbeddedDone;
  final VoidCallback? onEmbeddedCancel;
  final VoidCallback? onEmbeddedDeleted;

  /// Optional override for initial wizard step (defaults via [stepFromStatus]).
  final int? startAtStep;

  /// Same Pre/Execute/Post template; completed journals stay locked until
  /// the user double-clicks / double-taps a field to edit.
  final bool initialReadOnly;

  @override
  ConsumerState<TradeJournalWorkflowPage> createState() =>
      TradeJournalWorkflowPageState();
}

class TradeJournalWorkflowPageState
    extends ConsumerState<TradeJournalWorkflowPage> {
  late int _currentStep;
  late JournalEntry _entry;
  var _saving = false;
  var _isNew = true;
  late bool _readOnly;
  /// True after local edits since last successful Save Draft / Save Journal.
  var _dirty = false;
  final _stepScrollController = ScrollController();
  final _preColScrollController = ScrollController();
  final _execColScrollController = ScrollController();
  final _postColScrollController = ScrollController();
  final _preStepKey = GlobalKey<PreTradePlanStepState>();
  final _preStepMobileKey = GlobalKey<PreTradePlanStepMobileState>();
  final _execStepKey = GlobalKey<ExecuteTradeStepState>();
  final _postStepKey = GlobalKey<PostTradeReviewStepState>();
  final _preSectionKey = GlobalKey();
  final _execSectionKey = GlobalKey();
  final _postSectionKey = GlobalKey();
  static const _threeColBreakpoint = 900.0;
  static const _autosaveDelay = Duration(seconds: 20);
  Timer? _autosaveTimer;
  Future<void>? _autosaveFuture;
  DateTime? _lastDraftSavedAt;
  String _lastSavedFingerprint = '';

  static const _defaultChecklist = [
    'Trend aligned with setup',
    'Key level identified',
    'Volume confirmation',
    'Risk-reward > 2:1',
    'No major news risk',
    'Emotionally neutral',
    'Position size calculated',
    'Plan written down',
  ];

  static int stepFromStatus(String? status) {
    switch ((status ?? 'DRAFT').toUpperCase()) {
      case 'OPEN':
        return 1;
      // Completed demos / reviews still open on Pre-Trade so the plan is first.
      case 'COMPLETED':
      case 'PLANNED':
      case 'DRAFT':
      default:
        return 0;
    }
  }

  void _unlockEdit() {
    if (!_readOnly) return;
    setState(() => _readOnly = false);
  }

  @override
  void initState() {
    super.initState();
    _readOnly = widget.initialReadOnly;
    _hydrateFrom(widget.initialEntry, isNew: widget.initialEntry == null);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _stepScrollController.dispose();
    _preColScrollController.dispose();
    _execColScrollController.dispose();
    _postColScrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int step) {
    final key = switch (step.clamp(0, 2)) {
      0 => _preSectionKey,
      1 => _execSectionKey,
      _ => _postSectionKey,
    };
    final colScroll = switch (step.clamp(0, 2)) {
      0 => _preColScrollController,
      1 => _execColScrollController,
      _ => _postColScrollController,
    };
    if (colScroll.hasClients) {
      colScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  bool _validateAllStepsForSave() {
    if (_readOnly) return true;
    for (var step = 0; step <= 2; step++) {
      final ok = switch (step) {
        0 => widget.useMobileLayout
            ? (_preStepMobileKey.currentState?.validate() ?? true)
            : (_preStepKey.currentState?.validate() ?? true),
        1 => _execStepKey.currentState?.validate() ?? true,
        2 => _postStepKey.currentState?.validate() ?? true,
        _ => true,
      };
      final message = ok
          ? JournalEntryValidation.validateTradeStep(_entry, step)
          : (switch (step) {
                0 => widget.useMobileLayout
                    ? _preStepMobileKey.currentState?.validationMessage()
                    : _preStepKey.currentState?.validationMessage(),
                1 => _execStepKey.currentState?.validationMessage(),
                2 => _postStepKey.currentState?.validationMessage(),
                _ => null,
              } ??
              JournalEntryValidation.validateTradeStep(_entry, step) ??
              'Please fix the highlighted fields');
      if (!ok || message != null) {
        setState(() => _currentStep = step);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(step);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Please fix the highlighted fields'),
            backgroundColor: context.colors.statusWarning,
          ),
        );
        return false;
      }
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant TradeJournalWorkflowPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialReadOnly != oldWidget.initialReadOnly &&
        widget.initialEntry?.id == oldWidget.initialEntry?.id) {
      _readOnly = widget.initialReadOnly;
    }
    final next = widget.initialEntry;
    final prev = oldWidget.initialEntry;
    if (next == null) return;
    // Don't clobber in-progress edits when the list reloads after autosave.
    if (_dirty && prev?.id == next.id) return;
    if (prev == null ||
        prev.id != next.id ||
        prev.updatedAt != next.updatedAt) {
      _readOnly = widget.initialReadOnly;
      _hydrateFrom(next, isNew: false, keepStep: prev?.id == next.id);
      _lastSavedFingerprint = _entryFingerprint(_entry);
      _dirty = false;
    }
  }

  void _hydrateFrom(
    JournalEntry? source, {
    required bool isNew,
    bool keepStep = false,
  }) {
    _isNew = isNew;
    if (source == null) {
      _entry = _createNewEntry();
      _currentStep = widget.startAtStep ?? 0;
      return;
    }
    var entry = source;
    // Prefill default checklist on blank stubs (new temp or createFromTrades DRAFT).
    final status = (entry.journalStatus ?? '').toUpperCase();
    final plan = entry.preTradePlan ?? const PreTradePlan();
    if (plan.setupChecklist.isEmpty &&
        (isNew || status == 'DRAFT' || status == 'PLANNED')) {
      entry = entry.copyWith(
        preTradePlan: plan.copyWith(setupChecklist: _defaultChecklist),
      );
    }
    _entry = entry;
    _lastSavedFingerprint = _entryFingerprint(entry);
    if (!keepStep) {
      _currentStep = widget.startAtStep ?? stepFromStatus(entry.journalStatus);
    }
  }

  JournalEntry _createNewEntry() {
    final entry = JournalEntry(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      userId: '',
      title: 'New Trade',
      entryDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      entryType: 'TRADE_JOURNAL',
      journalStatus: 'DRAFT',
      tradeDirection: 'LONG',
      preTradePlan: const PreTradePlan(setupChecklist: _defaultChecklist),
      tradeExecution: const TradeExecution(),
      postTradeReview: const PostTradeReview(),
    );
    _lastSavedFingerprint = _entryFingerprint(entry);
    return entry;
  }

  void _updateEntry(JournalEntry updated) {
    setState(() {
      _entry = _recalc(updated);
      _dirty = true;
    });
    _scheduleAutosave();
  }

  bool get hasUnsavedChanges => !_readOnly && _dirty && !_saving;

  String _entryFingerprint(JournalEntry e) {
    final plan = e.preTradePlan;
    final exec = e.tradeExecution;
    final review = e.postTradeReview;
    return [
      e.title,
      e.symbol,
      e.setup,
      e.content,
      e.tradeDirection,
      plan?.strategy,
      plan?.setup,
      plan?.plannedEntryPrice,
      plan?.plannedStopLoss,
      plan?.plannedTarget,
      plan?.plannedQuantity,
      plan?.setupDescription,
      plan?.entryRationale,
      plan?.marketContext,
      plan?.setupChecklist.join(','),
      exec?.actualEntryPrice,
      exec?.quantity,
      exec?.notes,
      exec?.broker,
      review?.actualExitPrice,
      review?.whatWentWell,
      review?.whatCouldBeImproved,
      review?.lessonLearned,
      review?.followedStopLoss,
      review?.followedTarget,
      review?.mistakeCategory,
      review?.emotionalState,
      review?.executionScore,
      e.attachments.map((a) => a.fileUrl).join(','),
    ].join('\u241F');
  }

  bool get _hasMeaningfulContent {
    final e = _entry;
    final plan = e.preTradePlan;
    final exec = e.tradeExecution;
    final review = e.postTradeReview;
    return (e.symbol?.trim().isNotEmpty ?? false) ||
        (e.setup?.trim().isNotEmpty ?? false) ||
        (e.content?.trim().isNotEmpty ?? false) ||
        (e.title.trim().isNotEmpty && e.title.trim() != 'New Trade') ||
        plan?.plannedEntryPrice != null ||
        plan?.plannedStopLoss != null ||
        plan?.plannedTarget != null ||
        plan?.plannedQuantity != null ||
        (plan?.setupDescription?.trim().isNotEmpty ?? false) ||
        (plan?.entryRationale?.trim().isNotEmpty ?? false) ||
        (plan?.strategy?.trim().isNotEmpty ?? false) ||
        exec?.actualEntryPrice != null ||
        (exec?.notes?.trim().isNotEmpty ?? false) ||
        review?.actualExitPrice != null ||
        (review?.whatWentWell?.trim().isNotEmpty ?? false) ||
        (review?.whatCouldBeImproved?.trim().isNotEmpty ?? false) ||
        (review?.lessonLearned?.trim().isNotEmpty ?? false) ||
        e.attachments.isNotEmpty;
  }

  void _scheduleAutosave() {
    if (_readOnly || _saving || !mounted) return;
    if (!_hasMeaningfulContent) return;
    if (_entryFingerprint(_entry) == _lastSavedFingerprint) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDelay, () {
      _autosaveFuture = _save(complete: false, silent: true);
    });
  }

  /// Auto-saves a draft when leaving with unsaved work. Empty journals leave
  /// without creating a row. Returns false only if the flush fails.
  Future<bool> confirmLeaveIfUnsaved({bool force = false}) async {
    if (_saving) return true;
    if (!force && !hasUnsavedChanges) return true;
    if (!hasUnsavedChanges) return true;
    if (!_hasMeaningfulContent) return true;
    _autosaveTimer?.cancel();
    try {
      await _autosaveFuture;
    } catch (_) {}
    if (!hasUnsavedChanges) return true;
    await _save(complete: false, silent: true);
    return !hasUnsavedChanges;
  }

  JournalEntry _recalc(JournalEntry e) {
    final plan = e.preTradePlan ?? const PreTradePlan();
    final exec = e.tradeExecution ?? const TradeExecution();
    final review = e.postTradeReview ?? const PostTradeReview();

    // Prefer values already on the plan (user-edited Risk / R:R); fill gaps only.
    final calcRisk = JournalCalcHelper.plannedRiskAmount(
      entry: plan.plannedEntryPrice,
      stop: plan.plannedStopLoss,
      quantity: plan.plannedQuantity ?? exec.quantity,
    );
    final calcRr = JournalCalcHelper.plannedRRRatio(
      entry: plan.plannedEntryPrice,
      stop: plan.plannedStopLoss,
      target: plan.plannedTarget,
    );
    final risk = plan.plannedRiskAmount ?? calcRisk;
    final rr = plan.plannedRRRatio ?? calcRr;
    final pnl = JournalCalcHelper.actualPnl(
      entryPrice: exec.actualEntryPrice ?? plan.plannedEntryPrice,
      exitPrice: review.actualExitPrice,
      quantity: exec.quantity ?? plan.plannedQuantity,
      tradeDirection: e.tradeDirection,
    );
    final rMult = JournalCalcHelper.actualRMultiple(
      pnl: pnl,
      plannedRisk: risk,
    );

    return e.copyWith(
      setup: plan.setup ?? e.setup,
      symbol: e.symbol,
      preTradePlan: plan.copyWith(
        plannedRiskAmount: risk,
        plannedRRRatio: rr,
      ),
      postTradeReview: review.copyWith(
        actualPnl: pnl ?? review.actualPnl,
        actualRMultiple: rMult ?? review.actualRMultiple,
      ),
    );
  }

  Future<void> _save({required bool complete, bool silent = false}) async {
    if (_saving) return;
    if (complete && !silent && !_validateAllStepsForSave()) return;
    final fingerprintAtStart = _entryFingerprint(_entry);
    setState(() => _saving = true);
    try {
      var status = (_entry.journalStatus ?? 'DRAFT').toUpperCase();
      if (complete) {
        status = 'COMPLETED';
      } else if (!silent) {
        // Explicit Save Draft advances from filled sections (not wizard index).
        final hasExec =
            (_entry.tradeExecution?.actualEntryPrice ?? 0) > 0;
        if (hasExec && (status == 'DRAFT' || status == 'PLANNED')) {
          status = 'OPEN';
        } else if (status == 'DRAFT') {
          status = 'PLANNED';
        }
      } else if (status.isEmpty) {
        status = 'DRAFT';
      }

      final plan = _entry.preTradePlan;
      final symbol = _entry.symbol?.trim().isNotEmpty == true
          ? _entry.symbol!.trim()
          : null;
      final setup = (_entry.setup ?? plan?.setup)?.trim();
      final title = (symbol != null && symbol.isNotEmpty)
          ? '$symbol ${setup?.isNotEmpty == true ? setup : 'Trade'}'
          : (_entry.title.trim().isNotEmpty ? _entry.title : 'Untitled draft');

      final localAttachments = List<JournalAttachment>.from(_entry.attachments);
      var saved = await widget.journalCubit.saveEntryFull(
        entryId: _isNew ? null : _entry.id,
        title: title,
        content: _entry.content,
        entryDate: _entry.entryDate,
        tradeId: _entry.tradeId,
        entryType: _entry.entryType ?? 'TRADE_JOURNAL',
        journalStatus: status,
        symbol: symbol,
        setup: setup,
        tradeDirection: _entry.tradeDirection,
        folderId: _entry.folderId,
        playbookId: _entry.playbookId,
        portfolioId: widget.portfolioId ?? _entry.portfolioId,
        preTradePlan: _entry.preTradePlan,
        tradeExecution: _entry.tradeExecution,
        postTradeReview: _entry.postTradeReview,
        attachments: localAttachments,
        relatedTradeIds: _entry.relatedTradeIds,
        tagIds: _entry.tagIds,
      );
      // If create/update dropped attachments, persist via addAttachment API.
      final savedUrls = saved.attachments.map((a) => a.fileUrl).toSet();
      for (final a in localAttachments) {
        if (a.fileUrl.isEmpty || savedUrls.contains(a.fileUrl)) continue;
        try {
          saved = await widget.journalCubit.addAttachment(saved.id, a);
        } catch (_) {
          // Keep local URL visible even if sync fails this pass.
        }
      }
      if (saved.attachments.isEmpty && localAttachments.isNotEmpty) {
        saved = saved.copyWith(attachments: localAttachments);
      }
      if (!mounted) return;
      final stillSame = _entryFingerprint(_entry) == fingerprintAtStart;
      setState(() {
        if (stillSame) {
          _entry = saved;
          _dirty = false;
          _lastSavedFingerprint = _entryFingerprint(saved);
        } else {
          // Keep local edits; adopt server id so later saves update.
          _entry = _entry.copyWith(
            id: saved.id,
            journalStatus: saved.journalStatus,
            updatedAt: saved.updatedAt,
          );
          _dirty = true;
          _lastSavedFingerprint = fingerprintAtStart;
        }
        _isNew = false;
        _saving = false;
        if (silent) _lastDraftSavedAt = DateTime.now();
      });
      if (!silent && widget.embedded) {
        widget.onEmbeddedDone?.call(saved.id, complete: complete);
      } else if (!silent && complete) {
        Navigator.of(context).pop();
      }
      if (!silent && !complete && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved')),
        );
      } else if (!silent && complete && widget.embedded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal saved')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _linkTrade(String tradeId) async {
    if (_isNew || _entry.id.startsWith('temp-')) {
      await _save(complete: false);
    }
    final linked = await widget.journalCubit.linkTrade(_entry.id, tradeId);
    if (linked != null && mounted) {
      setState(() => _entry = linked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Linked trade $tradeId')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (_isNew || _entry.id.startsWith('temp-')) {
      widget.onEmbeddedCancel?.call();
      return;
    }
    final title = JournalTradeHeader.displayTitle(_entry);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete journal?'),
        content: Text('“$title” will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: ctx.statusError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.journalCubit.removeJournalEntry(_entry.id);
    if (!mounted) return;
    if (widget.embedded) {
      widget.onEmbeddedDeleted?.call();
    } else {
      Navigator.pop(context);
    }
  }

  static const _columnTitles = [
    'Pre-Trade',
    'Execute',
    'Post-Trade',
  ];

  Widget _preStep({bool omitSurface = false}) {
    if (widget.useMobileLayout) {
      return PreTradePlanStepMobile(
        key: _preStepMobileKey,
        entry: _entry,
        onUpdate: _updateEntry,
        applyDefaultChecklist: _isNew && !_readOnly,
      );
    }
    return PreTradePlanStep(
      key: _preStepKey,
      entry: _entry,
      onUpdate: _updateEntry,
      applyDefaultChecklist: _isNew && !_readOnly,
      // Web Pre always uses Symbol | Long/Short row (mockup); mobile uses Mobile step.
      omitSurface: omitSurface,
    );
  }

  Widget _execStep({bool omitSurface = false}) => ExecuteTradeStep(
        key: _execStepKey,
        entry: _entry,
        onUpdate: _updateEntry,
        portfolioId: widget.portfolioId,
        onLinkTrade: _readOnly ? null : _linkTrade,
        omitSurface: omitSurface,
      );

  Widget _postStep({bool omitSurface = false}) => PostTradeReviewStep(
        key: _postStepKey,
        entry: _entry,
        onUpdate: _updateEntry,
        omitSurface: omitSurface,
      );

  Widget _stepBadge(BuildContext context, int stepIndex, {required bool active}) {
    final colors = context.colors;
    final accent = ModuleColors.trade;
    const size = 28.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? accent : colors.border.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Text(
        '${stepIndex + 1}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: active ? colors.actionPrimaryFg : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  /// Equal-height design-system cards; scroll only when content overflows.
  Widget _columnScroll({
    required Key sectionKey,
    required ScrollController controller,
    required int stepIndex,
    required Widget child,
  }) {
    final active = stepIndex == _currentStep;
    return KeyedSubtree(
      key: sectionKey,
      child: Padding(
        // Right-only gap between columns; flush to entries-rail toggle on the left.
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        // Listener so clicking an input still updates the active card badge.
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (_currentStep != stepIndex) {
              setState(() => _currentStep = stepIndex);
            }
          },
          child: JournalFormSurface(
            fillHeight: true,
            centerHeader: true,
            title: _columnTitles[stepIndex],
            leading: _stepBadge(context, stepIndex, active: active),
            // Clip scroll to the card; top pad keeps floating border labels inside.
            // Read-only unlock overlay lives on the parent Stack (not here).
            child: ClipRect(
              child: SingleChildScrollView(
                controller: controller,
                primary: false,
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThreeColumns(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _columnScroll(
            sectionKey: _preSectionKey,
            controller: _preColScrollController,
            stepIndex: 0,
            child: _preStep(omitSurface: true),
          ),
        ),
        Expanded(
          child: _columnScroll(
            sectionKey: _execSectionKey,
            controller: _execColScrollController,
            stepIndex: 1,
            child: _execStep(omitSurface: true),
          ),
        ),
        Expanded(
          child: _columnScroll(
            sectionKey: _postSectionKey,
            controller: _postColScrollController,
            stepIndex: 2,
            child: _postStep(omitSurface: true),
          ),
        ),
      ],
    );
  }

  Widget _buildStackedSections(BuildContext context) {
    Widget section({
      required Key key,
      required int stepIndex,
      required Widget child,
    }) {
      return KeyedSubtree(
        key: key,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (_currentStep != stepIndex) {
              setState(() => _currentStep = stepIndex);
            }
          },
          child: JournalFormSurface(
            centerHeader: true,
            title: _columnTitles[stepIndex],
            leading: _stepBadge(
              context,
              stepIndex,
              active: stepIndex == _currentStep,
            ),
            child: child,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section(
          key: _preSectionKey,
          stepIndex: 0,
          child: _preStep(omitSurface: true),
        ),
        const SizedBox(height: AppSpacing.lg),
        section(
          key: _execSectionKey,
          stepIndex: 1,
          child: _execStep(omitSurface: true),
        ),
        const SizedBox(height: AppSpacing.lg),
        section(
          key: _postSectionKey,
          stepIndex: 2,
          child: _postStep(omitSurface: true),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final threeCol = !widget.useMobileLayout &&
            constraints.maxWidth >= _threeColBreakpoint;

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  IgnorePointer(
                    ignoring: _readOnly,
                    child: Opacity(
                      opacity: _readOnly ? 0.92 : 1,
                      child: threeCol
                          ? Padding(
                              // Flush to entries-rail toggle; keep right/top breathing room.
                              padding: const EdgeInsets.fromLTRB(
                                0,
                                AppSpacing.sm,
                                AppSpacing.sm,
                                AppSpacing.xs,
                              ),
                              child: _buildThreeColumns(context),
                            )
                          : SingleChildScrollView(
                              controller: _stepScrollController,
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.md,
                                AppSpacing.xxl + AppSpacing.lg,
                              ),
                              child: _buildStackedSections(context),
                            ),
                    ),
                  ),
                  if (_readOnly)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: _unlockEdit,
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
            _buildBottomActions(context),
          ],
        );
      },
    );

    final scrollIsolated = widget.useMobileLayout
        ? NotificationListener<ScrollNotification>(
            onNotification: (notification) =>
                notification.metrics.axis == Axis.vertical,
            child: body,
          )
        : body;

    final wrapped = PopScope(
      canPop: _readOnly || !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirmLeaveIfUnsaved();
        if (!leave || !mounted) return;
        if (widget.embedded) {
          widget.onEmbeddedCancel?.call();
        } else if (context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: scrollIsolated,
    );

    if (widget.embedded) {
      // Let the hub background show through — no solid white slab.
      return Material(
        type: MaterialType.transparency,
        child: wrapped,
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Trade Journal'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final leave = await confirmLeaveIfUnsaved();
            if (leave && mounted && context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: wrapped,
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final colors = context.colors;
    final navReserveFull = widget.embedded
        ? PlatformConstants.globalBottomNavReserve(context)
        : 0.0;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    Widget buildRow(EdgeInsets padding) {
      return Padding(
        padding: padding,
        child: Row(
          children: [
            AppButton(
              text: 'Close',
              type: AppButtonType.secondary,
              isOutlined: true,
              textColor: ModuleColors.trade,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: () async {
                if (_readOnly) {
                  if (widget.embedded) {
                    widget.onEmbeddedCancel?.call();
                  } else {
                    Navigator.pop(context);
                  }
                  return;
                }
                final leave = await confirmLeaveIfUnsaved(force: true);
                if (!leave || !mounted) return;
                if (widget.embedded) {
                  widget.onEmbeddedCancel?.call();
                } else if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            if (!_readOnly && !_isNew && !_entry.id.startsWith('temp-'))
              TextButton(
                onPressed: _saving ? null : _confirmDelete,
                style: TextButton.styleFrom(
                  foregroundColor: colors.statusError,
                ),
                child: const Text('Delete'),
              ),
            const Spacer(),
            if (_readOnly) ...[
              Text(
                'Double-click a field to edit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ] else ...[
              if (_lastDraftSavedAt != null) ...[
                Text(
                  'Draft saved',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
                const SizedBox(width: 8),
              ],
              AppButton(
                text: 'Save Draft',
                type: AppButtonType.secondary,
                isOutlined: true,
                textColor: ModuleColors.trade,
                onPressed: _saving ? null : () => _save(complete: false),
                height: 40,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                text: 'Save',
                icon: Icons.check_rounded,
                backgroundColor: ModuleColors.trade,
                isLoading: _saving,
                onPressed: _saving ? null : () => _save(complete: true),
                height: 40,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ],
          ],
        ),
      );
    }

    final hPad = widget.embedded ? AppSpacing.sm : AppSpacing.md;

    if (navReserveFull <= 0) {
      return buildRow(
        EdgeInsets.fromLTRB(
          hPad,
          AppSpacing.sm,
          hPad,
          AppSpacing.md + keyboardInset,
        ),
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: GlobalBottomNavVisibility.factor,
      builder: (context, navFactor, _) {
        final t = navFactor.clamp(0.0, 1.0);
        final bottomPad = keyboardInset > 0
            ? AppSpacing.sm + keyboardInset
            : AppSpacing.sm + (navReserveFull * t);
        return buildRow(
          EdgeInsets.fromLTRB(
            hPad,
            AppSpacing.sm,
            hPad,
            bottomPad,
          ),
        );
      },
    );
  }
}

