import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Journal Notes: Quill body always has a fixed, focusable writing box.
///
/// Checklist/header sit outside that box so they cannot crush editor height.
/// Avoids wrapping Quill in [InputDecorator] (breaks keyboard focus on web).
class RichTextEditor extends StatefulWidget {
  const RichTextEditor({
    required this.controller,
    this.readOnly = false,
    this.minHeight = 360,
    this.compact = false,
    this.label,
    this.header,
    this.editorLeading,
    this.footer,
    this.onPlainTextChanged,
    super.key,
  });

  final quill.QuillController controller;
  final bool readOnly;
  final double minHeight;
  final bool compact;
  final String? label;

  /// Above the toolbar (e.g. template chip / fields).
  final Widget? header;

  /// Between toolbar and Quill (e.g. template checklist) — not inside Quill height.
  final Widget? editorLeading;

  /// Below Quill (e.g. tags + word count).
  final Widget? footer;

  final ValueChanged<String>? onPlainTextChanged;

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  final _editorFocusNode = FocusNode(debugLabel: 'journal-notes-quill');
  final _wordCount = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _syncReadOnly();
    widget.controller.addListener(_onDocChanged);
    _wordCount.value = _countWords();
  }

  @override
  void didUpdateWidget(covariant RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onDocChanged);
      widget.controller.addListener(_onDocChanged);
      _wordCount.value = _countWords();
    }
    if (oldWidget.readOnly != widget.readOnly ||
        oldWidget.controller != widget.controller) {
      _syncReadOnly();
    }
  }

  void _syncReadOnly() {
    if (widget.controller.readOnly != widget.readOnly) {
      widget.controller.readOnly = widget.readOnly;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onDocChanged);
    _editorFocusNode.dispose();
    _wordCount.dispose();
    super.dispose();
  }

  void _onDocChanged() {
    widget.onPlainTextChanged?.call(widget.controller.document.toPlainText());
    final next = _countWords();
    if (_wordCount.value != next) {
      _wordCount.value = next;
    }
  }

  int _countWords() {
    final plain = widget.controller.document.toPlainText().trim();
    if (plain.isEmpty) return 0;
    return plain.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  bool get _isBlankDocument =>
      widget.controller.document.toPlainText().trim().isEmpty;

  double get _editorHeight => widget.minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Match [JournalFieldDecoration.borderLabel] fill so Notes chrome is consistent.
    final fieldFill = colors.surface.withValues(alpha: 0.45);
    final borderColor =
        colors.border.withValues(alpha: widget.readOnly ? 0.25 : 0.4);

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.header != null) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.compact ? AppSpacing.xs : AppSpacing.sm,
              widget.compact ? AppSpacing.xs : AppSpacing.sm,
              widget.compact ? AppSpacing.xs : AppSpacing.sm,
              0,
            ),
            child: widget.header!,
          ),
          SizedBox(height: widget.compact ? AppSpacing.sm : AppSpacing.md),
        ],
        if (!widget.readOnly) _buildToolbar(colors),
        if (widget.editorLeading != null) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.compact ? AppSpacing.xs : AppSpacing.md,
              widget.compact ? AppSpacing.xs : AppSpacing.sm,
              widget.compact ? AppSpacing.xs : AppSpacing.md,
              widget.compact ? AppSpacing.xs : AppSpacing.sm,
            ),
            child: widget.editorLeading!,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colors.border.withValues(alpha: 0.35),
          ),
        ],
        // Dedicated Quill box — fixed height, always present in edit mode.
        SizedBox(
          height: _editorHeight,
          child: widget.readOnly && _isBlankDocument
              ? Padding(
                  padding: EdgeInsets.all(
                    widget.compact ? AppSpacing.sm : AppSpacing.lg,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      widget.compact
                          ? 'No notes yet.'
                          : 'No notes yet. Tap Edit to write.',
                      style: context.text.body(compact: true).copyWith(
                            color: colors.textSecondary,
                            height: 1.3,
                          ),
                    ),
                  ),
                )
              : _buildEditor(colors),
        ),
        if (widget.footer != null || (!widget.readOnly && !widget.compact)) ...[
          Divider(
            height: 1,
            thickness: 1,
            color: colors.border.withValues(alpha: 0.35),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.compact ? AppSpacing.xs : AppSpacing.sm,
              AppSpacing.sm,
              widget.compact ? AppSpacing.xs : AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (widget.footer != null)
                  Expanded(child: widget.footer!)
                else
                  const Spacer(),
                if (!widget.compact)
                  ValueListenableBuilder<int>(
                    valueListenable: _wordCount,
                    builder: (_, count, __) => Text(
                      '$count words',
                      style: context.text.caption(compact: true).copyWith(
                            color: colors.textTertiary,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );

    final body = Localizations.override(
      context: context,
      delegates: const [quill.FlutterQuillLocalizations.delegate],
      child: column,
    );

    // Quill is not an InputClient — InputDecorator steals/breaks keyboard on web.
    // Same visual contract as JournalFieldDecoration.borderLabel, without wrapping Quill.
    final fill = widget.readOnly
        ? colors.cardSurface.withValues(alpha: 0.55)
        : fieldFill;
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadii.input,
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      padding: widget.label == null
          ? EdgeInsets.zero
          : EdgeInsets.only(
              top: widget.compact
                  ? AppSpacing.sm
                  : AppSpacing.sm + AppSpacing.xs,
            ),
      child: body,
    );

    if (widget.label == null) return card;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          left: AppSpacing.md,
          top: -AppSpacing.sm,
          child: ColoredBox(
            // Notch uses the same fill as the field so it blends on any parent surface.
            color: fill,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                widget.label!,
                style: context.text.label(compact: true).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactBtn(Widget button) {
    return SizedBox(
      width: AppSpacing.lg + AppSpacing.xs,
      height: AppSpacing.lg + AppSpacing.xs,
      child: FittedBox(fit: BoxFit.contain, child: button),
    );
  }

  Widget _buildToolbar(AppColorsTheme colors) {
    final buttons = <Widget>[
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
      if (!widget.compact)
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
      if (!widget.compact) ...[
        quill.QuillToolbarToggleStyleButton(
          attribute: quill.Attribute.blockQuote,
          controller: widget.controller,
        ),
        quill.QuillToolbarToggleStyleButton(
          attribute: quill.Attribute.codeBlock,
          controller: widget.controller,
        ),
      ],
      quill.QuillToolbarLinkStyleButton(controller: widget.controller),
      if (!widget.compact)
        quill.QuillToolbarClearFormatButton(controller: widget.controller),
    ];

    if (widget.compact) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.35),
          border: Border(
            bottom: BorderSide(color: colors.border.withValues(alpha: 0.35)),
          ),
        ),
        child: SizedBox(
          height: AppSpacing.xl,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            itemCount: buttons.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.xxs),
            itemBuilder: (_, i) => _compactBtn(buttons[i]),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.45),
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.35)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.sm,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xxs),
                  buttons[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(AppColorsTheme colors) {
    final bodyStyle = context.text.body(compact: widget.compact).copyWith(
          height: widget.compact ? 1.3 : (widget.readOnly ? 1.65 : 1.45),
          color: colors.textPrimary.withValues(
            alpha: widget.readOnly ? 0.95 : 1,
          ),
          fontSize: widget.readOnly ? AppTypeScale.xl : null,
        );

    return ColoredBox(
      color: colors.cardSurface.withValues(alpha: 0.35),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.compact ? AppSpacing.xs : AppSpacing.md,
          widget.compact ? AppSpacing.xs : AppSpacing.md,
          widget.compact ? AppSpacing.xs : AppSpacing.md,
          widget.compact ? AppSpacing.xs : AppSpacing.md,
        ),
        child: quill.QuillEditor.basic(
          controller: widget.controller,
          focusNode: _editorFocusNode,
          config: quill.QuillEditorConfig(
            scrollable: true,
            expands: true,
            checkBoxReadOnly: widget.readOnly,
            enableInteractiveSelection: !widget.readOnly,
            showCursor: !widget.readOnly,
            padding: EdgeInsets.zero,
            placeholder: widget.readOnly
                ? null
                : (widget.compact ? 'Write notes…' : 'Write your notes…'),
            customStyles: quill.DefaultStyles(
              h1: quill.DefaultTextBlockStyle(
                context.text.sectionTitle().copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: colors.textPrimary,
                      fontSize: AppTypeScale.h4,
                    ),
                quill.HorizontalSpacing.zero,
                const quill.VerticalSpacing(AppSpacing.sm, AppSpacing.xs),
                quill.VerticalSpacing.zero,
                null,
              ),
              h2: quill.DefaultTextBlockStyle(
                context.text.sectionTitle(compact: true).copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: colors.textPrimary,
                    ),
                quill.HorizontalSpacing.zero,
                const quill.VerticalSpacing(AppSpacing.sm, AppSpacing.xs),
                quill.VerticalSpacing.zero,
                null,
              ),
              paragraph: quill.DefaultTextBlockStyle(
                bodyStyle,
                quill.HorizontalSpacing.zero,
                quill.VerticalSpacing(
                  0,
                  widget.compact ? AppSpacing.xxs : AppSpacing.xs,
                ),
                quill.VerticalSpacing.zero,
                null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
