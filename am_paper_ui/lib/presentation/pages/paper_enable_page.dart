import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';

class PaperEnablePage extends StatelessWidget {
  const PaperEnablePage({super.key, this.onEnabled});

  final VoidCallback? onEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocConsumer<PaperOmsCubit, PaperOmsState>(
      listenWhen: (p, c) => p.wallet == null && c.wallet != null,
      listener: (context, state) => onEnabled?.call(),
      builder: (context, state) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Paper trading',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Practice buy/sell with ₹10,00,000 virtual cash and live market prices. '
                    'This is not a live broker account and uses no real money.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: state.submitting
                        ? null
                        : () => context.read<PaperOmsCubit>().enablePaper(),
                    child: state.submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enable paper trading'),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(state.error!, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
