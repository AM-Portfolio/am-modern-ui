import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/entities/notebook_tag.dart';
import '../models/journal_folder_filter.dart';

enum JournalSortOrder { latestFirst, oldestFirst }

/// Folder + tag / type / outcome / sort controls for the journal hub.
/// Entry text search is global-app search only (no duplicate bar here).
class JournalFilterBar extends StatefulWidget {
  const JournalFilterBar({
    required this.selectedFolder,
    required this.onFolderChanged,
    required this.selectedTagId,
    required this.onTagChanged,
    required this.selectedTradeType,
    required this.onTradeTypeChanged,
    required this.selectedOutcome,
    required this.onOutcomeChanged,
    required this.sortOrder,
    required this.onSortChanged,
    @Deprecated('Ignored — use global search') this.searchQuery = '',
    @Deprecated('Ignored — use global search') this.onSearchChanged,
    this.notebookFolders = const [],
    this.notebookTags = const [],
    this.availableOutcomes = const [],
    super.key,
  });

  final String selectedFolder;
  final ValueChanged<String> onFolderChanged;
  final String? selectedTagId;
  final ValueChanged<String?> onTagChanged;
  final String? selectedTradeType;
  final ValueChanged<String?> onTradeTypeChanged;
  final String? selectedOutcome;
  final ValueChanged<String?> onOutcomeChanged;
  final JournalSortOrder sortOrder;
  final ValueChanged<JournalSortOrder> onSortChanged;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final List<NotebookItem> notebookFolders;
  final List<NotebookTag> notebookTags;
  final List<String> availableOutcomes;

  @override
  State<JournalFilterBar> createState() => _JournalFilterBarState();
}

class _JournalFilterBarState extends State<JournalFilterBar> {
  static const _tradeTypes = <({String? value, String label})>[
    (value: null, label: 'All Trade Types'),
    (value: 'DAILY', label: 'Daily'),
    (value: 'TRADE_NOTE', label: 'Trade note'),
    (value: 'SESSION', label: 'Session'),
    (value: 'GENERAL', label: 'General'),
  ];

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
    final colors = context.colors;
    final theme = Theme.of(context);
    final folderValue = _folderOptions.contains(widget.selectedFolder)
        ? widget.selectedFolder
        : JournalFolderFilter.allNotes;

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

          final folderDrop = _DropdownShell(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: folderValue,
                isDense: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
                dropdownColor: colors.cardSurface,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                items: _folderOptions
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(JournalFolderFilter.listTitle(f)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) widget.onFolderChanged(v);
                },
              ),
            ),
          );

          final tagDrop = _DropdownShell(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _safeTagId,
                isDense: true,
                hint: Text(
                  'All Tags',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
                dropdownColor: colors.cardSurface,
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
              ),
            ),
          );

          final typeDrop = _DropdownShell(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: widget.selectedTradeType,
                isDense: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
                dropdownColor: colors.cardSurface,
                items: _tradeTypes
                    .map(
                      (t) => DropdownMenuItem<String?>(
                        value: t.value,
                        child: Text(t.label),
                      ),
                    )
                    .toList(),
                onChanged: widget.onTradeTypeChanged,
              ),
            ),
          );

          final outcomeDrop = _DropdownShell(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _safeOutcome,
                isDense: true,
                hint: Text(
                  'All Outcomes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
                dropdownColor: colors.cardSurface,
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
              ),
            ),
          );

          final sortDrop = _DropdownShell(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<JournalSortOrder>(
                value: widget.sortOrder,
                isDense: true,
                icon: Icon(
                  Icons.sort_rounded,
                  color: colors.textSecondary,
                  size: 18,
                ),
                dropdownColor: colors.cardSurface,
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
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                folderDrop,
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      tagDrop,
                      const SizedBox(width: AppSpacing.sm),
                      typeDrop,
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
              typeDrop,
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

class _DropdownShell extends StatelessWidget {
  const _DropdownShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}
