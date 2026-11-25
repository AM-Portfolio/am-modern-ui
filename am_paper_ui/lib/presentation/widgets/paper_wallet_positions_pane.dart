import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';
import 'paper_positions_pnl_pane.dart';

/// Wallet summary on top, deep links, then open positions (recent).
class PaperWalletPositionsPane extends StatelessWidget {
  const PaperWalletPositionsPane({
    super.key,
    this.onBuySell,
    this.onOpenTradeHistory,
  });

  final void Function(String symbol, String side)? onBuySell;

  /// Optional: stay on paper desk Orders instead of leaving for trade hub.
  final VoidCallback? onOpenTradeHistory;

  void _go(BuildContext context, String path) {
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');
    final accent = ModuleColors.market;

    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        final w = state.wallet;
        final available = double.tryParse(w?.available ?? '') ?? 0;
        final reserved = double.tryParse(w?.reserved ?? '') ?? 0;
        final uuid = w?.portfolioUuid.trim() ?? '';
        final hasUuid = uuid.isNotEmpty;

        final walletCard = Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 6),
              if (w == null)
                Text(
                  'No paper wallet loaded.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                )
              else ...[
                Text(
                  '₹${fmt.format(available)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Available · Reserved ₹${fmt.format(reserved)} · ${w.currency} · ${w.kind}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        );

        Widget linkChip({
          required String label,
          required IconData icon,
          required VoidCallback? onTap,
        }) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: onTap == null
                              ? colors.textSecondary
                              : colors.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        final links = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            linkChip(
              label: 'Trade history',
              icon: Icons.receipt_long_outlined,
              onTap: onOpenTradeHistory ??
                  (hasUuid
                      ? () => _go(context, '/app/trade/$uuid/trades')
                      : null),
            ),
            linkChip(
              label: 'Analysis',
              icon: Icons.insights_outlined,
              onTap: hasUuid
                  ? () => _go(context, '/app/portfolio/$uuid/analysis')
                  : null,
            ),
            linkChip(
              label: 'Portfolio',
              icon: Icons.pie_chart_outline,
              onTap: hasUuid
                  ? () => _go(context, '/app/portfolio/$uuid/overview')
                  : null,
            ),
            linkChip(
              label: 'Investment details',
              icon: Icons.account_balance_outlined,
              onTap: hasUuid
                  ? () => _go(context, '/app/portfolio/$uuid/holdings')
                  : null,
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: walletCard,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: links,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: PaperPositionsPnlPane(onBuySell: onBuySell),
            ),
          ],
        );
      },
    );
  }
}
