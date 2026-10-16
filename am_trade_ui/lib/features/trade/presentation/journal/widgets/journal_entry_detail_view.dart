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
    super.key,
  });

  final JournalEntry? entry;
  final JournalCubit cubit;
  final String portfolioId;

  @override
  State<JournalEntryDetailView> createState() => _JournalEntryDetailViewState();
}

class _JournalEntryDetailViewState extends State<JournalEntryDetailView> {
  GlobalKey<JournalEntryFormState> _formKey =
      GlobalKey<JournalEntryFormState>();
  var _formEditMode = false;

  @override
  void didUpdateWidget(covariant JournalEntryDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry?.id != widget.entry?.id) {
      _formKey = GlobalKey<JournalEntryFormState>();
      _formEditMode = false;
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
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: ModuleColors.trade.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ModuleColors.trade.withValues(alpha: 0.18),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 42,
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

    final dateStr = DateFormat('EEE MMM dd, yyyy').format(widget.entry!.entryDate);
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
                    color: colors.border.withValues(alpha: 0.35),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm + 2,
                AppSpacing.md,
                AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: ModuleColors.trade,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      dateStr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
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
                        _formKey.currentState?.enterEditMode();
                        setState(() => _formEditMode = true);
                      },
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: JournalEntryForm(
              key: _formKey,
              cubit: widget.cubit,
              portfolioId: widget.portfolioId,
              entry: widget.entry,
              onBrowseTemplates: _showTemplateBrowser,
              onEditModeChanged: (editing) {
                if (mounted) setState(() => _formEditMode = editing);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
