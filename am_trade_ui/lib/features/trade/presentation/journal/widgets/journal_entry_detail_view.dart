import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../web/widgets/journal/journal_entry_form.dart';
import 'simple_template_dialog.dart';

class JournalEntryDetailView extends StatefulWidget {
  const JournalEntryDetailView({
    required this.entry,
    required this.cubit,
    this.portfolioId = '',
    this.onEditModeChanged,
    super.key,
  });

  final JournalEntry? entry;
  final JournalCubit cubit;
  final String portfolioId;
  /// True while the entry form is in edit mode (parent expands to full page).
  final ValueChanged<bool>? onEditModeChanged;

  @override
  State<JournalEntryDetailView> createState() => _JournalEntryDetailViewState();
}

class _JournalEntryDetailViewState extends State<JournalEntryDetailView> {
  GlobalKey<JournalEntryFormState> _formKey =
      GlobalKey<JournalEntryFormState>();
  var _formEditMode = false;

  void _setFormEditMode(bool editing) {
    if (_formEditMode == editing) return;
    setState(() => _formEditMode = editing);
    widget.onEditModeChanged?.call(editing);
  }

  @override
  void didUpdateWidget(covariant JournalEntryDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry?.id != widget.entry?.id) {
      _formKey = GlobalKey<JournalEntryFormState>();
      if (_formEditMode) {
        _formEditMode = false;
        widget.onEditModeChanged?.call(false);
      }
    }
  }

  Future<void> _showTemplateBrowser() async {
    await EnhancedTemplateDialog.show(
      context: context,
      onTemplateSelected: (selection) {
        _formKey.currentState?.applyTemplate(selection);
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

  Future<void> _confirmDelete() async {
    final entry = widget.entry;
    if (entry == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
          '“${entry.title.trim().isEmpty ? 'Untitled entry' : entry.title}” will be removed.',
        ),
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
    await widget.cubit.removeJournalEntry(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entry == null) {
      final theme = Theme.of(context);
      final colors = context.colors;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ModuleColors.trade.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 34,
                  color: ModuleColors.trade,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Select an entry to view details',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Or create a new journal entry to get started.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateStr =
        DateFormat('EEE, MMM d, yyyy').format(widget.entry!.entryDate);
    final colors = context.colors;
    final editing = _formEditMode;

    return ColoredBox(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: colors.cardSurface,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colors.border.withValues(alpha: 0.28),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm + 2,
                AppSpacing.sm,
                AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  if (editing) ...[
                    IconButton(
                      tooltip: 'Back to entries',
                      onPressed: () {
                        _formKey.currentState?.exitEditMode();
                        _setFormEditMode(false);
                      },
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: ModuleColors.trade,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editing ? 'Edit entry' : dateStr,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        if (editing) ...[
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (editing)
                    AppButton(
                      text: 'Template',
                      icon: Icons.auto_awesome_outlined,
                      type: AppButtonType.secondary,
                      isOutlined: true,
                      height: 32,
                      onPressed: _showTemplateBrowser,
                    )
                  else
                    AppButton(
                      text: 'Edit',
                      icon: Icons.edit_outlined,
                      backgroundColor: ModuleColors.trade,
                      height: 32,
                      onPressed: () {
                        // Enter form edit first, then notify parent (avoid
                        // remount races wiping edit mode on the same frame).
                        _formKey.currentState?.enterEditMode();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _formKey.currentState?.enterEditMode();
                          _setFormEditMode(true);
                        });
                      },
                    ),
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'template':
                          if (!editing) {
                            _formKey.currentState?.enterEditMode();
                            _setFormEditMode(true);
                          }
                          await _showTemplateBrowser();
                        case 'delete':
                          await _confirmDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'template',
                        child: Text('Apply template'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete entry'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Fill the pane on every screen width — no centered maxWidth gutter.
          Expanded(
            child: JournalEntryForm(
              key: _formKey,
              cubit: widget.cubit,
              portfolioId: widget.portfolioId,
              entry: widget.entry,
              onBrowseTemplates: _showTemplateBrowser,
              onEditModeChanged: (isEditing) {
                if (mounted) _setFormEditMode(isEditing);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms);
  }
}
