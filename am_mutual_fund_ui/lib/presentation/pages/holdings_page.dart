import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/mf_dto.dart';
import '../../data/mf_error_message.dart';
import '../../providers/mf_providers.dart';
import '../widgets/mf_empty_state.dart';
import '../widgets/mf_page_header.dart';

class MfHoldingsPage extends ConsumerWidget {
  const MfHoldingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mfHoldingsProvider);
    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.mutualFund;
    final inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const MfPageHeader(
          title: 'Holdings',
          subtitle:
              'Units credited after allotment reconcile. Current value uses '
              'catalog latest NAV (client-side).',
        ),
        async.when(
          loading: () => const MfLoadingBlock(),
          error: (e, _) => MfErrorBanner(
            message: mfErrorMessage(e),
            onRetry: () => ref.invalidate(mfHoldingsProvider),
          ),
          data: (lots) {
            if (lots.isEmpty) {
              return MfEmptyState(
                title: 'No holdings yet',
                body:
                    'Complete purchase → pay → wait for allotment. Then lots appear here.',
                icon: Icons.account_balance_wallet_outlined,
                actionLabel: 'Explore funds',
                onAction: () => context.go('/app/mutual-funds'),
              );
            }

            final totalUnits =
                lots.fold<double>(0, (sum, l) => sum + l.units);

            return _HoldingsBody(
              lots: lots,
              accent: accent,
              totalUnits: totalUnits,
              inr: inr,
            );
          },
        ),
      ],
    );
  }
}

class _HoldingsBody extends ConsumerWidget {
  const _HoldingsBody({
    required this.lots,
    required this.accent,
    required this.totalUnits,
    required this.inr,
  });

  final List<MfHoldingLot> lots;
  final Color accent;
  final double totalUnits;
  final NumberFormat inr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double? totalValue;
    var anyNav = false;
    for (final lot in lots) {
      final nav = ref.watch(mfLatestNavProvider(lot.isin)).asData?.value;
      if (nav != null) {
        anyNav = true;
        totalValue = (totalValue ?? 0) + lot.units * nav;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: AppRadii.md,
          child: Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Lots',
                  value: '${lots.length}',
                  accent: accent,
                ),
              ),
              Container(width: 1, height: 40, color: context.borderColor),
              Expanded(
                child: _MetricTile(
                  label: 'Total units',
                  value: totalUnits.toStringAsFixed(
                    totalUnits == totalUnits.roundToDouble() ? 0 : 3,
                  ),
                  accent: accent,
                ),
              ),
              Container(width: 1, height: 40, color: context.borderColor),
              Expanded(
                child: _MetricTile(
                  label: 'Current value',
                  value: anyNav && totalValue != null
                      ? inr.format(totalValue)
                      : '—',
                  accent: accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final lot in lots)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _HoldingTile(lot: lot, accent: accent, inr: inr),
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
          ),
        ],
      ),
    );
  }
}

class _HoldingTile extends ConsumerWidget {
  const _HoldingTile({
    required this.lot,
    required this.accent,
    required this.inr,
  });

  final MfHoldingLot lot;
  final Color accent;
  final NumberFormat inr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = lot.schemeName?.trim().isNotEmpty == true
        ? lot.schemeName!
        : lot.isin;
    final navAsync = ref.watch(mfLatestNavProvider(lot.isin));
    final latestNav = navAsync.asData?.value;
    final currentValue =
        latestNav != null ? lot.units * latestNav : null;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadii.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                ),
              ),
              Text(
                '${lot.units} units',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            lot.isin,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (lot.folio != null && lot.folio!.isNotEmpty)
            Text(
              'Folio ${lot.folio}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          if (lot.allottedAt != null && lot.allottedAt!.isNotEmpty)
            Text(
              'Allotted ${lot.allottedAt}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Avg NAV ${lot.avgNav != null ? '₹${lot.avgNav!.toStringAsFixed(4)}' : '—'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.textSecondary,
                    ),
              ),
              Text(
                'Latest NAV ${latestNav != null ? '₹${latestNav.toStringAsFixed(4)}' : (navAsync.isLoading ? '…' : '—')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.textSecondary,
                    ),
              ),
              Text(
                'Value ${currentValue != null ? inr.format(currentValue) : '—'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton(
                onPressed: () => context.go(
                  '/app/mutual-funds/redeem/${lot.isin}'
                  '${lot.folio != null && lot.folio!.isNotEmpty ? '?folio=${Uri.encodeComponent(lot.folio!)}&units=${lot.units}' : '?units=${lot.units}'}',
                ),
                child: const Text('Redeem'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => context.go(
                  '/app/mutual-funds/switch/${lot.isin}'
                  '?units=${lot.units}'
                  '${lot.folio != null && lot.folio!.isNotEmpty ? '&folio=${Uri.encodeComponent(lot.folio!)}' : ''}',
                ),
                child: const Text('Switch'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
