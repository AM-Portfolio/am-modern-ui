import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Shows a premium glassmorphic bottom sheet with a list of portfolio quick actions.
///
/// Each row taps: sheet dismisses first, THEN the action fires via [Future.microtask].
/// This eliminates the "whole module changes" rebuild jank caused by overlapping
/// navigation and animation in the previous approach.
///
/// Usage:
/// ```dart
/// showPortfolioActionsSheet(
///   context: context,
///   triggerColor: ModuleColors.portfolio,
///   actions: [...],
/// );
/// ```
void showPortfolioActionsSheet({
  required BuildContext context,
  required Color triggerColor,
  required List<FloatingMenuAction> actions,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _PortfolioActionsSheet(
      triggerColor: triggerColor,
      actions: actions,
    ),
  );
}

class _PortfolioActionsSheet extends StatelessWidget {
  const _PortfolioActionsSheet({
    required this.triggerColor,
    required this.actions,
  });

  final Color triggerColor;
  final List<FloatingMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsTheme>() ?? AppColorsTheme.dark;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPad),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: triggerColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header row
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: triggerColor.withOpacity(0.15),
                      border: Border.all(color: triggerColor.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.bolt_rounded, color: triggerColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.border.withValues(alpha: 0.12),
                      ),
                      child: Icon(Icons.close_rounded, color: colors.textSecondary, size: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action rows
              ...actions.map((action) {
                return _ActionRow(
                  action: action,
                  colors: colors,
                  onTap: () {
                    // Dismiss sheet first, then fire action on next frame.
                    // This prevents the rebuild race condition (Gap 4).
                    Navigator.pop(context);
                    Future.microtask(action.onTap);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatefulWidget {
  const _ActionRow({
    required this.action,
    required this.colors,
    required this.onTap,
  });

  final FloatingMenuAction action;
  final AppColorsTheme colors;
  final VoidCallback onTap;

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final action = widget.action;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _pressed
              ? action.iconColor.withValues(alpha: 0.14)
              : colors.surface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pressed
                ? action.iconColor.withValues(alpha: 0.35)
                : colors.border.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    action.iconColor.withValues(alpha: 0.9),
                    action.iconColor.withValues(alpha: 0.35),
                  ],
                ),
              ),
              child: Icon(action.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
