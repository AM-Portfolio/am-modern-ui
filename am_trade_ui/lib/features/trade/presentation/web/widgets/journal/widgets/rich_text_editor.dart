import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class RichTextEditor extends StatefulWidget {
  const RichTextEditor({
    required this.controller,
    this.readOnly = false,
    this.minHeight = 360,
    super.key,
  });

  final quill.QuillController controller;
  final bool readOnly;
  final double minHeight;

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  @override
  void initState() {
    super.initState();
    widget.controller.readOnly = widget.readOnly;
  }

  @override
  void didUpdateWidget(covariant RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readOnly != widget.readOnly ||
        oldWidget.controller != widget.controller) {
      widget.controller.readOnly = widget.readOnly;
    }
  }

  bool get _isBlankDocument {
    final plain = widget.controller.document.toPlainText().trim();
    return plain.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    // Ensure Quill localizations even when the host MaterialApp omits the
    // delegate (am_trade_ui is embedded in am_app; missing delegates crash
    // checklist / tooltip lookups with UnimplementedError).
    return Localizations.override(
      context: context,
      delegates: const [quill.FlutterQuillLocalizations.delegate],
      child: Container(
        height: widget.minHeight,
        decoration: BoxDecoration(
          color: widget.readOnly
              ? colors.cardSurface.withValues(alpha: 0.55)
              : colors.surface.withValues(alpha: 0.45),
          borderRadius: AppRadii.card,
          border: Border.all(
            color: colors.border.withValues(alpha: widget.readOnly ? 0.25 : 0.4),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.readOnly) ...[
              _buildToolbar(colors),
              Divider(
                height: 1,
                color: colors.border.withValues(alpha: 0.35),
              ),
            ],
            Expanded(
              child: widget.readOnly && _isBlankDocument
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'No notes yet. Tap Edit to write your checklist and reflections.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    )
                  : _buildEditor(theme, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(AppColorsTheme colors) => Container(
        color: colors.cardSurface.withValues(alpha: 0.65),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs + AppSpacing.xxs,
          horizontal: AppSpacing.sm,
        ),
        // Checklist needs an explicit tooltip (flutter_quill 11 crashes otherwise).
        child: Wrap(
          spacing: AppSpacing.xxs,
          runSpacing: AppSpacing.xxs,
          children: [
            quill.QuillToolbarHistoryButton(
              controller: widget.controller,
              isUndo: true,
            ),
            quill.QuillToolbarHistoryButton(
              controller: widget.controller,
              isUndo: false,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.bold,
              controller: widget.controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.italic,
              controller: widget.controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.underline,
              controller: widget.controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.strikeThrough,
              controller: widget.controller,
            ),
            quill.QuillToolbarToggleCheckListButton(
              controller: widget.controller,
              options: const quill.QuillToolbarToggleCheckListButtonOptions(
                tooltip: 'Checklist',
              ),
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.ul,
              controller: widget.controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.ol,
              controller: widget.controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.blockQuote,
              controller: widget.controller,
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.codeBlock,
              controller: widget.controller,
            ),
            quill.QuillToolbarLinkStyleButton(controller: widget.controller),
            quill.QuillToolbarClearFormatButton(controller: widget.controller),
          ],
        ),
      );

  Widget _buildEditor(ThemeData theme, AppColorsTheme colors) {
    final bodyStyle = (widget.readOnly
            ? theme.textTheme.bodyLarge
            : theme.textTheme.bodyMedium)!
        .copyWith(
      height: widget.readOnly ? 1.65 : 1.5,
      color: theme.colorScheme.onSurface.withValues(
        alpha: widget.readOnly ? 0.95 : 1,
      ),
      fontSize: widget.readOnly ? 16 : null,
    );

    return Padding(
      padding: EdgeInsets.all(
        widget.readOnly ? AppSpacing.lg : AppSpacing.md,
      ),
      child: quill.QuillEditor.basic(
        controller: widget.controller,
        config: quill.QuillEditorConfig(
          scrollable: true,
          expands: true,
          // Checklist stays clickable after Use template / in view mode.
          checkBoxReadOnly: false,
          padding: EdgeInsets.zero,
          placeholder: widget.readOnly
              ? null
              : 'Tap a checkbox to mark it done. Type your answers on the empty lines under each field…',
          customStyles: quill.DefaultStyles(
            h1: quill.DefaultTextBlockStyle(
              theme.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: theme.colorScheme.onSurface,
              ),
              quill.HorizontalSpacing.zero,
              const quill.VerticalSpacing(AppSpacing.sm, AppSpacing.xs),
              quill.VerticalSpacing.zero,
              null,
            ),
            h2: quill.DefaultTextBlockStyle(
              theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: theme.colorScheme.onSurface,
              ),
              quill.HorizontalSpacing.zero,
              const quill.VerticalSpacing(AppSpacing.sm, AppSpacing.xs),
              quill.VerticalSpacing.zero,
              null,
            ),
            paragraph: quill.DefaultTextBlockStyle(
              bodyStyle,
              quill.HorizontalSpacing.zero,
              const quill.VerticalSpacing(0, AppSpacing.xs),
              quill.VerticalSpacing.zero,
              null,
            ),
          ),
        ),
      ),
    );
  }
}
