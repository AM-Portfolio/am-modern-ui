import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/entities/notebook_tag.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../cubit/journal/journal_state.dart';
import '../../notebook/cubit/notebook_cubit.dart';
import '../../notebook/cubit/notebook_state.dart';
import '../../web/widgets/journal/journal_entry_form.dart';
import '../models/journal_folder_filter.dart';
import '../pages/trade_journal_workflow_page.dart';
import 'journal_entry_detail_view.dart';
import 'journal_entry_list_view.dart';
import 'journal_navigation_sidebar.dart';
import 'simple_template_dialog.dart';

class JournalThreeColumnLayout extends StatefulWidget {
  const JournalThreeColumnLayout({
    required this.entries,
    required this.journalCubit,
    required this.notebookCubit,
    this.portfolioId = '',
    this.onAddFolder,
    this.onNewTradeTap,
    this.onEntryDropped,
    super.key,
  });

  final List<JournalEntry> entries;
  final JournalCubit journalCubit;
  final NotebookCubit notebookCubit;
  final String portfolioId;
  final VoidCallback? onAddFolder;
  final VoidCallback? onNewTradeTap;
  final void Function(JournalEntry entry, String folderId)? onEntryDropped;

  @override
  State<JournalThreeColumnLayout> createState() =>
      _JournalThreeColumnLayoutState();
}

class _JournalThreeColumnLayoutState extends State<JournalThreeColumnLayout> {
  String _selectedFolder = JournalFolderFilter.dailyJournal;
  String? _selectedEntryId;
  bool _isCreatingNew = false;
  /// When creating or viewing a trade-discipline entry, show workflow.
  bool _useTradeWorkflow = false;
  bool _isLeftSidebarCollapsed = false;
  GlobalKey<JournalEntryFormState> _newFormKey =
      GlobalKey<JournalEntryFormState>();

  List<NotebookItem> get _notebookFolders {
    final state = widget.notebookCubit.state;
    return state is NotebookLoaded ? state.items : const [];
  }

  List<JournalEntry> get _filteredEntries => JournalFolderFilter.filter(
        entries: widget.entries,
        folder: _selectedFolder,
        notebookFolders: _notebookFolders,
      );

  @override
  void initState() {
    super.initState();
    final filtered = _filteredEntries;
    if (filtered.isNotEmpty) {
      _selectedEntryId = filtered.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant JournalThreeColumnLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCreatingNew) return;
    final filtered = _filteredEntries;
    final stillVisible = filtered.any((e) => e.id == _selectedEntryId);
    if (!stillVisible) {
      setState(() {
        _selectedEntryId = filtered.isNotEmpty ? filtered.first.id : null;
      });
    }
  }

  void _selectFolder(String folder) {
    final filtered = JournalFolderFilter.filter(
      entries: widget.entries,
      folder: folder,
      notebookFolders: _notebookFolders,
    );
    setState(() {
      _selectedFolder = folder;
      _isCreatingNew = false;
      _selectedEntryId = filtered.isNotEmpty ? filtered.first.id : null;
    });
  }

  void _startNewEntry() {
    setState(() {
      _selectedEntryId = null;
      _isCreatingNew = true;
      _newFormKey = GlobalKey<JournalEntryFormState>();
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filteredEntries = _filteredEntries;
    final selectedEntry =
        filteredEntries.where((e) => e.id == _selectedEntryId).firstOrNull;

    return ColoredBox(
      color: colors.surface,
      child: Row(
        children: [
          BlocBuilder<NotebookCubit, NotebookState>(
            bloc: widget.notebookCubit,
            builder: (context, state) {
              final folders =
                  state is NotebookLoaded ? state.items : <NotebookItem>[];
              final tags =
                  state is NotebookLoaded ? state.tags : <NotebookTag>[];

              return JournalNavigationSidebar(
                selectedFolder: _selectedFolder,
                onFolderSelected: _selectFolder,
                isCollapsed: _isLeftSidebarCollapsed,
                onToggleCollapse: () => setState(
                  () => _isLeftSidebarCollapsed = !_isLeftSidebarCollapsed,
                ),
                folders: folders,
                tags: tags,
                onAddFolder: widget.onAddFolder,
                onTagTap: (tagId) {
                  final current = widget.journalCubit.state.maybeWhen(
                    loaded: (_, __, ___, ____, tagIds, _____, ______) => tagIds,
                    orElse: () => <String>[],
                  );
                  final next = List<String>.from(current);
                  if (next.contains(tagId)) {
                    next.remove(tagId);
                  } else {
                    next.add(tagId);
                  }
                  widget.journalCubit.setFilters(tagIds: next);
                },
                onNewTradeTap: () {
                  _startNewEntry();
                  widget.onNewTradeTap?.call();
                },
                onEntryDropped: widget.onEntryDropped,
              );
            },
          ),
          VerticalDivider(
            width: 1,
            color: colors.border.withValues(alpha: 0.35),
          ),
          JournalEntryListView(
            entries: filteredEntries,
            selectedEntryId: _isCreatingNew ? null : _selectedEntryId,
            listTitle: JournalFolderFilter.listTitle(_selectedFolder),
            emptyMessage: JournalFolderFilter.emptyMessage(_selectedFolder),
            onEntrySelected: (entry) => setState(() {
              _selectedEntryId = entry.id;
              _isCreatingNew = false;
            }),
            onLogDayPressed: _startNewEntry,
          ),
          VerticalDivider(
            width: 1,
            color: colors.border.withValues(alpha: 0.35),
          ),
          Expanded(
            child: _isCreatingNew
                ? ColoredBox(
                    color: colors.cardSurface.withValues(alpha: 0.35),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.sm + AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_document,
                                size: 22,
                                color: ModuleColors.trade,
                              ),
                              const SizedBox(
                                width: AppSpacing.sm + AppSpacing.xs,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'New Journal Entry',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      'Folder: $_selectedFolder',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              AppButton(
                                text: 'Use template',
                                icon: Icons.auto_awesome_outlined,
                                backgroundColor: ModuleColors.trade,
                                onPressed: () =>
                                    _browseTemplates(_newFormKey),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: colors.border.withValues(alpha: 0.35),
                        ),
                        Expanded(
                          child: JournalEntryForm(
                            key: _newFormKey,
                            cubit: widget.journalCubit,
                            portfolioId: widget.portfolioId,
                            defaultEntryType:
                                JournalFolderFilter.createEntryType(
                              _selectedFolder,
                            ),
                            defaultFolderId: JournalFolderFilter.createFolderId(
                              _selectedFolder,
                              notebookFolders: _notebookFolders,
                            ),
                            onCreated: (entryId) {
                              setState(() {
                                _isCreatingNew = false;
                                _selectedEntryId = entryId;
                              });
                            },
                            onBrowseTemplates: () =>
                                _browseTemplates(_newFormKey),
                          ),
                        ),
                      ],
                    ),
                  )
                : JournalEntryDetailView(
                    key: ValueKey(selectedEntry?.id ?? 'none'),
                    entry: selectedEntry,
                    cubit: widget.journalCubit,
                    portfolioId: widget.portfolioId,
                  ),
          ),
        ],
      ),
    );
  }
}
