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
    this.compact = false,
    super.key,
  });

  /// Matches [AppButton] height used by Cancel / Save in this bar.
  static const double actionRowHeight = 36;

  /// Extra scroll clearance so Supporting Evidence drop zone + previews sit
  /// above this sticky bar (picker drop zone ≈ 2×xxl + lg).
  static const double attachmentScrollClearance =
      AppSpacing.xxl * 2 + AppSpacing.lg;

  final bool isEditMode;
  final bool isSubmitting;
  final bool isNewEntry;
  final VoidCallback onSubmit;
  final VoidCallback onToggleEditMode;
  final VoidCallback? onCancel;

  /// Quiet secondary action — replaces the old gold header "Use template".
  final VoidCallback? onBrowseTemplates;

  /// Narrow mobile: shorter labels + tighter horizontal padding (no H overflow).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // View mode: Edit lives in the detail header — no sticky footer chrome.
    if (!isEditMode && !isNewEntry) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
    final buttonPad = compact
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + AppSpacing.xxs,
            vertical: AppSpacing.xs,
          )
        : null;
    final saveLabel = isSubmitting
        ? 'Saving...'
        : compact
            ? (isNewEntry ? 'Save' : 'Update')
            : (isNewEntry ? 'Save entry' : 'Update entry');

    return Row(
      children: [
        if (onBrowseTemplates != null)
          AppButton(
            text: 'Template',
            icon: Icons.auto_awesome_outlined,
            type: AppButtonType.secondary,
            isOutlined: true,
            backgroundColor: accent,
            textColor: accent,
            onPressed: onBrowseTemplates,
            height: 36,
            padding: buttonPad,
          ),
        const Spacer(),
        if (onCancel != null) ...[
          AppButton(
            text: 'Cancel',
            type: AppButtonType.secondary,
            isOutlined: true,
            backgroundColor: colors.border,
            textColor: colors.textSecondary,
            onPressed: onCancel,
            height: 36,
            padding: buttonPad,
          ),
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
        ],
        AppButton(
          text: saveLabel,
          icon: isNewEntry ? Icons.check_rounded : Icons.save_outlined,
          backgroundColor: accent,
          textColor: colors.actionPrimaryFg,
          isLoading: isSubmitting,
          onPressed: isSubmitting ? null : onSubmit,
          height: 36,
          padding: buttonPad,
        ),
      ],
    );
  }
}
