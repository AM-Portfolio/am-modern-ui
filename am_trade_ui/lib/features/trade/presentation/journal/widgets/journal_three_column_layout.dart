import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../internal/domain/entities/journal_entry.dart';
import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/entities/notebook_tag.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../notebook/cubit/notebook_cubit.dart';
import '../../notebook/cubit/notebook_state.dart';
import 'journal_entry_detail_view.dart';
import 'journal_entry_list_view.dart';
import 'journal_navigation_sidebar.dart';

class JournalThreeColumnLayout extends StatefulWidget {
  const JournalThreeColumnLayout({
    required this.entries,
    required this.userId,
    required this.journalCubit,
    required this.notebookCubit,
    this.onAddFolder,
    this.onEntryDropped,
    super.key,
  });

  final List<JournalEntry> entries;
  final String userId;
  final JournalCubit journalCubit;
  final NotebookCubit notebookCubit;
  final VoidCallback? onAddFolder;
  final Function(JournalEntry entry, String folderId)? onEntryDropped;

  @override
  State<JournalThreeColumnLayout> createState() => _JournalThreeColumnLayoutState();
}

class _JournalThreeColumnLayoutState extends State<JournalThreeColumnLayout> {
  String _selectedFolder = 'Daily Journal';
  String? _selectedEntryId;
  bool _isLeftSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    if (widget.entries.isNotEmpty) {
      _selectedEntryId = widget.entries.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant JournalThreeColumnLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.isNotEmpty && _selectedEntryId == null) {
      setState(() {
        _selectedEntryId = widget.entries.first.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEntry = widget.entries.where((e) => e.id == _selectedEntryId).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
          ],
        ),
      ),
      child: Row(
        children: [
          // Left Column: Navigation
          BlocBuilder<NotebookCubit, NotebookState>(
            bloc: widget.notebookCubit,
            builder: (context, state) {
              final folders = state is NotebookLoaded ? state.items : <NotebookItem>[]; // Assuming items are folders for now, or filter by type
              final tags = state is NotebookLoaded ? state.tags : <NotebookTag>[];
              
              return JournalNavigationSidebar(
                selectedFolder: _selectedFolder,
                onFolderSelected: (folder) => setState(() => _selectedFolder = folder),
                isCollapsed: _isLeftSidebarCollapsed,
                onToggleCollapse: () => setState(() => _isLeftSidebarCollapsed = !_isLeftSidebarCollapsed),
                folders: folders,
                tags: tags,
                onAddFolder: widget.onAddFolder,
                onEntryDropped: widget.onEntryDropped,
              );
            },
          ),
          
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),

          // Middle Column: Entry List
          JournalEntryListView(
            entries: widget.entries,
            selectedEntryId: _selectedEntryId,
            onEntrySelected: (entry) => setState(() => _selectedEntryId = entry.id),
          ),

          VerticalDivider(width: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),

          // Right Column: Detail View
          Expanded(
            child: JournalEntryDetailView(
              entry: selectedEntry,
              userId: widget.userId,
              cubit: widget.journalCubit,
            ),
          ),
        ],
      ),
    );
  }
}
