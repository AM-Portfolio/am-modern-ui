import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/color_extensions.dart';
import '../inputs/app_text_field.dart';

/// Theme-aware dialog for choosing the number of records shown per page.
class PageSizeDialog extends StatefulWidget {
  const PageSizeDialog({
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    super.key,
    this.title = 'Items per page',
  });

  final int currentValue;
  final int minValue;
  final int maxValue;
  final String title;

  /// Returns the validated page size, or null when the dialog is dismissed.
  static Future<int?> show({
    required BuildContext context,
    required int currentValue,
    required int minValue,
    required int maxValue,
    String title = 'Items per page',
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PageSizeDialog(
        currentValue: currentValue,
        minValue: minValue,
        maxValue: maxValue,
        title: title,
      ),
    );
  }

  @override
  State<PageSizeDialog> createState() => _PageSizeDialogState();
}

class _PageSizeDialogState extends State<PageSizeDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentValue}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < widget.minValue || value > widget.maxValue) {
      setState(
        () => _errorText =
            'Enter a whole number from ${widget.minValue} to ${widget.maxValue}.',
      );
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;

    return Dialog(
      backgroundColor: colors.cardSurface,
      surfaceTintColor: colors.cardSurface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: width < 600 ? 24 : 40,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg - 4,
            AppSpacing.lg - 4,
            AppSpacing.lg - 4,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md - 2),
              AppTextField(
                controller: _controller,
                labelText: 'Rows per page',
                hintText: '${widget.minValue}–${widget.maxValue}',
                errorText: _errorText,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                  signed: false,
                ),
                textInputAction: TextInputAction.done,
                autofocus: true,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md + 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.actionPrimaryBg,
                      foregroundColor: colors.actionPrimaryFg,
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
