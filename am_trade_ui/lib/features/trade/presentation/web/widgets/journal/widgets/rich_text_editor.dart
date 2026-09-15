import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class RichTextEditor extends StatelessWidget {
  const RichTextEditor({
    required this.controller,
    this.readOnly = false,
    super.key,
  });

  final quill.QuillController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journal notes',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Check off items, then type under each field — no need to erase blanks.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 360,
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: AppRadii.card,
            border: Border.all(color: colors.border.withValues(alpha: 0.45)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!readOnly) ...[
                _buildToolbar(colors),
                Divider(
                  height: 1,
                  color: colors.border.withValues(alpha: 0.35),
                ),
              ],
              Expanded(child: _buildEditor(theme)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(AppColorsTheme colors) => Container(
        color: colors.cardSurface.withValues(alpha: 0.65),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs + AppSpacing.xxs,
          horizontal: AppSpacing.sm,
        ),
        // Only attributes with built-in tooltips in flutter_quill 11.
        // Header / checklist require custom tooltips and crash otherwise.
        child: Wrap(
          spacing: AppSpacing.xxs,
          runSpacing: AppSpacing.xxs,
          children: [
            quill.QuillToolbarHistoryButton(
              controller: controller,
              isUndo: true,
            ),
            quill.QuillToolbarHistoryButton(
              controller: controller,
              isUndo: false,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.bold,
              controller: controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.italic,
              controller: controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.underline,
              controller: controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.strikeThrough,
              controller: controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.ul,
              controller: controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.ol,
              controller: controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.blockQuote,
              controller: controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.codeBlock,
              controller: controller,
            ),
            quill.QuillToolbarLinkStyleButton(controller: controller),
            quill.QuillToolbarClearFormatButton(controller: controller),
          ],
        ),
      );

  Widget _buildEditor(ThemeData theme) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AbsorbPointer(
          absorbing: readOnly,
          child: quill.QuillEditor.basic(
            controller: controller,
            config: quill.QuillEditorConfig(
              scrollable: true,
              expands: true,
              padding: EdgeInsets.zero,
              placeholder:
                  'Tap a checkbox to mark it done. Type your answers on the empty lines under each field…',
              customStyles: quill.DefaultStyles(
                h1: quill.DefaultTextBlockStyle(
                  theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  quill.HorizontalSpacing.zero,
                  const quill.VerticalSpacing(AppSpacing.sm, AppSpacing.xs),
                  quill.VerticalSpacing.zero,
                  null,
                ),
                h2: quill.DefaultTextBlockStyle(
                  theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  quill.HorizontalSpacing.zero,
                  const quill.VerticalSpacing(AppSpacing.sm, AppSpacing.xs),
                  quill.VerticalSpacing.zero,
                  null,
                ),
                paragraph: quill.DefaultTextBlockStyle(
                  theme.textTheme.bodyMedium!.copyWith(height: 1.5),
                  quill.HorizontalSpacing.zero,
                  const quill.VerticalSpacing(0, AppSpacing.xs),
                  quill.VerticalSpacing.zero,
                  null,
                ),
              ),
            ),
          ),
        ),
      );
}
