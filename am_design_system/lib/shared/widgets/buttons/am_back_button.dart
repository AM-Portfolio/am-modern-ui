import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/app_radii.dart';
import 'package:am_design_system/core/theme/app_text_styles.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

/// Compact modern back control for panels, sheets, and auth flows.
///
/// Soft glass chip with hover lift; use [label] for a text pill or omit for
/// an icon-only circle suitable inside dense headers.
class AmBackButton extends StatefulWidget {
  const AmBackButton({
    super.key,
    this.onPressed,
    this.label,
    this.tooltip = 'Back',
    this.compact = false,
    this.iconOnly = false,
  });

  final VoidCallback? onPressed;
  final String? label;
  final String tooltip;
  final bool compact;
  final bool iconOnly;

  @override
  State<AmBackButton> createState() => _AmBackButtonState();
}

class _AmBackButtonState extends State<AmBackButton> {
  bool _hovering = false;
  bool _pressed = false;

  VoidCallback get _effectiveOnPressed =>
      widget.onPressed ??
      () {
        final navigator = Navigator.maybeOf(context);
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        }
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showLabel =
        !widget.iconOnly && (widget.label != null && widget.label!.isNotEmpty);
    final size = widget.compact ? 34.0 : 40.0;
    final iconSize = widget.compact ? 16.0 : 18.0;
    final radius = showLabel ? AppRadii.pill : AppRadii.pill;

    final fill = colors.surface.withValues(
      alpha: _pressed
          ? (context.isDark ? 0.45 : 0.85)
          : _hovering
              ? (context.isDark ? 0.38 : 0.78)
              : (context.isDark ? 0.28 : 0.62),
    );
    final border = colors.border.withValues(
      alpha: _hovering ? 0.55 : 0.35,
    );

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() {
          _hovering = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: _effectiveOnPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _hovering ? -1.5 : 0, 0),
            height: size,
            padding: showLabel
                ? EdgeInsets.symmetric(
                    horizontal: widget.compact ? 12 : 14,
                  )
                : EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: size,
              minHeight: size,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: iconSize,
                  color: colors.textPrimary,
                ),
                if (showLabel) ...[
                  SizedBox(width: widget.compact ? 6 : 8),
                  Text(
                    widget.label!,
                    style: context.text
                        .link(compact: widget.compact)
                        .copyWith(color: colors.textPrimary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
