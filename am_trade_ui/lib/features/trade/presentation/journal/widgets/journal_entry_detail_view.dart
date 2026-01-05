import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../web/widgets/journal/journal_entry_form.dart';
import 'simple_template_dialog.dart';

class JournalEntryDetailView extends StatefulWidget {
  const JournalEntryDetailView({
    required this.entry,
    required this.userId,
    required this.cubit,
    super.key,
  });

  final JournalEntry? entry;
  final String userId;
  final JournalCubit cubit;

  @override
  State<JournalEntryDetailView> createState() => _JournalEntryDetailViewState();
}

class _JournalEntryDetailViewState extends State<JournalEntryDetailView> {
  @override
  Widget build(BuildContext context) {
    if (widget.entry == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'Select an entry to view details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
            ),
          ],
        ),
      );
    }

    final dateStr = DateFormat('EEE MMM dd, yyyy').format(widget.entry!.entryDate);
    final createdStr = DateFormat('MMM dd, yyyy h:mm a').format(widget.entry!.createdAt);
    final updatedStr = DateFormat('MMM dd, yyyy h:mm a').format(widget.entry!.updatedAt);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8), // Glassmorphism
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)), // Rounded corner for sheet effect
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 16),
                

                
                // Action Buttons
                Row(
                  children: [
                    Text('Recently used:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 12),
                    _HoverButton(
                      onPressed: () => _showTemplateBrowser(context),
                      icon: const Icon(Icons.description_outlined, size: 16),
                      child: const Text('Daily Game Plan'),
                    ),
                    const SizedBox(width: 12),
                    _HoverButton(
                      onPressed: () => _showTemplateBrowser(context),
                      icon: const Icon(Icons.add, size: 16),
                      child: const Text('Browse Templates'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
              ],
            ),
          ),

          // Content Editor (Reusing JournalEntryForm or similar, but simplified for viewing/editing)
          // For now, we'll wrap the JournalEntryForm to allow editing the content.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: JournalEntryForm(
                userId: widget.userId,
                cubit: widget.cubit,
                portfolioId: '8a57024c-05c2-475b-a2c4-0545865efa4a', // TODO: Pass from parent
                entry: widget.entry,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  void _showTemplateBrowser(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EnhancedTemplateDialog(
        onTemplateSelected: (templateName, richContent) {
          // Show template content in snackbar for now
          // TODO: Implement actual insertion into Quill editor
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Template "$templateName" selected! (Content insertion coming soon)'),
              backgroundColor: const Color(0xFF6C5DD3),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }
}

/// Hover button with purple color effect
class _HoverButton extends StatefulWidget {
  const _HoverButton({
    required this.onPressed,
    required this.child,
    this.icon,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Widget? icon;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF9C27B0) // Purple color
                : Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    IconTheme(
                      data: IconThemeData(
                        color: _isHovered
                            ? const Color(0xFF9C27B0)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      child: widget.icon!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: _isHovered
                              ? const Color(0xFF9C27B0)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
