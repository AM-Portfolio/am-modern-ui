import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/trade_controller_providers.dart';
import 'cubit/trade_controller_cubit.dart';
import 'add_trade/pages/add_trade_web_page.dart';

/// Opens [AddTradeWebPage] with a scoped [TradeControllerCubit].
///
/// Navigation stays inside the trade module so the host app (`am_app`) does not
/// need to register `/trade/add` on its root [MaterialApp].
Future<void> openAddTradeWebPage(
  BuildContext context, {
  required String? portfolioId,
  String? portfolioName,
  VoidCallback? onTradeAdded,
}) {
  if (portfolioId == null || portfolioId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select a portfolio before adding a trade.')),
    );
    return Future.value();
  }

  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (routeContext) => Consumer(
        builder: (context, ref, _) {
          final cubitAsync = ref.watch(tradeControllerCubitProvider);

          return cubitAsync.when(
            data: (cubit) => BlocProvider<TradeControllerCubit>.value(
              value: cubit,
              child: AddTradeWebPage(
                portfolioId: portfolioId,
                portfolioName: portfolioName,
                onTradeAdded: onTradeAdded,
              ),
            ),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Scaffold(
              body: Center(child: Text('Error loading trade service: $error')),
            ),
          );
        },
      ),
    ),
  );
}
