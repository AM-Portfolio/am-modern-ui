import 'dart:ui';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Shared glass shell for Portfolio Intelligence overview cards.
class IntelligenceGlassCard extends StatelessWidget {
  const IntelligenceGlassCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.minHeight,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints:
              minHeight != null ? BoxConstraints(minHeight: minHeight!) : null,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      context.colors.cardSurface.withValues(alpha: 0.95),
                      Color.lerp(
                            context.colors.cardSurface,
                            ModuleColors.portfolio,
                            ModuleColors.isBrandSynced ? 0.12 : 0.04,
                          )!
                          .withValues(alpha: 0.85),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.45),
                      const Color(0xFFF5F7FF).withValues(alpha: 0.25),
                    ],
            ),
            border: Border.all(
              color: ModuleColors.isBrandSynced
                  ? ModuleColors.portfolio.withValues(alpha: 0.28)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.07)),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: ModuleColors.portfolio.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: ModuleColors.portfolio,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact skeleton shimmer block used while intelligence loads.
class IntelligenceCardSkeleton extends StatelessWidget {
  const IntelligenceCardSkeleton({this.height = 220, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2A) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

/// Inline retry strip for intelligence card failures.
class IntelligenceRetryRow extends StatelessWidget {
  const IntelligenceRetryRow({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

void showIntelligenceSheet({
  required BuildContext context,
  required String title,
  required Widget body,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final isPhone = width < 600;
  if (isPhone) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: ListView(
            controller: controller,
            children: [
              Text(
                title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              body,
            ],
          ),
        ),
      ),
    );
    return;
  }

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(child: body),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
