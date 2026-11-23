import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/mf_dto.dart';
import '../../data/mf_scheme_view.dart';
import '../../providers/mf_providers.dart';
import '../widgets/mf_empty_state.dart';
import '../widgets/mf_fund_card.dart';
import '../widgets/mf_nav_chart.dart';
import '../widgets/mf_page_header.dart';

class MfSchemeDetailPage extends ConsumerWidget {
  const MfSchemeDetailPage({required this.isin, super.key});

  final String isin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mfSchemeDetailProvider(isin));
    final navAsync = ref.watch(mfSchemeNavProvider(isin));
    final perfAsync = ref.watch(mfSchemePerformanceProvider(isin));

    return async.when(
      loading: () => const MfLoadingBlock(),
      error: (e, _) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          MfPageHeader(
            title: 'Fund details',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/app/mutual-funds'),
            ),
          ),
          MfErrorBanner(message: e.toString()),
        ],
      ),
      data: (scheme) {
        final fund = MfSchemeView.fromSummary(scheme);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            MfPageHeader(
              title: 'Fund details',
              subtitle: fund.shortName,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/app/mutual-funds'),
              ),
            ),
            MfFundCard(
              fund: fund,
              period: MfReturnPeriod.y1,
              onTap: () {},
              onInvest: fund.digPurchaseEnabled
                  ? () => context.go('/app/mutual-funds/invest/${fund.isin}')
                  : null,
              onSip: fund.digPurchaseEnabled
                  ? () => context.go(
                        '/app/mutual-funds/systematic?isin=${fund.isin}',
                      )
                  : null,
            ),
            if (!fund.digPurchaseEnabled) ...[
              const SizedBox(height: AppSpacing.sm),
              MfQuietNote(
                message: fund.metricsIllustrative
                    ? 'Seed catalog row — purchase/SIP only for UAT-mapped ISINs '
                        'until SchemeIdMapper is expanded.'
                    : 'Purchase not allowed for this scheme.',
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Trailing returns',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            perfAsync.when(
              loading: () => const MfLoadingBlock(),
              error: (e, _) => MfQuietNote(message: e.toString()),
              data: (perf) => _ReturnsCard(perf: perf),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'NAV history (1Y)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: AppRadii.md,
              child: navAsync.when(
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text(
                  e.toString(),
                  style: TextStyle(color: context.textSecondary),
                ),
                data: (points) => MfNavChart(points: points),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: AppRadii.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scheme.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'ISIN ${fund.isin} · ${fund.planType} · ${fund.option}\n'
                    'Category ${fund.category} / ${fund.subCategory} · Risk ${fund.riskLevel}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.textSecondary,
                          height: 1.45,
                        ),
                  ),
                  if (fund.minSip != null || fund.minLumpsum != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      [
                        if (fund.minSip != null)
                          'Min SIP ₹${fund.minSip!.toStringAsFixed(0)}',
                        if (fund.minLumpsum != null)
                          'Min invest ₹${fund.minLumpsum!.toStringAsFixed(0)}',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.textSecondary,
                          ),
                    ),
                  ],
                  if (fund.exitLoad != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Exit load: ${fund.exitLoad}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.textSecondary,
                          ),
                    ),
                  ],
                  if (fund.lockInPeriod != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Lock-in: ${fund.lockInPeriod}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.textSecondary,
                          ),
                    ),
                  ],
                  if (fund.faceValue != null ||
                      fund.purchaseCutoffTime != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [
                        if (fund.faceValue != null)
                          'Face value ${fund.faceValue}',
                        if (fund.purchaseCutoffTime != null)
                          'Purchase cutoff ${fund.purchaseCutoffTime}',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.textSecondary,
                          ),
                    ),
                  ],
                  if (fund.benchmarkName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Benchmark: ${fund.benchmarkName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReturnsCard extends StatelessWidget {
  const _ReturnsCard({required this.perf});

  final MfPerformance perf;

  // 6M omitted until ret_6m denorm exists
  static const _keys = ['1D', '1W', '1M', '3M', '1Y', '3Y', '5Y'];

  @override
  Widget build(BuildContext context) {
    final pctFmt = NumberFormat('+0.00%;-0.00%');
    if (perf.unavailable && perf.returnsPct.isEmpty) {
      return const MfQuietNote(
        message: 'Performance unavailable (seed or catalog error).',
      );
    }
    final hasAnyReturn = perf.returnsPct.values.any((v) => v != null);
    if (!hasAnyReturn) {
      return MfQuietNote(
        message: perf.note?.isNotEmpty == true
            ? perf.note!
            : 'Period returns need multi-day NAV history (NSE daily or AMFI backfill) — not invented.',
      );
    }
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadii.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (perf.latestNav != null)
            Text(
              'Latest NAV ₹${perf.latestNav!.toStringAsFixed(4)}'
              '${perf.latestNavDate != null ? ' · ${perf.latestNavDate}' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in _keys)
                _ReturnChip(
                  label: k,
                  value: perf.returnsPct[k],
                  pctFmt: pctFmt,
                ),
            ],
          ),
          if (perf.note != null && perf.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              perf.note!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReturnChip extends StatelessWidget {
  const _ReturnChip({
    required this.label,
    required this.value,
    required this.pctFmt,
  });

  final String label;
  final double? value;
  final NumberFormat pctFmt;

  @override
  Widget build(BuildContext context) {
    final up = (value ?? 0) >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.textSecondary,
                ),
          ),
          Text(
            value == null ? '—' : pctFmt.format(value! / 100),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: value == null
                      ? context.textSecondary
                      : (up
                          ? context.marketPositive
                          : context.marketNegative),
                ),
          ),
        ],
      ),
    );
  }
}
