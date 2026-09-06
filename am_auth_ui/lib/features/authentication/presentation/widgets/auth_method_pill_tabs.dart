import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';

class AuthMethodPillOption<T> {
  const AuthMethodPillOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// Pill segmented control for login methods (Email / QR / OTP).
class AuthMethodPillTabs<T> extends StatelessWidget {
  const AuthMethodPillTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.compact = false,
    this.accentColor,
  });

  final List<AuthMethodPillOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool compact;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? context.colors.actionPrimaryBg;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.06),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _PillSegment(
                selected: option.value == selected,
                label: option.label,
                icon: option.icon,
                compact: compact,
                accent: accent,
                onTap: () => onChanged(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({
    required this.selected,
    required this.label,
    required this.compact,
    required this.accent,
    required this.onTap,
    this.icon,
  });

  final bool selected;
  final String label;
  final IconData? icon;
  final bool compact;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : context.colors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: Duration.zero,
          padding: EdgeInsets.symmetric(
            vertical: compact ? 8 : 10,
            horizontal: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? accent : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: compact ? 14 : 16, color: fg),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
