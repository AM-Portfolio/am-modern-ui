import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/mf_scheme_view.dart';

/// Thin horizontal ticker of catalog movers (no tall metric tiles).
class MfCatalogPulse extends StatelessWidget {
  const MfCatalogPulse({
    required this.funds,
    required this.period,
    required this.onTap,
    this.accent,
    super.key,
  });

  final List<MfSchemeView> funds;
  final MfReturnPeriod period;
  final ValueChanged<MfSchemeView> onTap;
  final Color? accent;

  static List<MfSchemeView> topMovers(
    List<MfSchemeView> funds,
    MfReturnPeriod period, {
    int limit = 5,
  }) {
    final ranked = [...funds]
      ..sort((a, b) {
        final ar = a.returnFor(period.apiKey) ?? a.navChangePercent;
        final br = b.returnFor(period.apiKey) ?? b.navChangePercent;
        if (ar != null && br != null) return br.compareTo(ar);
        if (ar != null) return -1;
        if (br != null) return 1;
        return 0;
      });
    return ranked
        .where(
          (f) =>
              f.returnFor(period.apiKey) != null || f.navChangePercent != null,
        )
        .take(limit)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (funds.isEmpty) return const SizedBox.shrink();

    final movers = topMovers(funds, period);
    if (movers.isEmpty) {
      return Text(
        'Market snapshot · period returns not in catalog yet (EOD NAV only)',
        style: context.text.caption().copyWith(color: context.textSecondary),
      );
    }

    final pctFmt = NumberFormat('+0.00%;-0.00%');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Text(
            'Pulse',
            style: context.text.caption().copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in movers) ...[
                    InkWell(
                      onTap: () => onTap(f),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              f.amcLabel.isNotEmpty
                                  ? f.amcLabel
                                  : f.shortName,
                              style: context.text.label().copyWith(
                                    color: context.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            Builder(
                              builder: (context) {
                                final ret = f.returnFor(period.apiKey);
                                final value = ret ?? f.navChangePercent;
                                final up = (value ?? 0) >= 0;
                                return Text(
                                  value == null
                                      ? '—'
                                      : pctFmt.format(value / 100),
                                  style: context.text.label().copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: value == null
                                            ? context.textSecondary
                                            : (up
                                                ? context.marketPositive
                                                : context.marketNegative),
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: context.borderColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
