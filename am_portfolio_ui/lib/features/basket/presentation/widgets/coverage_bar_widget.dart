import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Horizontal multi-color weight bar: Held / Substitute / Missing.
class CoverageBarWidget extends StatelessWidget {
  final double heldPct;
  final double substitutePct;
  final double missingPct;
  final bool compact;
  final bool showLegend;

  const CoverageBarWidget({
    super.key,
    required this.heldPct,
    required this.substitutePct,
    required this.missingPct,
    this.compact = true,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final held = heldPct.clamp(0.0, 100.0);
    final sub = substitutePct.clamp(0.0, 100.0);
    final missing = missingPct.clamp(0.0, 100.0);
    final total = (held + sub + missing);
    final heldFlex = total <= 0 ? 0 : (held * 100).round().clamp(0, 10000);
    final subFlex = total <= 0 ? 0 : (sub * 100).round().clamp(0, 10000);
    final missFlex = total <= 0 ? 0 : (missing * 100).round().clamp(0, 10000);
    final barH = compact ? 8.0 : 12.0;
    final heldColor = context.statusSuccess;
    final subColor = context.colors.actionPrimaryBg;
    final missColor = context.statusError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(barH),
          child: SizedBox(
            height: barH,
            child: Row(
              children: [
                if (heldFlex > 0)
                  Expanded(
                    flex: heldFlex,
                    child: ColoredBox(color: heldColor),
                  ),
                if (subFlex > 0)
                  Expanded(
                    flex: subFlex,
                    child: ColoredBox(color: subColor),
                  ),
                if (missFlex > 0)
                  Expanded(
                    flex: missFlex,
                    child: ColoredBox(color: missColor),
                  ),
                if (heldFlex + subFlex + missFlex == 0)
                  Expanded(
                    child: ColoredBox(
                      color: context.colors.border.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showLegend) ...[
          SizedBox(height: compact ? 6 : 8),
          Row(
            children: [
              _Legend(
                color: heldColor,
                label: 'Held ${held.toStringAsFixed(0)}%',
                compact: compact,
              ),
              const SizedBox(width: AppSpacing.sm),
              if (sub > 0.05)
                _Legend(
                  color: subColor,
                  label: 'Sub ${sub.toStringAsFixed(0)}%',
                  compact: compact,
                ),
              if (sub > 0.05) const SizedBox(width: AppSpacing.sm),
              if (missing > 0.05)
                _Legend(
                  color: missColor,
                  label: 'Gap ${missing.toStringAsFixed(0)}%',
                  compact: compact,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool compact;

  const _Legend({
    required this.color,
    required this.label,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 6 : 8,
          height: compact ? 6 : 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: compact ? 10 : null,
                color: context.colors.textSecondary,
              ),
        ),
      ],
    );
  }
}
