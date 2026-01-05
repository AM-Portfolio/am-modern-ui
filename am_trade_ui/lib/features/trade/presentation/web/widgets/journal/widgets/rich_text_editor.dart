import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class RichTextEditor extends StatelessWidget {
  const RichTextEditor({required this.controller, this.readOnly = false, super.key});

  final quill.QuillController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8, right: 12),
            child: Text(
              'What happened?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          if (!readOnly) ...[_buildToolbar(theme), const Divider(height: 1)],
          _buildEditor(),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) => Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    ),
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        quill.QuillToolbarHistoryButton(controller: controller, isUndo: true),
        quill.QuillToolbarHistoryButton(controller: controller, isUndo: false),
        quill.QuillToolbarToggleStyleButton(attribute: quill.Attribute.bold, controller: controller),
        quill.QuillToolbarToggleStyleButton(attribute: quill.Attribute.italic, controller: controller),
        quill.QuillToolbarToggleStyleButton(attribute: quill.Attribute.underline, controller: controller),
        quill.QuillToolbarToggleStyleButton(attribute: quill.Attribute.strikeThrough, controller: controller),
        quill.QuillToolbarColorButton(controller: controller, isBackground: false),
        quill.QuillToolbarToggleStyleButton(attribute: quill.Attribute.ol, controller: controller),
        quill.QuillToolbarToggleStyleButton(attribute: quill.Attribute.ul, controller: controller),
        quill.QuillToolbarToggleStyleButton(attribute: quill.Attribute.codeBlock, controller: controller),
        quill.QuillToolbarToggleStyleButton(attribute: quill.Attribute.blockQuote, controller: controller),
        quill.QuillToolbarLinkStyleButton(controller: controller),
        quill.QuillToolbarClearFormatButton(controller: controller),
      ],
    ),
  );

  Widget _buildEditor() => SizedBox(
    height: 250,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: AbsorbPointer(
        absorbing: readOnly,
        child: quill.QuillEditor.basic(controller: controller),
      ),
    ),
  );
}
