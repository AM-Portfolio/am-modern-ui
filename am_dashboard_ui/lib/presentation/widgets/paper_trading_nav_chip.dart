import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Segmented Paper Trading | Advanced control for the dashboard header.
///
/// Matches the toolbar mock: gold filled "Paper Trading" + outline "Advanced".
class PaperTradingNavChip extends StatelessWidget {
  const PaperTradingNavChip({
    required this.onTap,
    this.onAdvanced,
    this.compact = false,
    this.paperSelected = true,
    super.key,
  });

  /// Opens the paper desk.
  final VoidCallback onTap;

  /// Opens Users / Advanced accounts. When null, Advanced is omitted.
  final VoidCallback? onAdvanced;

  /// Narrow layout: shorter labels.
  final bool compact;

  /// Visual selection — Paper Trading is the default highlighted segment.
  final bool paperSelected;

  static const double _height = 36;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onAccent = context.colors.actionPrimaryFg;
    final track = isDark
        ? context.colors.cardSurface
        : context.colors.cardSurface.withValues(alpha: 0.95);
    final border = accent.withValues(alpha: isDark ? 0.35 : 0.28);

    Widget segment({
      required Key key,
      required bool selected,
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: _height - 4,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? onAccent : context.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected ? onAccent : context.textPrimary,
                    fontSize: compact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: _height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(
            key: const Key('dashboard-paper-chip'),
            selected: paperSelected,
            icon: Icons.science_rounded,
            label: compact ? 'Paper' : 'Paper Trading',
            onPressed: onTap,
          ),
          if (onAdvanced != null)
            segment(
              key: const Key('dashboard-advanced-chip'),
              selected: !paperSelected,
              icon: Icons.bolt_rounded,
              label: 'Advanced',
              onPressed: onAdvanced!,
            ),
        ],
      ),
    );
  }
}
