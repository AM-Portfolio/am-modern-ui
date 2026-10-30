import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/entities/notebook_tag.dart';
import '../models/journal_folder_filter.dart';
import 'journal_themed_dropdown.dart';

enum JournalSortOrder { latestFirst, oldestFirst }

/// Folder + tag / outcome / sort controls for the journal hub.
///
/// Prefer [embeddedInList] so filters live in the entries rail (inspiration
/// layout) instead of a full-width strip above the detail pane.
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
    @Deprecated('Ignored — use list search / global search') this.searchQuery = '',
    @Deprecated('Ignored — use list search / global search') this.onSearchChanged,
    this.notebookFolders = const [],
    this.notebookTags = const [],
    this.availableOutcomes = const [],
    this.folderCounts = const {},
    this.embeddedInList = false,
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
  final Map<String, int> folderCounts;

  /// Compact pill row for the left entries panel.
  final bool embeddedInList;

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

    final height = widget.embeddedInList ? 34.0 : 40.0;
    final fontSize = widget.embeddedInList ? 12.0 : 13.0;

    JournalThemedDropdown<T> pillDrop<T>({
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?>? onChanged,
      T? value,
      String? hint,
      double? width,
    }) {
      return JournalThemedDropdown<T>(
        value: value,
        hint: hint,
        items: items,
        onChanged: onChanged,
        height: height,
        fontSize: fontSize,
        width: width,
        compact: widget.embeddedInList,
      );
    }

    final folderDrop = pillDrop<String>(
      width: widget.embeddedInList ? null : 168,
      value: folderValue,
      items: _folderOptions
          .map(
            (f) => DropdownMenuItem(
              value: f,
              child: Text(folderLabel(f), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) widget.onFolderChanged(v);
      },
    );

    final tagDrop = pillDrop<String?>(
      width: widget.embeddedInList ? null : 140,
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
                child: Text(t.name, overflow: TextOverflow.ellipsis),
              ),
            ),
      ],
      onChanged: widget.onTagChanged,
    );

    final outcomeDrop = pillDrop<String?>(
      width: widget.embeddedInList ? null : 150,
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
            child: Text(o, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: widget.onOutcomeChanged,
    );

    final sortDrop = pillDrop<JournalSortOrder>(
      width: widget.embeddedInList ? null : 140,
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

    if (widget.embeddedInList) {
      // Two rows × two pills — readable without crowding the rail.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: folderDrop),
              const SizedBox(width: 8),
              Expanded(child: tagDrop),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: outcomeDrop),
              const SizedBox(width: 8),
              Expanded(child: sortDrop),
            ],
          ),
        ],
      );
    }

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
