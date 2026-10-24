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
    super.key,
  });

  final List<JournalEntry> entries;
  final JournalCubit journalCubit;
  final NotebookCubit notebookCubit;
  final String selectedFolder;
  final String portfolioId;
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
  bool _useTradeWorkflow = false;
  GlobalKey<JournalEntryFormState> _newFormKey =
      GlobalKey<JournalEntryFormState>();
  JournalTemplateSelection? _composerTemplate;

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
    if (widget.focusEntryId != null &&
        widget.focusEntryId != oldWidget.focusEntryId &&
        widget.entries.any((e) => e.id == widget.focusEntryId)) {
      setState(() => _selectedEntryId = widget.focusEntryId);
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifySelectedSymbol());
    }
    if (oldWidget.selectedFolder != widget.selectedFolder) {
      setState(() {
        _useTradeWorkflow = false;
        _isEditingEntry = false;
        _selectedEntryId =
            widget.entries.isNotEmpty ? widget.entries.first.id : null;
      });
      _setCreating(false);
      _notifyComposerOpen();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _notifySelectedSymbol());
      return;
    }
    if (_isCreatingNew) return;
    final stillVisible = widget.entries.any((e) => e.id == _selectedEntryId);
    if (!stillVisible) {
      setState(() {
        _selectedEntryId =
            widget.entries.isNotEmpty ? widget.entries.first.id : null;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySelectedSymbol());
  }

  void _notifySelectedSymbol() {
    final selected =
        widget.entries.where((e) => e.id == _selectedEntryId).firstOrNull;
    widget.onSelectedSymbolChanged?.call(selected?.symbol);
  }

  bool get _focusFullPage => _isCreatingNew || _isEditingEntry;

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

  void _startNewEntry({bool tradeWorkflow = false, bool clearTemplate = false}) {
    setState(() {
      _selectedEntryId = null;
      _isEditingEntry = false;
      _useTradeWorkflow = tradeWorkflow;
      if (clearTemplate) _composerTemplate = null;
      _newFormKey = GlobalKey<JournalEntryFormState>();
    });
    _setCreating(true);
    widget.onSelectedSymbolChanged?.call(null);
  }

  void _closeComposer({String? selectEntryId}) {
    setState(() {
      _useTradeWorkflow = false;
      _composerTemplate = null;
      _isEditingEntry = false;
      _selectedEntryId = selectEntryId ??
          (widget.entries.isNotEmpty ? widget.entries.first.id : null);
    });
    _setCreating(false);
  }

  bool _isTradeLike(JournalEntry? entry) {
    if (entry == null) return false;
    return JournalFolderFilter.isTradeLikeEntry(entry);
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
    final selectedEntry =
        widget.entries.where((e) => e.id == _selectedEntryId).firstOrNull;
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
                      listTitle: 'Entries',
                      emptyMessage: JournalFolderFilter.emptyMessage(
                        widget.selectedFolder,
                      ).split('\n').first,
                      emptySubtitle:
                          'Start documenting your trades to unlock powerful insights.',
                      onEntrySelected: (entry) {
                        setState(() {
                          _selectedEntryId = entry.id;
                          _useTradeWorkflow = _isTradeLike(entry);
                          _isEditingEntry = false;
                        });
                        _setCreating(false);
                        _notifyComposerOpen();
                        widget.onSelectedSymbolChanged?.call(entry.symbol);
                      },
                      onLogDayPressed: () => _startNewEntry(
                            tradeWorkflow: false,
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
                key: ValueKey(
                  _isCreatingNew
                      ? 'composer'
                      : _isEditingEntry
                          ? 'edit-${selectedEntry?.id ?? 'none'}'
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
        key: const ValueKey('new-trade-workflow'),
        journalCubit: widget.journalCubit,
        portfolioId: widget.portfolioId,
        embedded: true,
        onEmbeddedDone: (entryId) {
          setState(() {
            _useTradeWorkflow = true;
            _selectedEntryId = entryId;
          });
          _setCreating(false);
          widget.onEntryCreated?.call(entryId);
        },
        onEmbeddedCancel: () {
          setState(() => _useTradeWorkflow = false);
          _setCreating(false);
        },
      );
    }

    if (!_isCreatingNew &&
        selectedEntry != null &&
        (_useTradeWorkflow || _isTradeLike(selectedEntry))) {
      return TradeJournalWorkflowPage(
        key: ValueKey('wf-${selectedEntry.id}'),
        journalCubit: widget.journalCubit,
        initialEntry: selectedEntry,
        portfolioId: widget.portfolioId,
        embedded: true,
        onEmbeddedDone: (entryId) {
          setState(() {
            _selectedEntryId = entryId;
            _useTradeWorkflow = true;
          });
        },
        onEmbeddedCancel: () {
          setState(() => _useTradeWorkflow = false);
        },
      );
    }

    if (_isCreatingNew) {
      final folderLabel =
          JournalFolderFilter.listTitle(widget.selectedFolder);
      return ColoredBox(
        color: colors.surface,
        child: Column(
          children: [
            Material(
              color: colors.cardSurface,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colors.border.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back to entries',
                      onPressed: _closeComposer,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Log day',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: ModuleColors.trade.withValues(alpha: 0.12),
                              borderRadius: AppRadii.chip,
                              border: Border.all(
                                color:
                                    ModuleColors.trade.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              folderLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: ModuleColors.trade,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      text: 'Use template',
                      icon: Icons.auto_awesome_outlined,
                      backgroundColor: ModuleColors.trade,
                      height: 40,
                      onPressed: () => _browseTemplates(_newFormKey),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
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
                      _closeComposer(selectEntryId: entryId);
                      widget.onEntryCreated?.call(entryId);
                    },
                    onBrowseTemplates: () => _browseTemplates(_newFormKey),
                    onCancelCreate: _closeComposer,
                  ),
                ),
              ),
            ),
          ],
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
