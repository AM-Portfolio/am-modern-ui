import 'package:flutter/material.dart';

import '../../../core/theme/color_extensions.dart';

/// A theme-aware, dismissible informational dialog for non-blocking notices.
///
/// Modules provide the copy and optional icon; surfaces and text colors always
/// come from the active global theme.
class InformationDialog extends StatelessWidget {
  const InformationDialog({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  /// Shows the dialog and resolves after the user dismisses it.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => InformationDialog(
        title: title,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final width = MediaQuery.sizeOf(context).width;

    return Dialog(
      backgroundColor: colors.cardSurface,
      surfaceTintColor: colors.cardSurface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: width < 600 ? 24 : 40,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
