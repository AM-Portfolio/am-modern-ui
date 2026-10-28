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
    this.onBrowseTemplates,
    super.key,
  });

  final bool isEditMode;
  final bool isSubmitting;
  final bool isNewEntry;
  final VoidCallback onSubmit;
  final VoidCallback onToggleEditMode;
  final VoidCallback? onCancel;
  /// Quiet secondary action — replaces the old gold header "Use template".
  final VoidCallback? onBrowseTemplates;

  @override
  Widget build(BuildContext context) {
    // View mode: Edit lives in the detail header — no sticky footer chrome.
    if (!isEditMode && !isNewEntry) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (onBrowseTemplates != null)
          AppButton(
            text: 'Template',
            icon: Icons.auto_awesome_outlined,
            type: AppButtonType.secondary,
            isOutlined: true,
            backgroundColor: ModuleColors.trade,
            onPressed: onBrowseTemplates,
            height: 36,
          ),
        const Spacer(),
        if (onCancel != null) ...[
          AppButton(
            text: 'Cancel',
            type: AppButtonType.secondary,
            isOutlined: true,
            onPressed: onCancel,
            height: 36,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        AppButton(
          text: isSubmitting
              ? 'Saving...'
              : (isNewEntry ? 'Save entry' : 'Update entry'),
          icon: isNewEntry ? Icons.check_rounded : Icons.save_outlined,
          backgroundColor: ModuleColors.trade,
          isLoading: isSubmitting,
          onPressed: isSubmitting ? null : onSubmit,
          height: 36,
        ),
      ],
    );
  }
}
