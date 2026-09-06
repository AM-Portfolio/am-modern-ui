import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class AmGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AmGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (!context.isDark) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: AppRadii.dialog,
          border: Border.all(color: colors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: context.shadow(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: AppRadii.dialog,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardSurface.withValues(alpha: 0.92),
            borderRadius: AppRadii.dialog,
            border: Border.all(
              color: ModuleColors.isBrandSynced
                  ? ModuleColors.dashboard.withValues(alpha: 0.22)
                  : context.glassOverlay(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: ModuleColors.isBrandSynced
                    ? ModuleColors.dashboard.withValues(alpha: 0.12)
                    : context.shadow(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
