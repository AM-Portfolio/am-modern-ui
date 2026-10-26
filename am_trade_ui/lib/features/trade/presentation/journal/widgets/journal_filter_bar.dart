import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/entities/notebook_tag.dart';
import '../models/journal_folder_filter.dart';
import 'journal_themed_dropdown.dart';

enum JournalSortOrder { latestFirst, oldestFirst }

/// Folder + tag / outcome / sort controls for the journal hub.
///
/// Entry-type filtering is owned by [selectedFolder] (Trade notes / Daily /
/// Sessions) — a separate "trade type" dropdown was redundant and often blank.
/// Entry text search is global-app search only (no duplicate bar here).
class JournalFilterBar extends StatefulWidget {
  const JournalFilterBar({
    required this.selectedFolder,
    required this.onFolderChanged,
    required this.selectedTagId,
    required this.onTagChanged,
    required this.selectedOutcome,
    required this.onOutcomeChanged,
    required this.sortOrder,
    required this.onSortChanged,
    @Deprecated('Ignored — use global search') this.searchQuery = '',
    @Deprecated('Ignored — use global search') this.onSearchChanged,
    this.notebookFolders = const [],
    this.notebookTags = const [],
    this.availableOutcomes = const [],
    this.folderCounts = const {},
    super.key,
  });

  final String selectedFolder;
  final ValueChanged<String> onFolderChanged;
  final String? selectedTagId;
  final ValueChanged<String?> onTagChanged;
  final String? selectedOutcome;
  final ValueChanged<String?> onOutcomeChanged;
  final JournalSortOrder sortOrder;
  final ValueChanged<JournalSortOrder> onSortChanged;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final List<NotebookItem> notebookFolders;
  final List<NotebookTag> notebookTags;
  final List<String> availableOutcomes;

  /// Per-folder entry counts (keys = [JournalFolderFilter] / custom titles).
  final Map<String, int> folderCounts;

  @override
  State<JournalFilterBar> createState() => _JournalFilterBarState();
}

class _JournalFilterBarState extends State<JournalFilterBar> {
  List<String> get _folderOptions {
    final builtIns = [
      JournalFolderFilter.allNotes,
      JournalFolderFilter.tradeNotes,
      JournalFolderFilter.dailyJournal,
      JournalFolderFilter.sessionsRecap,
    ];
    final custom = widget.notebookFolders
        .map((f) => f.title)
        .where((t) => t.trim().isNotEmpty)
        .where((t) => !builtIns.contains(t))
        .toSet()
        .toList()
      ..sort();
    return [...builtIns, ...custom];
  }

  String? get _safeTagId {
    if (widget.selectedTagId == null) return null;
    final ids = widget.notebookTags.map((t) => t.id).whereType<String>();
    return ids.contains(widget.selectedTagId) ? widget.selectedTagId : null;
  }

  String? get _safeOutcome {
    if (widget.selectedOutcome == null) return null;
    return widget.availableOutcomes.contains(widget.selectedOutcome)
        ? widget.selectedOutcome
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final folderValue = _folderOptions.contains(widget.selectedFolder)
        ? widget.selectedFolder
        : JournalFolderFilter.allNotes;

    String folderLabel(String folder) {
      final title = JournalFolderFilter.listTitle(folder);
      final n = widget.folderCounts[folder];
      if (n == null) return title;
      return '$title ($n)';
    }

    final folderDrop = JournalThemedDropdown<String>(
      width: 168,
      value: folderValue,
      items: _folderOptions
          .map(
            (f) => DropdownMenuItem(
              value: f,
              child: Text(folderLabel(f)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) widget.onFolderChanged(v);
      },
    );

    final tagDrop = JournalThemedDropdown<String?>(
      width: 140,
      value: _safeTagId,
      hint: 'All Tags',
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Tags'),
        ),
        ...widget.notebookTags
            .where((t) => t.id != null && t.id!.isNotEmpty)
            .map(
              (t) => DropdownMenuItem<String?>(
                value: t.id,
                child: Text(t.name),
              ),
            ),
      ],
      onChanged: widget.onTagChanged,
    );

    final outcomeDrop = JournalThemedDropdown<String?>(
      width: 150,
      value: _safeOutcome,
      hint: 'All Outcomes',
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Outcomes'),
        ),
        ...widget.availableOutcomes.map(
          (o) => DropdownMenuItem<String?>(
            value: o,
            child: Text(o),
          ),
        ),
      ],
      onChanged: widget.onOutcomeChanged,
    );

    final sortDrop = JournalThemedDropdown<JournalSortOrder>(
      width: 140,
      value: widget.sortOrder,
      items: const [
        DropdownMenuItem(
          value: JournalSortOrder.latestFirst,
          child: Text('Latest First'),
        ),
        DropdownMenuItem(
          value: JournalSortOrder.oldestFirst,
          child: Text('Oldest First'),
        ),
      ],
      onChanged: (v) {
        if (v != null) widget.onSortChanged(v);
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: folderDrop),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      tagDrop,
                      const SizedBox(width: AppSpacing.sm),
                      outcomeDrop,
                      const SizedBox(width: AppSpacing.sm),
                      sortDrop,
                    ],
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              folderDrop,
              const SizedBox(width: AppSpacing.sm),
              tagDrop,
              const SizedBox(width: AppSpacing.sm),
              outcomeDrop,
              const SizedBox(width: AppSpacing.sm),
              sortDrop,
              const Spacer(),
            ],
          );
        },
      ),
    );
  }
}
