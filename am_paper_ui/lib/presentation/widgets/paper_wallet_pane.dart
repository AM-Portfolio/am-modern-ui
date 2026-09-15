import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';

/// Paper free / virtual cash summary (no symbol analyser).
class PaperWalletPane extends StatelessWidget {
  const PaperWalletPane({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        final w = state.wallet;
        final available = double.tryParse(w?.available ?? '') ?? 0;
        final reserved = double.tryParse(w?.reserved ?? '') ?? 0;

        Future<void> refresh() =>
            context.read<PaperOmsCubit>().refreshBooks();

        Widget cards() {
          if (w == null) {
            return Text(
              'No paper wallet loaded.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 520;
              final items = [
                _WalletCard(
                  label: 'Available',
                  value: '₹${fmt.format(available)}',
                  accent: colors.actionPrimaryBg,
                ),
                _WalletCard(
                  label: 'Reserved',
                  value: '₹${fmt.format(reserved)}',
                  accent: colors.actionPrimaryBg,
                ),
              ];
              if (wide) {
                return Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: items[i]),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    items[i],
                  ],
                ],
              );
            },
          );
        }

        final body = <Widget>[
          if (!isMobile) ...[
            Text(
              'Paper wallet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Virtual cash for paper trading · not live money',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
          ],
          cards(),
          if (w != null) ...[
            const SizedBox(height: 16),
            Text(
              'Currency ${w.currency} · ${w.kind}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ];

        if (isMobile) {
          return RefreshIndicator(
            color: colors.actionPrimaryBg,
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: body,
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: body,
        );
      },
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
