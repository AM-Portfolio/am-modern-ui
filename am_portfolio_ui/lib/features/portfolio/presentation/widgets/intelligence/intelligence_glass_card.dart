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
    this.footer,
    this.padding = const EdgeInsets.all(20),
    this.minHeight,
    this.scrollable = false,
    this.fillHeight = false,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final double? minHeight;
  /// Soft floor only — never forces a fixed card height alone.
  final bool scrollable;
  /// When true (peer stretch rows), expand to parent height and pin [footer].
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final header = Row(
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
    );

    Widget bodyChild = child;
    if (scrollable && !fillHeight) {
      bodyChild = SingleChildScrollView(child: child);
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        header,
        const SizedBox(height: 12),
        if (fillHeight)
          Expanded(
            child: scrollable
                ? SingleChildScrollView(child: child)
                : bodyChild,
          )
        else
          bodyChild,
        if (footer != null) ...[
          const SizedBox(height: 8),
          footer!,
        ],
      ],
    );

    final painted = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: fillHeight ? double.infinity : null,
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
          child: column,
        ),
      ),
    );

    // Peer rows pass a tight height — expand chrome to fill without IntrinsicHeight.
    if (fillHeight) {
      return SizedBox.expand(child: painted);
    }
    return painted;
  }
}

/// Gold text CTA used on intel card footers.
class IntelligenceTextLink extends StatelessWidget {
  const IntelligenceTextLink({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: ModuleColors.portfolio,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

InputDecoration intelligenceFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: ModuleColors.portfolio.withValues(alpha: 0.25),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.08),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ModuleColors.portfolio, width: 1.4),
    ),
  );
}

class IntelligenceEmptyHint extends StatelessWidget {
  const IntelligenceEmptyHint({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
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
        IntelligenceTextLink(label: 'Retry →', onPressed: onRetry),
      ],
    );
  }
}

void showIntelligenceSheet({
  required BuildContext context,
  required String title,
  required Widget body,
  String? subtitle,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final isPhone = width < 600;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  Widget chrome({ScrollController? controller, required bool expandBody}) {
    return Material(
      color: isDark
          ? const Color(0xFF121820)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: expandBody ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (expandBody)
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: body,
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  controller: controller,
                  child: body,
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IntelligenceTextLink(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (isPhone) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) =>
            chrome(controller: controller, expandBody: true),
      ),
    );
    return;
  }

  showDialog<void>(
    context: context,
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.78;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SizedBox(
          width: 560,
          height: maxH,
          child: chrome(expandBody: true),
        ),
      );
    },
  );
}
