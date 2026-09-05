import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Frosted glass dialog shell matching company-nav glass language.
class BasketGlassDialog extends StatelessWidget {
  final Widget child;

  const BasketGlassDialog({super.key, required this.child});

  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final fill = isDark
        ? const Color(0xFF1a1a2e).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < AmBreakpoints.mobile;
    final maxDialogWidth = isCompact
        ? screenWidth - 48
        : 420.0;
    final horizontalInset = isCompact ? 24.0 : 40.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxDialogWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Numbers-first coverage gate (below 80%).
class BasketCoverageGateDialog extends StatelessWidget {
  final double coverage;
  final double requiredCoverage;

  const BasketCoverageGateDialog({
    super.key,
    required this.coverage,
    this.requiredCoverage = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        (coverage / requiredCoverage).clamp(0.0, 1.0);
    final tips = [
      (Icons.payments_outlined, 'Raise amount'),
      (Icons.swap_horiz, 'Substitute'),
      (Icons.add_circle_outline, 'Add units'),
    ];

    return BasketGlassDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: context.statusWarning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Coverage too low',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${coverage.toStringAsFixed(0)}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.statusWarning,
                      ),
                    ),
                    Text(
                      'Coverage',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '/',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${requiredCoverage.toStringAsFixed(0)}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Required',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: context.colors.border.withValues(alpha: 0.4),
              color: context.statusWarning,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Need ${requiredCoverage.toStringAsFixed(0)}% to create',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: tips
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ModuleColors.portfolio.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: ModuleColors.portfolio.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.$1, size: 14, color: ModuleColors.portfolio),
                        const SizedBox(width: 6),
                        Text(
                          t.$2,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ModuleColors.portfolio,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: ModuleColors.portfolio,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Leave customize with unsaved changes.
class BasketLeaveCustomizeDialog extends StatelessWidget {
  const BasketLeaveCustomizeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BasketGlassDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Leave customize?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Unsaved changes',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Drafts stay in My Baskets',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('save'),
            style: FilledButton.styleFrom(
              backgroundColor: ModuleColors.portfolio,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save draft & exit'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.statusError,
              side: BorderSide(color: context.statusError.withValues(alpha: 0.5)),
            ),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('keep'),
            child: const Text('Keep editing'),
          ),
        ],
      ),
    );
  }
}
