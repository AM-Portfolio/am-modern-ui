import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_colors_theme.dart';
import 'floating_menu_action.dart';

/// Glassmorphic bottom sheet of quick actions (Sync / more_vert).
///
/// Set [showSubtitles] false on mobile for compact title-only rows.
void showQuickActionsSheet({
  required BuildContext context,
  required Color triggerColor,
  required List<FloatingMenuAction> actions,
  bool showSubtitles = true,
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
    builder: (context) => _QuickActionsSheet(
      triggerColor: triggerColor,
      actions: actions,
      showSubtitles: showSubtitles,
    ),
  );
}

class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet({
    required this.triggerColor,
    required this.actions,
    required this.showSubtitles,
  });

  final Color triggerColor;
  final List<FloatingMenuAction> actions;
  final bool showSubtitles;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColorsTheme>() ?? AppColorsTheme.dark;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.paddingOf(context).bottom +
        PlatformConstants.globalBottomNavReserve(context);

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
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: triggerColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: triggerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: triggerColor,
                      size: 20,
                    ),
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
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...actions.map((action) {
                return _ActionRow(
                  action: action,
                  colors: colors,
                  showSubtitle: showSubtitles,
                  onTap: () {
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
    required this.showSubtitle,
    required this.onTap,
  });

  final FloatingMenuAction action;
  final AppColorsTheme colors;
  final bool showSubtitle;
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
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: widget.showSubtitle ? 13 : 12,
        ),
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
                  if (widget.showSubtitle) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
