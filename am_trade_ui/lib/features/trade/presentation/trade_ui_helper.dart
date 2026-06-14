import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trade_controller_providers.dart';
import 'cubit/trade_controller_cubit.dart';
import 'add_trade/pages/add_trade_web_page.dart';

/// Helper class to provide cross-module UI components cleanly.
class TradeUIHelper {
  /// Builds the Add Trade overlay/dialog.
  /// This keeps the messy Riverpod/Cubit boilerplate inside the trade module
  /// instead of leaking it into the global AppShell.
  static Widget buildAddTradeOverlay(
    BuildContext context,
    String portfolioId,
    String? portfolioName,
    VoidCallback onComplete,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final cubitAsync = ref.watch(tradeControllerCubitProvider);

        return cubitAsync.when(
          data: (cubit) => BlocProvider<TradeControllerCubit>.value(
            value: cubit,
            child: AddTradeWebPage(
              portfolioId: portfolioId,
              portfolioName: portfolioName,
              onTradeAdded: onComplete,
              onCancel: onComplete,
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
    );
  }
}
