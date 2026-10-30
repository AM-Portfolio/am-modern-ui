import 'package:flutter/material.dart';

class IntelligenceModeChip extends StatelessWidget {
  const IntelligenceModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accentColor,
    this.compact = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;

  /// Denser padding for header / trailing rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 4 : 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: 0.22)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(compact ? 8 : 10),
            border: Border.all(
              color: selected
                  ? accentColor
                  : Theme.of(context).dividerColor.withValues(alpha: 0.55),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  Icons.check_rounded,
                  size: compact ? 12 : 14,
                  color: accentColor,
                ),
                SizedBox(width: compact ? 3 : 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? accentColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
