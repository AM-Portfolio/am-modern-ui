import 'package:flutter/material.dart';

class JournalFormActions extends StatelessWidget {
  const JournalFormActions({
    required this.isEditMode,
    required this.isSubmitting,
    required this.isNewEntry,
    required this.onSubmit,
    required this.onToggleEditMode,
    required this.onCancel,
    super.key,
  });

  final bool isEditMode;
  final bool isSubmitting;
  final bool isNewEntry;
  final VoidCallback onSubmit;
  final VoidCallback onToggleEditMode;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    if (!isEditMode && !isNewEntry) {
      // View mode - show Edit button
      return Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: onToggleEditMode,
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Journal'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17)),
        ),
      );
    }

    // Edit mode or new entry - show Update/Create and Cancel buttons
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isNewEntry && onCancel != null) ...[
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17)),
          ),
          const SizedBox(width: 12),
        ],
        FilledButton.icon(
          onPressed: isSubmitting ? null : onSubmit,
          icon: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(isNewEntry ? Icons.add : Icons.save, size: 18),
          label: Text(isSubmitting ? 'Saving...' : (isNewEntry ? 'Create Journal' : 'Update Journal')),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17)),
        ),
      ],
    );
  }
}
