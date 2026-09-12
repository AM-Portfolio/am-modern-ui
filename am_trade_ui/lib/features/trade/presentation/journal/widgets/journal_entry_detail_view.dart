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

  @override
  void didUpdateWidget(covariant JournalEntryDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry?.id != widget.entry?.id) {
      _formKey = GlobalKey<JournalEntryFormState>();
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entry == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Select an entry to view details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      );
    }

    final dateStr = DateFormat('EEE MMM dd, yyyy').format(widget.entry!.entryDate);
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(
                  child: Text(
                    dateStr,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                AppButton(
                  text: 'Use template',
                  icon: Icons.auto_awesome_outlined,
                  backgroundColor: ModuleColors.trade,
                  onPressed: _showTemplateBrowser,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.35)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: JournalEntryForm(
                key: _formKey,
                cubit: widget.cubit,
                portfolioId: widget.portfolioId,
                entry: widget.entry,
                onBrowseTemplates: _showTemplateBrowser,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
