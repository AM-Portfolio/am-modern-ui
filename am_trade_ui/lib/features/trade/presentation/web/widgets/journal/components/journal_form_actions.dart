import 'package:am_design_system/am_design_system.dart';
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
      return Align(
        alignment: Alignment.centerRight,
        child: AppButton(
          text: 'Edit Journal',
          icon: Icons.edit_outlined,
          backgroundColor: ModuleColors.trade,
          onPressed: onToggleEditMode,
          height: 44,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isNewEntry && onCancel != null) ...[
          AppButton(
            text: 'Cancel',
            type: AppButtonType.secondary,
            isOutlined: true,
            icon: Icons.close,
            onPressed: onCancel,
            height: 44,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        AppButton(
          text: isSubmitting
              ? 'Saving...'
              : (isNewEntry ? 'Create Journal' : 'Update Journal'),
          icon: isNewEntry ? Icons.add_rounded : Icons.save_outlined,
          backgroundColor: ModuleColors.trade,
          isLoading: isSubmitting,
          onPressed: isSubmitting ? null : onSubmit,
          height: 44,
        ),
      ],
    );
  }
}
