import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';

/// Minimal pane wrapper aligned with email login chrome (theme tokens only).
class AuthPaneFrame extends StatelessWidget {
  const AuthPaneFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(4),
    this.footer,
  });

  final Widget child;
  final EdgeInsets padding;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: padding,
          child: child,
        ),
        if (footer != null) ...[
          const SizedBox(height: 12),
          footer!,
        ],
      ],
    );
  }
}

/// Simple border around QR (same border token as inputs).
class AuthQrFrame extends StatelessWidget {
  const AuthQrFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}
