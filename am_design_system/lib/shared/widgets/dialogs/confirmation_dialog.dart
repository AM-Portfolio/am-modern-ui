import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors_theme.dart';
import 'dialog_header.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.icon,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
  });

  final String title;
  final String subtitle;
  final String message;
  final IconData icon;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;

  /// Shows the dialog and returns true if confirmed, false if cancelled/dismissed.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String message,
    required IconData icon,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConfirmationDialog(
        title: title,
        subtitle: subtitle,
        message: message,
        icon: icon,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsTheme>() ?? AppColorsTheme.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600 ? screenWidth * 0.9 : 500.0;
    
    final iconColor = isDestructive ? colors.statusError : colors.actionPrimaryBg;

    return Center(
      child: SingleChildScrollView(
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DialogHeader(
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                    iconColor: iconColor,
                    onClose: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(cancelText),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive ? colors.statusError : colors.actionPrimaryBg,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
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
