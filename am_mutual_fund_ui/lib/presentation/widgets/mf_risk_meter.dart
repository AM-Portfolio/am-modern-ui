import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../data/mf_scheme_view.dart';

/// Compact 5-segment risk meter driven by theme market/status colors.
class MfRiskMeter extends StatelessWidget {
  const MfRiskMeter({
    required this.riskLevel,
    this.showLabel = true,
    this.height = 6,
    super.key,
  });

  final String riskLevel;
  final bool showLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final band = normalizeRiskLevel(riskLevel);
    final fill = riskMeterFill(band);
    final active = _bandColor(context, band);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 1; i <= 5; i++) ...[
              if (i > 1) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: i <= fill
                        ? active
                        : context.borderColor.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            riskLevel.trim().isEmpty ? 'Moderate' : riskLevel,
            style: context.text.caption().copyWith(color: context.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Color _bandColor(BuildContext context, MfRiskBand band) {
    return switch (band) {
      MfRiskBand.low => context.marketPositive,
      MfRiskBand.moderatelyLow => context.marketPositive,
      MfRiskBand.moderate => context.statusWarning,
      MfRiskBand.moderatelyHigh => context.statusWarning,
      MfRiskBand.high => context.marketNegative,
    };
  }
}
