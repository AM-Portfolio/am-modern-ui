import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Mobile-only notes editor fallback (fixed-height body, scrollable toolbar).
///
/// Log day mobile uses [JournalEntryForm] → shared web [RichTextEditor]
/// with `compact: true`. Keep this file aligned with the same DS fills /
/// no-Expanded layout so any direct caller stays theme-safe.
class RichTextEditorMobile extends StatefulWidget {
  const RichTextEditorMobile({
    required this.controller,
    this.readOnly = false,
    this.minHeight = 180,
    super.key,
  });

  final quill.QuillController controller;
  final bool readOnly;
  final double minHeight;

  @override
  State<RichTextEditorMobile> createState() => _RichTextEditorMobileState();
}

class _RichTextEditorMobileState extends State<RichTextEditorMobile> {
  @override
  void initState() {
    super.initState();
    widget.controller.readOnly = widget.readOnly;
  }

  @override
  void didUpdateWidget(covariant RichTextEditorMobile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readOnly != widget.readOnly ||
        oldWidget.controller != widget.controller) {
      widget.controller.readOnly = widget.readOnly;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final height = widget.minHeight < AppSpacing.xxl * 2 + AppSpacing.lg
        ? widget.minHeight
        : AppSpacing.xxl * 2 + AppSpacing.lg;

    return Localizations.override(
      context: context,
      delegates: const [quill.FlutterQuillLocalizations.delegate],
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.45),
          borderRadius: AppRadii.input,
          border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.readOnly) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.35),
                  border: Border(
                    bottom: BorderSide(
                      color: colors.border.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: SizedBox(
                  height: AppSpacing.xl,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
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
                      quill.QuillToolbarToggleCheckListButton(
                        controller: widget.controller,
                        options: const quill
                            .QuillToolbarToggleCheckListButtonOptions(
                          tooltip: 'Checklist',
                        ),
                      ),
                      quill.QuillToolbarToggleStyleButton(
                        attribute: quill.Attribute.ul,
                        controller: widget.controller,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: quill.QuillEditor.basic(
                  controller: widget.controller,
                  config: quill.QuillEditorConfig(
                    scrollable: true,
                    expands: false,
                    checkBoxReadOnly: false,
                    padding: EdgeInsets.zero,
                    placeholder:
                        widget.readOnly ? null : 'Write notes…',
                    customStyles: quill.DefaultStyles(
                      paragraph: quill.DefaultTextBlockStyle(
                        theme.textTheme.bodyMedium!.copyWith(
                          height: 1.4,
                          color: colors.textPrimary,
                        ),
                        quill.HorizontalSpacing.zero,
                        const quill.VerticalSpacing(0, AppSpacing.xxs),
                        quill.VerticalSpacing.zero,
                        null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
