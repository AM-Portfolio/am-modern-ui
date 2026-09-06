import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/shared/widgets/display/interactive_background.dart';

/// Shared auth shell backdrop (login, register, forgot/reset password).
///
/// Colors come only from [AppColorsTheme] via [context.colors].
class AuthPageBackground extends StatelessWidget {
  const AuthPageBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: colors.authBackdropGradient),
        child: InteractiveBackground(
          baseColor: colors.actionPrimaryBg,
          highlightColor: colors.authParticleHighlight,
        ),
      ),
    );
  }
}
