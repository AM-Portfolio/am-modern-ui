import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';

/// Six digit tiles using the same primary / border tokens as email login.
class OtpDigitTiles extends StatelessWidget {
  const OtpDigitTiles({
    super.key,
    required this.digits,
    this.editable = false,
    this.onChanged,
    this.enabled = true,
  });

  final String digits;
  final bool editable;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (editable) {
      return _EditableOtpDigits(
        value: digits,
        onChanged: onChanged,
        enabled: enabled,
      );
    }

    final padded = digits.padRight(6).substring(0, 6);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 6; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _DigitTile(
            char: padded[i].trim().isEmpty ? '·' : padded[i],
          ),
        ],
      ],
    );
  }
}

class _DigitTile extends StatelessWidget {
  const _DigitTile({required this.char});

  final String char;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.colors.actionPrimaryBg;

    return Container(
      width: 40,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.35),
        border: Border.all(color: context.colors.border, width: 1.2),
      ),
      child: Text(
        char,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: char == '·' ? context.colors.textTertiary : accent,
        ),
      ),
    );
  }
}

class _EditableOtpDigits extends StatefulWidget {
  const _EditableOtpDigits({
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<_EditableOtpDigits> createState() => _EditableOtpDigitsState();
}

class _EditableOtpDigitsState extends State<_EditableOtpDigits> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _EditableOtpDigits oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection =
          TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = _controller.text.padRight(6).substring(0, 6);
    return GestureDetector(
      onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _DigitTile(
                  char: display[i].trim().isEmpty ? '' : display[i],
                ),
              ],
            ],
          ),
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  setState(() {});
                  widget.onChanged?.call(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
