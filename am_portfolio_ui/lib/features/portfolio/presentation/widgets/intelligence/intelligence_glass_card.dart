import 'dart:ui';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

    // Web: skip BackdropFilter — multiple live blurs tank Overview scroll.
    final surface = Container(
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
                  context.colors.cardSurface
                      .withValues(alpha: kIsWeb ? 0.92 : 0.45),
                  IntelligenceColors.mist.withValues(alpha: kIsWeb ? 0.85 : 0.25),
                ],
        ),
        border: Border.all(
          color: ModuleColors.isBrandSynced
              ? ModuleColors.portfolio.withValues(alpha: 0.28)
              : context.glassOverlay(0.07),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: padding,
      child: column,
    );
    final painted = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: kIsWeb
          ? surface
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: surface,
            ),
    );

    // Peer rows pass a tight height — expand chrome to fill without IntrinsicHeight.
    if (fillHeight) {
      return SizedBox.expand(child: painted);
    }
    return painted;
  }
}

/// Light inset surface for panes inside an [IntelligenceGlassCard] (e.g. X-Ray legend).
class IntelligenceInsetPanel extends StatelessWidget {
  const IntelligenceInsetPanel({
    required this.child,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius = 12,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.glassOverlay(0.04),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: context.glassOverlay(0.07)),
      ),
      padding: padding,
      child: child,
    );
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
  bool compact = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    // Compact row: avoid floating label (needs ~56px) — use hint instead.
    labelText: compact ? null : label,
    hintText: compact ? (hint ?? label) : hint,
    floatingLabelBehavior:
        compact ? FloatingLabelBehavior.never : FloatingLabelBehavior.auto,
    isDense: true,
    filled: true,
    fillColor: context.glassOverlay(isDark ? 0.04 : 0.03),
    contentPadding: EdgeInsets.symmetric(
      horizontal: compact ? 10 : 12,
      vertical: compact ? 10 : 12,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(compact ? 8 : 10),
      borderSide: BorderSide(
        color: ModuleColors.portfolio.withValues(alpha: 0.25),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(compact ? 8 : 10),
      borderSide: BorderSide(
        color: context.glassOverlay(isDark ? 0.1 : 0.08),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(compact ? 8 : 10),
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
        color: isDark ? IntelligenceColors.surfaceDeep : context.surfaceColor,
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

  Widget chrome({
    required BuildContext routeContext,
    ScrollController? controller,
    required bool expandBody,
  }) {
    void close() {
      // MUST use the dialog/sheet route context. Using the Overview card
      // context pops the ShellRoute page under a root dialog → blank page.
      Navigator.of(routeContext).pop();
    }

    final colors = Theme.of(routeContext).extension<AppColorsTheme>() ?? AppColorsTheme.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? colors.surface.withValues(alpha: 0.25)
            : colors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          )
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
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
                                  color: colors.textPrimary,
                                ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colors.textTertiary,
                                        fontWeight: FontWeight.w500,
                                      ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: close,
                      icon: Icon(Icons.close_rounded, size: 24, color: colors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: close,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
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
      builder: (routeContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => chrome(
          routeContext: routeContext,
          controller: controller,
          expandBody: true,
        ),
      ),
    );
    return;
  }

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (routeContext, animation, secondaryAnimation) {
      final maxH = MediaQuery.sizeOf(routeContext).height * 0.78;
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 580,
              maxHeight: maxH,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: chrome(routeContext: routeContext, expandBody: true),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    },
  );
}
