import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../models/journal_mood_options.dart';
import '../utils/journal_field_decoration.dart';

/// A responsive selector for tags.
/// On desktop (compact == false): renders the full chip Wrap.
/// On mobile (compact == true): renders a compact dropdown-style trigger that opens a bottom sheet.
class TagsSelector extends StatelessWidget {
  const TagsSelector({
    required this.selectedTags,
    required this.onTagToggled,
    this.compact = false,
    super.key,
  });

  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final catalog = JournalMoodOptions.getTags(context);
    final catalogLabels = catalog.map((t) => t['label'] as String).toSet();
    final extras = selectedTags.where((t) => !catalogLabels.contains(t)).toList();
    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;

    if (!compact) {
      // Web view: original chip wrap
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          ...catalog.map((tagData) {
            final tag = tagData['label'] as String;
            final color = tagData['color'] as Color;
            return AmToggleChip(
              label: tag,
              selected: selectedTags.contains(tag),
              compact: true,
              accentColor: color,
              onTap: () => onTagToggled(tag),
            );
          }),
          ...extras.map(
            (tag) => AmToggleChip(
              label: tag,
              selected: true,
              compact: true,
              accentColor: accent,
              onTap: () => onTagToggled(tag),
            ),
          ),
        ],
      );
    }

    // Mobile view: border-label trigger (same pattern as Title / Mood).
    final colors = context.colors;
    final theme = Theme.of(context);
    final count = selectedTags.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => _openTagsPicker(context, catalog, extras),
          borderRadius: AppRadii.input,
          child: InputDecorator(
            decoration: JournalFieldDecoration.outlined(
              context,
              labelText: 'Tags',
              floatingLabel: true,
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
            ).copyWith(
              suffixIcon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppSpacing.md + AppSpacing.xs,
                color: accent,
              ),
            ),
            child: Text(
              count == 0
                  ? 'Select tags'
                  : '$count tag${count == 1 ? '' : 's'} selected',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    count == 0 ? colors.textSecondary : colors.textPrimary,
              ),
            ),
          ),
        ),
        if (selectedTags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: selectedTags.map((tag) {
              return AmToggleChip(
                label: tag,
                selected: true,
                compact: true,
                accentColor: accent,
                onTap: () => onTagToggled(tag),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _openTagsPicker(
    BuildContext context,
    List<Map<String, dynamic>> catalog,
    List<String> extras,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return _TagsPickerSheet(
          catalog: catalog,
          extras: extras,
          selectedTags: selectedTags,
          onTagToggled: onTagToggled,
        );
      },
    );
  }
}

/// Stateful sheet so chips update reactively while the sheet is open.
class _TagsPickerSheet extends StatefulWidget {
  const _TagsPickerSheet({
    required this.catalog,
    required this.extras,
    required this.selectedTags,
    required this.onTagToggled,
  });

  final List<Map<String, dynamic>> catalog;
  final List<String> extras;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;

  @override
  State<_TagsPickerSheet> createState() => _TagsPickerSheetState();
}

class _TagsPickerSheetState extends State<_TagsPickerSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.selectedTags);
  }

  void _toggle(String tag) {
    setState(() {
      if (_selected.contains(tag)) {
        _selected.remove(tag);
      } else {
        _selected.add(tag);
      }
    });
    widget.onTagToggled(tag);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadii.xs / 2)),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Select Tags',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_selected.isNotEmpty)
                    Text(
                      '${_selected.length} selected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ModuleColorProvider.maybeOf(context) ??
                            ModuleColors.trade,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable chip grid
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Builder(
                  builder: (context) {
                    final sheetAccent = ModuleColorProvider.maybeOf(context) ??
                        ModuleColors.trade;
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ...widget.catalog.map((tagData) {
                          final tag = tagData['label'] as String;
                          final color = tagData['color'] as Color;
                          return AmToggleChip(
                            label: tag,
                            selected: _selected.contains(tag),
                            compact: true,
                            accentColor: color,
                            onTap: () => _toggle(tag),
                          );
                        }),
                        ...widget.extras.map(
                          (tag) => AmToggleChip(
                            label: tag,
                            selected: _selected.contains(tag),
                            compact: true,
                            accentColor: sheetAccent,
                            onTap: () => _toggle(tag),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: AppButton(
                text: 'Done',
                backgroundColor: ModuleColorProvider.maybeOf(context) ??
                    ModuleColors.trade,
                onPressed: () => Navigator.of(context).pop(),
                height: 44,
              ),
            ),
          ],
        );
      },
    );
  }
}
