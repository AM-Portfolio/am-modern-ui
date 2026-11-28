import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/mf_dto.dart';
import '../../providers/mf_providers.dart';

/// Explore right rail: portfolio, quick actions, tools, learn teaser.
class MfExploreRightRail extends ConsumerWidget {
  const MfExploreRightRail({
    required this.accent,
    this.onFocusSearch,
    this.firstBuyableIsin,
    super.key,
  });

  final Color accent;
  final VoidCallback? onFocusSearch;
  final String? firstBuyableIsin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PortfolioSummaryCard(accent: accent),
        const SizedBox(height: AppSpacing.md),
        _QuickActions(
          accent: accent,
          onFocusSearch: onFocusSearch,
          firstBuyableIsin: firstBuyableIsin,
        ),
        const SizedBox(height: AppSpacing.md),
        const _ToolsList(),
        const SizedBox(height: AppSpacing.md),
        _LearnTeaser(accent: accent),
      ],
    );
  }
}

class _PortfolioSummaryCard extends ConsumerWidget {
  const _PortfolioSummaryCard({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mfHoldingsProvider);
    final inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadii.lg,
      child: async.when(
        loading: () => const SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your portfolio',
              style: context.text.caption().copyWith(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Holdings unavailable',
              style: context.text.label().copyWith(color: context.textPrimary),
            ),
          ],
        ),
        data: (lots) {
          if (lots.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your portfolio',
                  style: context.text.caption().copyWith(
                        color: context.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹0',
                  style: context.text.heroTitle(compact: true).copyWith(
                        color: context.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No holdings yet — complete onboarding to invest.',
                  style: context.text.caption().copyWith(
                        color: context.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.go('/app/mutual-funds/onboarding'),
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Start onboarding'),
                ),
              ],
            );
          }

          final summary = _computePortfolio(ref, lots);
          final up = (summary.pnlPercent ?? 0) >= 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your portfolio',
                style: context.text.caption().copyWith(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                summary.currentValue != null
                    ? inr.format(summary.currentValue)
                    : '—',
                style: context.text.heroTitle(compact: true).copyWith(
                      color: context.textPrimary,
                    ),
              ),
              if (summary.pnlPercent != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${up ? '+' : ''}${summary.pnlPercent!.toStringAsFixed(2)}%',
                  style: context.text.label().copyWith(
                        color: up
                            ? context.marketPositive
                            : context.marketNegative,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go('/app/mutual-funds/holdings'),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('View holdings'),
              ),
            ],
          );
        },
      ),
    );
  }

  _PortfolioNums _computePortfolio(WidgetRef ref, List<MfHoldingLot> lots) {
    double? current;
    double? invested;
    for (final lot in lots) {
      final latest = ref.watch(mfLatestNavProvider(lot.isin)).asData?.value;
      final nav = latest ?? lot.avgNav;
      if (nav != null) {
        current = (current ?? 0) + lot.units * nav;
      }
      if (lot.avgNav != null) {
        invested = (invested ?? 0) + lot.units * lot.avgNav!;
      }
    }
    double? pnlPercent;
    if (current != null && invested != null && invested > 0) {
      pnlPercent = ((current - invested) / invested) * 100;
    }
    return _PortfolioNums(currentValue: current, pnlPercent: pnlPercent);
  }
}

class _PortfolioNums {
  const _PortfolioNums({this.currentValue, this.pnlPercent});
  final double? currentValue;
  final double? pnlPercent;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.accent,
    this.onFocusSearch,
    this.firstBuyableIsin,
  });

  final Color accent;
  final VoidCallback? onFocusSearch;
  final String? firstBuyableIsin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick actions',
          style: context.text.label().copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                label: 'Start a SIP',
                icon: Icons.autorenew_rounded,
                accent: accent,
                filled: true,
                onTap: () => context.go('/app/mutual-funds/systematic'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionTile(
                label: 'Lumpsum',
                icon: Icons.payments_outlined,
                accent: accent,
                onTap: () {
                  if (firstBuyableIsin != null &&
                      firstBuyableIsin!.isNotEmpty) {
                    context.go(
                      '/app/mutual-funds/invest/${firstBuyableIsin!}',
                    );
                  } else {
                    onFocusSearch?.call();
                    // No search field on Explore — fall back to systematic.
                    if (onFocusSearch == null) {
                      context.go('/app/mutual-funds/systematic');
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionTile(
                label: 'Holdings',
                icon: Icons.account_balance_wallet_outlined,
                accent: accent,
                onTap: () => context.go('/app/mutual-funds/holdings'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? accent.withValues(alpha: 0.22) : context.cardColor;
    final border = filled ? accent.withValues(alpha: 0.55) : context.borderColor;
    final fg = filled ? accent : context.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Ink(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.text.caption().copyWith(
                      color:
                          filled ? context.textPrimary : context.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolsList extends StatelessWidget {
  const _ToolsList();

  static const _tools = <(IconData, String, String)>[
    (Icons.calculate_outlined, 'SIP Calculator', 'Plan monthly investments'),
    (Icons.flag_outlined, 'Goal Planner', 'Target-based SIP amount'),
    (Icons.compare_arrows_outlined, 'MF Compare', 'Side-by-side schemes'),
    (Icons.upload_file_outlined, 'Import Portfolio', 'Bring external holdings'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      borderRadius: AppRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Text(
              'Tools & calculators',
              style: context.text.label().copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          for (final t in _tools)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Icon(t.$1, color: context.textSecondary, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.$2,
                          style: context.text.label().copyWith(
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          t.$3,
                          style: context.text.caption().copyWith(
                                color: context.textSecondary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Soon',
                    style: context.text.caption().copyWith(
                          color: context.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LearnTeaser extends StatelessWidget {
  const _LearnTeaser({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadii.lg,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(Icons.menu_book_outlined, color: accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learn & discover',
                  style: context.text.caption().copyWith(
                        color: context.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  "A beginner's guide to Mutual Funds",
                  style: context.text.label().copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
