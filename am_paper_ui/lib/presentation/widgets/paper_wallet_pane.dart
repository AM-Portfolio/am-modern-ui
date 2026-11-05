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

    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        final w = state.wallet;
        final available = double.tryParse(w?.available ?? '') ?? 0;
        final reserved = double.tryParse(w?.reserved ?? '') ?? 0;

        Future<void> refresh() =>
            context.read<PaperOmsCubit>().refreshBooks();

        final Widget body;
        if (w == null) {
          body = Text(
            'No paper wallet loaded.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          );
        } else {
          body = Text(
            'Available ₹${fmt.format(available)} · Reserved ₹${fmt.format(reserved)} · ${w.currency} · ${w.kind}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          );
        }

        return RefreshIndicator(
          color: ModuleColors.market,
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [body],
          ),
        );
      },
    );
  }
}
