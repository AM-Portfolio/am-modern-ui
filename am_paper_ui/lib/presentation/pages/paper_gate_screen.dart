import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/paper_oms_providers.dart';
import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';
import 'paper_desk_screen.dart';
import 'paper_enable_page.dart';

/// Loads OMS state and routes to enable or desk.
class PaperGateScreen extends ConsumerWidget {
  const PaperGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paperOmsCubitProvider);
    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Paper OMS unavailable: $e')),
      ),
      data: (cubit) {
        return BlocProvider<PaperOmsCubit>.value(
          value: cubit,
          child: BlocBuilder<PaperOmsCubit, PaperOmsState>(
            builder: (context, state) {
              if (state.loading && state.wallet == null) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (state.wallet == null) {
                return Scaffold(
                  body: PaperEnablePage(
                    onEnabled: () => ref.invalidate(paperOmsCubitProvider),
                  ),
                );
              }
              return const Scaffold(body: PaperDeskScreen());
            },
          ),
        );
      },
    );
  }
}
