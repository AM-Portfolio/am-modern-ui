import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/app_component_sizes.dart';
import 'package:am_design_system/core/theme/app_text_styles.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

/// Flat minimal primary CTA (solid brand color, no glossy gradient).
class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.actionPrimaryBg;
    final radius = BorderRadius.circular(AppComponentSizes.buttonRadius);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuad,
        transform: Matrix4.translationValues(0, _hovering ? -1 : 0, 0),
        height: AppComponentSizes.buttonHeight,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: primary.withValues(alpha: _hovering ? 1 : 0.92),
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.25),
          ),
        ),
        child: ElevatedButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: widget.loading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colors.actionPrimaryFg,
                    ),
                  ),
                )
              : Text(
                  widget.label,
                  style: context.text.button().copyWith(
                        color: context.colors.actionPrimaryFg,
                      ),
                ),
        ),
      ),
    );
  }
}
