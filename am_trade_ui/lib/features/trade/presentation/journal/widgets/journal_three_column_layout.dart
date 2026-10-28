import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../../internal/domain/entities/notebook_item.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../notebook/cubit/notebook_cubit.dart';
import '../../notebook/cubit/notebook_state.dart';
import '../../web/widgets/journal/journal_entry_form.dart';
import '../models/journal_folder_filter.dart';
import '../pages/trade_journal_workflow_page.dart';
import 'journal_entry_detail_view.dart';
import 'journal_entry_list_view.dart';
import 'simple_template_dialog.dart';

/// Two-column journal workspace: entries list | detail / create.
/// Folder filtering is owned by the parent (filter bar).
class JournalThreeColumnLayout extends StatefulWidget {
  const JournalThreeColumnLayout({
    required this.entries,
    required this.journalCubit,
    required this.notebookCubit,
    required this.selectedFolder,
    this.portfolioId = '',
    this.pendingTemplate,
    this.onPendingTemplateConsumed,
    this.onSelectedSymbolChanged,
    this.onComposerOpenChanged,
    this.focusEntryId,
    this.onEntryCreated,
    this.listFilterSlot,
    super.key,
  });

  final List<JournalEntry> entries;
  final JournalCubit journalCubit;
  final NotebookCubit notebookCubit;
  final String selectedFolder;
  final String portfolioId;

  /// Filters rendered inside the entries rail (inspiration layout).
  final Widget? listFilterSlot;

  /// When set (e.g. from Playbooks), open Log Day and apply this template once.
  final JournalTemplateSelection? pendingTemplate;
  final VoidCallback? onPendingTemplateConsumed;
  final ValueChanged<String?>? onSelectedSymbolChanged;

  /// Fired after Log Day (or the embedded trade workflow) saves a new entry.
  final ValueChanged<String>? onEntryCreated;

  /// True while Log Day / create pane is open — parent can free vertical space.
  final ValueChanged<bool>? onComposerOpenChanged;

  /// When set, selects this entry in the list (e.g. Global Search pick).
  final String? focusEntryId;

  @override
  State<JournalThreeColumnLayout> createState() =>
      _JournalThreeColumnLayoutState();
}

class _JournalThreeColumnLayoutState extends State<JournalThreeColumnLayout> {
  String? _selectedEntryId;
  bool _isCreatingNew = false;

  /// Edit on an existing entry — same full-page chrome as Log Day.
  bool _isEditingEntry = false;

  /// True while creating a new structured trade via the wizard.
  bool _useTradeWorkflow = false;

  /// Force wizard for a completed trade (user tapped Edit journal).
  bool _forceTradeEdit = false;
  int? _forceTradeEditStep;

  /// Fresh entity from getById — preferred over list row until list catches up.
  JournalEntry? _hydratedEntry;

  GlobalKey<JournalEntryFormState> _newFormKey =
      GlobalKey<JournalEntryFormState>();
  final GlobalKey<TradeJournalWorkflowPageState> _newTradeWorkflowKey =
      GlobalKey<TradeJournalWorkflowPageState>();
  final GlobalKey<TradeJournalWorkflowPageState> _editTradeWorkflowKey =
      GlobalKey<TradeJournalWorkflowPageState>();
  JournalTemplateSelection? _composerTemplate;

  /// Blocks list taps / mode switches while create/edit has unsaved work.
  Future<bool> _guardUnsavedLeave() async {
    if (_isCreatingNew && _useTradeWorkflow) {
      final state = _newTradeWorkflowKey.currentState;
      if (state != null) return state.confirmLeaveIfUnsaved();
      return true;
    }
    if (_isCreatingNew) {
      final state = _newFormKey.currentState;
      if (state != null) return state.confirmLeaveIfUnsaved();
      return true;
    }
    if (!_isCreatingNew &&
        (_forceTradeEdit ||
            (_selectedEntry != null &&
                JournalFolderFilter.shouldOpenTradeWorkflow(_selectedEntry!)))) {
      final state = _editTradeWorkflowKey.currentState;
      if (state != null && state.hasUnsavedChanges) {
        return state.confirmLeaveIfUnsaved();
      }
    }
    return true;
  }

  List<NotebookItem> get _notebookFolders {
    final state = widget.notebookCubit.state;
    return state is NotebookLoaded ? state.items : const [];
  }

  @override
  void initState() {
    super.initState();
    if (widget.entries.isNotEmpty) {
      _selectedEntryId = widget.entries.first.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySelectedSymbol());
  }

  @override
  void didUpdateWidget(covariant JournalThreeColumnLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pendingTemplate != null &&
        widget.pendingTemplate != oldWidget.pendingTemplate) {
      final selection = widget.pendingTemplate!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _composerTemplate = selection;
        _startNewEntry(tradeWorkflow: false);
        widget.onPendingTemplateConsumed?.call();
      });
    }
    final focusId = widget.focusEntryId;
    final focusChanged =
        focusId != null && focusId != oldWidget.focusEntryId;
    final entriesChanged = widget.entries != oldWidget.entries;
    final canFocus = focusId != null &&
        widget.entries.any((e) => e.id == focusId);

    if (oldWidget.selectedFolder != widget.selectedFolder) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (canFocus) {
          await _applyFocusEntry(focusId);
          return;
        }
        if (!await _guardUnsavedLeave()) return;
        if (!mounted) return;
        setState(() {
          _useTradeWorkflow = false;
          _forceTradeEdit = false;
          _forceTradeEditStep = null;
          _hydratedEntry = null;
          _isEditingEntry = false;
          _selectedEntryId =
              widget.entries.isNotEmpty ? widget.entries.first.id : null;
        });
        _setCreating(false);
        _notifyComposerOpen();
        _notifySelectedSymbol();
      });
      return;
    }
    if ((focusChanged || entriesChanged) && canFocus) {
      // Close New Trade / Log Day composer so imported stubs are visible.
      _applyFocusEntry(focusId);
    }
    if (_isCreatingNew) return;
    final stillVisible = widget.entries.any((e) => e.id == _selectedEntryId);
    if (!stillVisible) {
      setState(() {
        _selectedEntryId =
            widget.entries.isNotEmpty ? widget.entries.first.id : null;
        _forceTradeEdit = false;
        _forceTradeEditStep = null;
        _hydratedEntry = null;
      });
    } else if (_hydratedEntry != null &&
        _hydratedEntry!.id == _selectedEntryId) {
      final listRow =
          widget.entries.where((e) => e.id == _selectedEntryId).firstOrNull;
      if (listRow != null &&
          !listRow.updatedAt.isBefore(_hydratedEntry!.updatedAt)) {
        _hydratedEntry = null;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySelectedSymbol());
  }

  JournalEntry? get _selectedEntry {
    if (_hydratedEntry != null && _hydratedEntry!.id == _selectedEntryId) {
      return _hydratedEntry;
    }
    return widget.entries.where((e) => e.id == _selectedEntryId).firstOrNull;
  }

  void _notifySelectedSymbol() {
    widget.onSelectedSymbolChanged?.call(_selectedEntry?.symbol);
  }

  /// Select [entryId], exit any open composer, show the entries rail again.
  Future<void> _applyFocusEntry(String entryId) async {
    if (!mounted) return;
    final already =
        _selectedEntryId == entryId && !_isCreatingNew && !_useTradeWorkflow;
    if (already && !_forceTradeEdit) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _notifySelectedSymbol());
      return;
    }
    if (!await _guardUnsavedLeave()) return;
    if (!mounted) return;
    setState(() {
      _selectedEntryId = entryId;
      _isCreatingNew = false;
      _useTradeWorkflow = false;
      _forceTradeEdit = false;
      _forceTradeEditStep = null;
      _hydratedEntry = null;
      _isEditingEntry = false;
      _composerTemplate = null;
    });
    _notifyComposerOpen();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _notifySelectedSymbol());
  }

  /// Always keep the entries rail (same as Log Day). Trade Pre/Execute/Post
  /// shares the right pane; collapsing the list felt like the sidebar vanished.
  bool get _focusFullPage => false;

  /// Which create-mode pill is highlighted (`false` Log day, `true` Trade).
  /// Always non-null so one segment stays selected in the rail.
  bool _createModeHighlight(JournalEntry? selected) {
    if (_isCreatingNew) return _useTradeWorkflow;
    if (_forceTradeEdit) return true;
    if (selected != null) {
      return JournalFolderFilter.shouldOpenTradeWorkflow(selected);
    }
    // Default when browsing with nothing selected.
    return true;
  }

  void _notifyComposerOpen() {
    widget.onComposerOpenChanged?.call(_focusFullPage);
  }

  void _setCreating(bool value) {
    if (_isCreatingNew == value) return;
    setState(() {
      _isCreatingNew = value;
      if (value) _isEditingEntry = false;
    });
    _notifyComposerOpen();
  }

  void _setEditingEntry(bool value) {
    if (_isEditingEntry == value) return;
    setState(() => _isEditingEntry = value);
    _notifyComposerOpen();
  }

  Future<void> _startNewEntry({
    bool tradeWorkflow = false,
    bool clearTemplate = false,
  }) async {
    // Switching Log day ↔ Trade (or re-opening) while composing must warn.
    if (_isCreatingNew ||
        (_newTradeWorkflowKey.currentState?.hasUnsavedChanges ?? false) ||
        (_editTradeWorkflowKey.currentState?.hasUnsavedChanges ?? false)) {
      if (!await _guardUnsavedLeave()) return;
    }
    if (!mounted) return;
    setState(() {
      _selectedEntryId = null;
      _isEditingEntry = false;
      _useTradeWorkflow = tradeWorkflow;
      _forceTradeEdit = false;
      _forceTradeEditStep = null;
      if (clearTemplate) _composerTemplate = null;
      _newFormKey = GlobalKey<JournalEntryFormState>();
    });
    _setCreating(true);
    widget.onSelectedSymbolChanged?.call(null);
  }

  Future<void> _closeComposer({
    String? selectEntryId,
    bool skipLeaveGuard = false,
  }) async {
    // After an in-form Cancel dialog already confirmed leave, skip re-prompt.
    if (!skipLeaveGuard &&
        selectEntryId == null &&
        !await _guardUnsavedLeave()) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _useTradeWorkflow = false;
      _forceTradeEdit = false;
      _forceTradeEditStep = null;
      _hydratedEntry = null;
      _composerTemplate = null;
      _isEditingEntry = false;
      _selectedEntryId = selectEntryId ??
          (widget.entries.isNotEmpty ? widget.entries.first.id : null);
    });
    _setCreating(false);
  }

  Future<void> _onEntrySelected(JournalEntry entry) async {
    if (_selectedEntryId == entry.id && !_isCreatingNew && !_forceTradeEdit) {
      return;
    }
    if (!await _guardUnsavedLeave()) return;
    if (!mounted) return;
    setState(() {
      _selectedEntryId = entry.id;
      _useTradeWorkflow = false;
      _forceTradeEdit = false;
      _forceTradeEditStep = null;
      _hydratedEntry = null;
      _isEditingEntry = false;
    });
    _setCreating(false);
    _notifyComposerOpen();
    widget.onSelectedSymbolChanged?.call(entry.symbol);

    // Refresh full entity so list stubs don't leave the detail empty.
    if (JournalFolderFilter.shouldOpenTradeWorkflow(entry)) {
      final fresh = await widget.journalCubit.loadEntryDetail(entry.id);
      if (!mounted || fresh == null) return;
      if (_selectedEntryId != entry.id) return;
      setState(() => _hydratedEntry = fresh);
    }
  }

  Future<void> _confirmAndDelete(JournalEntry entry) async {
    final title = entry.title.trim().isEmpty
        ? (entry.symbol?.trim().isNotEmpty == true
            ? entry.symbol!.trim()
            : 'Untitled entry')
        : entry.title.trim();
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
    await widget.journalCubit.removeJournalEntry(entry.id);
    if (!mounted) return;
    setState(() {
      if (_selectedEntryId == entry.id) {
        _selectedEntryId = null;
        _hydratedEntry = null;
        _forceTradeEdit = false;
        _forceTradeEditStep = null;
      }
    });
  }

  Future<void> _browseTemplates(
    GlobalKey<JournalEntryFormState> formKey,
  ) async {
    await EnhancedTemplateDialog.show(
      context: context,
      onTemplateSelected: (selection) {
        formKey.currentState?.applyTemplate(selection);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied "${selection.name}" template'),
            backgroundColor: ModuleColors.trade,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedEntry = _selectedEntry;
    final focusFullPage = _focusFullPage;

    return ColoredBox(
      color: colors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            width: focusFullPage ? 0 : 320,
            child: focusFullPage
                ? const SizedBox.shrink()
                : ClipRect(
                    child: JournalEntryListView(
                      entries: widget.entries,
                      selectedEntryId: _selectedEntryId,
                      showListTitle: false,
                      width: 320,
                      createMode: _createModeHighlight(selectedEntry),
                      filterSlot: widget.listFilterSlot,
                      emptyMessage: JournalFolderFilter.emptyMessage(
                        widget.selectedFolder,
                      ).split('\n').first,
                      emptySubtitle:
                          'Start documenting your trades to unlock powerful insights.',
                      onEntrySelected: _onEntrySelected,
                      onDeleteEntry: _confirmAndDelete,
                      onLogDayPressed: () => _startNewEntry(
                            tradeWorkflow: false,
                            clearTemplate: true,
                          ),
                      onNewTradeJournalPressed: () => _startNewEntry(
                            tradeWorkflow: true,
                            clearTemplate: true,
                          ),
                    ),
                  ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 340),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: KeyedSubtree(
                // Do not key on _isEditingEntry — remounting on Edit forces a
                // second click before the form actually enters edit mode.
                key: ValueKey(
                  _isCreatingNew
                      ? 'composer-${_useTradeWorkflow ? 'trade' : 'day'}'
                      : _forceTradeEdit
                          ? 'trade-edit-${selectedEntry?.id ?? 'none'}'
                          : (selectedEntry?.id ?? 'empty-detail'),
                ),
                child: _buildRightPane(colors, selectedEntry),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPane(dynamic colors, JournalEntry? selectedEntry) {
    if (_isCreatingNew && _useTradeWorkflow) {
      return TradeJournalWorkflowPage(
        key: _newTradeWorkflowKey,
        journalCubit: widget.journalCubit,
        portfolioId: widget.portfolioId,
        embedded: true,
        onEmbeddedDone: (entryId, {required bool complete}) {
          setState(() {
            _selectedEntryId = entryId;
            _useTradeWorkflow = false;
            _forceTradeEdit = false;
            _forceTradeEditStep = null;
          });
          _setCreating(false);
          widget.onEntryCreated?.call(entryId);
        },
        onEmbeddedCancel: () {
          _closeComposer(skipLeaveGuard: true);
        },
      );
    }

    if (!_isCreatingNew &&
        selectedEntry != null &&
        JournalFolderFilter.shouldOpenTradeWorkflow(selectedEntry)) {
      final completed =
          JournalFolderFilter.isCompletedTradeJournal(selectedEntry);
      // Same Pre/Execute/Post template for saved journals; completed starts locked.
      return TradeJournalWorkflowPage(
        key: _editTradeWorkflowKey,
        journalCubit: widget.journalCubit,
        initialEntry: selectedEntry,
        portfolioId: widget.portfolioId,
        embedded: true,
        initialReadOnly: completed && !_forceTradeEdit,
        startAtStep: _forceTradeEditStep ?? (completed ? 2 : null),
        onEmbeddedDone: (entryId, {required bool complete}) {
          setState(() {
            _selectedEntryId = entryId;
            if (complete) {
              _forceTradeEdit = false;
              _forceTradeEditStep = null;
            }
          });
          _notifyComposerOpen();
          widget.onEntryCreated?.call(entryId);
        },
        onEmbeddedCancel: () {
          setState(() {
            _forceTradeEdit = false;
            _forceTradeEditStep = null;
          });
          _notifyComposerOpen();
        },
        onEmbeddedDeleted: () {
          setState(() {
            _selectedEntryId = null;
            _hydratedEntry = null;
            _forceTradeEdit = false;
            _forceTradeEditStep = null;
          });
          _notifyComposerOpen();
        },
      );
    }

    if (_isCreatingNew) {
      return ColoredBox(
        color: colors.surface,
        child: JournalEntryForm(
          key: _newFormKey,
          cubit: widget.journalCubit,
          portfolioId: widget.portfolioId,
          initialTemplate: _composerTemplate,
          defaultEntryType: JournalFolderFilter.createEntryType(
            widget.selectedFolder,
          ),
          defaultFolderId: JournalFolderFilter.createFolderId(
            widget.selectedFolder,
            notebookFolders: _notebookFolders,
          ),
          onCreated: (entryId) {
            _closeComposer(selectEntryId: entryId, skipLeaveGuard: true);
            widget.onEntryCreated?.call(entryId);
          },
          onBrowseTemplates: () => _browseTemplates(_newFormKey),
          onCancelCreate: () => _closeComposer(skipLeaveGuard: true),
        ),
      );
    }

    return JournalEntryDetailView(
      key: ValueKey(selectedEntry?.id ?? 'none'),
      entry: selectedEntry,
      cubit: widget.journalCubit,
      portfolioId: widget.portfolioId,
      onEditModeChanged: _setEditingEntry,
    );
  }
}
